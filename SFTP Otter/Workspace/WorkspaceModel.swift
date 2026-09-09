import Foundation

@Observable
final class WorkspaceModel {
#if DEBUG
    var localPreviewURL: URL?
#endif
    var visibleLocalBrowsers: [ObjectIdentifier: LocalFileBrowserModel] = [:]

    func refreshFiles() {
        let visibleSessionIDs = [selectedSessionID, secondarySessionID].compactMap { $0 }
        for session in sessions where visibleSessionIDs.contains(session.id) && session.isConnected && !session.isPreview {
            session.refresh()
        }
        for browser in visibleLocalBrowsers.values {
            browser.refresh()
        }
    }
    var section = WorkspaceSection.files
    var hosts: [Host] = []
    var sessions: [SFTPSession] = []
    var transfers: [FileTransfer] = []
    let uploads = UploadQueue()
    var selectedSessionID: UUID?
    var secondarySessionID: UUID?
    var activePane = BrowserPane.primary
    var hostSearch = ""
    var showHostEditor = false
    var showHostPicker = false
    var showPickerEditor = false
    private var pendingConnection: Host?
    private var pendingAuthentication: (host: Host, password: String)?
    var editingHost: Host?
    var connectingHost: Host?
    var showSettings = false
    var showError = false
    var errorMessage = ""
    let trustStore = HostKeyTrustStore()
    private let store = HostStore()
    private var hostsLoaded = false
    private var didRestoreConnections = false
    private var restorationQueue: [Host] = []
    private var restorationPaths: [String: String] = [:]
    private var restorationPanes: [UUID: BrowserPane] = [:]
    var reopenConnectedHosts = UserDefaults.standard.bool(forKey: "reopenConnectedHosts") {
        didSet {
            UserDefaults.standard.set(reopenConnectedHosts, forKey: "reopenConnectedHosts")
            rememberConnectedHosts()
            updateRememberedLocations()
        }
    }
    
    var rememberHostLocations = UserDefaults.standard.bool(forKey: "rememberHostLocations") {
        didSet {
            UserDefaults.standard.set(rememberHostLocations, forKey: "rememberHostLocations")
            updateRememberedLocations()
        }
    }
    
    private func updateRememberedLocations() {
        guard reopenConnectedHosts && rememberHostLocations else {
            UserDefaults.standard.removeObject(forKey: "connectedHost.locations")
            restorationPaths = [:]
            return
        }
        for session in sessions where session.isConnected && !session.isPreview && !session.isLoading {
            rememberLocation(session.path, for: session.host.id)
        }
    }
    
    private func rememberLocation(_ path: String, for hostID: UUID) {
        guard reopenConnectedHosts && rememberHostLocations else { return }
        var locations = UserDefaults.standard.dictionary(forKey: "connectedHost.locations") as? [String: String] ?? [:]
        locations[hostID.uuidString] = path
        UserDefaults.standard.set(locations, forKey: "connectedHost.locations")
    }
    
    var connectedHostIDs: [String] {
        sessions.filter { $0.isConnected && !$0.isPreview }.map { $0.host.id.uuidString }
    }
    
    func rememberConnectedHosts() {
        UserDefaults.standard.set(reopenConnectedHosts ? connectedHostIDs : [], forKey: "connectedHostIDs")
        UserDefaults.standard.set(reopenConnectedHosts ? session(in: .primary)?.host.id.uuidString : nil, forKey: "connectedHost.primary")
        UserDefaults.standard.set(reopenConnectedHosts ? session(in: .secondary)?.host.id.uuidString : nil, forKey: "connectedHost.secondary")
    }
    
    func restoreConnections() {
        guard !didRestoreConnections else { return }
        didRestoreConnections = true
        guard reopenConnectedHosts else { return }
        if rememberHostLocations {
            restorationPaths = UserDefaults.standard.dictionary(forKey: "connectedHost.locations") as? [String: String] ?? [:]
        }
        let ids = UserDefaults.standard.stringArray(forKey: "connectedHostIDs") ?? []
        restorationPaths = restorationPaths.filter { ids.contains($0.key) }
        for (key, pane) in [("connectedHost.primary", BrowserPane.primary), ("connectedHost.secondary", BrowserPane.secondary)] {
            if let value = UserDefaults.standard.string(forKey: key), let id = UUID(uuidString: value) { restorationPanes[id] = pane }
        }
        restorationQueue = ids.compactMap { id in hosts.first { $0.id.uuidString == id } }
        restoreNextConnection()
    }
    
    private func restoreNextConnection() {
        while !restorationQueue.isEmpty {
            let host = restorationQueue.removeFirst()
            activePane = restorationPanes[host.id] ?? .primary
            requestConnection(host)
            if connectingHost != nil { return }
        }
    }
    
    init() {
        do {
            hosts = try store.load()
            hostsLoaded = true
        }
        catch { report(error) }
    }
    
    var filteredHosts: [Host] {
        hosts.filter {
            hostSearch.isEmpty || $0.displayName.localizedStandardContains(hostSearch) || $0.address.localizedStandardContains(hostSearch)
        }
    }
    
    var selectedSession: SFTPSession? { session(in: activePane) ?? session(in: .primary) }
    
    @discardableResult
    func save(_ host: Host) -> Bool {
        guard hostsLoaded else { report(KeychainStoreError.unavailable); return false }
        var host = host
        host.address = host.address.trimmingCharacters(in: .whitespacesAndNewlines)
        host.username = host.username.trimmingCharacters(in: .whitespacesAndNewlines)
        if host.initialPath.isEmpty { host.initialPath = "." }
        var updated = hosts
        if let index = updated.firstIndex(where: { $0.id == host.id }) { updated[index] = host }
        else { updated.append(host) }
        do {
            try store.save(updated)
            hosts = updated
            for session in sessions { session.updateLabel(from: host) }
            editingHost = nil
            return true
        } catch { report(error); return false }
    }
    
    func edit(_ host: Host) {
        editingHost = host
        addHost()
    }
    
    func remove(_ host: Host) {
        guard hostsLoaded else { report(KeychainStoreError.unavailable); return }
        let updated = hosts.filter { $0.id != host.id }
        do {
            try store.save(updated)
            hosts = updated
        } catch { report(error) }
    }
    
    func addHost() {
        if showHostPicker { showPickerEditor = true }
        else { showHostEditor = true }
    }
    
    func hostPickerDismissed() {
        if let host = pendingConnection {
            pendingConnection = nil
            requestConnection(host)
        }
    }
    
    func requestConnection(_ host: Host) {
        if showHostPicker {
            pendingConnection = host
            showHostPicker = false
            return
        }
        if let session = sessions.first(where: { $0.host.id == host.id && $0.isConnected }) {
            select(session)
        } else if let password = host.savedPassword {
            connect(host, password: password)
        } else {
            connectingHost = host
        }
    }
    
    func submitAuthentication(_ host: Host, password: String) {
        pendingAuthentication = (host, password)
        connectingHost = nil
    }
    
    func authenticationDismissed() {
        if let authentication = pendingAuthentication {
            pendingAuthentication = nil
            connect(authentication.host, password: authentication.password)
        }
        restoreNextConnection()
    }
    
    func connect(_ host: Host, password: String) {
        if let old = sessions.first(where: { $0.host.id == host.id }) { close(old) }
        let trust = trustStore
        let session = SFTPSession(host: host, transport: CitadelSFTPTransport { key, endpoint in
            try await trust.verify(key: key, endpoint: endpoint)
        })
        if reopenConnectedHosts && rememberHostLocations,
           let path = restorationPaths.removeValue(forKey: host.id.uuidString) {
            session.path = path
            session.pathInput = path
        }
        session.didLoadLocation = { [weak self] path in
            self?.rememberLocation(path, for: host.id)
        }
        sessions.append(session)
        select(session)
        session.connect(password: password)
    }
    
    func session(in pane: BrowserPane) -> SFTPSession? {
        let id = pane == .primary ? selectedSessionID : secondarySessionID
        return sessions.first { $0.id == id }
    }
    
    func chooseHost(for pane: BrowserPane) {
        activePane = pane
        showHostPicker = true
    }
    
    func select(_ session: SFTPSession) {
        if activePane == .primary { selectedSessionID = session.id }
        else { secondarySessionID = session.id }
        section = .files
    }
    
    func close(_ session: SFTPSession) {
        trustStore.cancel(endpoint: "\(session.host.address.lowercased()):\(session.host.port)")
        session.close()
        sessions.removeAll { $0.id == session.id }
        if selectedSessionID == session.id { selectedSessionID = nil }
        if secondarySessionID == session.id { secondarySessionID = nil }
    }
    
    func upload(_ url: URL, to session: SFTPSession) {
        guard session.isConnected && !session.isPreview else { return }
        let transfer = FileTransfer(name: url.lastPathComponent, isUpload: true)
        transfers.insert(transfer, at: 0)
        uploads.enqueue(url, session: session, transfer: transfer)
    }
    
    func download(_ file: RemoteFile, from session: SFTPSession) {
        guard session.isConnected && !session.isPreview && !file.isDirectory else { return }
        let transfer = FileTransfer(name: file.name, isUpload: false)
        transfers.insert(transfer, at: 0)
        transfer.task = Task {
            let directory = URL.documentsDirectory.appending(path: "Downloads").appending(path: transfer.id.uuidString)
            let destination = directory.appending(path: URL(filePath: file.name).lastPathComponent)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try await session.transport.download(remote: file.path, local: destination) { completed, total in
                    await MainActor.run {
                        if completed == 0 { transfer.started = Date() }
                        transfer.status = transfer.isUpload ? "Uploading" : "Downloading"
                        transfer.completedBytes = completed
                        transfer.totalBytes = total
                    }
                }
                transfer.localURL = destination
                transfer.status = "Downloaded"
            } catch {
                transfer.status = Task.isCancelled ? "Cancelled" : "Failed"
                transfer.failure = Task.isCancelled ? nil : error.localizedDescription
            }
            transfer.finished = true
            transfer.task = nil
        }
    }
    
    func report(_ error: any Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

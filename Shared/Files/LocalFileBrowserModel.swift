import Foundation

@MainActor
@Observable
final class LocalFileBrowserModel {
    private(set) var directory: URL?
    private var root: URL?
    private var hasAccess = false
    private var persistenceKey: String?
    private var navigationTask: Task<Void, Never>?
    private var navigationID = UUID()
    private var pendingDirectory: URL?
    private var copyTask: Task<Void, Never>?
    var sortOrder = FileSortOrder() {
        didSet { files = sortOrder.sorted(files) }
    }
    
    func restoreLocation(for pane: BrowserPane) {
        persistenceKey = pane == .primary ? "localFolder.primary" : "localFolder.secondary"
#if os(macOS)
        guard UserDefaults.standard.bool(forKey: "reopenConnectedHosts"), let persistenceKey,
              let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        do {
            var stale = false
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], bookmarkDataIsStale: &stale)
            let path = UserDefaults.standard.string(forKey: persistenceKey + ".path")
            open(url)
            if let path {
                let current = URL(filePath: path).standardizedFileURL
                let rootPath = url.standardizedFileURL.path(percentEncoded: false)
                if current.path(percentEncoded: false).hasPrefix(rootPath.hasSuffix("/") ? rootPath : rootPath + "/") { navigate(to: current) }
            }
        } catch { self.error = error.localizedDescription }
#endif
    }
    
    func rememberLocation() {
        guard let persistenceKey else { return }
        guard UserDefaults.standard.bool(forKey: "reopenConnectedHosts") else {
            UserDefaults.standard.removeObject(forKey: persistenceKey)
            return
        }
#if os(macOS)
        guard let directory, let root else { return }
        do {
            let data = try root.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: persistenceKey)
            UserDefaults.standard.set(directory.path(percentEncoded: false), forKey: persistenceKey + ".path")
        } catch { self.error = error.localizedDescription }
#endif
    }
    private(set) var files: [RemoteFile] = []
    private(set) var error: String?
    var selection = FileSelection()
    var showHidden = false {
        didSet { refresh() }
    }

    var selectedURLs: [URL] {
        files.filter { selection.ids.contains($0.id) && $0.name != ".." }.map { URL(filePath: $0.path) }
    }

    func copyFiles(_ sources: [URL], to destination: URL) {
        let accessRoot = root
        copyTask = Task {
            let failures = await LocalFileOperations.copy(sources: sources, to: destination, accessRoot: accessRoot)
            refresh()
            await waitForNavigation()
            if !failures.isEmpty { error = failures.joined(separator: "\n") }
        }
    }

    func waitForCopy() async { await copyTask?.value }

    func waitForNavigation() async { await navigationTask?.value }

    func report(_ failure: any Error) { error = failure.localizedDescription }

    
    func open(_ url: URL) {
        close(forget: false)
        hasAccess = url.startAccessingSecurityScopedResource()
        root = url
        navigate(to: url)
    }
    
    func navigate(to url: URL) {
        navigationTask?.cancel()
        let request = UUID()
        navigationID = request
        pendingDirectory = url
        let root = root
        let showHidden = showHidden
        navigationTask = Task {
            do {
                let entries = try await LocalFileOperations.list(directory: url, root: root, showHidden: showHidden)
                guard !Task.isCancelled, navigationID == request else { return }
                pendingDirectory = nil
                directory = url
                files = sortOrder.sorted(entries)
                selection = FileSelection()
                error = nil
                rememberLocation()
            } catch {
                guard !Task.isCancelled, navigationID == request else { return }
                pendingDirectory = nil
                self.error = error.localizedDescription
                if directory == nil { directory = url }
            }
        }
    }

    func refresh() {
        if let directory = pendingDirectory ?? directory { navigate(to: directory) }
    }
    
    func close(forget: Bool = true) {
        navigationTask?.cancel()
        navigationTask = nil
        navigationID = UUID()
        pendingDirectory = nil
        if forget, let persistenceKey { UserDefaults.standard.removeObject(forKey: persistenceKey) }
        if hasAccess { root?.stopAccessingSecurityScopedResource() }
        hasAccess = false
        root = nil
        directory = nil
        files = []
        selection = FileSelection()
        error = nil
    }
}

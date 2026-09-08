import Foundation

@MainActor
@Observable
final class SFTPSession: Identifiable {
    let id = UUID()
    let host: Host
    var path: String
    var pathInput: String
    var didLoadLocation: (String) -> Void = { _ in }
    var files: [RemoteFile] = []
    var search = ""
    var showHidden = false
    var isPreview = false
    var isConnected = false
    var isLoading = false
    var error: String?
    private var history: [String] = []
    private var historyIndex = -1
    private var pendingHistoryIndex: Int?
    private var request: Task<Void, Never>?
    private var generation = UUID()
    let transport: any SFTPTransport

    init(host: Host, transport: any SFTPTransport) {
        self.host = host
        self.transport = transport
        path = host.initialPath
        pathInput = host.initialPath
    }

    var filteredFiles: [RemoteFile] {
        files.filter {
            (showHidden || !$0.name.hasPrefix(".")) && (search.isEmpty || $0.name.localizedStandardContains(search))
        }.sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    var browserFiles: [RemoteFile] {
        guard path != "/" else { return filteredFiles }
        let parent = RemoteFile(path: path + "/..", name: "..", isDirectory: true, size: 0, permissions: "")
        return [parent] + filteredFiles
    }

    func connect(password: String) {
        request?.cancel()
        let token = UUID()
        generation = token
        isLoading = true
        error = nil
        request = Task {
            do {
                try await transport.connect(host: host, password: password)
                try Task.checkCancellation()
                guard generation == token else { return }
                isConnected = true
                await load(path, token: token)
            } catch {
                guard generation == token else { return }
                self.error = error.localizedDescription
                isConnected = false
                isLoading = false
            }
        }
    }

    func navigate(to path: String) {
        guard isConnected && !isPreview else { return }
        pendingHistoryIndex = nil
        request?.cancel()
        let token = UUID()
        generation = token
        isLoading = true
        error = nil
        request = Task { await load(path, token: token) }
    }

    private func load(_ destination: String, token: UUID) async {
        do {
            let result = try await transport.list(path: destination)
            try Task.checkCancellation()
            guard generation == token else { return }
            if let index = pendingHistoryIndex {
                historyIndex = index
            } else if historyIndex < 0 || history[historyIndex] != result.path {
                history = Array(history.prefix(historyIndex + 1))
                history.append(result.path)
                historyIndex = history.count - 1
            }
            pendingHistoryIndex = nil
            path = result.path
            pathInput = result.path
            files = result.files
            didLoadLocation(result.path)
        } catch {
            guard generation == token else { return }
            pendingHistoryIndex = nil
            self.error = error.localizedDescription
            pathInput = path
        }
        guard generation == token else { return }
        isLoading = false
    }

    var canGoBack: Bool { historyIndex > 0 }
    var canGoForward: Bool { historyIndex >= 0 && historyIndex < history.count - 1 }

    func goBack() {
        guard canGoBack else { return }
        let index = historyIndex - 1
        navigate(to: history[index])
        pendingHistoryIndex = index
    }

    func goForward() {
        guard canGoForward else { return }
        let index = historyIndex + 1
        navigate(to: history[index])
        pendingHistoryIndex = index
    }

    func goUp() {
        navigate(to: path == "/" ? "/" : path + "/..")
    }

    func refresh() { navigate(to: path) }

    func close() {
        request?.cancel()
        generation = UUID()
        isConnected = false
        Task { await transport.close() }
    }
}

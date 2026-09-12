import Foundation

actor ActionDownloadTransport: SFTPTransport {
    let slow: Bool
    let failingPath: String?
    private(set) var activeDownloads = 0
    private(set) var peakDownloads = 0
    private(set) var cancelledDownloads = 0
    private(set) var permissionChanges: [String: UInt32] = [:]

    init(slow: Bool = false, failingPath: String? = nil) {
        self.slow = slow
        self.failingPath = failingPath
    }

    func connect(host: Host, password: String) async throws {}
    func close() async {}
    func upload(local: URL, remote: String, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {}

    func list(path: String) async throws -> (path: String, files: [RemoteFile]) {
        let names: [String]
        switch path {
        case "/folder": names = ["one.txt", "two.txt", "nested", "empty"]
        case "/folder/nested": names = ["three.txt"]
        default: names = []
        }
        return (path, names.map {
            RemoteFile(path: path + "/" + $0, name: $0, isDirectory: !$0.hasSuffix(".txt"), size: 7, permissions: "")
        })
    }

    func setPermissions(path: String, mode: UInt32) async throws {
        permissionChanges[path] = mode
    }

    func download(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        activeDownloads += 1
        peakDownloads = max(peakDownloads, activeDownloads)
        defer { activeDownloads -= 1 }
        do {
            await progress(0, 7)
            try await Task.sleep(for: slow && remote != failingPath ? .seconds(5) : .milliseconds(40))
            if remote == failingPath { throw CocoaError(.fileReadUnknown) }
            try Data("content".utf8).write(to: local)
            await progress(7, 7)
        } catch {
            if error is CancellationError { cancelledDownloads += 1 }
            throw error
        }
    }
}

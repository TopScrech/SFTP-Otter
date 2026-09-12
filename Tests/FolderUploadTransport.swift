import Foundation

actor FolderUploadTransport: SFTPTransport {
    private var directories: Set<String> = ["/uploads"]
    private(set) var contents: [String: Data] = [:]
    private(set) var active = 0
    private(set) var peak = 0
    private(set) var cancelled = 0
    private let delay: Duration

    init(delay: Duration = .milliseconds(80), existingFolder: Bool = false) {
        self.delay = delay
        if existingFolder {
            directories.insert("/uploads/source")
            contents["/uploads/source/existing.txt"] = Data("keep".utf8)
        }
    }

    func connect(host: Host, password: String) async throws {}
    func close() async {}

    func list(path: String) async throws -> (path: String, files: [RemoteFile]) {
        guard directories.contains(path) else { throw CocoaError(.fileNoSuchFile) }
        let folders = directories.filter { $0 != path && URL(filePath: $0).deletingLastPathComponent().path == path }
            .map { RemoteFile(path: $0, name: URL(filePath: $0).lastPathComponent, isDirectory: true, size: 0, permissions: "") }
        let files = contents.filter { URL(filePath: $0.key).deletingLastPathComponent().path == path }
            .map { RemoteFile(path: $0.key, name: URL(filePath: $0.key).lastPathComponent, isDirectory: false, size: UInt64($0.value.count), permissions: "") }
        return (path, folders + files)
    }

    func createDirectory(path: String) async throws {
        try Task.checkCancellation()
        guard directories.contains(URL(filePath: path).deletingLastPathComponent().path) else { throw CocoaError(.fileNoSuchFile) }
        guard directories.insert(path).inserted else { throw CocoaError(.fileWriteFileExists) }
    }

    func hasDirectory(_ path: String) -> Bool { directories.contains(path) }

    func upload(local: URL, remote: String, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        try await upload(local: local, remote: remote, replacing: false, progress: progress)
    }

    func upload(local: URL, remote: String, replacing: Bool, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        guard directories.contains(URL(filePath: remote).deletingLastPathComponent().path) else { throw CocoaError(.fileNoSuchFile) }
        guard replacing || contents[remote] == nil else { throw CocoaError(.fileWriteFileExists) }
        let data = try Data(contentsOf: local)
        active += 1
        peak = max(peak, active)
        defer { active -= 1 }
        do {
            await progress(0, UInt64(data.count))
            try await Task.sleep(for: delay)
            try Task.checkCancellation()
            contents[remote] = data
            await progress(UInt64(data.count), UInt64(data.count))
        } catch {
            if error is CancellationError { cancelled += 1 }
            throw error
        }
    }

    func download(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {}
}

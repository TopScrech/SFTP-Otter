import Foundation

actor UploadConflictTransport: SFTPTransport {
    private let delay: Duration
    private var active = 0
    private(set) var peak = 0

    init(delay: Duration = .zero) { self.delay = delay }

    var destinations: [String] = []
    var replacements: [Bool] = []

    func connect(host: Host, password: String) async throws {}
    func close() async {}
    func list(path: String) async throws -> (path: String, files: [RemoteFile]) {
        (path, [RemoteFile(path: path + "/photo.png", name: "photo.png", isDirectory: false, size: 5, permissions: "")])
    }
    func upload(local: URL, remote: String, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        try await upload(local: local, remote: remote, replacing: false, progress: progress)
    }
    func upload(local: URL, remote: String, replacing: Bool, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        active += 1
        peak = max(peak, active)
        defer { active -= 1 }
        try await Task.sleep(for: delay)
        destinations.append(remote)
        replacements.append(replacing)
    }
    func download(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {}
}

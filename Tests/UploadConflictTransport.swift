import Foundation

actor UploadConflictTransport: SFTPTransport {
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
        destinations.append(remote)
        replacements.append(replacing)
    }
    func download(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {}
}

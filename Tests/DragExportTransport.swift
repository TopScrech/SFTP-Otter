import Foundation

actor DragExportTransport: SFTPTransport {
    private(set) var downloads: [String] = []
    func connect(host: Host, password: String) async throws {}
    func close() async {}
    func list(path: String) async throws -> (path: String, files: [RemoteFile]) {
        (path, [RemoteFile(path: path + "/child.txt", name: "child.txt", isDirectory: false, size: 7, permissions: "-rw-r--r--")])
    }
    func upload(local: URL, remote: String, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {}
    func download(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        downloads.append(remote)
        try Data("fixture".utf8).write(to: local, options: .withoutOverwriting)
    }
}

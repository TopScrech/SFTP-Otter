import Foundation

actor NavigationTransport: SFTPTransport {
    func connect(host: SFTPProTests.Host, password: String) async throws {}
    func list(path: String) async throws -> (path: String, files: [RemoteFile]) {
        if path == "/missing" { throw CocoaError(.fileNoSuchFile) }
        return (path == "." ? "/" : path, [])
    }
    func upload(local: URL, remote: String, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {}
    func download(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {}
    func close() async {}
}

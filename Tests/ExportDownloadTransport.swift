import Foundation

actor ExportDownloadTransport: SFTPTransport {
    let fails: Bool

    init(fails: Bool = false) { self.fails = fails }

    func connect(host: Host, password: String) async throws {}
    func close() async {}
    func list(path: String) async throws -> (path: String, files: [RemoteFile]) { (path, []) }
    func upload(local: URL, remote: String, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {}
    func download(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        await progress(0, 100)
        try await Task.sleep(for: .milliseconds(50))
        if fails { throw CocoaError(.fileReadUnknown) }
        await progress(100, 100)
    }
}

import Foundation

nonisolated protocol SFTPTransport: AnyObject, Sendable {
    func connect(host: Host, password: String) async throws
    func list(path: String) async throws -> (path: String, files: [RemoteFile])
    func upload(local: URL, remote: String, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws
    func download(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws
    func rename(path: String, to destination: String) async throws
    func createDirectory(path: String) async throws
    func remove(path: String, isDirectory: Bool) async throws
    func setPermissions(path: String, mode: UInt32) async throws
    func close() async
}

nonisolated extension SFTPTransport {
    func rename(path: String, to destination: String) async throws { throw CocoaError(.featureUnsupported) }
    func createDirectory(path: String) async throws { throw CocoaError(.featureUnsupported) }
    func remove(path: String, isDirectory: Bool) async throws { throw CocoaError(.featureUnsupported) }
    func setPermissions(path: String, mode: UInt32) async throws { throw CocoaError(.featureUnsupported) }
}

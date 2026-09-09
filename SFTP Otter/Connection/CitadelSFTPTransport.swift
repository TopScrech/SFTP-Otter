import Foundation
import CryptoKit
import OSLog
import NIOSSH
@preconcurrency import Citadel

actor CitadelSFTPTransport: SFTPTransport {
    private static let logger = Logger(subsystem: "SFTPOtter", category: "Connection")
    private static var connectionAlgorithms: SSHAlgorithms {
        // Citadel 0.12.1 provides RSA and AES128CTR in this preset
        // Keep NIOSSH’s default key exchanges by removing the preset’s DH additions
        var algorithms = SSHAlgorithms.all
        algorithms.keyExchangeAlgorithms = nil
        return algorithms
    }
    
    private let gate = TransferGate()
    private var ssh: SSHClient?
    private var sftp: SFTPClient?
    private var validator: ServerKeyValidator?
    private var generation = UUID()
    private let verifyHostKey: @Sendable (String, String) async throws -> Void
    
    init(verifyHostKey: @escaping @Sendable (String, String) async throws -> Void) {
        self.verifyHostKey = verifyHostKey
    }
    
    func connect(host: Host, password: String) async throws {
        await close()
        let token = UUID()
        generation = token
        let started = ContinuousClock.now
        var stage = "ssh_handshake_and_authentication"
        var outcome = "success"
        var errorType = "none"
        var errorCode = 0
        defer {
            let elapsed = started.duration(to: .now).components
            let durationMS = Double(elapsed.seconds) * 1_000 + Double(elapsed.attoseconds) / 1_000_000_000_000_000
            Self.logger.notice("event=connection_completed request_id=\(token.uuidString, privacy: .public) stage=\(stage, privacy: .public) outcome=\(outcome, privacy: .public) duration_ms=\(durationMS) error_type=\(errorType, privacy: .public) error_code=\(errorCode)")
        }
        Self.logger.notice("event=connection_started request_id=\(token.uuidString, privacy: .public) host_id=\(host.id.uuidString, privacy: .public) port=\(host.port) auth_method=password")
        let endpoint = "\(host.address.lowercased()):\(host.port)"
        let verify = verifyHostKey
        let validator = ServerKeyValidator {
            Self.logger.notice("event=host_key_verification_started request_id=\(token.uuidString, privacy: .public)")
            do {
                try await verify($0, endpoint)
                Self.logger.notice("event=host_key_verification_completed request_id=\(token.uuidString, privacy: .public) outcome=success")
            } catch {
                Self.logger.error("event=host_key_verification_completed request_id=\(token.uuidString, privacy: .public) outcome=failure error_type=\(String(reflecting: type(of: error)), privacy: .public)")
                throw error
            }
        }
        self.validator = validator
        do {
            try await withTaskCancellationHandler {
                let client = try await SSHClient.connect(
                    host: host.address, port: host.port,
                    authenticationMethod: .passwordBased(username: host.username, password: password),
                    hostKeyValidator: .custom(validator),
                    reconnect: .never,
                    algorithms: Self.connectionAlgorithms
                )
                do {
                    try Task.checkCancellation()
                    stage = "open_sftp"
                    Self.logger.notice("event=ssh_authenticated request_id=\(token.uuidString, privacy: .public)")
                    let channel = try await client.openSFTP()
                    guard token == generation else { throw CancellationError() }
                    try Task.checkCancellation()
                    ssh = client
                    sftp = channel
                } catch {
                    try? await client.close()
                    throw error
                }
            } onCancel: {
                validator.cancel()
            }
        } catch {
            outcome = error is CancellationError ? "cancelled" : "failure"
            errorType = String(reflecting: type(of: error))
            errorCode = (error as NSError).code
            Self.logger.error("event=connection_error request_id=\(token.uuidString, privacy: .public) stage=\(stage, privacy: .public) error_type=\(errorType, privacy: .public) error_code=\(errorCode) detail=\(String(describing: error), privacy: .private)")
            if let sshError = error as? NIOSSHError, sshError.type == .keyExchangeNegotiationFailure {
                await SSHNegotiationLogger.inspect(host: host.address, port: host.port, requestID: token.uuidString)
                throw SFTPConnectionError.incompatibleAlgorithms
            }
            throw error
        }
    }
    
    func list(path: String) async throws -> (path: String, files: [RemoteFile]) {
        let requestID = UUID().uuidString
        Self.logger.notice("event=directory_listing_started request_id=\(requestID, privacy: .public) connection_id=\(self.generation.uuidString, privacy: .public)")
        do {
            guard let sftp else { throw ConnectionError.notConnected }
            let resolved = try await sftp.getRealPath(atPath: path)
            let entries = try await sftp.listDirectory(atPath: resolved).flatMap(\.components)
            let files = entries.compactMap { entry -> RemoteFile? in
                let name = entry.filename
                guard name != ".", name != "..", !name.contains("/"), !name.contains("\0") else { return nil }
                let mode = entry.attributes.permissions ?? 0
                return RemoteFile(
                    path: resolved + (resolved.hasSuffix("/") ? "" : "/") + name,
                    name: name, isDirectory: mode & 0o170000 == 0o040000,
                    size: entry.attributes.size ?? 0,
                    modified: entry.attributes.accessModificationTime?.modificationTime,
                    permissions: Self.permissions(mode),
                    mode: mode,
                    owner: entry.attributes.uidgid.map { String($0.userId) },
                    group: entry.attributes.uidgid.map { String($0.groupId) }
                )
            }
            Self.logger.notice("event=directory_listing_completed request_id=\(requestID, privacy: .public) outcome=success file_count=\(files.count)")
            return (resolved, files)
        } catch {
            Self.logger.error("event=directory_listing_completed request_id=\(requestID, privacy: .public) outcome=failure error_type=\(String(reflecting: type(of: error)), privacy: .public) error_code=\((error as NSError).code) detail=\(String(describing: error), privacy: .private)")
            throw error
        }
    }
    
    func upload(local: URL, remote: String, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        try await gate.run { try await self.performUpload(local: local, remote: remote, progress: progress) }
    }
    
    func download(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        try await gate.run { try await self.performDownload(remote: remote, local: local, progress: progress) }
    }
    
    private func performUpload(local: URL, remote: String, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        guard let ssh else { throw ConnectionError.notConnected }
        let sftp = try await ssh.openSFTP()
        defer { Task { try? await sftp.close() } }
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let disk = try TransferDiskFile(reading: local)
            let temporary = remote + ".sftp-otter-" + UUID().uuidString + ".part"
            do {
                let total = try await disk.size()
                let file = try await sftp.openFile(filePath: temporary, flags: [.write, .create, .forceCreate])
                let handle = RemoteFileHandle(file: file)
                do {
                    try await TransferPipeline.copy(total: total, read: { try await disk.read(offset: $0, length: $1) }, write: { try await handle.write($0, offset: $1) }, progress: progress)
                    guard try await disk.size() == total else { throw SFTPConnectionError.remoteFileChanged }
                    try await handle.close()
                    try await disk.close()
                    try Task.checkCancellation()
                    // SFTP v3 rename refuses an existing destination, preserving the user's files
                    try await sftp.rename(at: temporary, to: remote)
                } catch {
                    try? await handle.close()
                    throw error
                }
            } catch {
                try? await disk.close()
                try? await self.sftp?.remove(at: temporary)
                throw error
            }
        } onCancel: {
            Task { try? await sftp.close() }
        }
    }
    
    private func performDownload(remote: String, local: URL, progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        guard let ssh else { throw ConnectionError.notConnected }
        let sftp = try await ssh.openSFTP()
        defer { Task { try? await sftp.close() } }
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let file = try await sftp.openFile(filePath: remote, flags: .read)
            let handle = RemoteFileHandle(file: file)
            let temporary = local.appendingPathExtension("part")
            do {
                let before = try await handle.attributes()
                guard let total = before.size else { throw SFTPConnectionError.unexpectedEndOfFile }
                let disk = try TransferDiskFile(writing: temporary)
                do {
                    try await TransferPipeline.copy(total: total, read: { try await handle.read(offset: $0, length: $1) }, write: { try await disk.write($0, offset: $1) }, progress: progress)
                    let after = try await handle.attributes()
                    guard after.size == before.size, after.accessModificationTime == before.accessModificationTime else { throw SFTPConnectionError.remoteFileChanged }
                    try await disk.close()
                    try await handle.close()
                    try Task.checkCancellation()
                    try FileManager.default.moveItem(at: temporary, to: local)
                } catch {
                    try? await disk.close()
                    throw error
                }
            } catch {
                try? await handle.close()
                try? FileManager.default.removeItem(at: temporary)
                throw error
            }
        } onCancel: {
            Task { try? await sftp.close() }
        }
    }
    
    func rename(path: String, to destination: String) async throws {
        guard let sftp else { throw ConnectionError.notConnected }
        try await sftp.rename(at: path, to: destination)
    }
    
    func createDirectory(path: String) async throws {
        guard let sftp else { throw ConnectionError.notConnected }
        try await sftp.createDirectory(atPath: path)
    }
    
    func remove(path: String, isDirectory: Bool) async throws {
        guard let sftp else { throw ConnectionError.notConnected }
        if isDirectory { try await sftp.rmdir(at: path) }
        else { try await sftp.remove(at: path) }
    }
    
    func setPermissions(path: String, mode: UInt32) async throws {
        guard let sftp else { throw ConnectionError.notConnected }
        var attributes = SFTPFileAttributes()
        attributes.permissions = mode
        try await sftp.setAttributes(at: path, to: attributes)
    }
    
    func close() async {
        generation = UUID()
        validator?.cancel()
        validator = nil
        let channel = sftp
        let client = ssh
        sftp = nil
        ssh = nil
        try? await channel?.close()
        try? await client?.close()
    }
    
    private static func permissions(_ mode: UInt32) -> String {
        var result = mode & 0o170000 == 0o040000 ? "d" : (mode & 0o170000 == 0o120000 ? "l" : "-")
        let bits: [(UInt32, String)] = [(0o400, "r"), (0o200, "w"), (0o100, "x"), (0o40, "r"), (0o20, "w"), (0o10, "x"), (0o4, "r"), (0o2, "w"), (0o1, "x")]
        for (bit, letter) in bits { result += mode & bit != 0 ? letter : "-" }
        return result
    }
}

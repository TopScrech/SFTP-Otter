import Foundation
import CryptoKit
import OSLog

@MainActor
@Observable
final class HostKeyTrustStore {
    var challenge: HostKeyChallenge?
    private var requests: [(challenge: HostKeyChallenge, key: String, continuation: CheckedContinuation<Void, any Error>)] = []
    private static let logger = Logger(subsystem: "SFTPPro", category: "TrustedHosts")
    private let keychain: KeychainHostData
    private let url: URL

    init(url: URL = URL.applicationSupportDirectory.appending(path: "SFTP Pro/known-hosts.json"), service: String = "SFTPPro.trusted-hosts") {
        keychain = KeychainHostData(service: service)
        self.url = url
    }

    func cancel(endpoint: String) {
        let ids = requests.filter { $0.challenge.endpoint == endpoint }.map { $0.challenge.id }
        ids.forEach { cancel($0) }
    }

    func verify(key: String, endpoint: String) async throws {
        let keys = try load()
        if let trusted = keys[endpoint] {
            guard trusted == key else { throw SFTPConnectionError.hostKeyChanged(endpoint) }
            Self.logger.notice("event=host_key_verified storage=keychain")
            return
        }
        Self.logger.notice("event=host_key_approval_required reason=not_saved")
        let fields = key.split(separator: " ")
        guard fields.count >= 2, let bytes = Data(base64Encoded: String(fields[1])) else {
            throw SFTPConnectionError.invalidHostKey
        }
        let fingerprint = "SHA256:" + Data(SHA256.hash(data: bytes)).base64EncodedString().replacing("=", with: "")
        let request = HostKeyChallenge(id: UUID(), endpoint: endpoint, fingerprint: fingerprint)
        let timeout = Task {
            try await Task.sleep(for: .seconds(60))
            cancel(request.id)
        }
        defer { timeout.cancel() }
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { continuation in
                requests.append((request, key, continuation))
                if challenge == nil { challenge = request }
            }
        } onCancel: {
            Task { @MainActor in self.cancel(request.id) }
        }
    }

    func resolve(trust: Bool) {
        guard let current = challenge, let index = requests.firstIndex(where: { $0.challenge.id == current.id }) else { return }
        let request = requests.remove(at: index)
        do {
            guard trust else { throw SFTPConnectionError.hostKeyRejected }
            var keys = try load()
            if let existing = keys[current.endpoint], existing != request.key {
                throw SFTPConnectionError.hostKeyChanged(current.endpoint)
            }
            keys[current.endpoint] = request.key
            try save(keys)
            request.continuation.resume()
            // Parallel connections to the same server share one saved approval
            let waiting = requests.filter { $0.challenge.endpoint == current.endpoint }
            requests.removeAll { $0.challenge.endpoint == current.endpoint }
            for pending in waiting {
                if pending.key == request.key { pending.continuation.resume() }
                else { pending.continuation.resume(throwing: SFTPConnectionError.hostKeyChanged(current.endpoint)) }
            }
        } catch {
            request.continuation.resume(throwing: error)
        }
        challenge = requests.first?.challenge
    }

    private func cancel(_ id: UUID) {
        guard let index = requests.firstIndex(where: { $0.challenge.id == id }) else { return }
        requests.remove(at: index).continuation.resume(throwing: CancellationError())
        if challenge?.id == id { challenge = requests.first?.challenge }
    }

    func forget(endpoint: String) throws {
        var keys = try load()
        keys.removeValue(forKey: endpoint)
        try save(keys)
    }

    func fingerprint(for key: String) -> String {
        let fields = key.split(separator: " ")
        guard fields.count >= 2, let bytes = Data(base64Encoded: String(fields[1])) else { return "Invalid key" }
        return "SHA256:" + Data(SHA256.hash(data: bytes)).base64EncodedString().replacing("=", with: "")
    }

    func load() throws -> [String: String] {
        do {
            if let data = try keychain.load() {
                return try JSONDecoder().decode([String: String].self, from: data)
            }
            guard FileManager.default.fileExists(atPath: url.path()) else { return [:] }
            let keys = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: url))
            try save(keys)
            Self.logger.notice("event=trusted_hosts_migrated storage=keychain host_count=\(keys.count)")
            return keys
        } catch {
            Self.logger.error("event=trusted_hosts_load_failed error_type=\(String(reflecting: type(of: error)), privacy: .public)")
            throw error
        }
    }

    private func save(_ keys: [String: String]) throws {
        do {
            try keychain.save(JSONEncoder().encode(keys))
            Self.logger.notice("event=trusted_hosts_saved storage=keychain host_count=\(keys.count)")
        } catch {
            Self.logger.error("event=trusted_hosts_save_failed error_type=\(String(reflecting: type(of: error)), privacy: .public)")
            throw error
        }
        if FileManager.default.fileExists(atPath: url.path()) {
            do { try FileManager.default.removeItem(at: url) }
            catch { Self.logger.error("event=trusted_hosts_legacy_cleanup_failed") }
        }
    }
}

import Foundation
import Testing
import Security

@MainActor
struct HostKeyTrustTests {
    @Test
    func acceptedKeyPersistsAndChangedKeyFails() async throws {
        let service = "SFTPPro.tests.\(UUID().uuidString)"
        defer { removeKeychainEntry(service: service) }
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "known-hosts.json")
        let store = HostKeyTrustStore(url: url, service: service)
        let verification = Task { try await store.verify(key: "ssh-ed25519 AQID", endpoint: "fixture:22") }
        while store.challenge == nil { await Task.yield() }
        #expect(store.challenge?.fingerprint.hasPrefix("SHA256:") == true)
        store.resolve(trust: true)
        try await verification.value
        let reloaded = HostKeyTrustStore(url: url, service: service)
        try await reloaded.verify(key: "ssh-ed25519 AQID", endpoint: "fixture:22")
        #expect(reloaded.challenge == nil)
        #expect(try reloaded.load()["fixture:22"] == "ssh-ed25519 AQID")
        await #expect(throws: SFTPConnectionError.self, "A changed server key must fail") {
            try await reloaded.verify(key: "ssh-ed25519 BAUG", endpoint: "fixture:22")
        }
    }

    @Test
    func forgettingKeyRequiresVerificationAgain() async throws {
        let service = "SFTPPro.tests.\(UUID().uuidString)"
        defer { removeKeychainEntry(service: service) }
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "known-hosts.json")
        try JSONEncoder().encode(["fixture:22": "ssh-ed25519 AQID", "other:22": "ssh-ed25519 BAUG"]).write(to: url)
        let store = HostKeyTrustStore(url: url, service: service)
        try store.forget(endpoint: "fixture:22")
        #expect(try store.load() == ["other:22": "ssh-ed25519 BAUG"])
        #expect(!FileManager.default.fileExists(atPath: url.path()))
        #expect(try HostKeyTrustStore(url: url, service: service).load() == ["other:22": "ssh-ed25519 BAUG"])
        let verification = Task { try await store.verify(key: "ssh-ed25519 AQID", endpoint: "fixture:22") }
        while store.challenge == nil { await Task.yield() }
        #expect(store.challenge?.endpoint == "fixture:22")
        store.resolve(trust: false)
        await #expect(throws: SFTPConnectionError.self) { try await verification.value }
    }

    @Test
    func rejectedAndCancelledKeysAreNotSaved() async throws {
        let service = "SFTPPro.tests.\(UUID().uuidString)"
        defer { removeKeychainEntry(service: service) }
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).appending(path: "known-hosts.json")
        let store = HostKeyTrustStore(url: url, service: service)
        let rejected = Task { try await store.verify(key: "ssh-ed25519 AQID", endpoint: "fixture:22") }
        while store.challenge == nil { await Task.yield() }
        store.resolve(trust: false)
        await #expect(throws: (any Error).self, "Rejected keys must fail") {
            try await rejected.value
        }
        #expect(!FileManager.default.fileExists(atPath: url.path()))
        let cancelled = Task { try await store.verify(key: "ssh-ed25519 AQID", endpoint: "fixture:22") }
        while store.challenge == nil { await Task.yield() }
        cancelled.cancel()
        await #expect(throws: (any Error).self, "Cancelled verification must fail") {
            try await cancelled.value
        }
        #expect(store.challenge == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path()))
    }

    @Test
    func corruptSavedTrustFailsWithoutRequestingNewApproval() async throws {
        let service = "SFTPPro.tests.\(UUID().uuidString)"
        defer { removeKeychainEntry(service: service) }
        try KeychainHostData(service: service).save(Data("invalid".utf8))
        let store = HostKeyTrustStore(url: URL.temporaryDirectory.appending(path: UUID().uuidString), service: service)
        await #expect(throws: DecodingError.self) {
            try await store.verify(key: "ssh-ed25519 AQID", endpoint: "fixture:22")
        }
        #expect(store.challenge == nil)
    }

    private func removeKeychainEntry(service: String) {
        let status = SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "saved-hosts"
        ] as CFDictionary)
        #expect(status == errSecSuccess || status == errSecItemNotFound)
    }
}

import Foundation
import Security
import Testing

@MainActor
struct HostStoreTests {
    @Test
    func savedHostsPersistAcrossStoreInstancesAndUpdates() throws {
        let service = "SFTPOtter.tests.\(UUID().uuidString)"
        defer { removeKeychainEntry(service: service) }
        let legacyURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appending(path: "hosts.json")
        let host = Host(name: "Fixture", address: "example.invalid", port: 2222, username: "fixture", initialPath: "/backups", savedPassword: "fixture-only-password")
        try HostStore(service: service, legacyURL: legacyURL).save([host])
        #expect(try HostStore(service: service, legacyURL: legacyURL).load() == [host])
        var updated = host
        updated.name = "Updated"
        updated.savedPassword = nil
        try HostStore(service: service, legacyURL: legacyURL).save([updated])
        #expect(try HostStore(service: service, legacyURL: legacyURL).load() == [updated])
        try HostStore(service: service, legacyURL: legacyURL).save([])
        #expect(try HostStore(service: service, legacyURL: legacyURL).load().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: legacyURL.path()))
    }

    @Test
    func migratesLegacyHostsAndKeepsKeychainAuthoritative() throws {
        let service = "SFTPOtter.tests.\(UUID().uuidString)"
        defer { removeKeychainEntry(service: service) }
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "hosts.json")
        let host = Host(name: "Migrated", address: "example.invalid")
        try JSONEncoder().encode([host]).write(to: url)
        #expect(try HostStore(service: service, legacyURL: url).load() == [host])
        #expect(!FileManager.default.fileExists(atPath: url.path()))
        try JSONEncoder().encode([Host(name: "Stale")]).write(to: url)
        #expect(try HostStore(service: service, legacyURL: url).load() == [host])
        #expect(!FileManager.default.fileExists(atPath: url.path()))
    }

    @Test
    func corruptKeychainDataDoesNotFallBackToEmptyHosts() throws {
        let service = "SFTPOtter.tests.\(UUID().uuidString)"
        defer { removeKeychainEntry(service: service) }
        try KeychainHostData(service: service).save(Data("invalid JSON".utf8))
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString)
        #expect(throws: DecodingError.self) {
            try HostStore(service: service, legacyURL: url).load()
        }
    }

    private func removeKeychainEntry(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "saved-hosts"
        ]
        let status = SecItemDelete(query as CFDictionary)
        #expect(status == errSecSuccess || status == errSecItemNotFound)
    }
}

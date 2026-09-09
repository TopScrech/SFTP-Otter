import Foundation
import OSLog

struct HostStore {
    private static let logger = Logger(subsystem: "SFTPOtter", category: "SavedHosts")
    private let keychain: KeychainHostData
    private let legacyURL: URL
    
    init(
        service: String = "SFTPPro.saved-hosts",
        legacyURL: URL = URL.applicationSupportDirectory.appending(path: "SFTP Pro/hosts.json")
    ) {
        keychain = KeychainHostData(service: service)
        self.legacyURL = legacyURL
    }
    
    func load() throws -> [Host] {
        do {
            if let data = try keychain.load() {
                let hosts = try JSONDecoder().decode([Host].self, from: data)
                removeLegacyFile()
                Self.logger.notice("event=hosts_loaded storage=keychain host_count=\(hosts.count)")
                return hosts
            }
            guard FileManager.default.fileExists(atPath: legacyURL.path()) else { return [] }
            let hosts = try JSONDecoder().decode([Host].self, from: Data(contentsOf: legacyURL))
            try save(hosts)
            Self.logger.notice("event=hosts_migrated storage=keychain host_count=\(hosts.count)")
            return hosts
        } catch {
            Self.logger.error("event=hosts_load_failed error_type=\(String(reflecting: type(of: error)), privacy: .public) detail=\(error.localizedDescription, privacy: .private)")
            throw error
        }
    }
    
    func save(_ hosts: [Host]) throws {
        do {
            try keychain.save(JSONEncoder().encode(hosts))
            removeLegacyFile()
            Self.logger.notice("event=hosts_saved storage=keychain host_count=\(hosts.count)")
        } catch {
            Self.logger.error("event=hosts_save_failed error_type=\(String(reflecting: type(of: error)), privacy: .public) detail=\(error.localizedDescription, privacy: .private)")
            throw error
        }
    }
    
    private func removeLegacyFile() {
        guard FileManager.default.fileExists(atPath: legacyURL.path()) else { return }
        do { try FileManager.default.removeItem(at: legacyURL) }
        catch {
            Self.logger.error("event=legacy_hosts_cleanup_failed detail=\(error.localizedDescription, privacy: .private)")
        }
    }
}

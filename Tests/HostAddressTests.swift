import Foundation
import Testing

struct HostAddressTests {
    @Test(arguments: [
        "http://example.com", "https://example.com/",
        "ssh://example.com", "sftp://example.com/",
        " HTTPS://example.com/\n", " example.com\n"
    ])
    func normalizesPastedAddresses(address: String) {
        #expect(Host(address: address).connectionAddress == "example.com")
    }

    @Test(arguments: [
        "192.0.2.1", "2001:db8::1", "server.local",
        "sftp://example.com:2222", "sftp://user@example.com",
        "https://example.com/files", "https://example.com?host=other",
        "https://example.com#fragment", "ftp://example.com"
    ])
    func preservesAddressesWithOtherComponents(address: String) {
        #expect(Host(address: address).connectionAddress == address)
    }

    @Test
    func normalizesPreviouslySavedHost() throws {
        let saved = Host(address: "http://example.com", port: 2222, username: "fixture")
        let restored = try JSONDecoder().decode(Host.self, from: JSONEncoder().encode(saved))
        #expect(restored.connectionAddress == "example.com")
        #expect(restored.port == 2222)
        #expect(restored.username == "fixture")
    }
}

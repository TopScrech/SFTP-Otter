import Foundation
import Testing

@MainActor
struct SessionNavigationTests {
    @Test
    func historyPreservesForwardNavigationOnRefreshAndFailedNavigation() async throws {
        let session = SFTPSession(host: Host(), transport: NavigationTransport())
        session.connect(password: "")
        try await settle(session)
        session.navigate(to: "/backups")
        try await settle(session)
        session.navigate(to: "/archives")
        try await settle(session)
        session.goBack()
        try await settle(session)
        #expect(session.path == "/backups")
        #expect(session.canGoForward)
        session.refresh()
        try await settle(session)
        #expect(session.canGoForward)
        session.navigate(to: "/missing")
        try await settle(session)
        #expect(session.path == "/backups")
        #expect(session.canGoForward)
        session.goForward()
        try await settle(session)
        #expect(session.path == "/archives")
        #expect(session.error == nil)
        session.close()
    }
    
    @Test
    func reportsOnlySuccessfullyOpenedLocations() async throws {
        let session = SFTPSession(host: Host(), transport: NavigationTransport())
        var locations: [String] = []
        session.didLoadLocation = { locations.append($0) }
        session.path = "/saved-folder"
        session.connect(password: "")
        try await settle(session)
        #expect(locations == ["/saved-folder"])
        session.navigate(to: "/missing")
        try await settle(session)
        #expect(locations == ["/saved-folder"])
        session.navigate(to: "/backups")
        try await settle(session)
        #expect(locations == ["/saved-folder", "/backups"])
        session.close()
    }
    
    private func settle(_ session: SFTPSession) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while session.isLoading && ContinuousClock.now < deadline { await Task.yield() }
        #expect(!session.isLoading)
    }
}

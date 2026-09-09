import Testing

@MainActor
struct BrowserActionsNavigationTests {
    @Test func prefixesCycleAndReset() {
        let menu = BrowserActionsNavigation()
        menu.items = ["Download selected file", "Disconnect", "Refresh"]
        menu.type("d", at: 10)
        #expect(menu.selected == "Download selected file")
        menu.type("d", at: 10.2)
        #expect(menu.selected == "Disconnect")
        menu.type("r", at: 12)
        #expect(menu.selected == "Refresh")
        menu.type("dis", at: 14)
        #expect(menu.selected == "Disconnect")
    }

    @Test func arrowsWrapAndUnavailableItemsAreSkipped() {
        let menu = BrowserActionsNavigation()
        menu.items = ["Choose host", "Disconnect"]
        menu.type("u", at: 10)
        #expect(menu.selected == nil)
        menu.move(-1)
        #expect(menu.selected == "Disconnect")
        menu.move(1)
        #expect(menu.selected == "Choose host")
    }
}

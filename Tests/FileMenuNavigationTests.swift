import Testing

@MainActor
struct FileMenuNavigationTests {
    @Test func prefixesCycleAndReset() {
        let menu = FileMenuNavigation()
        menu.type("o", at: 10)
        #expect(menu.selected == .open)
        menu.type("o", at: 10.2)
        #expect(menu.selected == .openWith)
        menu.type("o", at: 10.4)
        #expect(menu.selected == .open)
        menu.type("pen w", at: 10.5)
        #expect(menu.selected == .openWith)
        menu.type("d", at: 12)
        #expect(menu.selected == .delete)
        menu.type("e", at: 14)
        #expect(menu.selected == .permissions)
    }
    
    @Test func onlyAvailableOptionsAndArrowWrapping() {
        let menu = FileMenuNavigation(parentOnly: true)
        menu.type("d", at: 10)
        #expect(menu.selected == nil)
        menu.move(-1)
        #expect(menu.selected == .open)
        menu.move(1)
        #expect(menu.selected == .open)
        menu.type("REF", at: 12)
        #expect(menu.selected == .open)
    }
}

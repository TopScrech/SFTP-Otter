import Foundation
import Testing

@MainActor
struct LocalActionsTests {
    @Test func hiddenFilesCanBeShownAndHidden() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data().write(to: directory.appending(path: ".hidden"))
        let browser = LocalFileBrowserModel()
        browser.open(directory)
        await browser.waitForNavigation()
        defer { browser.close() }
        #expect(browser.files.isEmpty)
        browser.showHidden = true
        await browser.waitForNavigation()
        #expect(browser.files.map(\.name) == [".hidden"])
        browser.showHidden = false
        await browser.waitForNavigation()
        #expect(browser.files.isEmpty)
    }

    @Test func copyingPreservesExistingFilesAndRefreshesListing() async throws {
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let source = root.appending(path: "source")
        let destination = root.appending(path: "destination")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = source.appending(path: "file.txt")
        try Data("original".utf8).write(to: file)
        let browser = LocalFileBrowserModel()
        browser.open(destination)
        await browser.waitForNavigation()
        defer { browser.close() }
        browser.copyFiles([file], to: destination)
        await browser.waitForCopy()
        #expect(browser.files.map(\.name) == ["file.txt"])
        try Data("replacement".utf8).write(to: file)
        browser.copyFiles([file], to: destination)
        await browser.waitForCopy()
        #expect(try Data(contentsOf: destination.appending(path: "file.txt")) == Data("original".utf8))
        #expect(browser.error != nil)
    }

    @Test func navigationRetainsRowsAndOnlyPublishesLatestRequest() async throws {
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let first = root.appending(path: "first")
        let second = root.appending(path: "second")
        try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
        try Data().write(to: second.appending(path: "latest.txt"))
        defer { try? FileManager.default.removeItem(at: root) }
        let browser = LocalFileBrowserModel()
        browser.open(root)
        await browser.waitForNavigation()
        let oldRows = browser.files.map(\.id)
        browser.navigate(to: first)
        #expect(browser.files.map(\.id) == oldRows)
        browser.navigate(to: second)
        await browser.waitForNavigation()
        #expect(browser.directory == second)
        #expect(browser.files.map(\.name) == ["..", "latest.txt"])
        browser.navigate(to: root)
        browser.close()
        await Task.yield()
        #expect(browser.directory == nil)
        #expect(browser.files.isEmpty)
    }

}

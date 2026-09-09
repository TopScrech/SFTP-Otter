import Foundation
import Testing

@MainActor
struct LocalActionsTests {
    @Test func hiddenFilesCanBeShownAndHidden() throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data().write(to: directory.appending(path: ".hidden"))
        let browser = LocalFileBrowserModel()
        browser.open(directory)
        defer { browser.close() }
        #expect(browser.files.isEmpty)
        browser.showHidden = true
        #expect(browser.files.map(\.name) == [".hidden"])
        browser.showHidden = false
        #expect(browser.files.isEmpty)
    }

    @Test func copyingPreservesExistingFilesAndRefreshesListing() throws {
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
        defer { browser.close() }
        browser.copyFiles([file], to: destination)
        #expect(browser.files.map(\.name) == ["file.txt"])
        try Data("replacement".utf8).write(to: file)
        browser.copyFiles([file], to: destination)
        #expect(try Data(contentsOf: destination.appending(path: "file.txt")) == Data("original".utf8))
        #expect(browser.error != nil)
    }
}

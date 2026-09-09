import Foundation
import Testing

@MainActor
struct FileActionsTests {
    @Test func localRenameCreateAndPermissions() async throws {
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appending(path: "before.txt")
        try Data("content".utf8).write(to: source)
        let model = FileActionsModel()
        model.directory = root.path(percentEncoded: false)
        model.file = RemoteFile(path: source.path(percentEncoded: false), name: "before.txt", isDirectory: false, size: 7, permissions: "")
        model.input = "after.txt"
        model.run(.rename)
        while model.busy { await Task.yield() }
        #expect(model.error == nil)
        let renamed = root.appending(path: "after.txt")
        #expect(try String(contentsOf: renamed, encoding: .utf8) == "content")
        model.file?.path = renamed.path(percentEncoded: false)
        model.input = "600"
        model.run(.permissions)
        while model.busy { await Task.yield() }
        #expect(model.error == nil)
        let attributes = try FileManager.default.attributesOfItem(atPath: renamed.path(percentEncoded: false))
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
        model.input = "new folder"
        model.run(.newFolder)
        while model.busy { await Task.yield() }
        #expect(model.error == nil)
        #expect(FileManager.default.fileExists(atPath: root.appending(path: "new folder").path(percentEncoded: false)))
        model.input = "../outside"
        model.run(.rename)
        while model.busy { await Task.yield() }
        #expect(model.error != nil)
        #expect(FileManager.default.fileExists(atPath: renamed.path(percentEncoded: false)))
    }
}

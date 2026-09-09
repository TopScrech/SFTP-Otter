import Foundation
import Testing

@MainActor
struct FileActionsTests {
    @Test func permissionSaveRequiresAnActualChange() {
        let model = FileActionsModel()
        model.file = RemoteFile(path: "/fixture", name: "fixture", isDirectory: false, size: 0, permissions: "-rw-r--r--", mode: 0o644)
        model.transport = NavigationTransport()
        model.choose(.permissions)
        #expect(!model.permissionsChanged)
        model.savePermissions()
        #expect(!model.busy)
        #expect(model.prompt == .permissions)
        model.permissionGroups[1].write = true
        #expect(model.permissionsChanged)
        model.permissionGroups[1].write = false
        #expect(!model.permissionsChanged)
    }
    
    @Test func confirmsWholeSelectionBeforeDeleting() async {
        let transport = NavigationTransport()
        let model = FileActionsModel()
        model.transport = transport
        model.selectedFiles = ["one", "two"].map {
            RemoteFile(path: "/" + $0, name: $0, isDirectory: false, size: 0, permissions: "")
        }
        model.file = model.selectedFiles.first
        model.choose(.delete)
        #expect(model.showDeleteConfirmation)
        #expect(model.deletionTitle == "Delete 2 items?")
        #expect(await transport.removedPaths.isEmpty)
        model.run(.delete)
        while model.busy { await Task.yield() }
        #expect(await transport.removedPaths == ["/one", "/two"])
    }
    
    @Test func permissionSwitchesPreserveSpecialBits() async throws {
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let model = FileActionsModel()
        model.file = RemoteFile(path: url.path(percentEncoded: false), name: url.lastPathComponent, isDirectory: false, size: 0, permissions: "")
        model.input = "1644"
        model.permissionGroups = PermissionAccess.groups(mode: 0o644)
        model.permissionGroups[0].execute = true
        model.savePermissions()
        while model.busy { await Task.yield() }
        #expect(model.input == "1744")
        #expect(model.error == nil)
    }
    
    @Test func deleteRequiresConfirmation() throws {
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appending(path: "keep.txt")
        try Data("keep".utf8).write(to: source)
        let model = FileActionsModel()
        model.file = RemoteFile(path: source.path(percentEncoded: false), name: "keep.txt", isDirectory: false, size: 4, permissions: "")
        model.choose(.delete)
        #expect(model.showDeleteConfirmation)
        #expect(!model.busy)
        #expect(try String(contentsOf: source, encoding: .utf8) == "keep")
        model.showDeleteConfirmation = false
        #expect(FileManager.default.fileExists(atPath: source.path(percentEncoded: false)))
        model.file = RemoteFile(path: root.path(percentEncoded: false) + "/..", name: "..", isDirectory: true, size: 0, permissions: "")
        model.choose(.delete)
        #expect(!model.showDeleteConfirmation)
    }
    
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

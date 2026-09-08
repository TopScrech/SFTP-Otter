import Foundation
import Testing

@MainActor
struct LocalFolderRestoreTests {
    @Test func restoresDirectoryAndRetainsAuthorizedParent() throws {
        let defaults = UserDefaults.standard
        let keys = ["reopenConnectedHosts", "localFolder.primary", "localFolder.primary.path"]
        let original = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, original) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        keys.forEach { defaults.removeObject(forKey: $0) }
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let child = root.appending(path: "child")
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = LocalFileBrowserModel()
        first.restoreLocation(for: .primary)
        first.open(root)
        #expect(defaults.data(forKey: "localFolder.primary") == nil)
        defaults.set(true, forKey: "reopenConnectedHosts")
        first.navigate(to: child)
        #expect(defaults.data(forKey: "localFolder.primary") != nil)
        first.close(forget: false)
        let restored = LocalFileBrowserModel()
        restored.restoreLocation(for: .primary)
        #expect(restored.error == nil)
        #expect(restored.directory?.resolvingSymlinksInPath().pathComponents == child.resolvingSymlinksInPath().pathComponents)
        #expect(restored.files.contains { $0.name == ".." })
        restored.navigate(to: root)
        #expect(!restored.files.contains { $0.name == ".." })
        restored.close()
        #expect(defaults.data(forKey: "localFolder.primary") == nil)
    }
}

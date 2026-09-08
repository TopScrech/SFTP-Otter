import AppKit
import SwiftUI
import Testing

@MainActor
struct FileMenuAppearanceTests {
    @Test func rendersPermissionsEditor() throws {
        let actions = FileActionsModel()
        actions.file = RemoteFile(path: "/test", name: "test", isDirectory: true, size: 0, permissions: "-rw-r--r--")
        actions.permissionOwner = "u655197"
        actions.permissionGroup = "u655197"
        let renderer = ImageRenderer(content: PermissionsEditorView().environment(actions))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        let data = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        try data.write(to: URL(filePath: "/tmp/sftp-pro-permissions.png"))
        #expect(image.width == 1120)
    }

    @Test func rendersDarkMenuWithDeleteLast() throws {
        let renderer = ImageRenderer(content: FileContextMenuView { _ in }.environment(FileMenuNavigation()))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        let data = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        try data.write(to: URL(filePath: "/tmp/sftp-pro-context-menu.png"))
        #expect(FileMenuAction.allCases.last == .delete)
        #expect(image.width == 600)
    }
}

import AppKit
import SwiftUI
import Testing

@MainActor
struct FileMenuAppearanceTests {
    @Test func rendersDarkMenuWithDeleteLast() throws {
        let renderer = ImageRenderer(content: FileContextMenuView { _ in })
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        let data = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        try data.write(to: URL(filePath: "/tmp/sftp-pro-context-menu.png"))
        #expect(FileMenuAction.allCases.last == .delete)
        #expect(image.width == 600)
    }
}

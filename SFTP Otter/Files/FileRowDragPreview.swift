#if os(macOS)
import SwiftUI
import AppKit

enum FileRowDragPreview {
    static func item(file: RemoteFile, width: CGFloat, writer: any NSPasteboardWriting) -> NSDraggingItem {
        let renderer = ImageRenderer(content: DesktopFileRowView(file: file, width: width, isSelected: true)
            .frame(width: width)
            .environment(\.colorScheme, .dark))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let item = NSDraggingItem(pasteboardWriter: writer)
        if let image = renderer.nsImage {
            item.setDraggingFrame(NSRect(origin: .zero, size: image.size), contents: image)
        }
        return item
    }
}
#endif

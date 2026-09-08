#if os(macOS)
import AppKit
import SwiftUI

final class FileMenuMouseView: NSView {
    var action: (FileMenuAction) -> Void = { _ in }
    var select: () -> Void = {}
    var parentOnly = false
    private var menuPanel: FileMenuPanel?

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(convert(point, from: superview)), let event = NSApp.currentEvent else { return nil }
        return event.type == .rightMouseDown || (event.type == .leftMouseDown && event.modifierFlags.contains(.control)) ? self : nil
    }

    override func mouseDown(with event: NSEvent) { rightMouseDown(with: event) }

    override func rightMouseDown(with event: NSEvent) {
        select()
        menuPanel?.close()
        let panel = FileMenuPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.level = .popUpMenu
        let content = FileContextMenuView(parentOnly: parentOnly) { [weak self, weak panel] action in
            panel?.close()
            self?.action(action)
        }
        let host = NSHostingView(rootView: content)
        let size = host.fittingSize
        panel.contentView = host
        let pointer = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(pointer) }?.visibleFrame ?? window?.screen?.visibleFrame
        var origin = NSPoint(x: pointer.x, y: pointer.y - size.height)
        if let screen {
            origin.x = max(screen.minX, min(origin.x, screen.maxX - size.width))
            origin.y = max(screen.minY, min(origin.y, screen.maxY - size.height))
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        menuPanel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { menuPanel?.close() }
    }
}
#endif

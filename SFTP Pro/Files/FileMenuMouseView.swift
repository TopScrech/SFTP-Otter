#if os(macOS)
import AppKit
import SwiftUI

final class FileMenuMouseView: NSView {
    var action: (FileMenuAction) -> Void = { _ in }
    var select: () -> Void = {}
    var parentOnly = false

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(convert(point, from: superview)), let event = NSApp.currentEvent else { return nil }
        return event.type == .rightMouseDown || (event.type == .leftMouseDown && event.modifierFlags.contains(.control)) ? self : nil
    }

    override func mouseDown(with event: NSEvent) { rightMouseDown(with: event) }

    override func rightMouseDown(with event: NSEvent) {
        select()
        let menu = NSMenu()
        let item = NSMenuItem()
        let content = FileContextMenuView(parentOnly: parentOnly) { [weak self, weak menu] action in
            menu?.cancelTracking()
            self?.action(action)
        }
        let host = NSHostingView(rootView: content)
        host.frame.size = host.fittingSize
        item.view = host
        menu.addItem(item)
        menu.appearance = NSAppearance(named: .darkAqua)
        menu.popUp(positioning: nil, at: convert(event.locationInWindow, from: nil), in: self)
    }
}
#endif

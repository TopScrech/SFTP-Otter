#if os(macOS)
import AppKit
import SwiftUI

final class FileMenuMouseView: NSView, NSDraggingSource {
    var dragItems: () -> [NSDraggingItem] = { [] }
    private var mouseDownEvent: NSEvent?
    private var deferredSelection = false
    private var activeDragItems: [NSDraggingItem] = []
    var action: (FileMenuAction) -> Void = { _ in }
    var select: (Bool, Bool, Bool) -> Void = { _, _, _ in }
    var parentOnly = false
    var keyboardFocused = false
    var rowSelected = false
    var moveSelection: (Int, Bool) -> Void = { _, _ in }
    var openSelection: () -> Void = {}
    var goToParent: () -> Void = {}
    
    func updateKeyboardFocus() {
        if keyboardFocused, let window, window.firstResponder is FileMenuMouseView || window.firstResponder === window {
            window.makeFirstResponder(self)
        }
    }
    private var menuPanel: FileMenuPanel?
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(convert(point, from: superview)), let event = NSApp.currentEvent else { return nil }
        return event.type == .rightMouseDown || event.type == .leftMouseDown ? self : nil
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { rightMouseDown(with: event); return }
        window?.makeFirstResponder(self)
        mouseDownEvent = event
        deferredSelection = rowSelected && event.modifierFlags.intersection([.shift, .command]).isEmpty && event.clickCount == 1
        select(event.modifierFlags.contains(.shift), event.modifierFlags.contains(.command), deferredSelection)
        if event.clickCount == 2 { action(.open) }
    }
    
    override func mouseUp(with event: NSEvent) {
        if deferredSelection { select(false, false, false) }
        deferredSelection = false
        mouseDownEvent = nil
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard !parentOnly, let start = mouseDownEvent,
              hypot(event.locationInWindow.x - start.locationInWindow.x, event.locationInWindow.y - start.locationInWindow.y) >= 4 else { return }
        let items = dragItems()
        guard !items.isEmpty else { return }
        for (index, item) in items.enumerated() {
            var frame = item.draggingFrame
            frame.origin = NSPoint(x: CGFloat(index * 4), y: -CGFloat(index * 4))
            item.draggingFrame = frame
        }
        activeDragItems = items
        mouseDownEvent = nil
        deferredSelection = false
        let session = beginDraggingSession(with: items, event: event, source: self)
        session.draggingFormation = .pile
    }
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { .copy }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 125 || event.keyCode == 126 {
            moveSelection(event.keyCode == 125 ? 1 : -1, event.modifierFlags.contains(.shift))
        } else if [36, 76, 124].contains(event.keyCode) {
            openSelection()
        } else if event.keyCode == 123 {
            goToParent()
        } else if [51, 117].contains(event.keyCode), event.modifierFlags.intersection([.command, .shift, .control, .option]).isSubset(of: .command) {
            action(.delete)
        } else if event.keyCode == 15, event.modifierFlags.contains(.command) {
            action(.refresh)
        } else { super.keyDown(with: event) }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        select(false, false, true)
        menuPanel?.close()
        let panel = FileMenuPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.level = .popUpMenu
        panel.navigation = FileMenuNavigation(parentOnly: parentOnly)
        panel.perform = { [weak self] in self?.action($0) }
        let content = FileContextMenuView { [weak self, weak panel] action in
            panel?.close()
            self?.action(action)
        }
        let host = NSHostingView(rootView: content.environment(panel.navigation))
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
        else { updateKeyboardFocus() }
    }
}
#endif

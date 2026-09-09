#if os(macOS)
import AppKit

final class FilterFocusMouseView: NSView {
    private var monitor: Any?

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.dismissFocus(outside: event)
            return event
        }
        Task { @MainActor [weak self] in
            self?.resignFieldEditor()
        }
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func dismissFocus(outside event: NSEvent) {
        guard let window, event.window === window,
              !bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        resignFieldEditor()
    }

    private func resignFieldEditor() {
        guard let window, let editor = window.firstResponder as? NSTextView,
              editor.isFieldEditor, let field = editor.delegate as? NSView,
              field.window === window,
              convert(bounds, to: nil).intersects(field.convert(field.bounds, to: nil)) else { return }
        window.makeFirstResponder(nil)
    }
}
#endif

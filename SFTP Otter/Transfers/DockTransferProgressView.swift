#if os(macOS)
import AppKit

final class DockTransferProgressView: NSView {
    var fraction = 0.0
    let icon = NSApplication.shared.applicationIconImage

    override func draw(_ dirtyRect: NSRect) {
        icon?.draw(in: bounds)

        let track = NSRect(x: bounds.width * 0.08, y: bounds.height * 0.07,
                           width: bounds.width * 0.84, height: bounds.height * 0.1)
        let radius = track.height / 2
        let background = NSBezierPath(roundedRect: track, xRadius: radius, yRadius: radius)
        NSColor.black.withAlphaComponent(0.8).setFill()
        background.fill()

        let interior = track.insetBy(dx: 2, dy: 2)
        let fill = NSRect(x: interior.minX, y: interior.minY,
                          width: interior.width * fraction, height: interior.height)
        NSColor.systemBlue.setFill()
        NSBezierPath(roundedRect: fill, xRadius: fill.height / 2, yRadius: fill.height / 2).fill()
        NSColor.white.withAlphaComponent(0.8).setStroke()
        background.lineWidth = 1
        background.stroke()
    }
}
#endif

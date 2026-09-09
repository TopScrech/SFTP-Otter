#if os(macOS)
import SwiftUI

struct FileMenuBridge: NSViewRepresentable {
    let parentOnly: Bool
    let select: () -> Void
    let action: (FileMenuAction) -> Void

    func makeNSView(context: Context) -> FileMenuMouseView { FileMenuMouseView() }
    func updateNSView(_ view: FileMenuMouseView, context: Context) {
        view.parentOnly = parentOnly
        view.select = select
        view.action = action
    }
}
#endif

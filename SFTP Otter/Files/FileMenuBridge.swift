#if os(macOS)
import SwiftUI

struct FileMenuBridge: NSViewRepresentable {
    let parentOnly: Bool
    var keyboardFocused = false
    var rowSelected = false
    var moveSelection: (Int, Bool) -> Void = { _, _ in }
    var openSelection: () -> Void = {}
    var goToParent: () -> Void = {}
    var dragItems: () -> [NSDraggingItem] = { [] }
    let select: (Bool, Bool, Bool) -> Void
    let action: (FileMenuAction) -> Void
    
    func makeNSView(context: Context) -> FileMenuMouseView { FileMenuMouseView() }
    func updateNSView(_ view: FileMenuMouseView, context: Context) {
        view.rowSelected = rowSelected
        view.dragItems = dragItems
        view.parentOnly = parentOnly
        let needsFocus = keyboardFocused && !view.keyboardFocused
        view.keyboardFocused = keyboardFocused
        view.moveSelection = moveSelection
        view.openSelection = openSelection
        view.goToParent = goToParent
        if needsFocus { view.updateKeyboardFocus() }
        view.select = select
        view.action = action
    }
}
#endif

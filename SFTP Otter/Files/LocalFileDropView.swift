#if os(macOS)
import SwiftUI

struct LocalFileDropView: NSViewRepresentable {
    @Binding var targeted: Bool
    @Environment(LocalFileBrowserModel.self) private var browser
    @Environment(FileActionsModel.self) private var actions

    func makeNSView(context: Context) -> LocalFileDropTargetView { LocalFileDropTargetView() }

    func updateNSView(_ view: LocalFileDropTargetView, context: Context) {
        view.destination = browser.directory
        view.targetChanged = { targeted = $0 }
        view.completed = { error in
            if let error { actions.error = error }
            browser.refresh()
        }
    }
}
#endif

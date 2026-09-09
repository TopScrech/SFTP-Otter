#if os(macOS)
import SwiftUI

struct FilterFocusDismissView: NSViewRepresentable {
    func makeNSView(context: Context) -> FilterFocusMouseView { FilterFocusMouseView() }
    static func dismantleNSView(_ view: FilterFocusMouseView, coordinator: ()) { view.stopMonitoring() }

    func updateNSView(_ view: FilterFocusMouseView, context: Context) {}
}
#endif

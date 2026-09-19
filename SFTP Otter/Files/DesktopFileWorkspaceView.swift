import SwiftUI

struct DesktopFileWorkspaceView: View {
    @State private var stacksVertically = false

    var body: some View {
        let layout = stacksVertically ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))

        layout {
            FileConnectionPaneView(pane: .primary)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)

            Rectangle()
                .fill(WorkspaceTheme.raised)
                .frame(width: stacksVertically ? nil : 1, height: stacksVertically ? 1 : nil)

            FileConnectionPaneView(pane: .secondary)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        .background(WorkspaceTheme.surface)
        .onGeometryChange(for: Bool.self) { geometry in
            geometry.size.width < 760
        } action: {
            stacksVertically = $0
        }
    }
}

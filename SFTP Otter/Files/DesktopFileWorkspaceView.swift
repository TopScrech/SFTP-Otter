import SwiftUI

struct DesktopFileWorkspaceView: View {
    var body: some View {
        HStack(spacing: 0) {
            FileConnectionPaneView(pane: .primary)
            Divider()
            FileConnectionPaneView(pane: .secondary)
        }
        .background(WorkspaceTheme.surface)
    }
}

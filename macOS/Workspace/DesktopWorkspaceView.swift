import ScrechKit

struct DesktopWorkspaceView: View {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some View {
        HStack(spacing: 0) {
            if workspace.section == .files {
                FileWorkspaceView()
            } else {
                TransfersView()
                    .maxFrame(.infinity)
            }
        }
        .toolbar {
            DesktopWorkspaceToolbar()
        }
        .toolbarBackground(WorkspaceTheme.background, for: .windowToolbar)
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
    }
}

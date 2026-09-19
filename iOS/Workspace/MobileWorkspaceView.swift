import ScrechKit

struct MobileWorkspaceView: View {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some View {
        VStack(spacing: 0) {
            ConnectionTabsView(showSessions: false)

            Divider()
                .overlay(WorkspaceTheme.raised)

            if workspace.section == .files {
                FileWorkspaceView()
            } else {
                TransfersView()
                    .maxFrame(.infinity)
            }
        }
    }
}

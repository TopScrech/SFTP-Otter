import SwiftUI

struct DesktopWorkspaceView: View {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some View {
        VStack(spacing: 0) {
            #if !os(macOS)
            ConnectionTabsView(showSessions: false)
            Divider().overlay(WorkspaceTheme.raised)
            #endif
            HStack(spacing: 0) {
                if workspace.section == .files {
                    DesktopFileWorkspaceView()
                } else {
                    WorkspaceDetailView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        #if os(macOS)
        .toolbar { DesktopWorkspaceToolbar() }
        .toolbarBackground(WorkspaceTheme.background, for: .windowToolbar)
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        #endif
    }
}

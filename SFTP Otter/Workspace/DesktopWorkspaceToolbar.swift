#if os(macOS)
import SwiftUI

struct DesktopWorkspaceToolbar: ToolbarContent {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button("SFTP", systemImage: "folder.fill") { workspace.section = .files }
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(workspace.section == .files ? WorkspaceTheme.raised : WorkspaceTheme.background, in: .rect(cornerRadius: 8))
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .navigation) {
            Button("New host", systemImage: "plus") { workspace.addHost() }
                .labelStyle(.iconOnly)
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarSpacer(.flexible, placement: .primaryAction)

        ToolbarItem(placement: .primaryAction) {
            Button("Settings", systemImage: "gearshape") { workspace.showSettings = true }
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .primaryAction) {
            Button("Transfers", systemImage: "arrow.down.circle") { workspace.section = .transfers }
        }
        .sharedBackgroundVisibility(.hidden)
    }
}
#endif

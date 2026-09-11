#if os(macOS)
import SwiftUI

struct DesktopWorkspaceToolbar: ToolbarContent {
    @Environment(WorkspaceModel.self) private var workspace
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button("SFTP", systemImage: "folder.fill") { workspace.section = .files }
                .labelStyle(.titleAndIcon)
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(workspace.section == .files ? WorkspaceTheme.raised : WorkspaceTheme.background, in: .rect(cornerRadius: 8))
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .navigation) {
            Button("New tab", systemImage: "plus") { workspace.chooseHost(for: workspace.activePane) }
                .labelStyle(.iconOnly)
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarSpacer(.flexible, placement: .primaryAction)
        
        ToolbarItem(placement: .primaryAction) {
            Button("Settings", systemImage: "gearshape") { workspace.showSettings = true }
                .buttonStyle(CircularToolbarButtonStyle())
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .primaryAction) {
            Button("Transfers", systemImage: "arrow.down.circle") { workspace.toggleTransfers() }
                .buttonStyle(CircularToolbarButtonStyle())
        }
        .sharedBackgroundVisibility(.hidden)
    }
}
#endif

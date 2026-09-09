import SwiftUI

struct MobileWorkspaceView: View {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some View {
        @Bindable var workspace = workspace
        TabView(selection: $workspace.section) {
            Tab("Connections", systemImage: "folder", value: .files) {
                VStack(spacing: 0) {
                    ConnectionTabsView()
                    FileBrowserView()
                }
            }
            Tab("Transfers", systemImage: "arrow.up.arrow.down", value: .transfers) {
                TransfersView()
            }
        }
    }
}

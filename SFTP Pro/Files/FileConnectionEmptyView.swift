import SwiftUI

struct FileConnectionEmptyView: View {
    @Environment(WorkspaceModel.self) private var workspace
    let pane: BrowserPane
    @Binding var showLocalFolderPicker: Bool

    var body: some View {
        VStack {
            Image(systemName: "folder.fill")
                .padding(10)
                .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 12))
                .padding(.bottom)
            Text("Connect to host")
                .font(.subheadline).bold()
            Text("Start by connecting to a saved host\nto manage your files with SFTP")
                .font(.caption2)
                .foregroundStyle(WorkspaceTheme.muted)
                .multilineTextAlignment(.center)
            Button("Select host") { workspace.chooseHost(for: pane) }
                .font(.caption).bold()
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 8))
                .padding(.top)
            #if os(macOS)
            Button("Browse my Mac", systemImage: "desktopcomputer") {
                showLocalFolderPicker = true
            }
            .buttonStyle(.plain)
            .font(.caption)
            .padding()
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

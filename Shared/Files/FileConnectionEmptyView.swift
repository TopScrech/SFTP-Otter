import ScrechKit

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
                .subheadline().bold()
            Text("Start by connecting to a saved host\nto manage your files with SFTP")
                .caption2()
                .foregroundStyle(WorkspaceTheme.muted)
                .multilineTextAlignment(.center)
            Button {
                workspace.chooseHost(for: pane)
            } label: {
                Text("Select host")
                    .caption().bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 8))
                    .contentShape(.rect(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.top)
            #if os(macOS)
            Button("Browse my Mac", systemImage: "desktopcomputer") {
                showLocalFolderPicker = true
            }
            .buttonStyle(.plain)
            .caption()
            .padding()
            #endif
        }
        .padding()
        .maxFrame(.infinity)
    }
}

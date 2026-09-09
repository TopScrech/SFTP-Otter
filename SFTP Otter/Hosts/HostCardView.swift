import ScrechKit

struct HostCardView: View {
    @Environment(WorkspaceModel.self) private var workspace
    let host: Host
    
    var body: some View {
        Button {
            workspace.requestConnection(host)
        } label: {
            HStack {
                Image(systemName: "server.rack")
                    .title2()
                    .padding()
                    .background(WorkspaceTheme.accent.opacity(0.2), in: .rect(cornerRadius: 10))
                    .foregroundStyle(WorkspaceTheme.accent)
                VStack(alignment: .leading) {
                    Text(host.displayName).headline()
                    Text(host.address).subheadline()
                        .foregroundStyle(WorkspaceTheme.muted)
                    Text("SFTP · \(host.username)")
                        .caption()
                        .foregroundStyle(WorkspaceTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(WorkspaceTheme.muted)
            }
            .padding()
            .background(WorkspaceTheme.surface, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit host", systemImage: "pencil") {
                workspace.edit(host)
            }
            Button("Remove host", systemImage: "trash", role: .destructive) {
                workspace.remove(host)
            }
        }
    }
}

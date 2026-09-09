import ScrechKit

struct SavedHostsSectionView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @State private var showEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Saved hosts")
                .headline()

            if workspace.hosts.isEmpty {
                Text("No saved hosts yet")
                    .foregroundStyle(WorkspaceTheme.muted)
            }

            ForEach(workspace.hosts) { host in
                HStack {
                    VStack(alignment: .leading) {
                        Text(host.displayName)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text(host.endpoint)
                            .subheadline()
                            .foregroundStyle(WorkspaceTheme.muted)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Button("Edit") {
                        workspace.editingHost = host
                        showEditor = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(WorkspaceTheme.accent)
                    .accessibilityLabel("Edit \(host.displayName)")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 12))
            }
        }
        .sheet($showEditor) {
            HostEditorView()
        }
        .onChange(of: showEditor) {
            if !showEditor { workspace.editingHost = nil }
        }
    }
}

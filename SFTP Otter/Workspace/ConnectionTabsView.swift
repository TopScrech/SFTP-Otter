import ScrechKit

struct ConnectionTabsView: View {
    @Environment(WorkspaceModel.self) private var workspace
    var showSessions = true
    
    var body: some View {
        HStack {
            Button("SFTP", systemImage: "folder.fill") { workspace.section = .files }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(workspace.section == .files ? WorkspaceTheme.raised : WorkspaceTheme.surface, in: .rect(cornerRadius: 8))
            if showSessions && !workspace.sessions.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(workspace.sessions) { session in
                            HStack {
                                Button(session.host.displayName, systemImage: "folder") {
                                    workspace.select(session)
                                }
                                Button("Close connection", systemImage: "xmark") {
                                    workspace.close(session)
                                }
                                .labelStyle(.iconOnly)
                                .foregroundStyle(WorkspaceTheme.muted)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(workspace.selectedSessionID == session.id && workspace.section == .files ? WorkspaceTheme.raised : WorkspaceTheme.surface, in: .rect(cornerRadius: 8))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            Button("New tab", systemImage: "plus") {
                workspace.chooseHost(for: workspace.activePane)
            }
            .labelStyle(.iconOnly)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            Spacer(minLength: 0)
            Button("Settings", systemImage: "gearshape") { workspace.showSettings = true }
                .buttonStyle(CircularToolbarButtonStyle())
            Button("Transfers", systemImage: "arrow.down.circle") {
                workspace.toggleTransfers()
            }
            .buttonStyle(CircularToolbarButtonStyle())
        }
        .subheadline()
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(WorkspaceTheme.background)
    }
}

import ScrechKit

struct HostsView: View {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some View {
        @Bindable var workspace = workspace
        VStack(alignment: .leading) {
            HStack {
                Text("Hosts").largeTitle().bold()
                Spacer()
                Button("New host", systemImage: "plus") {
                    workspace.addHost()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical)
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search hosts", text: $workspace.hostSearch)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(WorkspaceTheme.surface, in: .rect(cornerRadius: 10))
            Text("SAVED HOSTS")
                .caption()
                .foregroundStyle(WorkspaceTheme.muted)
                .padding(.top)
            if workspace.hosts.isEmpty {
                ContentUnavailableView {
                    Label("A home for your servers", systemImage: "server.rack")
                } description: {
                    Text("Add a host to browse files and transfer them securely over SFTP")
                } actions: {
                    Button("Add your first host", systemImage: "plus") {
                        workspace.addHost()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else if workspace.filteredHosts.isEmpty {
                ContentUnavailableView.search(text: workspace.hostSearch)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), alignment: .topLeading)]) {
                        ForEach(workspace.filteredHosts) {
                            HostCardView(host: $0)
                        }
                    }
                }
            }
        }
        .padding()
        .background(WorkspaceTheme.background)
    }
}

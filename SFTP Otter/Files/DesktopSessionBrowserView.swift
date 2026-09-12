import ScrechKit
import UniformTypeIdentifiers

struct DesktopSessionBrowserView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SFTPSession.self) private var session
    @State private var showImporter = false
    @State private var showActions = false
    @State private var selection = FileSelection()
    let pane: BrowserPane
    
    var body: some View {
        VStack(spacing: 0) {
            FileBrowserHeaderView {
                HStack {
                    Image(systemName: "server.rack")
                        .padding(8)
                        .background(Color(red: 0, green: 0.30, blue: 0.46), in: .rect(cornerRadius: 10))
                    Text(session.host.displayName).lineLimit(1)
                    Spacer()
                    FileFilterView()
                    Button("Actions", systemImage: "chevron.down") { showActions.toggle() }
                        .popover(isPresented: $showActions, arrowEdge: .bottom) {
                            BrowserActionsMenuView(showImporter: $showImporter, selectedIDs: selection.ids, pane: pane)
                        }
                    .fixedSize()
                }
            } path: {
                RemoteBreadcrumbsView()
            }
            if session.isConnected && session.error == nil {
                DesktopFileTableView(selection: $selection)
            } else if let error = session.error {
                ContentUnavailableView("Connection unavailable", systemImage: "network.slash", description: Text(error))
                    .maxFrame(.infinity)
            } else {
                ProgressView("Connecting")
                    .maxFrame(.infinity)
            }
        }
        .modifier(UploadDropZoneModifier())
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data, .content, .folder], allowsMultipleSelection: true) {
            switch $0 {
            case .success(let urls): urls.forEach { workspace.upload($0, to: session) }
            case .failure(let error): workspace.report(error)
            }
        }
    }
}

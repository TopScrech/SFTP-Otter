import ScrechKit
import UniformTypeIdentifiers

struct FileConnectionPaneView: View {
    @Environment(WorkspaceModel.self) private var workspace
    let pane: BrowserPane
    @State private var localBrowser = LocalFileBrowserModel()
    @State private var showLocalFolderPicker = false

    var body: some View {
        Group {
            if let session = workspace.session(in: pane) {
                DesktopSessionBrowserView(pane: pane)
                    .environment(session)
            } else if localBrowser.directory != nil {
                LocalFileBrowserView(showFolderPicker: $showLocalFolderPicker)
                    .environment(localBrowser)
            } else {
                FileConnectionEmptyView(pane: pane, showLocalFolderPicker: $showLocalFolderPicker)
            }
        }
        .maxFrame(.infinity)
        .fileImporter(isPresented: $showLocalFolderPicker, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let url): localBrowser.open(url)
            case .failure(let error): workspace.report(error)
            }
        }
        #if DEBUG
        .onChange(of: workspace.localPreviewURL) {
            if pane == .primary, let url = workspace.localPreviewURL { localBrowser.open(url) }
        }
        #endif
        .task { localBrowser.restoreLocation(for: pane) }
        .onChange(of: workspace.reopenConnectedHosts) { localBrowser.rememberLocation() }
        .onDisappear { localBrowser.close(forget: false) }
    }
}

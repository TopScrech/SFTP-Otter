import SwiftUI

struct FileBrowserView: View {
    @Environment(WorkspaceModel.self) private var workspace
    
    var body: some View {
        if let session = workspace.selectedSession {
            SessionBrowserView()
                .environment(session)
        } else {
            ContentUnavailableView {
                Label("Open an SFTP connection", systemImage: "folder.badge.gearshape")
            } description: {
                Text("Choose a saved host to start browsing")
            } actions: {
                Button("Browse hosts", systemImage: "server.rack") {
                    workspace.chooseHost(for: .primary)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

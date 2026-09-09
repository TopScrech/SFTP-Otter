import SwiftUI
import UniformTypeIdentifiers

struct SessionBrowserView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SFTPSession.self) private var session
    @State private var showImporter = false

    var body: some View {
        VStack(alignment: .leading) {
            FileBrowserToolbarView(showImporter: $showImporter)
            if session.isLoading {
                ProgressView("Loading directory")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = session.error {
                ContentUnavailableView {
                    Label("Connection unavailable", systemImage: "network.slash")
                } description: {
                    Text(error)
                } actions: {
                    Button("Reconnect", systemImage: "arrow.clockwise") {
                        workspace.requestConnection(session.host)
                    }
                }
            } else if !session.isConnected {
                ContentUnavailableView("Not connected", systemImage: "network.slash", description: Text("Connect to this host to view its files"))
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(session.filteredFiles) {
                            FileRowView(file: $0)
                        }
                    }
                    .padding()
                }
                .background(WorkspaceTheme.surface, in: .rect(cornerRadius: 14))
                .overlay {
                    if session.filteredFiles.isEmpty {
                        ContentUnavailableView("No files", systemImage: "folder", description: Text(session.search.isEmpty ? "This directory is empty" : "No files match your search"))
                    }
                }
            }
            HStack {
                Label(session.isPreview ? "Layout preview · No server connection" : (session.isConnected ? "Connected" : "Disconnected"), systemImage: "circle.fill")
                    .foregroundStyle(session.isConnected && !session.isPreview ? .green : WorkspaceTheme.muted)
                Spacer()
                Text("\(session.files.count) items")
                Text("SFTP")
            }
            .font(.caption)
            .foregroundStyle(WorkspaceTheme.muted)
            .padding()
        }
        .padding()
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data, .content], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls): urls.forEach { workspace.upload($0, to: session) }
            case .failure(let error): workspace.report(error)
            }
        }
    }
}

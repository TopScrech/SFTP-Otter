import SwiftUI
import UniformTypeIdentifiers

struct DesktopSessionBrowserView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SFTPSession.self) private var session
    @State private var showImporter = false
    @State private var showFilter = false
    @State private var selection = FileSelection()
    let pane: BrowserPane

    var body: some View {
        @Bindable var session = session
        VStack(spacing: 0) {
            VStack {
                HStack {
                    Image(systemName: "server.rack")
                        .padding(8)
                        .background(Color(red: 0, green: 0.30, blue: 0.46), in: .rect(cornerRadius: 10))
                    Text(session.host.displayName).lineLimit(1)
                    Spacer()
                    Button("Filter", systemImage: "magnifyingglass") {
                        showFilter.toggle()
                        if !showFilter { session.search = "" }
                    }
                    Menu("Actions") {
                        Button("Upload files", systemImage: "arrow.up.to.line") { showImporter = true }
                            .disabled(!session.isConnected || session.isPreview)
                        Button("Download selected file", systemImage: "arrow.down.to.line") {
                            for file in session.files where selection.ids.contains(file.id) && !file.isDirectory {
                                workspace.download(file, from: session)
                            }
                        }
                        .disabled(session.isPreview || !session.files.contains { selection.ids.contains($0.id) && !$0.isDirectory })
                        Divider()
                        Button("Refresh", systemImage: "arrow.clockwise", action: session.refresh)
                            .disabled(session.isPreview || !session.isConnected)
                        Toggle("Show hidden files", isOn: $session.showHidden)
                        Button("Choose host", systemImage: "server.rack") { workspace.chooseHost(for: pane) }
                        Button("Disconnect", systemImage: "xmark.circle", role: .destructive) { workspace.close(session) }
                    }
                    .fixedSize()
                }
                .buttonStyle(.plain)
                RemoteBreadcrumbsView()
                    .padding(.top)
                if showFilter {
                    TextField("Filter files", text: $session.search)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Filter files")
                }
            }
            .font(.body)
            .padding()
            .background(WorkspaceTheme.raised)
            if session.isConnected && session.error == nil {
                DesktopFileTableView(selection: $selection)
            } else if let error = session.error {
                ContentUnavailableView("Connection unavailable", systemImage: "network.slash", description: Text(error))
            } else {
                ProgressView("Connecting")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { workspace.refreshFiles = session.refresh }
        .overlay {
            if session.isLoading && session.isConnected { ProgressView("Loading files") }
        }
        .modifier(UploadDropZoneModifier())
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data, .content], allowsMultipleSelection: true) {
            switch $0 {
            case .success(let urls): urls.forEach { workspace.upload($0, to: session) }
            case .failure(let error): workspace.report(error)
            }
        }
    }
}

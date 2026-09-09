import ScrechKit

struct LocalFileBrowserView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(LocalFileBrowserModel.self) private var browser
    @Binding var showFolderPicker: Bool
    
#if os(macOS)
    @State private var actions = FileActionsModel()
#endif
    
    @State private var scrollTarget: String?
    @State private var keyboardNavigationActive = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("My Mac", systemImage: "desktopcomputer")
                Spacer()
                Button("Choose folder", systemImage: "folder") { showFolderPicker = true }
                Button("Close", systemImage: "xmark", action: { browser.close() })
                    .labelStyle(.iconOnly)
            }
            .padding()
            .background(WorkspaceTheme.raised)
            Text(browser.directory?.path(percentEncoded: false) ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .enableSelection()
                .background(WorkspaceTheme.raised)
            if let error = browser.error {
                ContentUnavailableView("Folder unavailable", systemImage: "folder.badge.questionmark", description: Text(error))
            } else {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        FileTableHeaderView(width: geometry.size.width, showsColumnDividers: false)
                        Divider()
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(browser.files) {
                                    LocalBrowserRowView(
                                        file: $0, width: geometry.size.width, keyboardNavigationActive: $keyboardNavigationActive)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollPosition(id: $scrollTarget)
                        .onChange(of: browser.selection.cursor) { scrollTarget = browser.selection.cursor }
                        .overlay {
                            if browser.files.isEmpty {
                                ContentUnavailableView("No files", systemImage: "folder")
                            }
                        }
                    }
                }
            }
        }
        .onAppear { workspace.refreshFiles = browser.refresh }
        .buttonStyle(.plain)
        .background(WorkspaceTheme.surface)
#if os(macOS)
        .modifier(FileActionPresentationModifier())
        .environment(actions)
#endif
    }
}

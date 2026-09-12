import ScrechKit
import UniformTypeIdentifiers

struct LocalFileBrowserView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(LocalFileBrowserModel.self) private var browser
    @Binding var showFolderPicker: Bool
    
#if os(macOS)
    @State private var dropTargeted = false
    @State private var actions = FileActionsModel()
#endif
    
    @State private var showActions = false
    @State private var showImporter = false
    @State private var showCopyDestination = false
    @State private var scrollTarget: String?
    @State private var keyboardNavigationActive = false
    
    var body: some View {
        VStack(spacing: 0) {
            FileBrowserHeaderView {
                HStack {
                    Image(systemName: "desktopcomputer")
                        .padding(8)
                        .background(Color(red: 0, green: 0.30, blue: 0.46), in: .rect(cornerRadius: 10))
                    Text("My Mac")
                    Spacer()
                    Button("Choose folder", systemImage: "folder") { showFolderPicker = true }
                    Button("Actions", systemImage: "chevron.down") { showActions.toggle() }
                        .popover(isPresented: $showActions, arrowEdge: .bottom) {
                            LocalActionsMenuView(showFolderPicker: $showFolderPicker, showImporter: $showImporter, showCopyDestination: $showCopyDestination)
                        }
                }
            } path: {
                Text(browser.directory?.path(percentEncoded: false) ?? "")
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .enableSelection()
            }
            if let error = browser.error {
                ContentUnavailableView("Folder unavailable", systemImage: "folder.badge.questionmark", description: Text(error))
            } else {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        FileTableHeaderView(width: geometry.size.width, showsColumnDividers: false, sortOrder: browser.sortOrder) {
                            browser.sortOrder.select($0)
                        }
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
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                if let directory = browser.directory { browser.copyFiles(urls, to: directory) }
            case .failure(let error): browser.report(error)
            }
        }
        .fileImporter(isPresented: $showCopyDestination, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let destination): browser.copyFiles(browser.selectedURLs, to: destination)
            case .failure(let error): browser.report(error)
            }
        }
        .onAppear { workspace.visibleLocalBrowsers[ObjectIdentifier(browser)] = browser }
        .onDisappear { workspace.visibleLocalBrowsers.removeValue(forKey: ObjectIdentifier(browser)) }
        .buttonStyle(.plain)
        .background(WorkspaceTheme.surface)
#if os(macOS)
        .overlay { LocalFileDropView(targeted: $dropTargeted) }
        .overlay {
            if dropTargeted, let directory = browser.directory {
                FileDropHighlightView(title: "Copy to \(directory.path(percentEncoded: false))", systemImage: "arrow.down.doc")
            }
        }
        .modifier(FileActionPresentationModifier())
        .environment(actions)
#endif
    }
}

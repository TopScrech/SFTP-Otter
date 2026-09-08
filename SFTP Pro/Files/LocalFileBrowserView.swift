import SwiftUI

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
                .textSelection(.enabled)
                .background(WorkspaceTheme.raised)
            if let error = browser.error {
                ContentUnavailableView("Folder unavailable", systemImage: "folder.badge.questionmark", description: Text(error))
            } else {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(["Name", "Date Modified", "Size", "Kind"].enumerated(), id: \.offset) { index, title in
                                Text(title)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .frame(width: geometry.size.width * [0.44, 0.24, 0.16, 0.16][index], height: 45)
                            }
                        }
                        Divider()
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(browser.files) { file in
                                    Button { browser.selection.click(file.id, in: browser.files.map(\.id)) } label: {
                                        DesktopFileRowView(file: file, width: geometry.size.width, isSelected: browser.selection.ids.contains(file.id))
                                            .contentShape(.rect)
                                    }
                                    .contentShape(.rect)
                                #if !os(macOS)
                                .onTapGesture(count: 2) {
                                    if file.isDirectory { browser.navigate(to: URL(filePath: file.path)) }
                                }
                                #endif

                                    #if os(macOS)
                                .overlay {
                                    FileMenuBridge(parentOnly: file.name == "..", keyboardFocused: browser.selection.cursor == file.id || (keyboardNavigationActive && browser.selection.cursor == nil && browser.files.first?.id == file.id),
                                        moveSelection: { browser.selection.move($0, in: browser.files.map(\.id), extending: $1) },
                                        openSelection: {
                                            if let file = browser.files.first(where: { $0.id == browser.selection.cursor && browser.selection.ids.contains($0.id) && $0.isDirectory }) { browser.navigate(to: URL(filePath: file.path)) }
                                        },
                                        goToParent: {
                                            if let file = browser.files.first(where: { $0.name == ".." }) { browser.navigate(to: URL(filePath: file.path)) }
                                        }, select: { shift, command, context in keyboardNavigationActive = true; workspace.refreshFiles = browser.refresh; browser.selection.click(file.id, in: browser.files.map(\.id), extending: shift, toggling: command, contextMenu: context) }) { action in
                                        guard !actions.busy else { return }

                                        actions.file = file
                                        actions.selectedFiles = browser.files.filter { browser.selection.ids.contains($0.id) && $0.name != ".." }
                                        if action == .delete {
                                            guard let first = actions.selectedFiles.first else { return }
                                            actions.file = first
                                        }
                                        actions.transport = nil
                                            actions.directory = browser.directory?.path(percentEncoded: false) ?? ""
                                            actions.refresh = { if let directory = browser.directory { browser.navigate(to: directory) } }
                                            actions.navigate = { browser.navigate(to: URL(filePath: $0)) }
                                        actions.choose(action)
                                    }
                                }
                                #endif
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

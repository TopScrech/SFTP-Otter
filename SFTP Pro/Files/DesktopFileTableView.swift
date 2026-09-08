import SwiftUI

struct DesktopFileTableView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SFTPSession.self) private var session
    @Binding var selection: FileSelection

    #if os(macOS)
    @State private var actions = FileActionsModel()
    #endif

    @State private var scrollTarget: String?
    @State private var keyboardNavigationActive = false

    var body: some View {
        // One width keeps the lazy rows aligned with the proportional column headers
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(["Name", "Date Modified", "Size", "Kind"].enumerated(), id: \.offset) { index, title in
                        Text(title)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .frame(width: geometry.size.width * [0.44, 0.24, 0.16, 0.16][index], height: 45)
                            .overlay(alignment: .trailing) {
                                if index < 3 { Rectangle().fill(WorkspaceTheme.raised).frame(width: 1) }
                            }
                    }
                }
                Divider().overlay(WorkspaceTheme.raised)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(session.browserFiles) { file in
                            Button { selection.click(file.id, in: session.browserFiles.map(\.id)) } label: {
                                DesktopFileRowView(file: file, width: geometry.size.width, isSelected: selection.ids.contains(file.id))
                                    .contentShape(.rect)
                            }
                                .contentShape(.rect)
                                #if !os(macOS)
                                .onTapGesture(count: 2) {
                                    if file.isDirectory { session.navigate(to: file.path) }
                                }
                                #endif


                                #if os(macOS)
                                .overlay {
                                    FileMenuBridge(parentOnly: file.name == "..", keyboardFocused: selection.cursor == file.id || (keyboardNavigationActive && selection.cursor == nil && session.browserFiles.first?.id == file.id),
                                        moveSelection: { selection.move($0, in: session.browserFiles.map(\.id), extending: $1) },
                                        openSelection: {
                                            if let file = session.browserFiles.first(where: { $0.id == selection.cursor && selection.ids.contains($0.id) && $0.isDirectory }) { session.navigate(to: file.path) }
                                        },
                                        goToParent: {
                                            if let file = session.browserFiles.first(where: { $0.name == ".." }) { session.navigate(to: file.path) }
                                        }, select: { shift, command, context in keyboardNavigationActive = true; workspace.refreshFiles = session.refresh; selection.click(file.id, in: session.browserFiles.map(\.id), extending: shift, toggling: command, contextMenu: context) }) { action in
                                        guard !actions.busy else { return }
                                        guard !session.isPreview, session.isConnected else { actions.error = "Connect to a server to use file actions"; return }
                                        actions.file = file
                                        actions.selectedFiles = session.browserFiles.filter { selection.ids.contains($0.id) && $0.name != ".." }
                                        if action == .delete {
                                            guard let first = actions.selectedFiles.first else { return }
                                            actions.file = first
                                        }
                                        actions.transport = session.transport
                                            actions.directory = session.path
                                            actions.refresh = { session.refresh() }
                                            actions.navigate = { session.navigate(to: $0) }
                                        actions.choose(action)
                                    }
                                }
                                #endif
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrollTarget)
                .onChange(of: selection.cursor) { scrollTarget = selection.cursor }
            }
            .onChange(of: session.path) { selection = FileSelection() }
            .buttonStyle(.plain)
            .font(.body)
            .background(WorkspaceTheme.surface)
        #if os(macOS)
        .modifier(FileActionPresentationModifier())
        .environment(actions)
        #endif
        }
    }
}

import SwiftUI

struct DesktopFileTableView: View {
    @Environment(SFTPSession.self) private var session
    @Binding var selection: RemoteFile.ID?

    #if os(macOS)
    @State private var actions = FileActionsModel()
    #endif

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
                            Button { selection = file.id } label: {
                                DesktopFileRowView(file: file, width: geometry.size.width, isSelected: selection == file.id)
                                    .contentShape(.rect)
                            }
                                .contentShape(.rect)
                                .onTapGesture(count: 2) {
                                    if file.isDirectory { session.navigate(to: file.path) }
                                }

                                #if os(macOS)
                                .overlay {
                                    FileMenuBridge(parentOnly: file.name == "..", select: { selection = file.id }) { action in
                                        guard !actions.busy else { return }
                                        guard !session.isPreview, session.isConnected else { actions.error = "Connect to a server to use file actions"; return }
                                        actions.file = file
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
                }
            }
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

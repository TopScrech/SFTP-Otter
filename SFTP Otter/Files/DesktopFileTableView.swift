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
                FileTableHeaderView(width: geometry.size.width, showsColumnDividers: false, sortOrder: session.sortOrder) {
                    session.sortOrder.select($0)
                }
                Divider()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(session.browserFiles) {
                            RemoteBrowserRowView(
                                selection: $selection, file: $0, width: geometry.size.width,
                                keyboardNavigationActive: $keyboardNavigationActive)
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

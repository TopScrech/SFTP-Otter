import SwiftUI

struct FileBrowserToolbarView: View {
    @Environment(SFTPSession.self) private var session
    @Binding var showImporter: Bool
    @State private var showSearch = false

    var body: some View {
        @Bindable var session = session
        VStack {
            HStack {
                Button("Parent directory", systemImage: "chevron.left", action: session.goUp)
                    .labelStyle(.iconOnly)
                    .disabled(!session.isConnected || session.isPreview)
                TextField("Remote path", text: $session.pathInput)
                    .textFieldStyle(.plain)
                    .onSubmit { session.navigate(to: session.pathInput) }
                    .accessibilityLabel("Remote path")
                Spacer()
                Button("Upload", systemImage: "arrow.up.to.line") { showImporter = true }
                    .buttonStyle(.bordered)
                    .disabled(!session.isConnected || session.isPreview)
                Menu("File options", systemImage: "ellipsis") {
                    Button("Refresh", systemImage: "arrow.clockwise", action: session.refresh)
                        .disabled(!session.isConnected || session.isPreview)
                    Toggle("Show hidden files", isOn: $session.showHidden)
                }
                .menuStyle(.borderlessButton)
                .labelStyle(.iconOnly)
                .fixedSize()
                Button("Search files", systemImage: "magnifyingglass") {
                    showSearch.toggle()
                    if !showSearch { session.search = "" }
                }
                .labelStyle(.iconOnly)
            }
            .buttonStyle(.plain)
            if showSearch {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search files", text: $session.search)
                        .textFieldStyle(.plain)
                    Button("Clear search", systemImage: "xmark.circle.fill") {
                        session.search = ""
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .disabled(session.search.isEmpty)
                }
                .padding(.vertical)
            }
        }
        .foregroundStyle(WorkspaceTheme.muted)
        .padding()
    }
}

import SwiftUI

struct RemoteBreadcrumbsView: View {
    @Environment(SFTPSession.self) private var session
    @State private var editingPath = false

    var body: some View {
        @Bindable var session = session
        HStack {
            Button("Back", systemImage: "chevron.left", action: session.goBack)
                .disabled(!session.canGoBack || session.isPreview)
            Button("Forward", systemImage: "chevron.right", action: session.goForward)
                .disabled(!session.canGoForward || session.isPreview)
            if editingPath {
                TextField("Remote path", text: $session.pathInput)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        session.navigate(to: session.pathInput)
                        editingPath = false
                    }
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        Button("/", systemImage: "folder.fill") { session.navigate(to: "/") }
                            .labelStyle(BreadcrumbLabelStyle())
                            .tint(.cyan)
                        ForEach(session.path.split(separator: "/").enumerated(), id: \.offset) { index, component in
                            Image(systemName: "chevron.right")
                            Button(String(component), systemImage: "folder.fill") {
                                session.navigate(to: "/" + session.path.split(separator: "/").prefix(index + 1).joined(separator: "/"))
                            }
                            .labelStyle(BreadcrumbLabelStyle())
                            .tint(.cyan)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .contextMenu {
                    Button("Edit path", systemImage: "pencil") { editingPath = true }
                }
            }
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
    }
}

import ScrechKit
import UniformTypeIdentifiers

struct UploadDropZoneModifier: ViewModifier {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SFTPSession.self) private var session
    @State private var targeted = false
    
    func body(content: Content) -> some View {
        content
            .dropDestination(for: URL.self) { urls, _ in
                guard session.isConnected, !session.isPreview, !urls.isEmpty else { return false }
                urls.forEach { workspace.upload($0, to: session) }
                return true
            } isTargeted: { targeted = $0 }
            .overlay {
                if targeted, session.isConnected, !session.isPreview {
                    FileDropHighlightView(title: "Upload to \(session.path)", systemImage: "arrow.up.doc")
                }
            }
    }
}

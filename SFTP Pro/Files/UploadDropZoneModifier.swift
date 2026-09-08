import SwiftUI
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
                    RoundedRectangle(cornerRadius: 16)
                        .fill(WorkspaceTheme.accent.opacity(0.18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(WorkspaceTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [8]))
                        }
                        .overlay {
                            Label("Upload to \(session.path)", systemImage: "arrow.up.doc")
                                .font(.title2)
                                .padding()
                                .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 12))
                        }
                        .padding()
                        .allowsHitTesting(false)
                }
            }
    }
}

import SwiftUI
import QuickLook

struct FilePreviewPresentationModifier: ViewModifier {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(FilePreviewModel.self) private var preview

    func body(content: Content) -> some View {
        @Bindable var preview = preview
        content
            .quickLookPreview($preview.url)
            .onChange(of: preview.url) {
                if preview.url == nil { preview.dismiss() }
            }
            .onAppear {
                preview.registerTransfer = { workspace.transfers.insert($0, at: 0) }
            }
            .onDisappear { preview.dismiss() }
            .overlay(alignment: .bottom) {
                if preview.task != nil {
                    VStack {
                        ProgressView("Loading preview…")
                        Button("Cancel", systemImage: "xmark") { preview.dismiss() }
                    }
                    .padding()
                    .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 10))
                }
                if let error = preview.error {
                    VStack {
                        Text(error)
                        Button("Dismiss", systemImage: "xmark") { preview.error = nil }
                    }
                    .padding()
                    .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 10))
                }
            }
    }
}

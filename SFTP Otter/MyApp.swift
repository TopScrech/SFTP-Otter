import SwiftUI

@main struct MyApp: App {
    @State private var workspace = WorkspaceModel()
    
    var body: some Scene {
        WindowGroup {
            WorkspaceView()
                .environment(workspace)
        }
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
#endif
        .defaultSize(width: 1180, height: 760)
#if os(macOS)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh files") { workspace.refreshFiles() }
                    .keyboardShortcut("r")
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { workspace.showSettings = true }
                    .keyboardShortcut(",")
            }
        }
#endif
#if DEBUG && os(macOS)
        .commands {
            CommandMenu("Development") {
                Button("Load visual preview") { workspace.loadVisualPreview() }
                Button("Load local file preview") { workspace.loadLocalFilePreview() }
            }
        }
#endif
    }
}

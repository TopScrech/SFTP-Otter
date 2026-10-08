import SwiftUI

@main
struct MyApp: App {
    @State private var workspace = WorkspaceModel()
    @State private var dockProgress = DockTransferProgress()
    
    init() {
        QuickLookCache.prepareForLaunch()
    }
    
    var body: some Scene {
        WindowGroup {
            WorkspaceView()
                .environment(workspace)
                .frame(minWidth: 400, minHeight: 500)
                .task {
                    dockProgress.start(workspace: workspace)
                }
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1180, height: 760)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh files") {
                    workspace.refreshFiles()
                }
                .keyboardShortcut("r")
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    workspace.showSettings = true
                }
                .keyboardShortcut(",")
            }
        }
#if DEBUG
        .commands {
            CommandMenu("Development") {
                Button("Load visual preview") {
                    workspace.loadVisualPreview()
                }
                
                Button("Load local file preview") {
                    workspace.loadLocalFilePreview()
                }
            }
        }
#endif
    }
}

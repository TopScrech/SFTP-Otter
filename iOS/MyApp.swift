import SwiftUI

@main struct MyApp: App {
    @State private var workspace = WorkspaceModel()

    var body: some Scene {
        WindowGroup {
            WorkspaceView()
                .environment(workspace)
        }
    }
}

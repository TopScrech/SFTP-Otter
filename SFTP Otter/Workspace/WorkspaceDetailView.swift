import SwiftUI

struct WorkspaceDetailView: View {
    @Environment(WorkspaceModel.self) private var workspace
    
    var body: some View {
        switch workspace.section {
        case .files: FileBrowserView()
        case .transfers: TransfersView()
        }
    }
}

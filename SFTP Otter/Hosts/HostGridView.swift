import SwiftUI

struct HostGridView: View {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), alignment: .topLeading)]) {
            ForEach(workspace.filteredHosts) {
                HostCardView(host: $0)
            }
        }
    }
}

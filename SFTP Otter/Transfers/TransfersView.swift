import ScrechKit

struct TransfersView: View {
    @Environment(WorkspaceModel.self) private var workspace
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Transfers").largeTitle().bold()
                Spacer()
                Button("Clear") {
                    workspace.transfers.removeAll { $0.state.isFinished }
                }
                .disabled(!workspace.transfers.contains { $0.state.isFinished })
            }
            .padding(.vertical)
            if workspace.transfers.isEmpty {
                ContentUnavailableView("No transfers yet", systemImage: "arrow.up.arrow.down", description: Text("Uploads and downloads appear here with live progress"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(workspace.transfers) {
                            TransferRowView(transfer: $0)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

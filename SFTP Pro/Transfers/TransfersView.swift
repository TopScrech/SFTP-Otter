import SwiftUI

struct TransfersView: View {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Transfers").font(.largeTitle).bold()
                Spacer()
                Button("Clear finished", systemImage: "checkmark.circle") {
                    workspace.transfers.removeAll { $0.finished }
                }
                .disabled(!workspace.transfers.contains { $0.finished })
            }
            .padding(.vertical)
            if workspace.transfers.isEmpty {
                ContentUnavailableView("No transfers yet", systemImage: "arrow.up.arrow.down", description: Text("Uploads and downloads appear here with live progress"))
                    .frame(maxHeight: .infinity)
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

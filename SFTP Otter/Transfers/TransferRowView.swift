import ScrechKit

struct TransferRowView: View {
    let transfer: FileTransfer
    
    var body: some View {
        HStack {
            Image(systemName: transfer.isUpload ? "arrow.up.doc" : "arrow.down.doc")
                .title2()
                .padding()
                .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 10))
            VStack(alignment: .leading) {
                HStack {
                    Text(transfer.name).headline()
                    Spacer()
                    Text(transfer.status).caption()
                        .foregroundStyle(transfer.failure == nil ? WorkspaceTheme.muted : .red)
                }
                ProgressView(value: transfer.progress)
                HStack {
                    Text(Int64(clamping: transfer.completedBytes), format: .byteCount(style: .file))
                    Text("of")
                    Text(Int64(clamping: transfer.totalBytes), format: .byteCount(style: .file))
                    Spacer()
                    if !transfer.finished {
                        Text(transfer.bytesPerSecond / 1_000_000, format: .number.precision(.fractionLength(1)))
                        Text("MB/s")
                    }
                }
                .caption()
                .monospacedDigit()
                .foregroundStyle(WorkspaceTheme.muted)
                if let failure = transfer.failure {
                    Text(failure).caption().foregroundStyle(.red)
                }
            }
            if let url = transfer.localURL {
                ShareLink(item: url) {
                    Label("Export download", systemImage: "square.and.arrow.up")
                }
                .labelStyle(.iconOnly)
            }
            if !transfer.finished {
                Button("Cancel transfer", systemImage: "xmark", action: transfer.cancel)
                    .labelStyle(.iconOnly)
            }
        }
        .padding()
        .background(WorkspaceTheme.surface, in: .rect(cornerRadius: 12))
    }
}

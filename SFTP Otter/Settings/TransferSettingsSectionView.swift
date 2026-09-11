import ScrechKit

struct TransferSettingsSectionView: View {
    @AppStorage(TransferPreferences.parallelTransfersKey) private var parallelTransfers = TransferPreferences.defaultParallelTransfers
    @AppStorage(TransferPreferences.requestsPerFileKey) private var requestsPerFile = TransferPreferences.defaultRequestsPerFile

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Transfers")
                .headline()

            HStack {
                Text("Parallel transfers")

                Spacer()

                Stepper(value: $parallelTransfers, in: 1...16) {
                    Text(parallelTransfers, format: .number)
                        .monospacedDigit()
                }
                .fixedSize()
            }

            if parallelTransfers >= 10 {
                Label("10 or more parallel transfers may exceed your server’s connection limits and increase memory usage. Lower this setting if transfers fail or slow down", systemImage: "exclamationmark.triangle.fill")
                    .footnote()
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack {
                Text("Requests per file")

                Spacer()

                Stepper(value: $requestsPerFile, in: 1...128) {
                    Text(requestsPerFile, format: .number)
                        .monospacedDigit()
                }
                .fixedSize()
            }

            Text("Parallel transfers limits simultaneous uploads and downloads across hosts. Requests per file controls how many chunks each file transfers at once. Changes apply as transfer slots become available; active files keep their request count")
                .footnote()
                .foregroundStyle(WorkspaceTheme.muted)
        }
    }
}

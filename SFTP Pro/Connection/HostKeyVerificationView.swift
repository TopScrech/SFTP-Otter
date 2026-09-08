import SwiftUI

struct HostKeyVerificationView: View {
    @Environment(HostKeyTrustStore.self) private var trustStore
    let challenge: HostKeyChallenge

    var body: some View {
        WorkspaceDialogView(title: "Verify server identity", close: { trustStore.resolve(trust: false) }) {
            Text("Verify the server key for \(challenge.endpoint)")
            Text("Compare this fingerprint with the one provided by your server administrator before trusting the server")
                .foregroundStyle(.secondary)
            Text(challenge.fingerprint)
                .font(.body.monospaced())
                .textSelection(.enabled)
                .padding()
                .background(WorkspaceTheme.surface, in: .rect(cornerRadius: 8))
            HStack {
                Spacer()
                Button("Trust, save and connect", systemImage: "checkmark.shield") {
                    trustStore.resolve(trust: true)
                }
                .buttonStyle(DialogActionStyle())
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 520)
        .interactiveDismissDisabled()
    }
}

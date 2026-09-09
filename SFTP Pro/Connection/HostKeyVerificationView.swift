import SwiftUI

struct HostKeyVerificationView: View {
    @Environment(HostKeyTrustStore.self) private var trustStore
    let challenge: HostKeyChallenge

    var body: some View {
        VStack(alignment: .leading) {
            Label("Verify server identity", systemImage: "lock.shield")
                .font(.title2).bold()
            Text("Verify the server key for \(challenge.endpoint)")
            Text("Compare this fingerprint with the one provided by your server administrator before trusting the server")
                .foregroundStyle(.secondary)
            Text(challenge.fingerprint)
                .font(.body.monospaced())
                .textSelection(.enabled)
                .padding()
                .background(WorkspaceTheme.surface, in: .rect(cornerRadius: 8))
            HStack {
                Button("Cancel", role: .cancel) { trustStore.resolve(trust: false) }
                Spacer()
                Button("Trust, save and connect", systemImage: "checkmark.shield") {
                    trustStore.resolve(trust: true)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 320, idealWidth: 520)
        .interactiveDismissDisabled()
    }
}

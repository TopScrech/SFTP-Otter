import SwiftUI

struct TrustedHostsSectionView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        Section {
            if let errorMessage = settings.errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else if settings.keys.isEmpty {
                Text("No trusted hosts yet").foregroundStyle(.secondary)
            }
            ForEach(settings.keys.keys.sorted(), id: \.self) { endpoint in
                VStack(alignment: .leading) {
                    HStack {
                        Label(endpoint, systemImage: "checkmark.shield")
                        Spacer()
                        Button("Forget", role: .destructive) {
                            settings.requestRemoval(of: endpoint)
                        }
                    }
                    if let key = settings.keys[endpoint] {
                        Text(workspace.trustStore.fingerprint(for: key))
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            HStack {
                Text("Trusted SSH hosts")
                Spacer()
                Button("About trusted SSH hosts", systemImage: "questionmark.circle") {
                    settings.showTrustedHostsHelp = true
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
            }
        }
    }
}

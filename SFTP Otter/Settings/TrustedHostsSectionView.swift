import ScrechKit

struct TrustedHostsSectionView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Trusted SSH hosts")
                    .headline()

                Spacer()

                Button("About trusted SSH hosts", systemImage: "questionmark.circle") {
                    settings.showTrustedHostsHelp = true
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(WorkspaceTheme.muted)
            }

            if let errorMessage = settings.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else if settings.keys.isEmpty {
                Text("No trusted hosts yet")
                    .foregroundStyle(WorkspaceTheme.muted)
            }

            ForEach(settings.keys.keys.sorted(), id: \.self) { endpoint in
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(endpoint)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        if let key = settings.keys[endpoint] {
                            Text(workspace.trustStore.fingerprint(for: key))
                                .caption(design: .monospaced)
                                .enableSelection()
                                .foregroundStyle(WorkspaceTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()

                    Button("Forget", role: .destructive) {
                        settings.requestRemoval(of: endpoint)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 12))
            }
        }
    }
}

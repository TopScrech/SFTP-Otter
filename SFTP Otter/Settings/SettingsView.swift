import ScrechKit

struct SettingsView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    @State private var settings = SettingsModel()
    
    var body: some View {
        @Bindable var workspace = workspace
        @Bindable var settings = settings
        WorkspaceDialogView(title: "Settings", close: { dismiss() }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Startup")
                            .headline()

                        HStack {
                            Text("Reopen hosts and local folders after relaunch")

                            Spacer()

                            Toggle("Reopen hosts and local folders after relaunch", isOn: $workspace.reopenConnectedHosts)
                                .labelsHidden()
                        }

                        Divider()

                        HStack {
                            Text("Remember last opened folder in connected hosts")

                            Spacer()

                            Toggle("Remember last opened folder in connected hosts", isOn: $workspace.rememberHostLocations)
                                .labelsHidden()
                        }
                        .disabled(!workspace.reopenConnectedHosts)
                    }
                    .toggleStyle(.switch)

                    TransferSettingsSectionView()

                    SavedHostsSectionView()

                    TrustedHostsSectionView()
                }
            }
            .frame(maxHeight: 400)

            HStack {
                Spacer()

                Button("Done") { dismiss() }
                    .buttonStyle(DialogActionStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .sheet($settings.showConfirmation) {
            MessageDialogView(title: "Forget this trusted host?", message: settings.pendingRemoval ?? "", actionTitle: "Forget host", destructive: true) {
                settings.forget(in: workspace.trustStore)
            }
        }
        .sheet($settings.showTrustedHostsHelp) {
            MessageDialogView(title: "Trusted SSH hosts", message: "These server keys were approved when connecting. Forgetting a key asks you to verify the server again on your next connection")
        }
        .onAppear { settings.load(from: workspace.trustStore) }
        .environment(settings)
        .frame(width: 620)
    }
}

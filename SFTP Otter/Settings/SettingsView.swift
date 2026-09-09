import ScrechKit

struct SettingsView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    @State private var settings = SettingsModel()
    
    var body: some View {
        @Bindable var workspace = workspace
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Startup") {
                    Toggle("Reopen hosts and local folders after relaunch", isOn: $workspace.reopenConnectedHosts)
                    Toggle("Remember last opened folder in connected hosts", isOn: $workspace.rememberHostLocations)
                        .disabled(!workspace.reopenConnectedHosts)
                }
                TrustedHostsSectionView()
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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
        }
        .environment(settings)
        .frame(minWidth: 340, idealWidth: 600, minHeight: 360)
    }
}

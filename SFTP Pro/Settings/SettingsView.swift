import SwiftUI

struct SettingsView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    @State private var keys: [String: String] = [:]
    @State private var pendingRemoval: String?
    @State private var showConfirmation = false
    @State private var showTrustedHostsHelp = false
    @State private var errorMessage: String?

    var body: some View {
        @Bindable var workspace = workspace
        NavigationStack {
            Form {
                Section("Startup") {
                    Toggle("Reopen hosts and local folders after relaunch", isOn: $workspace.reopenConnectedHosts)
                    Toggle("Remember last opened folder in connected hosts", isOn: $workspace.rememberHostLocations)
                        .disabled(!workspace.reopenConnectedHosts)
                }
                Section {
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    } else if keys.isEmpty {
                        Text("No trusted hosts yet").foregroundStyle(.secondary)
                    }
                    ForEach(keys.keys.sorted(), id: \.self) { endpoint in
                        VStack(alignment: .leading) {
                            HStack {
                                Label(endpoint, systemImage: "checkmark.shield")
                                Spacer()
                                Button("Forget", role: .destructive) {
                                    pendingRemoval = endpoint
                                    showConfirmation = true
                                }
                            }
                            if let key = keys[endpoint] {
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
                            showTrustedHostsHelp = true
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showConfirmation) {
                MessageDialogView(title: "Forget this trusted host?", message: pendingRemoval ?? "", actionTitle: "Forget host", destructive: true) {
                    guard let endpoint = pendingRemoval else { return }
                    do {
                        try workspace.trustStore.forget(endpoint: endpoint)
                        keys = try workspace.trustStore.load()
                    } catch { errorMessage = error.localizedDescription }
                }
            }
            .sheet(isPresented: $showTrustedHostsHelp) {
                MessageDialogView(title: "Trusted SSH hosts", message: "These server keys were approved when connecting. Forgetting a key asks you to verify the server again on your next connection")
            }
            .onAppear {
                do { keys = try workspace.trustStore.load() }
                catch { errorMessage = error.localizedDescription }
            }
        }
        .frame(minWidth: 340, idealWidth: 600, minHeight: 360)
    }
}

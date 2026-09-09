import SwiftUI

struct HostEditorView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    @State private var host = Host()
    @State private var savePassword = false
    @State private var password = ""
    @State private var port = "22"

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    TextField("Label", text: $host.name)
                    TextField("Address", text: $host.address)
                        .autocorrectionDisabled()
                    TextField("Port", text: $port)
                }
                Section("Authentication") {
                    TextField("Username", text: $host.username)
                        .autocorrectionDisabled()
                    Toggle("Save password in Keychain", isOn: $savePassword)
                    if savePassword {
                        SecureField("Password", text: $password)
                    }
                }
                Section("SFTP") {
                    TextField("Initial directory", text: $host.initialPath)
                        .autocorrectionDisabled()
                    Label("SFTP connection", systemImage: "lock.shield")
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(workspace.editingHost == nil ? "New host" : "Edit host")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        host.port = Int(port) ?? 22
                        host.savedPassword = savePassword ? password : nil
                        if workspace.save(host) { dismiss() }
                    }
                    .disabled(host.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || host.username.isEmpty || !(1...65535).contains(Int(port) ?? 0))
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 460, minHeight: 460)
        .onAppear {
            if let editing = workspace.editingHost {
                host = editing
                port = String(editing.port)
                savePassword = editing.savedPassword != nil
                password = editing.savedPassword ?? ""
            }
        }
    }
}

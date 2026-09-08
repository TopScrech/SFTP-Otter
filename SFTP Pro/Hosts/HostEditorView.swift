import ScrechKit

struct HostEditorView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    @State private var editor = HostEditorModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    TextField("Label", text: $editor.host.name)
                    TextField("Address", text: $editor.host.address)
                        .autocorrectionDisabled()
                    TextField("Port", text: $editor.port)
                }
                Section("Authentication") {
                    TextField("Username", text: $editor.host.username)
                        .autocorrectionDisabled()
                    Toggle("Save password in Keychain", isOn: $editor.savePassword)
                    if editor.savePassword {
                        SecureField("Password", text: $editor.password)
                    }
                }
                Section("SFTP") {
                    TextField("Initial directory", text: $editor.host.initialPath)
                        .autocorrectionDisabled()
                    Label("SFTP connection", systemImage: "lock.shield")
                        .secondary()
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
                        if editor.save(to: workspace) { dismiss() }
                    }
                    .disabled(!editor.canSave)
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 460, minHeight: 460)
        .onAppear { editor.load(workspace.editingHost) }
    }
}

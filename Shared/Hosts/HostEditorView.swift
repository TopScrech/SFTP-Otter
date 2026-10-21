import ScrechKit

struct HostEditorView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    @State private var editor = HostEditorModel()
    
    var body: some View {
        WorkspaceDialogView(desktopWidth: 520, title: workspace.editingHost == nil ? "Add host" : "Edit host", close: { dismiss() }) {
            VStack(alignment: .leading, spacing: 16) {
                DialogFieldView(title: "Label") {
                    TextField("", text: $editor.host.name)
                        .accessibilityLabel("Label")
                }
                
                HStack(alignment: .top) {
                    DialogFieldView(title: "Address *") {
                        TextField("", text: $editor.host.address)
                            .autocorrectionDisabled()
                            #if os(iOS) || os(visionOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .accessibilityLabel("Address")
                    }
                    
                    DialogFieldView(title: "Port *") {
                        TextField("", text: $editor.port)
                            .accessibilityLabel("Port")
                    }
                    .frame(width: 100)
                }
                
                DialogFieldView(title: "Username *") {
                    TextField("", text: $editor.host.username)
                        .autocorrectionDisabled()
                        #if os(iOS) || os(visionOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .accessibilityLabel("Username")
                }
                
                Toggle("Save password in Keychain", isOn: $editor.savePassword)
                    .toggleStyle(.switch)
                    .padding(.top)
                
                if editor.savePassword {
                    DialogFieldView(title: "Password") {
                        SecureField("", text: $editor.password)
                            .accessibilityLabel("Password")
                    }
                }
                
                DialogFieldView(title: "Initial directory") {
                    TextField("", text: $editor.host.initialPath)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Initial directory")
                }
            }
            
            HStack {
                Spacer()
                
                Button("Save") {
                    if editor.save(to: workspace) { dismiss() }
                }
                .buttonStyle(DialogActionStyle())
                .disabled(!editor.canSave)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onAppear { editor.load(workspace.editingHost) }
    }
}

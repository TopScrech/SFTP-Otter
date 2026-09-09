import ScrechKit

struct AuthenticationView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    let host: Host
    @State private var password = ""
    @FocusState private var passwordFocused: Bool
    
    var body: some View {
        WorkspaceDialogView(title: "Connect", close: { dismiss() }) {
            VStack(alignment: .leading) {
                Label(host.displayName, systemImage: "server.rack")
                Text(host.endpoint).foregroundStyle(WorkspaceTheme.muted)
            }
            VStack(alignment: .leading) {
                Text("Password").foregroundStyle(WorkspaceTheme.muted)
                SecureField("Password", text: $password)
                    .textFieldStyle(.plain)
                    .padding()
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(WorkspaceTheme.muted.opacity(0.3)) }
                    .focused($passwordFocused)
                Text("Used for this connection only and never saved to disk")
                    .caption()
                    .foregroundStyle(WorkspaceTheme.muted)
            }
            HStack {
                Spacer()
                Button("Connect") {
                    workspace.submitAuthentication(host, password: password)
                    password = ""
                }
                .buttonStyle(DialogActionStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(password.isEmpty)
            }
        }
        .frame(width: 460)
        .onAppear { passwordFocused = true }
    }
}

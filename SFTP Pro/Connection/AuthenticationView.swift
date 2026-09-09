import SwiftUI

struct AuthenticationView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    let host: Host
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(host.displayName, systemImage: "server.rack")
                    Text(host.endpoint).foregroundStyle(.secondary)
                }
                Section("Password") {
                    SecureField("Password", text: $password)
                    Text("Used for this connection only and never saved to disk")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Connect")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        workspace.submitAuthentication(host, password: password)
                        password = ""
                    }
                    .disabled(password.isEmpty)
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 420, minHeight: 320)
    }
}

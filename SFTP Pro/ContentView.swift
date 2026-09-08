import SwiftUI

struct ContentView: View {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some View {
        @Bindable var workspace = workspace
        @Bindable var trustStore = workspace.trustStore
        ViewThatFits(in: .horizontal) {
            DesktopWorkspaceView()
                .frame(minWidth: 760)
            MobileWorkspaceView()
        }
        .task { workspace.restoreConnections() }
        .onChange(of: workspace.connectedHostIDs) { workspace.rememberConnectedHosts() }
        .onChange(of: workspace.selectedSessionID) { workspace.rememberConnectedHosts() }
        .onChange(of: workspace.secondarySessionID) { workspace.rememberConnectedHosts() }
        .background(WorkspaceTheme.background)
        .foregroundStyle(WorkspaceTheme.text)
        .tint(WorkspaceTheme.accent)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $workspace.showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $workspace.showHostPicker, onDismiss: workspace.hostPickerDismissed) {
            HostPickerView()
        }
        .sheet(isPresented: $workspace.showHostEditor) {
            HostEditorView()
        }
        .sheet(item: $workspace.connectingHost, onDismiss: workspace.authenticationDismissed) {
            AuthenticationView(host: $0)
        }
        .onChange(of: workspace.showHostEditor) {
            if !workspace.showHostEditor { workspace.editingHost = nil }
        }
        .sheet(item: $trustStore.challenge) {
            HostKeyVerificationView(challenge: $0)
                .environment(trustStore)
        }
        .sheet(isPresented: $workspace.showError) {
            MessageDialogView(title: "Something went wrong", message: workspace.errorMessage)
        }
    }
}

#Preview {
    ContentView()
        .environment(WorkspaceModel())
}

import ScrechKit

struct SettingsView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    @State private var settings = SettingsModel()
    
    var body: some View {
        @Bindable var settings = settings
        
        WorkspaceDialogView(desktopWidth: 620, title: "Settings", close: { dismiss() }) {
            #if os(macOS)
            ScrollView {
                SettingsContentView()
            }
            .scrollClipDisabled()
            .frame(maxHeight: 400)
            #else
            SettingsContentView()
            #endif
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
    }
}

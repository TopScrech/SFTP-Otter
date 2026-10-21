import ScrechKit

struct SettingsView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    @State private var vm = SettingsVM()
    
    var body: some View {
        @Bindable var vm = vm
        
        WorkspaceDialogView(desktopWidth: 620, title: "Settings", close: { dismiss() }) {
#if os(macOS)
            ScrollView {
                SettingsContentView()
            }
            .frame(maxHeight: 400)
#else
            SettingsContentView()
#endif
        }
        .sheet($vm.showConfirmation) {
            MessageDialogView(title: "Forget this trusted host?", message: vm.pendingRemoval ?? "", actionTitle: "Forget host", destructive: true) {
                vm.forget(in: workspace.trustStore)
            }
        }
        .sheet($vm.showTrustedHostsHelp) {
            MessageDialogView(title: "Trusted SSH hosts", message: "These server keys were approved when connecting. Forgetting a key asks you to verify the server again on your next connection")
        }
        .onAppear {
            vm.load(from: workspace.trustStore)
        }
        .environment(vm)
    }
}

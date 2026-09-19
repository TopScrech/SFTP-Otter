import ScrechKit

struct SettingsContentView: View {
    @Environment(WorkspaceModel.self) private var workspace

    var body: some View {
        @Bindable var workspace = workspace

        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Startup")
                    .headline()
                
                HStack {
                    Text("Reopen hosts and local folders after relaunch")
                    
                    Spacer()
                    
                    Toggle("Reopen hosts and local folders after relaunch", isOn: $workspace.reopenConnectedHosts)
                        .labelsHidden()
                        .fixedSize()
                }
                
                Divider()
                
                HStack {
                    Text("Remember last opened folder in connected hosts")
                    
                    Spacer()
                    
                    Toggle("Remember last opened folder in connected hosts", isOn: $workspace.rememberHostLocations)
                        .labelsHidden()
                        .fixedSize()
                }
                .disabled(!workspace.reopenConnectedHosts)
            }
            .toggleStyle(.switch)
            
            TransferSettingsSectionView()
            
            SavedHostsSectionView()
            
            TrustedHostsSectionView()
        }
    }
}

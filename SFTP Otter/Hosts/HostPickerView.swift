import ScrechKit

struct HostPickerView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        @Bindable var workspace = workspace
        WorkspaceDialogView(title: "Select host", close: { dismiss() }) {
            HostsView()
        }
        .frame(width: 600)
        .sheet($workspace.showPickerEditor) {
            HostEditorView()
        }
        .onChange(of: workspace.showPickerEditor) {
            if !workspace.showPickerEditor { workspace.editingHost = nil }
        }
    }
}

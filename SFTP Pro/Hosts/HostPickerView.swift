import SwiftUI

struct HostPickerView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var workspace = workspace
        NavigationStack {
            HostsView()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
        .frame(minWidth: 320, idealWidth: 600, minHeight: 450)
        .sheet(isPresented: $workspace.showPickerEditor) {
            HostEditorView()
        }
        .onChange(of: workspace.showPickerEditor) {
            if !workspace.showPickerEditor { workspace.editingHost = nil }
        }
    }
}

#if os(macOS)
import SwiftUI

struct FileActionPresentationModifier: ViewModifier {
    @Environment(FileActionsModel.self) private var actions

    func body(content: Content) -> some View {
        @Bindable var actions = actions
        content
            .alert(actions.deletionTitle, isPresented: $actions.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { actions.run(.delete) }
                    .keyboardShortcut(.defaultAction)
            } message: {
                Text(actions.transport == nil ? "The item will be moved to the Trash" : "This permanently deletes the remote item and its contents and cannot be undone")
            }
            .sheet(item: $actions.prompt) { action in
                if action == .permissions {
                    PermissionsEditorView().environment(actions)
                } else {
                    FileActionPromptView(action: action).environment(actions)
                }
            }
            .overlay(alignment: .bottom) {
                if actions.busy { ProgressView("Working…").padding().background(WorkspaceTheme.raised, in: .rect(cornerRadius: 10)) }
                if let error = actions.error {
                    VStack {
                        Text(error)
                        Button("Dismiss") { actions.error = nil }
                    }
                    .padding()
                    .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 10))
                }
            }
    }
}
#endif

#if os(macOS)
import ScrechKit

struct FileActionPresentationModifier: ViewModifier {
    @Environment(FileActionsModel.self) private var actions
    
    func body(content: Content) -> some View {
        @Bindable var actions = actions
        content
            .sheet($actions.showDeleteConfirmation) {
                MessageDialogView(
                    title: actions.deletionTitle,
                    message: actions.transport == nil ? "The selected items will be moved to the Trash" : "This permanently deletes the selected remote items and their contents and cannot be undone",
                    actionTitle: "Delete",
                    destructive: true
                ) {
                    actions.run(.delete)
                }
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

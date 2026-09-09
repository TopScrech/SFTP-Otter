#if os(macOS)
import ScrechKit

struct FileActionPromptView: View {
    @Environment(FileActionsModel.self) private var actions
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool
    let action: FileMenuAction
    
    var body: some View {
        @Bindable var actions = actions
        WorkspaceDialogView(title: action.rawValue, close: { dismiss() }) {
            VStack(alignment: .leading, spacing: 0) {
                Text(action == .rename ? "New filename *" : "Folder name *")
                    .callout()
                    .foregroundStyle(WorkspaceTheme.muted)
                    .padding(.horizontal, 6)
                    .background(WorkspaceTheme.surface)
                    .padding(.leading, 10)
                    .offset(y: 8)
                    .zIndex(1)
                TextField("", text: $actions.input)
                    .textFieldStyle(.plain)
                    .padding()
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(WorkspaceTheme.muted.opacity(0.3)) }
                    .focused($nameFocused)
                    .onSubmit { if !actions.input.isEmpty { actions.run(action) } }
            }
            HStack {
                Spacer()
                Button("Confirm") { actions.run(action) }
                    .buttonStyle(DialogActionStyle())
                    .disabled(actions.input.isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 460)
        .onAppear { nameFocused = true }
    }
}
#endif

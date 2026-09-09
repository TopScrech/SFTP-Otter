#if os(macOS)
import SwiftUI

struct FileActionPromptView: View {
    @Environment(FileActionsModel.self) private var actions
    @Environment(\.dismiss) private var dismiss
    let action: FileMenuAction

    var body: some View {
        @Bindable var actions = actions
        VStack(alignment: .leading) {
            Text(action.rawValue).font(.title2).bold()
            if action == .delete {
                Text("Delete “\(actions.file?.name ?? "")”\(actions.file?.isDirectory == true ? " and its contents" : "")?")
                Text(actions.transport == nil ? "The item will be moved to the Trash" : "This permanently deletes the remote item and cannot be undone")
                    .foregroundStyle(.secondary)
            } else {
                TextField(action == .permissions ? "Octal permissions, e.g. 755" : "Name", text: $actions.input)
                    .onSubmit { actions.run(action) }
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button(action == .delete ? "Delete" : "Save", role: action == .delete ? .destructive : nil) { actions.run(action) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}
#endif

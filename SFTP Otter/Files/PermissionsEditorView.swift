#if os(macOS)
import ScrechKit

struct PermissionsEditorView: View {
    @Environment(FileActionsModel.self) private var actions
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var actions = actions
        WorkspaceDialogView(title: "Edit permissions", close: { dismiss() }) {
            VStack(alignment: .leading, spacing: 24) {
                Text(actions.file?.path ?? "").lineLimit(2).enableSelection()
                Grid(alignment: .leading, horizontalSpacing: 36, verticalSpacing: 8) {
                    GridRow {
                        Text("File Access").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Read")
                        Text("Write")
                        Text("Execute")
                    }
                    .bold()
                    Divider()
                    ForEach($actions.permissionGroups) { access in
                        PermissionAccessRowView(access: access)
                        if access.wrappedValue.id < 2 { Divider() }
                    }
                }
                VStack(alignment: .leading) {
                    Text("Ownership").bold().foregroundStyle(WorkspaceTheme.text)
                    Divider()
                    HStack { Text("User"); Spacer(); Text(actions.permissionOwner) }
                        .padding(.vertical, 8)
                    Divider()
                    HStack { Text("Group"); Spacer(); Text(actions.permissionGroup) }
                        .padding(.vertical, 8)
                    Divider()
                }
                .foregroundStyle(WorkspaceTheme.muted)
                HStack {
                    Spacer()
                    Button("Save", action: actions.savePermissions)
                        .buttonStyle(DialogActionStyle())
                        .disabled(!actions.permissionsChanged)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(width: 560)
    }
}
#endif

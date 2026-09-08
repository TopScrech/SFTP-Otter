#if os(macOS)
import SwiftUI

struct PermissionsEditorView: View {
    @Environment(FileActionsModel.self) private var actions
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var actions = actions
        VStack(spacing: 0) {
            HStack {
                Text("Edit permissions").font(.title2)
                Spacer()
                Button("Close", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(30)
            .background(WorkspaceTheme.raised)
            VStack(alignment: .leading, spacing: 24) {
                Text(actions.file?.path ?? "").lineLimit(2).textSelection(.enabled)
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
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(actions.permissionsChanged ? WorkspaceTheme.accent : WorkspaceTheme.raised, in: .rect(cornerRadius: 12))
                        .foregroundStyle(actions.permissionsChanged ? WorkspaceTheme.text : WorkspaceTheme.muted)
                        .disabled(!actions.permissionsChanged)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(30)
        }
        .font(.title3)
        .foregroundStyle(WorkspaceTheme.text)
        .tint(WorkspaceTheme.accent)
        .background(WorkspaceTheme.surface)
        .preferredColorScheme(.dark)
        .frame(width: 560)
    }
}
#endif

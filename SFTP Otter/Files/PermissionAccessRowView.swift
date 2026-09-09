#if os(macOS)
import SwiftUI

struct PermissionAccessRowView: View {
    @Binding var access: PermissionAccess
    
    var body: some View {
        GridRow {
            Text(access.title)
                .foregroundStyle(WorkspaceTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("\(access.title) read", isOn: $access.read)
            Toggle("\(access.title) write", isOn: $access.write)
            Toggle("\(access.title) execute", isOn: $access.execute)
        }
        .toggleStyle(PermissionToggleStyle())
        .labelsHidden()
        .padding(.vertical, 4)
    }
}
#endif

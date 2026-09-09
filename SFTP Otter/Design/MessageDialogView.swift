import SwiftUI

struct MessageDialogView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String
    var actionTitle = "OK"
    var destructive = false
    var action: () -> Void = {}

    var body: some View {
        WorkspaceDialogView(title: title, close: { dismiss() }) {
            Text(message)
                .foregroundStyle(WorkspaceTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button(actionTitle, role: destructive ? .destructive : nil) {
                    dismiss()
                    action()
                }
                .buttonStyle(DialogActionStyle(destructive: destructive))
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 460)
    }
}

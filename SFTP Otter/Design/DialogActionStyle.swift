import SwiftUI

struct DialogActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var destructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bold()
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .foregroundStyle(isEnabled ? WorkspaceTheme.text : WorkspaceTheme.muted)
            .background(isEnabled ? (destructive ? Color.red : WorkspaceTheme.accent) : WorkspaceTheme.raised, in: .rect(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(.rect(cornerRadius: 12))
    }
}

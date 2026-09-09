import ScrechKit

struct BrowserActionsButtonView: View {
    let title: String
    var destructive = false
    var checked = false
    let action: () -> Void
    @Environment(\.isEnabled) private var enabled
    @Environment(BrowserActionsNavigation.self) private var navigation

    var body: some View {
        Button(role: destructive ? .destructive : nil, action: action) {
            HStack {
                Text(title)
                Spacer()
                if checked { Image(systemName: "checkmark") }
            }
            .title3()
            .foregroundStyle(!enabled ? WorkspaceTheme.muted : destructive ? .red : .white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(navigation.selected == title && enabled ? Color.white.opacity(0.08) : .clear, in: .rect(cornerRadius: 6))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { if $0, enabled { navigation.selected = title } }
    }
}

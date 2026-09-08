import SwiftUI

struct PermissionToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Capsule()
                .fill(configuration.isOn ? WorkspaceTheme.accent.opacity(0.45) : WorkspaceTheme.muted.opacity(0.3))
                .frame(width: 38, height: 16)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(configuration.isOn ? WorkspaceTheme.accent : WorkspaceTheme.muted)
                        .frame(width: 22, height: 22)
                }
                .frame(height: 26)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }
}

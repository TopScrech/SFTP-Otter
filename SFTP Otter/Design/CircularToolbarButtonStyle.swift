import SwiftUI

struct CircularToolbarButtonStyle: ButtonStyle {
    @ScaledMetric private var diameter = 32
    @State private var hovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .frame(width: diameter, height: diameter)
            .background(hovered || configuration.isPressed ? WorkspaceTheme.raised : .clear, in: .circle)
            .contentShape(.circle)
            .onHover { hovered = $0 }
    }
}

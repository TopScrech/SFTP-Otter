import SwiftUI

struct FileMenuButtonView: View {
    let item: FileMenuAction
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Text(item.rawValue)
                .font(.title3)
                .foregroundStyle(item == .delete ? .red : .white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(hovered ? Color.white.opacity(0.08) : .clear)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

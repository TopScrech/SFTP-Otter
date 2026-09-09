import SwiftUI

struct FileContextMenuView: View {
    @Environment(FileMenuNavigation.self) private var navigation
    let action: (FileMenuAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(navigation.items) { item in
                FileMenuButtonView(item: item) { action(item) }
            }
        }
        .padding(8)
        .frame(width: 300)
        .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08)) }
        .environment(\.colorScheme, .dark)
    }
}

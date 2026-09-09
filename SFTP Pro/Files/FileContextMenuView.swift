import SwiftUI

struct FileContextMenuView: View {
    var parentOnly = false
    let action: (FileMenuAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(parentOnly ? [.open, .refresh] : FileMenuAction.allCases) { item in
                FileMenuButtonView(item: item) { action(item) }
            }
        }
        .padding(.vertical, 8)
        .frame(width: 300)
        .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08)) }
        .environment(\.colorScheme, .dark)
    }
}

import SwiftUI

struct FileTableHeaderView: View {
    let width: CGFloat
    let showsColumnDividers: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(["Name", "Date Modified", "Size", "Kind"].enumerated(), id: \.offset) { index, title in
                Text(title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .frame(width: width * [0.44, 0.24, 0.16, 0.16][index], height: 45)
                    .overlay(alignment: .trailing) {
                        if showsColumnDividers, index < 3 {
                            Rectangle().fill(WorkspaceTheme.raised).frame(width: 1)
                        }
                    }
            }
        }
    }
}

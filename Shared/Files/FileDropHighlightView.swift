import ScrechKit

struct FileDropHighlightView: View {
    let title: String
    let systemImage: String

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(WorkspaceTheme.accent.opacity(0.18))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(WorkspaceTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [8]))
            }
            .overlay {
                Label(title, systemImage: systemImage)
                    .title2()
                    .padding()
                    .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 12))
            }
            .padding(8)
            .allowsHitTesting(false)
    }
}

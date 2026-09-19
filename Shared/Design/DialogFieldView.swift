import ScrechKit

struct DialogFieldView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .callout()
                .foregroundStyle(WorkspaceTheme.muted)
                .padding(.horizontal, 6)
                .background(WorkspaceTheme.surface)
                .padding(.leading, 10)
                .offset(y: 8)
                .zIndex(1)

            content
                .textFieldStyle(.plain)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(WorkspaceTheme.muted.opacity(0.3))
                }
        }
    }
}

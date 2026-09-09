import ScrechKit

struct WorkspaceDialogView<Content: View>: View {
    let title: String
    let close: () -> Void
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .title2()
                
                Spacer()
                
                Button(action: close) {
                    Label("Close", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(30)
            .background(WorkspaceTheme.raised)
            
            VStack(alignment: .leading, spacing: 28) {
                content
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .title3()
        .foregroundStyle(WorkspaceTheme.text)
        .tint(WorkspaceTheme.accent)
        .background(WorkspaceTheme.surface)
        .clipShape(.rect(cornerRadius: 24))
        .presentationBackground(.clear)
        .presentationCornerRadius(24)
        .darkSchemePreferred()
        .frame(idealWidth: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}

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
        .presentationBackground {
            // Match the content edges in the sheet's outer insets
            VStack(spacing: 0) {
                WorkspaceTheme.raised
                WorkspaceTheme.surface
            }
        }
        .presentationCornerRadius(24)
        .presentationSizing(.fitted)
        .darkSchemePreferred()
        .frame(idealWidth: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}

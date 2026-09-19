import ScrechKit

struct WorkspaceDialogView<Content: View>: View {
    var desktopWidth: CGFloat = 460
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
            .zIndex(1)
            
            #if os(macOS)
            WorkspaceDialogContentView {
                content
            }
            #else
            ScrollView {
                WorkspaceDialogContentView {
                    content
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            #endif
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
        .darkSchemePreferred()
        #if os(macOS)
        .presentationSizing(.fitted)
        .frame(width: desktopWidth)
        .fixedSize(horizontal: false, vertical: true)
        #endif
    }
}

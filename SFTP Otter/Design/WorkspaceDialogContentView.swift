import SwiftUI

struct WorkspaceDialogContentView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            content
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

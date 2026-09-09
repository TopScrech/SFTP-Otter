#if os(macOS)
import SwiftUI

struct FileActionPresentationModifier: ViewModifier {
    @Environment(FileActionsModel.self) private var actions

    func body(content: Content) -> some View {
        @Bindable var actions = actions
        content
            .sheet(item: $actions.prompt) { action in
                FileActionPromptView(action: action).environment(actions)
            }
            .overlay(alignment: .bottom) {
                if actions.busy { ProgressView("Working…").padding().background(WorkspaceTheme.raised, in: .rect(cornerRadius: 10)) }
                if let error = actions.error {
                    VStack {
                        Text(error)
                        Button("Dismiss") { actions.error = nil }
                    }
                    .padding()
                    .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 10))
                }
            }
    }
}
#endif

import SwiftUI

struct BrowserActionsMenuView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SFTPSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var navigation = BrowserActionsNavigation()
    @FocusState private var keyboardFocused: Bool
    @Binding var showImporter: Bool
    let selectedIDs: Set<String>
    let pane: BrowserPane

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(["Upload files", "Download selected file", "Refresh", "Show hidden files", "Choose host", "Disconnect"], id: \.self) { title in
                BrowserActionsButtonView(title: title, destructive: title == "Disconnect", checked: title == "Show hidden files" && session.showHidden) {
                    perform(title)
                }
                .disabled(!isEnabled(title))
            }
        }
        .environment(navigation)
        .focusable()
        .focusEffectDisabled()
        .focused($keyboardFocused)
        .onAppear { keyboardFocused = true }
        .onKeyPress(phases: [.down, .repeat]) { press in
            navigation.items = ["Upload files", "Download selected file", "Refresh", "Show hidden files", "Choose host", "Disconnect"].filter { isEnabled($0) }
            switch press.key {
            case .downArrow: navigation.move(1)
            case .upArrow: navigation.move(-1)
            case .return:
                if let selected = navigation.selected, isEnabled(selected) { perform(selected) }
            case .escape: dismiss()
            default:
                guard press.modifiers.intersection([.command, .control, .option]).isEmpty,
                      !press.characters.isEmpty,
                      press.characters.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else { return .ignored }
                navigation.type(press.characters)
            }
            return .handled
        }
        .padding(8)
        .frame(width: 300)
        .background(WorkspaceTheme.raised, in: .rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.08)) }
        .environment(\.colorScheme, .dark)
        .presentationBackground(.clear)
        .presentationCornerRadius(14)
    }

    private func isEnabled(_ title: String) -> Bool {
        switch title {
        case "Upload files", "Refresh": session.isConnected && !session.isPreview
        case "Download selected file": !session.isPreview && session.files.contains { selectedIDs.contains($0.id) && !$0.isDirectory }
        default: true
        }
    }

    private func perform(_ title: String) {
        guard isEnabled(title) else { return }
        dismiss()
        switch title {
        case "Upload files": showImporter = true
        case "Download selected file":
            for file in session.files where selectedIDs.contains(file.id) && !file.isDirectory {
                workspace.download(file, from: session)
            }
        case "Refresh": workspace.refreshFiles()
        case "Show hidden files": session.showHidden.toggle()
        case "Choose host": workspace.chooseHost(for: pane)
        case "Disconnect": workspace.close(session)
        default: break
        }
    }

}

import SwiftUI

struct BrowserActionsListView: View {
    let titles: [String]
    let destructiveTitle: String
    let checkedTitle: String?
    let isEnabled: (String) -> Bool
    let perform: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var navigation = BrowserActionsNavigation()
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(titles, id: \.self) { title in
                BrowserActionsButtonView(title: title, destructive: title == destructiveTitle, checked: title == checkedTitle) {
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
            navigation.items = titles.filter { isEnabled($0) }
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
}

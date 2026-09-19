import ScrechKit

struct FileFilterView: View {
    @Environment(SFTPSession.self) private var session
    @FocusState private var focused: Bool
    
    var body: some View {
        @Bindable var session = session
        
        TextField("Search...", text: $session.search)
            .textFieldStyle(.plain)
            .focused($focused)
            .defaultFocus($focused, false)
            .accessibilityLabel("Search")
            .padding(.vertical, 4)
            .frame(minWidth: 80, idealWidth: 140, maxWidth: 180)
#if os(macOS)
            .background(FilterFocusDismissView())
#endif
    }
}

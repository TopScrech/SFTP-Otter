import Foundation

@Observable
final class BrowserActionsNavigation {
    var items: [String] = []
    var selected: String?
    private var prefix = ""
    private var lastTyped: TimeInterval = 0
    
    func move(_ offset: Int) {
        prefix = ""
        guard !items.isEmpty else { return }
        let index = selected.flatMap { items.firstIndex(of: $0) }
        selected = items[index.map { ($0 + offset + items.count) % items.count } ?? (offset > 0 ? 0 : items.count - 1)]
    }
    
    func type(_ text: String, at time: TimeInterval = Date.timeIntervalSinceReferenceDate) {
        guard !text.isEmpty else { return }
        if time - lastTyped > 1 { prefix = "" }
        lastTyped = time
        let repeated = prefix.count == 1 && prefix.localizedCaseInsensitiveCompare(text) == .orderedSame
        let candidate = repeated ? text : prefix + text
        let matches = items.filter { $0.range(of: candidate, options: [.anchored, .caseInsensitive, .diacriticInsensitive], locale: .current) != nil }
        if repeated, let selected, let index = matches.firstIndex(of: selected) {
            self.selected = matches[(index + 1) % matches.count]
            prefix = candidate
        } else if let match = matches.first {
            selected = match
            prefix = candidate
        } else if let match = items.first(where: { $0.range(of: text, options: [.anchored, .caseInsensitive, .diacriticInsensitive], locale: .current) != nil }) {
            selected = match
            prefix = text
        }
    }
}

import Foundation

struct FileSelection {
    var ids: Set<String> = []
    private var anchor: String?
    private(set) var cursor: String?

    mutating func click(_ id: String, in orderedIDs: [String], extending: Bool = false, toggling: Bool = false, contextMenu: Bool = false) {
        if extending, !contextMenu, ids.contains(id) {
            select(id, in: orderedIDs, toggling: true)
        } else {
            select(id, in: orderedIDs, extending: extending, toggling: toggling, contextMenu: contextMenu)
        }
    }

    mutating func move(_ offset: Int, in orderedIDs: [String], extending: Bool = false) {
        guard !orderedIDs.isEmpty else { return }
        let current = cursor.flatMap { orderedIDs.firstIndex(of: $0) }
        let index = current.map { min(max($0 + offset, 0), orderedIDs.count - 1) } ?? (offset > 0 ? 0 : orderedIDs.count - 1)
        select(orderedIDs[index], in: orderedIDs, extending: extending)
    }

    mutating func select(_ id: String, in orderedIDs: [String], extending: Bool = false, toggling: Bool = false, contextMenu: Bool = false) {
        cursor = id
        if contextMenu, ids.contains(id) { return }
        if extending, let anchor, let start = orderedIDs.firstIndex(of: anchor), let end = orderedIDs.firstIndex(of: id) {
            let range = Set(orderedIDs[min(start, end)...max(start, end)])
            ids = toggling ? ids.union(range) : range
        } else if toggling {
            if !ids.insert(id).inserted { ids.remove(id) }
            anchor = id
        } else {
            ids = [id]
            anchor = id
        }
    }
}

import Foundation

nonisolated struct FileSortOrder: Equatable, Sendable {
    var column: FileSortColumn = .name
    var ascending = true

    mutating func select(_ column: FileSortColumn) {
        if self.column == column {
            ascending.toggle()
        } else {
            self.column = column
            ascending = true
        }
    }

    func sorted(_ files: [RemoteFile]) -> [RemoteFile] {
        files.sorted { lhs, rhs in
            if (lhs.name == "..") != (rhs.name == "..") { return lhs.name == ".." }
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            let comparison: ComparisonResult
            switch column {
            case .name:
                comparison = lhs.name.localizedStandardCompare(rhs.name)
            case .modified:
                comparison = (lhs.modified ?? .distantPast).compare(rhs.modified ?? .distantPast)
            case .size:
                comparison = lhs.size == rhs.size ? .orderedSame : lhs.size < rhs.size ? .orderedAscending : .orderedDescending
            case .kind:
                let lhsKind = lhs.name.split(separator: ".").dropFirst().last.map(String.init) ?? "File"
                let rhsKind = rhs.name.split(separator: ".").dropFirst().last.map(String.init) ?? "File"
                comparison = lhsKind.localizedStandardCompare(rhsKind)
            }
            if comparison == .orderedSame {
                let names = lhs.name.localizedStandardCompare(rhs.name)
                if names == .orderedSame { return lhs.path < rhs.path }
                return names == .orderedAscending
            }
            return comparison == (ascending ? .orderedAscending : .orderedDescending)
        }
    }
}

import Foundation

nonisolated enum FileSortColumn: String, CaseIterable, Sendable {
    case name, modified, size, kind

    var title: String {
        switch self {
        case .name: "Name"
        case .modified: "Date Modified"
        case .size: "Size"
        case .kind: "Kind"
        }
    }

    static func visibleColumns(for width: Double) -> [Self] {
        width < 600 ? [.name, .modified, .size] : allCases
    }

    func widthFraction(for width: Double) -> Double {
        if width < 600 {
            return switch self {
            case .name: 0.5
            case .modified: 0.3
            case .size: 0.2
            case .kind: 0
            }
        }

        return switch self {
        case .name: 0.44
        case .modified: 0.24
        case .size, .kind: 0.16
        }
    }
}

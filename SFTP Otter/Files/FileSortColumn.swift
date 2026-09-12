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

    var widthFraction: Double {
        switch self {
        case .name: 0.44
        case .modified: 0.24
        case .size, .kind: 0.16
        }
    }
}

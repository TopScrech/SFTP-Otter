import Foundation

enum WorkspaceSection: String, CaseIterable, Identifiable {
    case files = "SFTP", transfers = "Transfers"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .files: "folder"
        case .transfers: "arrow.up.arrow.down"
        }
    }
}

import Foundation

nonisolated struct RemoteFile: Identifiable, Sendable {
    var path: String
    var name: String
    var isDirectory: Bool
    var size: UInt64
    var modified: Date?
    var permissions: String
    var mode: UInt32?
    var owner: String?
    var group: String?

    var id: String { path }
    var icon: String {
        if isDirectory { return "folder.fill" }
        switch name.split(separator: ".").last?.lowercased() {
        case "zip", "gz", "tar": return "doc.zipper"
        case "png", "jpg", "jpeg", "heic": return "photo"
        case "json", "yml", "yaml", "conf", "swift", "js": return "curlybraces"
        default: return "doc.text"
        }
    }
}

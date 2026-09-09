import Foundation

nonisolated struct Host: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var name = ""
    var address = ""
    var port = 22
    var username = ""
    var initialPath = "."
    var group = "Personal"
    var savedPassword: String?

    var displayName: String { name.isEmpty ? address : name }
    var endpoint: String { "\(username)@\(address):\(port)" }
}

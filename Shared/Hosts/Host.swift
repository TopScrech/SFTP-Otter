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

    var connectionAddress: String {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              ["http", "https", "ssh", "sftp"].contains(scheme),
              let hostname = components.host, !hostname.isEmpty,
              components.port == nil,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              components.path.isEmpty || components.path == "/" else {
            return trimmed
        }
        return hostname
    }
    
    var displayName: String {
        name.isEmpty ? address : name
    }
    
    var endpoint: String {
        "\(username)@\(address):\(port)"
    }
}

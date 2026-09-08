import Foundation

struct PermissionAccess: Identifiable {
    let id: Int
    let title: String
    var read: Bool
    var write: Bool
    var execute: Bool

    var bits: UInt32 { (read ? 4 : 0) | (write ? 2 : 0) | (execute ? 1 : 0) }

    static func groups(mode: UInt32) -> [Self] {
        ["Owner", "Groups", "Others"].enumerated().map { index, title in
            let bits = mode >> ((2 - index) * 3)
            return Self(id: index, title: title, read: bits & 4 != 0, write: bits & 2 != 0, execute: bits & 1 != 0)
        }
    }
}

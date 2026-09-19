import Foundation

struct HostKeyChallenge: Identifiable {
    let id: UUID
    let endpoint: String
    let fingerprint: String
}

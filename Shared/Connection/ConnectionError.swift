import Foundation

nonisolated enum ConnectionError: LocalizedError {
    case notConnected
    
    var errorDescription: String? {
        switch self {
        case .notConnected: "Connect to the server before transferring files"
        }
    }
}

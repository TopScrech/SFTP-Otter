import Foundation
import Security

nonisolated enum KeychainStoreError: LocalizedError {
    case status(OSStatus), invalidData, unavailable

    var errorDescription: String? {
        switch self {
        case .status(let status):
            "Unable to access saved hosts in Keychain (\(status)): \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown Keychain error")"
        case .invalidData:
            "Keychain returned invalid saved-host data"
        case .unavailable:
            "Saved hosts could not be loaded — restart the app after unlocking Keychain before making changes"
        }
    }
}

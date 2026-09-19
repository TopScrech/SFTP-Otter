import Foundation

nonisolated enum FileActionError: LocalizedError {
    case invalidName, invalidPermissions, symbolicLink
    
    var errorDescription: String? {
        switch self {
        case .invalidName: "Enter a file name without slashes, not . or .."
        case .invalidPermissions: "Enter three or four octal digits, for example 644 or 755"
        case .symbolicLink: "This operation cannot follow symbolic links or folders nested more than 64 levels"
        }
    }
}

import Foundation

nonisolated enum SFTPConnectionError: LocalizedError {
    case incompatibleAlgorithms, hostKeyChanged(String), invalidHostKey, hostKeyRejected, unexpectedEndOfFile, invalidFilename, remoteFileChanged

    var errorDescription: String? {
        switch self {
        case .incompatibleAlgorithms: "This client could not negotiate compatible SSH algorithms with the server — diagnostic details are available in the connection log"
        case .hostKeyChanged(let host): "The identity of \(host) has changed — the connection was refused"
        case .invalidHostKey: "The server supplied an invalid host key"
        case .hostKeyRejected: "The server identity was not trusted"
        case .unexpectedEndOfFile: "The file ended before all expected bytes were transferred"
        case .invalidFilename: "The server returned an invalid filename"
        case .remoteFileChanged: "The file changed while it was being transferred — please retry"
        }
    }
}

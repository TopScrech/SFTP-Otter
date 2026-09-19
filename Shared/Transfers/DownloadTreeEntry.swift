import Foundation

nonisolated struct DownloadTreeEntry: Sendable {
    let file: RemoteFile
    let destination: URL
}

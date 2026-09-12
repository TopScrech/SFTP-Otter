import Foundation

nonisolated struct FolderUploadFile: Sendable {
    let source: URL
    let destination: String
    let replacing: Bool
    let size: UInt64
}

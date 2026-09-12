import Foundation

@MainActor
final class FolderTransferProgress {
    private var completed: [String: UInt64] = [:]
    private let transfer: FileTransfer

    init(transfer: FileTransfer) { self.transfer = transfer }

    func update(path: String, bytes: UInt64) {
        completed[path] = bytes
        transfer.completedBytes = completed.values.reduce(0, +)
        transfer.status = "Uploading"
    }
}

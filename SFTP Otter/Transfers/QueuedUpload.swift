import Foundation

struct QueuedUpload {
    let url: URL
    let directory: String
    let session: SFTPSession
    let transfer: FileTransfer
}

#if os(macOS)
import Foundation

struct QuickLookCacheEntry {
    let file: RemoteFile
    let url: URL
    let transfers: [FileTransfer]
}
#endif

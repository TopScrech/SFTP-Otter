#if os(macOS)
import AppKit
import Testing

struct FileDragPromiseTests {
    @MainActor
    @Test func operationQueueCanBeRequestedFromBackgroundThread() async {
        let promise = FileDragPromise(
            file: RemoteFile(path: "/file.txt", name: "file.txt", isDirectory: false, size: 1, permissions: ""),
            download: { _, _ in },
            reportError: { _ in }
        )
        let isMainQueue = await Task.detached {
            // Exercise the Objective-C entry point used by file coordination
            let selector = NSSelectorFromString("operationQueueForFilePromiseProvider:")
            let queue = promise.perform(selector, with: nil)?.takeUnretainedValue() as? OperationQueue
            return queue === OperationQueue.main
        }.value
        #expect(isMainQueue)
    }
}
#endif

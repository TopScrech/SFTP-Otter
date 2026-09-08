import AppKit
import Testing

@MainActor
struct FileDragPromiseTests {
    @Test func promiseDownloadsOnlyWhenFulfilled() async throws {
        let transport = DragExportTransport()
        let file = RemoteFile(path: "/folder", name: "folder", isDirectory: true, size: 0, permissions: "drwxr-xr-x")
        let promise = FileDragPromise(file: file, transport: transport) { _ in Issue.record("Unexpected export failure") }
        let provider = promise.provider()
        #expect(provider.delegate === promise)
        #expect(provider.userInfo as? FileDragPromise === promise)
        #expect(promise.filePromiseProvider(provider, fileNameForType: provider.fileType) == "folder")
        #expect(await transport.downloads.isEmpty)
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: root) }
        let destination = root.appending(path: "folder")
        let error: (any Error)? = await withCheckedContinuation { continuation in
            promise.filePromiseProvider(provider, writePromiseTo: destination) { continuation.resume(returning: $0) }
        }
        #expect(error == nil)
        #expect(try String(contentsOf: destination.appending(path: "child.txt"), encoding: .utf8) == "fixture")
        #expect(await transport.downloads == ["/folder/child.txt"])
    }

    @Test func promiseReportsCollisionWithoutOverwriting() async throws {
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: root) }
        let destination = root.appending(path: "keep.txt")
        try Data("keep".utf8).write(to: destination)
        let transport = DragExportTransport()
        let file = RemoteFile(path: "/keep.txt", name: "keep.txt", isDirectory: false, size: 7, permissions: "-rw-r--r--")
        var reportedError: String?
        let promise = FileDragPromise(file: file, transport: transport) { reportedError = $0 }
        let error: (any Error)? = await withCheckedContinuation { continuation in
            promise.filePromiseProvider(promise.provider(), writePromiseTo: destination) { continuation.resume(returning: $0) }
        }
        #expect(error != nil)
        #expect(reportedError != nil)
        #expect(try String(contentsOf: destination, encoding: .utf8) == "keep")
        #expect(await transport.downloads.isEmpty)
    }
}

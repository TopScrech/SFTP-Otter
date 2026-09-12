import Foundation
import Testing

@MainActor
struct FolderUploadTests {
    @Test func recursiveUploadsPreserveEmptyFoldersAndAggregateParallelFiles() async throws {
        let source = try sourceFolder()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let transport = FolderUploadTransport()
        let queue = UploadQueue()
        let session = SFTPSession(host: Host(initialPath: "/uploads"), transport: transport)
        let transfer = FileTransfer(name: "source", isUpload: true)
        queue.enqueue(source, session: session, transfer: transfer)
        try await waitForFinish(transfer)
        #expect(transfer.state == .uploaded)
        #expect(transfer.state.failure == nil)
        #expect(transfer.totalBytes == 12)
        #expect(transfer.completedBytes == 12)
        #expect(await transport.hasDirectory("/uploads/source/nested/empty"))
        #expect(await transport.contents == ["/uploads/source/a.txt": Data("abcd".utf8), "/uploads/source/nested/b.txt": Data("efgh".utf8), "/uploads/source/nested/c.txt": Data("ijkl".utf8)])
        #expect(await transport.peak == min(3, TransferPreferences.parallelTransfers))
    }

    @Test(arguments: [UploadConflictChoice.skip, .duplicate])
    func folderConflictsPreserveExistingFiles(choice: UploadConflictChoice) async throws {
        let source = try sourceFolder()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let transport = FolderUploadTransport(existingFolder: true)
        let session = SFTPSession(host: Host(initialPath: "/uploads"), transport: transport)
        let transfer = FileTransfer(name: "source", isUpload: true)
        let queue = UploadQueue()
        queue.enqueue(source, session: session, transfer: transfer)
        for _ in 0..<400 where queue.conflict == nil && !transfer.state.isFinished { try await Task.sleep(for: .milliseconds(5)) }
        #expect(queue.conflict?.name == "source")
        queue.resolve(choice)
        queue.dialogDismissed()
        try await waitForFinish(transfer)
        let contents = await transport.contents
        #expect(contents["/uploads/source/existing.txt"] == Data("keep".utf8))
        if choice == .skip {
            #expect(transfer.state == .skipped)
            #expect(contents.count == 1)
        } else {
            #expect(transfer.state == .uploaded)
            #expect(contents.count == 4)
            #expect(contents["/uploads/source copy/nested/b.txt"] == Data("efgh".utf8))
            #expect(await transport.hasDirectory("/uploads/source copy/nested/empty"))
        }
    }

    @Test func cancellationStopsActiveFolderUploads() async throws {
        let source = try sourceFolder()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let transport = FolderUploadTransport(delay: .seconds(10))
        let session = SFTPSession(host: Host(initialPath: "/uploads"), transport: transport)
        let transfer = FileTransfer(name: "source", isUpload: true)
        let queue = UploadQueue()
        queue.enqueue(source, session: session, transfer: transfer)
        for _ in 0..<400 {
            if await transport.active > 0 { break }
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(await transport.active > 0)
        transfer.cancel()
        try await waitForFinish(transfer)
        #expect(transfer.state == .cancelled)
        #expect(transfer.state.failure == nil)
        #expect(await transport.active == 0)
        #expect(await transport.cancelled > 0)
        #expect(await transport.contents.isEmpty)
    }

    private func sourceFolder() throws -> URL {
        let source = URL.temporaryDirectory.appending(path: UUID().uuidString).appending(path: "source")
        try FileManager.default.createDirectory(at: source.appending(path: "nested/empty"), withIntermediateDirectories: true)
        try Data("abcd".utf8).write(to: source.appending(path: "a.txt"))
        try Data("efgh".utf8).write(to: source.appending(path: "nested/b.txt"))
        try Data("ijkl".utf8).write(to: source.appending(path: "nested/c.txt"))
        return source
    }

    private func waitForFinish(_ transfer: FileTransfer) async throws {
        for _ in 0..<600 where !transfer.state.isFinished { try await Task.sleep(for: .milliseconds(5)) }
        #expect(transfer.state.isFinished)
    }
}

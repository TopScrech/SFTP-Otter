import Foundation
import Testing

@MainActor
struct UploadQueueTests {
    @Test func uploadsRunInParallelAfterCheckingDestinations() async throws {
        let transport = UploadConflictTransport(delay: .milliseconds(50))
        let session = SFTPSession(host: Host(initialPath: "/uploads"), transport: transport)
        let queue = UploadQueue()
        let transfers = (1...3).map { FileTransfer(name: "file\($0)", isUpload: true) }
        for transfer in transfers {
            queue.enqueue(URL(filePath: "/" + transfer.name), session: session, transfer: transfer)
        }
        for _ in 0..<200 where transfers.contains(where: { !$0.finished }) {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(transfers.allSatisfy { $0.finished })
        #expect(await transport.peak == 3)
    }

    @Test func duplicateNamesPreserveExtensionsAndAvoidCollisions() {
        #expect(UploadQueue.duplicateName("photo.png", existing: ["photo.png", "photo copy.png"]) == "photo copy 2.png")
        #expect(UploadQueue.duplicateName("README", existing: ["README"]) == "README copy")
    }

    @Test(arguments: [UploadConflictChoice.stop, .skip, .replace, .duplicate])
    func conflictRequiresDecisionBeforeUploading(choice: UploadConflictChoice) async throws {
        let transport = UploadConflictTransport()
        let session = SFTPSession(host: Host(initialPath: "/uploads"), transport: transport)
        let queue = UploadQueue()
        let first = FileTransfer(name: "photo.png", isUpload: true)
        let next = FileTransfer(name: "next.png", isUpload: true)
        queue.enqueue(URL(filePath: "/photo.png"), session: session, transfer: first)
        queue.enqueue(URL(filePath: "/next.png"), session: session, transfer: next)
        for _ in 0..<200 where queue.conflict == nil { try await Task.sleep(for: .milliseconds(5)) }
        #expect(queue.conflict?.name == "photo.png")
        #expect(await transport.destinations.isEmpty)
        queue.resolve(choice)
        queue.dialogDismissed()
        for _ in 0..<200 where !next.finished { try await Task.sleep(for: .milliseconds(5)) }
        #expect(first.finished)
        #expect(next.finished)
        let paths = await transport.destinations
        switch choice {
        case .stop:
            #expect(paths.isEmpty)
            #expect(next.status == "Cancelled")
        case .skip:
            #expect(paths == ["/uploads/next.png"])
            #expect(first.status == "Skipped")
        case .replace:
            #expect(paths == ["/uploads/photo.png", "/uploads/next.png"])
            #expect(await transport.replacements == [true, false])
        case .duplicate:
            #expect(paths == ["/uploads/photo copy.png", "/uploads/next.png"])
            #expect(await transport.replacements == [false, false])
        }
    }
}

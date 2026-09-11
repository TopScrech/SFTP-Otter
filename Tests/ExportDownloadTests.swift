#if os(macOS)
import Foundation
import Testing

@MainActor
struct ExportDownloadTests {
    @Test(arguments: [false, true])
    func exportAppearsInTransfers(fails: Bool) async throws {
        var transfers: [FileTransfer] = []
        let exporter = DownloadExporter { transfers.insert($0, at: 0) }
        let file = RemoteFile(path: "/file.txt", name: "file.txt", isDirectory: false, size: 100, permissions: "")
        let destination = URL.temporaryDirectory.appending(path: UUID().uuidString)
        do {
            try await exporter.downloadExport(file, to: destination, using: ExportDownloadTransport(fails: fails))
            #expect(!fails)
        } catch { #expect(fails) }
        let transfer = try #require(transfers.first)
        #expect(transfer.finished)
        #expect(!transfer.isUpload)
        #expect(transfer.status == (fails ? "Failed" : "Downloaded"))
        #expect((transfer.failure != nil) == fails)
        if !fails {
            #expect(transfer.completedBytes == 100)
            #expect(transfer.localURL == destination)
        }
    }

    @Test func exportCanBeCancelledFromTransfers() async throws {
        var transfers: [FileTransfer] = []
        let exporter = DownloadExporter { transfers.insert($0, at: 0) }
        let file = RemoteFile(path: "/file.txt", name: "file.txt", isDirectory: false, size: 100, permissions: "")
        let task = Task {
            try await exporter.downloadExport(file, to: URL.temporaryDirectory.appending(path: UUID().uuidString), using: ExportDownloadTransport())
        }
        for _ in 0..<100 where transfers.isEmpty { await Task.yield() }
        let transfer = try #require(transfers.first)
        transfer.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(transfer.status == "Cancelled")
        #expect(transfer.finished)
    }
}
#endif

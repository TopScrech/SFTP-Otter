#if os(macOS)
import Foundation
import Testing

@MainActor
@Suite(.serialized)
struct ActionDownloadTests {
    @Test func materializedRemoteFileIsTracked() async throws {
        let model = FileActionsModel()
        model.transport = ActionDownloadTransport()
        var transfers: [FileTransfer] = []
        model.registerTransfer = { transfers.append($0) }
        let file = RemoteFile(path: "/one.txt", name: "one.txt", isDirectory: false, size: 7, permissions: "")
        let url = try await model.materialize(file)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        #expect(try String(contentsOf: url, encoding: .utf8) == "content")
        let transfer = try #require(transfers.first)
        #expect(transfers.count == 1)
        #expect(transfer.name == file.name)
        #expect(transfer.state.isFinished)
        #expect(transfer.state == .downloaded)
        #expect(transfer.completedBytes == 7)
        #expect(transfer.localURL == url)
    }

    @Test func permissionsApplyToEverySelectedFile() async {
        let model = FileActionsModel()
        let transport = ActionDownloadTransport()
        model.transport = transport
        model.selectedFiles = ["one", "two", "three"].map {
            RemoteFile(path: "/" + $0, name: $0, isDirectory: false, size: 0, permissions: "")
        }
        model.file = model.selectedFiles.first
        model.input = "640"
        model.run(.permissions)
        while model.busy { await Task.yield() }
        #expect(model.error == nil)
        #expect(await transport.permissionChanges == ["/one": 0o640, "/two": 0o640, "/three": 0o640])
    }

    @Test func recursiveDownloadsRunConcurrentlyAndTrackEveryFile() async throws {
        let destination = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: destination) }
        var transfers: [FileTransfer] = []
        let transport = ActionDownloadTransport()
        let exporter = DownloadExporter { transfers.append($0) }
        let folder = RemoteFile(path: "/folder", name: "folder", isDirectory: true, size: 0, permissions: "")
        try await exporter.downloadExport(folder, to: destination, using: transport)
        #expect(await transport.peakDownloads == min(3, TransferPreferences.parallelTransfers))
        #expect(await transport.activeDownloads == 0)
        #expect(Set(transfers.map(\.name)) == ["one.txt", "two.txt", "three.txt"])
        #expect(transfers.allSatisfy { $0.state.isFinished && $0.state == .downloaded && $0.completedBytes == 7 })
        #expect(try String(contentsOf: destination.appending(path: "nested/three.txt"), encoding: .utf8) == "content")
        #expect(try FileManager.default.contentsOfDirectory(atPath: destination.appending(path: "empty").path(percentEncoded: false)).isEmpty)
    }

    @Test func recursiveFailureCancelsAndDrainsSiblingDownloads() async throws {
        let destination = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: destination) }
        var transfers: [FileTransfer] = []
        let transport = ActionDownloadTransport(slow: true, failingPath: "/folder/one.txt")
        let exporter = DownloadExporter { transfers.append($0) }
        let folder = RemoteFile(path: "/folder", name: "folder", isDirectory: true, size: 0, permissions: "")
        await #expect(throws: CocoaError.self) {
            try await exporter.downloadExport(folder, to: destination, using: transport)
        }
        #expect(await transport.activeDownloads == 0)
        #expect(transfers.allSatisfy { $0.state.isFinished })
        #expect(transfers.contains { $0.state.failure != nil })
        if TransferPreferences.parallelTransfers > 1 {
            #expect(await transport.cancelledDownloads > 0)
            #expect(transfers.contains { $0.state == .cancelled })
        }
    }

    @Test func cancellingFolderDownloadWaitsForChildrenToStop() async throws {
        let destination = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: destination) }
        var transfers: [FileTransfer] = []
        let transport = ActionDownloadTransport(slow: true)
        let exporter = DownloadExporter { transfers.append($0) }
        let folder = RemoteFile(path: "/folder", name: "folder", isDirectory: true, size: 0, permissions: "")
        let task = Task { try await exporter.downloadExport(folder, to: destination, using: transport) }
        for _ in 0..<500 {
            if await transport.activeDownloads > 0 { break }
            try await Task.sleep(for: .milliseconds(1))
        }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await transport.activeDownloads == 0)
        #expect(await transport.cancelledDownloads > 0)
        #expect(!transfers.isEmpty)
        #expect(transfers.allSatisfy { $0.state.isFinished && $0.state == .cancelled })
    }

}
#endif

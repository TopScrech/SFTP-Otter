#if os(macOS)
import Foundation
import Testing

@MainActor
struct FilePreviewTests {
    @Test func localPreviewUsesWholeFileSelectionAndSkipsFolders() async throws {
        let model = FileActionsModel()
        let files = [file("first.png"), file("folder", directory: true), file("..", directory: true), file("second.pdf")]
        var transfers: [FileTransfer] = []
        model.registerTransfer = { transfers.append($0) }

        model.preview(files)
        await model.previewTask?.value

        #expect(model.previewURLs == [URL(filePath: "/first.png"), URL(filePath: "/second.pdf")])
        #expect(model.previewURL == model.previewURLs.first)
        #expect(transfers.isEmpty)
        #expect(!model.busy)

        model.preview(files)
        #expect(model.previewURL == nil)
        #expect(model.previewTask == nil)
    }

    @Test func remotePreviewRegistersEveryDownload() async throws {
        let model = FileActionsModel()
        var transfers: [FileTransfer] = []
        model.registerTransfer = { transfers.append($0) }

        model.preview([file("first.png"), file("second.pdf")], using: ExportDownloadTransport())
        await model.previewTask?.value
        defer { removePreviewDirectories(model.previewURLs) }

        #expect(model.error == nil)
        #expect(model.previewURLs.map(\.lastPathComponent) == ["first.png", "second.pdf"])
        #expect(model.previewURL == model.previewURLs.first)
        #expect(transfers.count == 2)
        #expect(transfers.allSatisfy { !$0.isUpload && $0.state.isFinished && $0.completedBytes == 100 })
        #expect(transfers.compactMap(\.localURL) == model.previewURLs)
    }

    @Test func cancelledPreviewNeverOpensQuickLook() async {
        let model = FileActionsModel()
        var transfers: [FileTransfer] = []
        model.registerTransfer = { [weak model] in
            transfers.append($0)
            // A second Space press cancels preview preparation even before the download starts
            model?.preview([])
        }

        model.preview([file("first.png"), file("second.pdf")], using: ExportDownloadTransport())
        await model.previewTask?.value

        #expect(transfers.count == 1)
        #expect(transfers.first?.state == .cancelled)
        #expect(transfers.first?.state.isFinished == true)
        #expect(model.previewURL == nil)
        #expect(model.previewURLs.isEmpty)
        #expect(model.error == nil)
        #expect(!model.busy)
        #expect(model.previewTask == nil)
    }

    @Test func cacheReusesUnchangedFilesAndRemovesExpiredCopies() async throws {
        let cache = QuickLookCache()
        let transport = ActionDownloadTransport()
        var transfers: [FileTransfer] = []
        var item = file("cached.txt")
        let first = try await cache.materialize(item, using: transport) { transfers.append($0) }
        let second = try await cache.materialize(item, using: transport) { transfers.append($0) }
        #expect(first == second)
        #expect(transfers.count == 1)
        item.size += 1
        let updated = try await cache.materialize(item, using: transport) { transfers.append($0) }
        #expect(updated != first)
        #expect(!(await LocalFileOperations.exists(at: first)))
        #expect(transfers.first?.localURL == nil)
        await cache.clear()
        #expect(!(await LocalFileOperations.exists(at: updated)))
        #expect(transfers.allSatisfy { $0.localURL == nil })
    }

    private func file(_ name: String, directory: Bool = false) -> RemoteFile {
        RemoteFile(path: "/" + name, name: name, isDirectory: directory, size: 100, permissions: "")
    }

    private func removePreviewDirectories(_ urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
    }
}
#endif

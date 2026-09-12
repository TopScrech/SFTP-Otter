import Foundation

@MainActor
final class DownloadExporter {
    private let register: (FileTransfer) -> Void

    init(register: @escaping (FileTransfer) -> Void) {
        self.register = register
    }
    func downloadExport(_ file: RemoteFile, to destination: URL, using transport: any SFTPTransport) async throws {
        try await DirectoryDownload().download(file, to: destination, using: transport) { file, target in
            try await self.downloadTracked(file, to: target, using: transport)
        }
    }

    private func downloadTracked(_ file: RemoteFile, to destination: URL, using transport: any SFTPTransport) async throws {
        let transfer = FileTransfer(name: file.name, isUpload: false)
        transfer.totalBytes = file.size
        register(transfer)
        var failure: (any Error)?
        let task = Task {
            defer {
                transfer.finished = true
                transfer.task = nil
            }
            do {
                try Task.checkCancellation()
                try await transport.download(remote: file.path, local: destination) { completed, total in
                    await MainActor.run {
                        if completed == 0 { transfer.started = Date() }
                        transfer.status = "Downloading"
                        transfer.completedBytes = completed
                        transfer.totalBytes = total
                    }
                }
                transfer.localURL = destination
                transfer.status = "Downloaded"
            } catch {
                failure = error
                let cancelled = Task.isCancelled || error is CancellationError
                transfer.status = cancelled ? "Cancelled" : "Failed"
                transfer.failure = cancelled ? nil : error.localizedDescription
            }
        }
        transfer.task = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        if let failure { throw failure }
    }
}

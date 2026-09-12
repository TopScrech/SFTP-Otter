import Testing

@MainActor
struct CombinedTransferProgressTests {
    @Test func combinesUploadsDownloadsAndQueuedFilesBySize() {
        let upload = FileTransfer(name: "upload", isUpload: true)
        upload.totalBytes = 100
        upload.completedBytes = 50
        let download = FileTransfer(name: "download", isUpload: false)
        download.totalBytes = 300
        download.completedBytes = 150
        let queued = FileTransfer(name: "queued", isUpload: true)
        queued.totalBytes = 100
        let progress = CombinedTransferProgress(transfers: [upload, download, queued])
        #expect(progress.activeCount == 3)
        #expect(progress.fraction == 0.4)
    }

    @Test func ignoresFinishedFailedAndCancelledTransfers() {
        let transfers = [TransferState.downloaded, .failed("Test failure"), .cancelled].map {
            let transfer = FileTransfer(name: $0.title, isUpload: false)
            transfer.updateState($0)
            transfer.totalBytes = 100
            transfer.completedBytes = 50
            return transfer
        }
        let progress = CombinedTransferProgress(transfers: transfers)
        #expect(progress.activeCount == 0)
        #expect(progress.fraction == 0)
    }

    @Test func handlesUnknownSizesAndClampsProgress() {
        let transfer = FileTransfer(name: "file", isUpload: false)
        #expect(CombinedTransferProgress(transfers: [transfer]).fraction == 0)
        transfer.totalBytes = 10
        transfer.completedBytes = 20
        #expect(CombinedTransferProgress(transfers: [transfer]).fraction == 1)
        #expect(CombinedTransferProgress(transfers: []).activeCount == 0)
    }
}

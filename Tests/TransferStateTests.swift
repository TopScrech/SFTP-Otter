import Foundation
import Testing

@MainActor
struct TransferStateTests {
    @Test func onlySuccessfulEmptyTransfersHaveCompleteProgress() {
        for state in [TransferState.uploaded, .downloaded, .skipped, .cancelled, .failed("Unavailable")] {
            let transfer = FileTransfer(name: "empty", isUpload: false)
            transfer.updateState(state)
            #expect(transfer.state.isFinished)
            #expect(transfer.progress == (state.isSuccessful ? 1 : 0))
        }
    }

    @Test func cancellingStaysActiveUntilTaskStops() async {
        let transfer = FileTransfer(name: "file", isUpload: true)
        transfer.task = Task { }
        transfer.updateState(.uploading)
        transfer.cancel()
        #expect(transfer.state == .cancelling)
        #expect(transfer.task?.isCancelled == true)
        #expect(CombinedTransferProgress(transfers: [transfer]).activeCount == 1)
        transfer.updateState(.uploading)
        #expect(transfer.state == .cancelling)
        await transfer.task?.value
        transfer.updateState(.cancelled)
        #expect(CombinedTransferProgress(transfers: [transfer]).activeCount == 0)
    }

    @Test func terminalStatesCannotBeOverwritten() {
        let transfer = FileTransfer(name: "file", isUpload: false)
        transfer.updateState(.failed("Connection lost"))
        transfer.cancel()
        transfer.updateState(.downloading)
        #expect(transfer.state == .failed("Connection lost"))
        #expect(transfer.state.failure == "Connection lost")
    }

    @Test func queuedCancellationIsImmediatelyFinished() {
        let transfer = FileTransfer(name: "queued", isUpload: true)
        transfer.cancel()
        #expect(transfer.state == .cancelled)
        transfer.updateState(.uploading)
        #expect(transfer.state == .cancelled)
    }
}

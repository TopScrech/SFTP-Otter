import Foundation

@MainActor
@Observable
final class FileTransfer: Identifiable {
    let id = UUID()
    let name: String
    let isUpload: Bool
    var completedBytes: UInt64 = 0
    var totalBytes: UInt64 = 0
    private(set) var state = TransferState.queued
    var localURL: URL?
    var started = Date()
    var task: Task<Void, Never>?
    
    init(name: String, isUpload: Bool) {
        self.name = name
        self.isUpload = isUpload
    }
    
    var progress: Double {
        totalBytes == 0 ? (state.isSuccessful ? 1 : 0) : min(1, Double(completedBytes) / Double(totalBytes))
    }
    
    var bytesPerSecond: Double {
        Double(completedBytes) / max(0.1, Date().timeIntervalSince(started))
    }
    
    func updateState(_ newState: TransferState) {
        guard !state.isFinished else { return }
        guard state != .cancelling || newState.isFinished else { return }
        state = newState
    }

    func cancel() {
        guard !state.isFinished, state != .cancelling else { return }
        state = task == nil ? .cancelled : .cancelling
        task?.cancel()
    }
}

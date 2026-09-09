import Foundation
import Observation

@Observable
final class FileTransfer: Identifiable {
    let id = UUID()
    let name: String
    let isUpload: Bool
    var completedBytes: UInt64 = 0
    var totalBytes: UInt64 = 0
    var status = "Queued"
    var finished = false
    var failure: String?
    var localURL: URL?
    var started = Date()
    var task: Task<Void, Never>?

    init(name: String, isUpload: Bool) {
        self.name = name
        self.isUpload = isUpload
    }

    var progress: Double {
        totalBytes == 0 ? (finished && failure == nil && status != "Cancelled" ? 1 : 0) : min(1, Double(completedBytes) / Double(totalBytes))
    }

    var bytesPerSecond: Double {
        Double(completedBytes) / max(0.1, Date().timeIntervalSince(started))
    }

    func cancel() {
        task?.cancel()
    }
}

import Foundation

struct CombinedTransferProgress: Equatable {
    let activeCount: Int
    let fraction: Double

    @MainActor
    init(transfers: [FileTransfer]) {
        let active = transfers.filter { !$0.finished }
        activeCount = active.count
        let total = active.reduce(0.0) { $0 + Double($1.totalBytes) }
        let completed = active.reduce(0.0) { $0 + Double(min($1.completedBytes, $1.totalBytes)) }
        fraction = total > 0 ? completed / total : 0
    }
}

import Foundation

nonisolated enum TransferPreferences {
    static let parallelTransfersKey = "parallelTransfers"
    static let requestsPerFileKey = "requestsPerFile"
    static let defaultParallelTransfers = 4
    static let defaultRequestsPerFile = 64

    static var parallelTransfers: Int {
        value(for: parallelTransfersKey, fallback: defaultParallelTransfers, range: 1...16)
    }

    static var requestsPerFile: Int {
        value(for: requestsPerFileKey, fallback: defaultRequestsPerFile, range: 1...128)
    }

    private static func value(for key: String, fallback: Int, range: ClosedRange<Int>) -> Int {
        guard let stored = UserDefaults.standard.object(forKey: key) as? Int else { return fallback }
        return min(range.upperBound, max(range.lowerBound, stored))
    }
}

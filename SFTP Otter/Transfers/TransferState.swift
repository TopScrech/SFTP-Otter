import Foundation

nonisolated enum TransferState: Equatable, Sendable {
    case queued, preparingFolder, waitingForDecision, uploading, downloading, downloadingFolder, cancelling
    case uploaded, downloaded, skipped, cancelled
    case failed(String)

    var title: String {
        switch self {
        case .queued: "Queued"
        case .preparingFolder: "Preparing folder"
        case .waitingForDecision: "Waiting for a decision"
        case .uploading: "Uploading"
        case .downloading: "Downloading"
        case .downloadingFolder: "Downloading folder"
        case .cancelling: "Cancelling"
        case .uploaded: "Uploaded"
        case .downloaded: "Downloaded"
        case .skipped: "Skipped"
        case .cancelled: "Cancelled"
        case .failed: "Failed"
        }
    }

    var isFinished: Bool {
        switch self {
        case .uploaded, .downloaded, .skipped, .cancelled, .failed: true
        case .queued, .preparingFolder, .waitingForDecision, .uploading, .downloading, .downloadingFolder, .cancelling: false
        }
    }

    var isSuccessful: Bool {
        self == .uploaded || self == .downloaded
    }

    var failure: String? {
        if case .failed(let message) = self { message } else { nil }
    }
}

import Foundation

actor TransferGate {
    static let shared = TransferGate()
    private let fixedLimit: Int?
    private var running = 0

    init(limit: Int? = nil) {
        fixedLimit = limit.map { max(1, $0) }
    }

    private var limit: Int { fixedLimit ?? TransferPreferences.parallelTransfers }
    private var waiters: [(id: UUID, continuation: CheckedContinuation<Void, any Error>)] = []
    
    func run(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        try await acquire()
        do {
            try Task.checkCancellation()
            try await operation()
            release()
        } catch {
            release()
            throw error
        }
    }
    
    private func acquire() async throws {
        try Task.checkCancellation()
        if running < limit {
            running += 1
            return
        }
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                if Task.isCancelled { continuation.resume(throwing: CancellationError()) }
                else { waiters.append((id, continuation)) }
            }
        } onCancel: {
            Task { await self.cancel(id) }
        }
    }
    
    private func release() {
        running -= 1
        while running < limit, !waiters.isEmpty {
            running += 1
            waiters.removeFirst().continuation.resume()
        }
    }
    
    private func cancel(_ id: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
        waiters.remove(at: index).continuation.resume(throwing: CancellationError())
    }
}

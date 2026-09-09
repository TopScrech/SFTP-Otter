import Foundation

actor TransferGate {
    private var running = 0
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
        if running < 3 {
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
        if waiters.isEmpty { running -= 1 }
        else { waiters.removeFirst().continuation.resume() }
    }
    
    private func cancel(_ id: UUID) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
        waiters.remove(at: index).continuation.resume(throwing: CancellationError())
    }
}

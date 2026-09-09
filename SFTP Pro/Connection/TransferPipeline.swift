import Foundation

nonisolated enum TransferPipeline {
    static let chunkSize = 32_000
    static let concurrentRequests = 64

    static func copy(total: UInt64, requestCount: Int = concurrentRequests,
                     read: @escaping @Sendable (UInt64, Int) async throws -> Data,
                     write: @escaping @Sendable (Data, UInt64) async throws -> Void,
                     progress: @escaping @Sendable (UInt64, UInt64) async -> Void) async throws {
        try Task.checkCancellation()
        await progress(0, total)
        try await withThrowingTaskGroup(of: UInt64.self) { group in
            var next: UInt64 = 0
            var completed: UInt64 = 0
            var lastUpdate = ContinuousClock.now
            func enqueue() {
                guard next < total else { return }
                let offset = next
                let length = Int(min(UInt64(chunkSize), total - next))
                next += UInt64(length)
                group.addTask {
                    try Task.checkCancellation()
                    let data = try await read(offset, length)
                    guard data.count == length else { throw SFTPConnectionError.unexpectedEndOfFile }
                    try Task.checkCancellation()
                    try await write(data, offset)
                    return UInt64(length)
                }
            }
            for _ in 0..<max(1, min(requestCount, 128)) { enqueue() }
            while let count = try await group.next() {
                try Task.checkCancellation()
                completed += count
                if completed == total || lastUpdate.duration(to: .now) >= .milliseconds(100) {
                    await progress(completed, total)
                    lastUpdate = .now
                }
                enqueue()
            }
        }
        try Task.checkCancellation()
    }
}

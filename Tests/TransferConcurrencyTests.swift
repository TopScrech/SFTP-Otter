import Foundation
import Testing

struct TransferConcurrencyTests {
    @Test(arguments: [1, 3, 6])
    func gateHonorsParallelLimit(limit: Int) async throws {
        let gate = TransferGate(limit: limit)
        let probe = TransferConcurrencyProbe()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<12 {
                group.addTask {
                    try await gate.run { try await probe.work() }
                }
            }
            try await group.waitForAll()
        }
        #expect(await probe.peak == limit)
    }

    @Test(arguments: [1, 4, 8])
    func pipelineHonorsRequestLimit(limit: Int) async throws {
        let probe = TransferConcurrencyProbe()
        try await TransferPipeline.copy(total: 640_000, requestCount: limit, read: { _, length in
            try await probe.work()
            return Data(count: length)
        }, write: { _, _ in }, progress: { _, _ in })
        #expect(await probe.peak == limit)
    }
}

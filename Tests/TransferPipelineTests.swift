import Foundation
import Testing

@MainActor
struct TransferPipelineTests {
    @Test
    func outOfOrderTransfersPreserveBytesAndShortFinalChunk() async throws {
        let source = Data((0..<250_017).map { UInt8($0 % 251) })
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "result")
        let destination = try TransferDiskFile(writing: url)
        try await TransferPipeline.copy(total: UInt64(source.count), read: { offset, length in
            try await Task.sleep(for: .milliseconds(offset == 0 ? 15 : 1))
            return source.subdata(in: Int(offset)..<(Int(offset) + length))
        }, write: { try await destination.write($0, offset: $1) }, progress: { _, _ in })
        try await destination.close()
        #expect(try Data(contentsOf: url) == source)
    }

    @Test
    func shortReadFailsInsteadOfReportingSuccess() async {
        await #expect(throws: SFTPConnectionError.self, "A truncated source must fail") {
            try await TransferPipeline.copy(total: 32_000, read: { _, _ in Data([1]) }, write: { _, _ in }, progress: { _, _ in })
        }
    }

    @Test
    func cancellationStopsTransfer() async {
        let task = Task {
            try await TransferPipeline.copy(total: 1_000_000, read: { _, length in
                try await Task.sleep(for: .seconds(1))
                return Data(count: length)
            }, write: { _, _ in }, progress: { _, _ in })
        }
        task.cancel()
        await #expect(throws: CancellationError.self, "Cancelled transfer must fail") {
            try await task.value
        }
    }

    @Test
    func pipeliningReducesLatencyCost() async throws {
        func measure(requests: Int) async throws -> Duration {
            let start = ContinuousClock.now
            try await TransferPipeline.copy(total: 640_000, requestCount: requests, read: { _, length in
                try await Task.sleep(for: .milliseconds(10))
                return Data(count: length)
            }, write: { _, _ in }, progress: { _, _ in })
            return start.duration(to: .now)
        }
        let serial = try await measure(requests: 1)
        let pipelined = try await measure(requests: 64)
        print("Synthetic 10 ms request latency: serial=\(serial), pipelined=\(pipelined)")
        #expect(pipelined < serial / 3)
    }
}

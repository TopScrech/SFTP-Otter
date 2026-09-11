import Foundation

actor TransferConcurrencyProbe {
    private var active = 0
    private(set) var peak = 0

    func work() async throws {
        active += 1
        peak = max(peak, active)
        defer { active -= 1 }
        try await Task.sleep(for: .milliseconds(20))
    }
}

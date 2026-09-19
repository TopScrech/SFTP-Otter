import Foundation
import NIOCore
import NIOSSH
import Synchronization

nonisolated final class ServerKeyValidator: NIOSSHClientServerAuthenticationDelegate, Sendable {
    private let state = Mutex<(cancelled: Bool, task: Task<Void, Never>?)>((false, nil))
    private let verify: @Sendable (String) async throws -> Void
    
    init(verify: @escaping @Sendable (String) async throws -> Void) {
        self.verify = verify
    }
    
    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        let key = String(openSSHPublicKey: hostKey)
        let task = Task {
            do {
                try Task.checkCancellation()
                try await verify(key)
                try Task.checkCancellation()
                validationCompletePromise.succeed(())
            } catch {
                validationCompletePromise.fail(error)
            }
        }
        state.withLock {
            if $0.cancelled { task.cancel() }
            else { $0.task = task }
        }
    }
    
    func cancel() {
        state.withLock {
            $0.cancelled = true
            $0.task?.cancel()
        }
    }
}

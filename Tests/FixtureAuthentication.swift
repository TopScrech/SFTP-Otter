import NIOCore
import NIOSSH

nonisolated final class FixtureAuthentication: NIOSSHServerUserAuthenticationDelegate, Sendable {
    let password: String
    var supportedAuthenticationMethods: NIOSSHAvailableUserAuthenticationMethods { .password }
    init(password: String) { self.password = password }
    
    func requestReceived(request: NIOSSHUserAuthenticationRequest, responsePromise: EventLoopPromise<NIOSSHUserAuthenticationOutcome>) {
        if request.username == "fixture", case .password(let value) = request.request, value.password == password {
            responsePromise.assumeIsolated().succeed(.success)
        } else { responsePromise.assumeIsolated().succeed(.failure) }
    }
}

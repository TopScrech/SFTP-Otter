import NIOCore
@preconcurrency import NIOSSH

final class FixtureAuthentication: NIOSSHServerUserAuthenticationDelegate {
    let password: String
    let supportedAuthenticationMethods: NIOSSHAvailableUserAuthenticationMethods = .password
    init(password: String) { self.password = password }

    func requestReceived(request: NIOSSHUserAuthenticationRequest, responsePromise: EventLoopPromise<NIOSSHUserAuthenticationOutcome>) {
        if request.username == "fixture", case .password(let value) = request.request, value.password == password {
            responsePromise.succeed(.success)
        } else { responsePromise.succeed(.failure) }
    }
}

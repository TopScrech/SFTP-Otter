import Foundation
import CryptoKit
import Testing
@preconcurrency import Citadel
import NIOSSH

@MainActor
struct SFTPIntegrationTests {
    @Test(arguments: [0, 1, 2])
    func encryptedUploadDownloadListingAndHostRejection(algorithmProfile: Int) async throws {
        let password = UUID().uuidString
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let key: NIOSSHPrivateKey
        if algorithmProfile == 2 {
            let keyURL = directory.appending(path: "fixture-key")
            let generator = Process()
            generator.executableURL = URL(filePath: "/usr/bin/ssh-keygen")
            generator.arguments = ["-q", "-t", "rsa", "-b", "2048", "-N", "", "-f", keyURL.path()]
            let exitStatus = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int32, any Error>) in
                generator.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
                do { try generator.run() }
                catch { continuation.resume(throwing: error) }
            }
            try #require(exitStatus == 0)
            key = NIOSSHPrivateKey(custom: try Insecure.RSA.PrivateKey(sshRsa: String(contentsOf: keyURL, encoding: .utf8)))
        } else {
            key = NIOSSHPrivateKey(p521Key: .init())
        }
        let expectedKey = String(openSSHPublicKey: key.publicKey)
        let port = Int.random(in: 30000...45000)
        var algorithms = SSHAlgorithms()
        if algorithmProfile != 0 {
            algorithms.transportProtectionSchemes = .replace(with: [AES128CTR.self])
        }
        if algorithmProfile == 2 {
            algorithms.publicKeyAlgorihtms = .add([(Insecure.RSA.PublicKey.self, Insecure.RSA.Signature.self)])
        }
        let server = try await SSHServer.host(host: "127.0.0.1", port: port, hostKeys: [key], algorithms: algorithms, authenticationDelegate: FixtureAuthentication(password: password))
        server.enableSFTP(withDelegate: FixtureFilesystem())
        let transport = CitadelSFTPTransport { key, _ in
            guard key == expectedKey else { throw SFTPConnectionError.hostKeyRejected }
        }
        let host = Host(name: "Fixture", address: "127.0.0.1", port: port, username: "fixture")
        do {
            await SSHNegotiationLogger.inspect(host: host.address, port: host.port, requestID: "fixture-negotiation")
            try await transport.connect(host: host, password: password)
            let bytes = Data((0..<2_000_017).map { UInt8($0 % 251) })
            let source = directory.appending(path: "source.bin")
            let downloaded = directory.appending(path: "downloaded.bin")
            try bytes.write(to: source)
            try await transport.upload(local: source, remote: "/roundtrip.bin", progress: { _, _ in })
            let listing = try await transport.list(path: ".")
            #expect(listing.path == "/")
            #expect(listing.files.map(\.name) == ["roundtrip.bin"])
            try await transport.download(remote: "/roundtrip.bin", local: downloaded, progress: { _, _ in })
            #expect(try Data(contentsOf: downloaded) == bytes)
            await #expect(throws: (any Error).self, "Existing remote files must not be overwritten") {
                try await transport.upload(local: source, remote: "/roundtrip.bin", progress: { _, _ in })
            }
            let afterCollision = try await transport.list(path: "/")
            #expect(afterCollision.files.map(\.name) == ["roundtrip.bin"])
            let empty = directory.appending(path: "empty.bin")
            try Data().write(to: empty)
            try await transport.upload(local: empty, remote: "/empty.bin", progress: { _, _ in })
            let emptyDownload = directory.appending(path: "empty-download.bin")
            try await transport.download(remote: "/empty.bin", local: emptyDownload, progress: { _, _ in })
            #expect(try Data(contentsOf: emptyDownload) == Data())
            let (events, continuation) = AsyncStream<Void>.makeStream()
            let cancelledURL = directory.appending(path: "cancelled.bin")
            let cancelled = Task {
                try await transport.download(remote: "/roundtrip.bin", local: cancelledURL) { _, _ in
                    continuation.yield(())
                }
            }
            var iterator = events.makeAsyncIterator()
            _ = await iterator.next()
            cancelled.cancel()
            await #expect(throws: (any Error).self, "Cancelled download must fail") {
                try await cancelled.value
            }
            #expect(!FileManager.default.fileExists(atPath: cancelledURL.path()))
            #expect(!FileManager.default.fileExists(atPath: cancelledURL.appendingPathExtension("part").path()))
            let stillConnected = try await transport.list(path: "/")
            #expect(stillConnected.files.count == 2)
            try await transport.createDirectory(path: "/new-folder")
            try await transport.setPermissions(path: "/empty.bin", mode: 0o600)
            let changed = try await transport.list(path: "/")
            #expect(changed.files.first { $0.name == "empty.bin" }?.permissions == "-rw-------")
            #expect(changed.files.first { $0.name == "new-folder" }?.isDirectory == true)
            await #expect(throws: (any Error).self) {
                try await transport.rename(path: "/empty.bin", to: "/roundtrip.bin")
            }
            try await transport.rename(path: "/empty.bin", to: "/renamed.bin")
            try await transport.remove(path: "/renamed.bin", isDirectory: false)
            try await transport.remove(path: "/new-folder", isDirectory: true)
            let remaining = try await transport.list(path: "/")
            #expect(remaining.files.map(\.name) == ["roundtrip.bin"])
            await transport.close()
            let rejected = CitadelSFTPTransport { _, _ in throw SFTPConnectionError.hostKeyRejected }
            await #expect(throws: (any Error).self, "Untrusted host keys must be rejected") {
                try await rejected.connect(host: host, password: password)
            }
            await rejected.close()
            try await server.close()
        } catch {
            await transport.close()
            try? await server.close()
            throw error
        }
    }
}

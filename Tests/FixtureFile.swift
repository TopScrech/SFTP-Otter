import Foundation
@preconcurrency import Citadel
import NIOCore

struct FixtureFile: SFTPFileHandle, Sendable {
    let path: String
    let filesystem: FixtureFilesystem
    
    func read(at offset: UInt64, length: UInt32) async throws -> ByteBuffer {
        let bytes = try await filesystem.contents(path)
        let lower = min(bytes.count, Int(offset))
        // Deliberately return short reads to exercise client reassembly
        let upper = min(bytes.count, lower + min(Int(length), 16_000))
        return ByteBuffer(bytes: bytes[lower..<upper])
    }
    func write(_ data: ByteBuffer, atOffset offset: UInt64) async throws -> SFTPStatusCode {
        try await filesystem.write(path, bytes: Data(data.readableBytesView), offset: Int(offset))
        return .ok
    }
    func close() async throws -> SFTPStatusCode { .ok }
    func readFileAttributes() async throws -> SFTPFileAttributes { try await filesystem.attributes(path) }
    func setFileAttributes(to attributes: SFTPFileAttributes) async throws {}
}

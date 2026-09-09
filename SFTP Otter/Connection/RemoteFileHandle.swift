import Foundation
@preconcurrency import Citadel
import NIOCore

actor RemoteFileHandle {
    private let file: SFTPFile
    
    init(file: sending SFTPFile) { self.file = file }
    
    func read(offset: UInt64, length: Int) async throws -> Data {
        var result = Data()
        while result.count < length {
            try Task.checkCancellation()
            let bytes = try await file.read(from: offset + UInt64(result.count), length: UInt32(length - result.count))
            guard bytes.readableBytes > 0 else { throw SFTPConnectionError.unexpectedEndOfFile }
            result.append(contentsOf: bytes.readableBytesView)
        }
        return result
    }
    
    func write(_ data: Data, offset: UInt64) async throws {
        try Task.checkCancellation()
        try await file.write(ByteBuffer(bytes: data), at: offset)
    }
    
    func attributes() async throws -> SFTPFileAttributes { try await file.readAttributes() }
    func close() async throws { try await file.close() }
}

import Foundation

actor TransferDiskFile {
    private let handle: FileHandle
    
    init(reading url: URL) throws {
        handle = try FileHandle(forReadingFrom: url)
    }
    
    init(writing url: URL) throws {
        guard FileManager.default.createFile(atPath: url.path(), contents: nil) else { throw CocoaError(.fileWriteUnknown) }
        handle = try FileHandle(forWritingTo: url)
    }
    
    func size() throws -> UInt64 { try handle.seekToEnd() }
    
    func read(offset: UInt64, length: Int) throws -> Data {
        try handle.seek(toOffset: offset)
        return try handle.read(upToCount: length) ?? Data()
    }
    
    func write(_ data: Data, offset: UInt64) throws {
        try handle.seek(toOffset: offset)
        try handle.write(contentsOf: data)
    }
    
    func close() throws { try handle.close() }
}

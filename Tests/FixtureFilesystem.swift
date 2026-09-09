import Foundation
@preconcurrency import Citadel

actor FixtureFilesystem: SFTPDelegate {
    private var directories: Set<String> = []
    private var modes: [String: UInt32] = [:]
    private var files: [String: Data] = [:]
    func contents(_ path: String) throws -> Data {
        guard let bytes = files[path] else { throw CocoaError(.fileNoSuchFile) }
        return bytes
    }
    func attributes(_ path: String) throws -> SFTPFileAttributes {
        var attributes = SFTPFileAttributes(size: directories.contains(path) ? 0 : UInt64(try contents(path).count))
        attributes.permissions = modes[path] ?? (directories.contains(path) ? 0o040755 : 0o100644)
        return attributes
    }
    func write(_ path: String, bytes: Data, offset: Int) throws {
        var data = try contents(path)
        if data.count < offset + bytes.count { data.append(Data(count: offset + bytes.count - data.count)) }
        data.replaceSubrange(offset..<(offset + bytes.count), with: bytes)
        files[path] = data
    }
    func entries() -> [SFTPPathComponent] {
        (Array(files.keys) + Array(directories)).sorted().map {
            SFTPPathComponent(filename: String($0.dropFirst()), longname: "", attributes: (try? attributes($0)) ?? .none)
        }
    }
    nonisolated func fileAttributes(atPath path: String, context: SSHContext) async throws -> SFTPFileAttributes { try await attributes(path) }
    nonisolated func openFile(_ filePath: String, withAttributes: SFTPFileAttributes, flags: SFTPOpenFileFlags, context: SSHContext) async throws -> SFTPFileHandle {
        try await open(filePath, flags: flags)
    }
    private func open(_ filePath: String, flags: SFTPOpenFileFlags) throws -> FixtureFile {
        if flags.contains(.create) {
            if flags.contains(.forceCreate), files[filePath] != nil { throw CocoaError(.fileWriteFileExists) }
            files[filePath] = Data()
        }
        _ = try contents(filePath)
        return FixtureFile(path: filePath, filesystem: self)
    }
    nonisolated func removeFile(_ filePath: String, context: SSHContext) async throws -> SFTPStatusCode {
        await remove(filePath)
        return .ok
    }
    private func remove(_ path: String) { files[path] = nil }
    nonisolated func createDirectory(_ filePath: String, withAttributes: SFTPFileAttributes, context: SSHContext) async throws -> SFTPStatusCode { await makeDirectory(filePath) }
    private func makeDirectory(_ path: String) -> SFTPStatusCode {
        guard files[path] == nil, !directories.contains(path) else { return .failure }
        directories.insert(path)
        return .ok
    }
    nonisolated func removeDirectory(_ filePath: String, context: SSHContext) async throws -> SFTPStatusCode { await removeDirectory(filePath) }
    private func removeDirectory(_ path: String) -> SFTPStatusCode {
        guard directories.remove(path) != nil else { return .failure }
        return .ok
    }
    nonisolated func realPath(for canonicalUrl: String, context: SSHContext) async throws -> [SFTPPathComponent] {
        [SFTPPathComponent(filename: canonicalUrl == "." ? "/" : canonicalUrl, longname: "", attributes: .none)]
    }
    nonisolated func openDirectory(atPath path: String, context: SSHContext) async throws -> SFTPDirectoryHandle { FixtureDirectory(filesystem: self) }
    nonisolated func setFileAttributes(to attributes: SFTPFileAttributes, atPath path: String, context: SSHContext) async throws -> SFTPStatusCode { await setMode(attributes.permissions, path: path) }
    private func setMode(_ mode: UInt32?, path: String) -> SFTPStatusCode {
        guard let mode, files[path] != nil || directories.contains(path) else { return .failure }
        modes[path] = mode | (directories.contains(path) ? 0o040000 : 0o100000)
        return .ok
    }
    nonisolated func addSymlink(linkPath: String, targetPath: String, context: SSHContext) async throws -> SFTPStatusCode { .failure }
    nonisolated func readSymlink(atPath path: String, context: SSHContext) async throws -> [SFTPPathComponent] { [] }
    nonisolated func rename(oldPath: String, newPath: String, flags: UInt32, context: SSHContext) async throws -> SFTPStatusCode {
        try await move(oldPath, to: newPath)
    }
    private func move(_ oldPath: String, to newPath: String) throws -> SFTPStatusCode {
        guard files[newPath] == nil else { return .failure }
        files[newPath] = try contents(oldPath)
        files[oldPath] = nil
        return .ok
    }
}

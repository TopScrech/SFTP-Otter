import Foundation

nonisolated enum LocalFileOperations {
    @concurrent static func list(directory: URL, root: URL?, showHidden: Bool) async throws -> [RemoteFile] {
        let access = root?.startAccessingSecurityScopedResource() == true
        defer { if access { root?.stopAccessingSecurityScopedResource() } }
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: Array(keys), options: showHidden ? [] : [.skipsHiddenFiles])
        var entries: [RemoteFile] = []
        for url in urls {
            try Task.checkCancellation()
            let values = try url.resourceValues(forKeys: keys)
            entries.append(RemoteFile(path: url.path(percentEncoded: false), name: url.lastPathComponent, isDirectory: values.isDirectory == true, size: UInt64(max(0, values.fileSize ?? 0)), modified: values.contentModificationDate, permissions: ""))
        }
        if directory.standardizedFileURL.pathComponents != root?.standardizedFileURL.pathComponents {
            entries.insert(RemoteFile(path: directory.deletingLastPathComponent().path(percentEncoded: false), name: "..", isDirectory: true, size: 0, permissions: ""), at: 0)
        }
        return entries
    }

    @concurrent static func copy(sources: [URL], to destination: URL, accessRoot: URL? = nil) async -> [String] {
        let rootAccess = accessRoot?.startAccessingSecurityScopedResource() == true
        let destinationAccess = destination.startAccessingSecurityScopedResource()
        defer {
            if rootAccess { accessRoot?.stopAccessingSecurityScopedResource() }
            if destinationAccess { destination.stopAccessingSecurityScopedResource() }
        }
        var failures: [String] = []
        for source in sources {
            if Task.isCancelled { break }
            do { try await copy(source: source, to: destination.appending(path: source.lastPathComponent)) }
            catch { failures.append("\(source.lastPathComponent): \(error.localizedDescription)") }
        }
        return failures
    }

    @concurrent static func copy(source: URL, to destination: URL) async throws {
        let access = source.startAccessingSecurityScopedResource()
        defer { if access { source.stopAccessingSecurityScopedResource() } }
        try Task.checkCancellation()
        try FileManager.default.copyItem(at: source, to: destination)
    }

    @concurrent static func move(from source: URL, to destination: URL) async throws {
        try FileManager.default.moveItem(at: source, to: destination)
    }

    @concurrent static func createDirectory(at url: URL, withIntermediateDirectories: Bool = false) async throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }

    @concurrent static func setPermissions(at url: URL, mode: UInt32) async throws {
        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: mode)], ofItemAtPath: url.path(percentEncoded: false))
    }

#if os(macOS)
    @concurrent static func trash(at url: URL) async throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }
#endif

    @concurrent static func exists(at url: URL) async -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    @concurrent static func remove(at url: URL) async throws {
        try FileManager.default.removeItem(at: url)
    }

    @concurrent static func metadata(at url: URL) async throws -> RemoteFile {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        return RemoteFile(path: url.path(percentEncoded: false), name: url.lastPathComponent, isDirectory: attributes[.type] as? FileAttributeType == .typeDirectory, size: (attributes[.size] as? NSNumber)?.uint64Value ?? 0, modified: attributes[.modificationDate] as? Date, permissions: "", mode: (attributes[.posixPermissions] as? NSNumber)?.uint32Value, owner: attributes[.ownerAccountName] as? String, group: attributes[.groupOwnerAccountName] as? String)
    }
}

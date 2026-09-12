import Foundation

nonisolated struct UploadSource: Sendable {
    let url: URL
    let isDirectory: Bool
    let size: UInt64

    @concurrent static func children(of directory: URL) async throws -> [UploadSource] {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: Array(keys)).map { url in
            try Task.checkCancellation()
            let values = try url.resourceValues(forKeys: keys)
            // Never traverse links outside the folder selected by the user
            guard values.isSymbolicLink != true else { throw CocoaError(.featureUnsupported) }
            return UploadSource(url: url, isDirectory: values.isDirectory == true, size: UInt64(max(0, values.fileSize ?? 0)))
        }.sorted { $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent) == .orderedAscending }
    }

    @concurrent static func isDirectory(_ url: URL) async throws -> Bool {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard values?.isSymbolicLink != true else { throw CocoaError(.featureUnsupported) }
        return values?.isDirectory == true
    }
}

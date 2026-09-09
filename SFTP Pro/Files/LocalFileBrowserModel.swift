import Foundation
import Observation

@Observable
final class LocalFileBrowserModel {
    private(set) var directory: URL?
    private var root: URL?
    private var hasAccess = false
    private(set) var files: [RemoteFile] = []
    private(set) var error: String?
    var selection: RemoteFile.ID?

    func open(_ url: URL) {
        close()
        hasAccess = url.startAccessingSecurityScopedResource()
        root = url
        navigate(to: url)
    }

    func navigate(to url: URL) {
        do {
            let keys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles])
            var entries = try urls.map { item in
                let values = try item.resourceValues(forKeys: keys)
                return RemoteFile(path: item.path(percentEncoded: false), name: item.lastPathComponent, isDirectory: values.isDirectory == true, size: UInt64(max(0, values.fileSize ?? 0)), modified: values.contentModificationDate, permissions: "")
            }.sorted {
                if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            if url.standardizedFileURL != root?.standardizedFileURL {
                entries.insert(RemoteFile(path: url.deletingLastPathComponent().path(percentEncoded: false), name: "..", isDirectory: true, size: 0, permissions: ""), at: 0)
            }
            directory = url
            files = entries
            selection = nil
            error = nil
        } catch {
            self.error = error.localizedDescription
            if directory == nil { directory = url }
        }
    }

    func close() {
        if hasAccess { root?.stopAccessingSecurityScopedResource() }
        hasAccess = false
        root = nil
        directory = nil
        files = []
        selection = nil
        error = nil
    }
}

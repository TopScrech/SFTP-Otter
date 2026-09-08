import Foundation
import Observation

@Observable
final class LocalFileBrowserModel {
    private(set) var directory: URL?
    private var root: URL?
    private var hasAccess = false
    private var persistenceKey: String?

    func restoreLocation(for pane: BrowserPane) {
        persistenceKey = pane == .primary ? "localFolder.primary" : "localFolder.secondary"
        #if os(macOS)
        guard UserDefaults.standard.bool(forKey: "reopenConnectedHosts"), let persistenceKey,
              let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        do {
            var stale = false
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], bookmarkDataIsStale: &stale)
            let path = UserDefaults.standard.string(forKey: persistenceKey + ".path")
            open(url)
            if let path {
                let current = URL(filePath: path).standardizedFileURL
                let rootPath = url.standardizedFileURL.path(percentEncoded: false)
                if current.path(percentEncoded: false).hasPrefix(rootPath.hasSuffix("/") ? rootPath : rootPath + "/") { navigate(to: current) }
            }
        } catch { self.error = error.localizedDescription }
        #endif
    }

    func rememberLocation() {
        guard let persistenceKey else { return }
        guard UserDefaults.standard.bool(forKey: "reopenConnectedHosts") else {
            UserDefaults.standard.removeObject(forKey: persistenceKey)
            return
        }
        #if os(macOS)
        guard let directory, let root else { return }
        do {
            let data = try root.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: persistenceKey)
            UserDefaults.standard.set(directory.path(percentEncoded: false), forKey: persistenceKey + ".path")
        } catch { self.error = error.localizedDescription }
        #endif
    }
    private(set) var files: [RemoteFile] = []
    private(set) var error: String?
    var selection = FileSelection()

    func open(_ url: URL) {
        close(forget: false)
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
            if url.standardizedFileURL.pathComponents != root?.standardizedFileURL.pathComponents {
                entries.insert(RemoteFile(path: url.deletingLastPathComponent().path(percentEncoded: false), name: "..", isDirectory: true, size: 0, permissions: ""), at: 0)
            }
            directory = url
            files = entries
            selection = FileSelection()
            error = nil
            rememberLocation()
        } catch {
            self.error = error.localizedDescription
            if directory == nil { directory = url }
        }
    }

    func refresh() {
        if let directory { navigate(to: directory) }
    }

    func close(forget: Bool = true) {
        if forget, let persistenceKey { UserDefaults.standard.removeObject(forKey: persistenceKey) }
        if hasAccess { root?.stopAccessingSecurityScopedResource() }
        hasAccess = false
        root = nil
        directory = nil
        files = []
        selection = FileSelection()
        error = nil
    }
}

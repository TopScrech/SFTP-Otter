#if os(macOS)
import Foundation

@MainActor
final class QuickLookCache {
    private static let directory = URL.temporaryDirectory.appending(path: "SFTP Otter Previews")
    private static let launchCleanup = Task {
        try? await LocalFileOperations.remove(at: directory)
    }

    static func prepareForLaunch() { _ = launchCleanup }

    private var transport: (any SFTPTransport)?
    private var entries: [String: QuickLookCacheEntry] = [:]
    private var cleanupTask: Task<Void, Never>?

    func begin() { cleanupTask?.cancel() }

    func materialize(_ file: RemoteFile, using transport: any SFTPTransport, register: @escaping (FileTransfer) -> Void) async throws -> URL {
        await Self.launchCleanup.value
        try Task.checkCancellation()
        if self.transport.map({ ObjectIdentifier($0) != ObjectIdentifier(transport) }) == true {
            await clear()
        }
        self.transport = transport
        if let entry = entries[file.path] {
            if entry.file.size == file.size, entry.file.modified == file.modified,
               await LocalFileOperations.exists(at: entry.url) {
                return entry.url
            }
            entries[file.path] = nil
            await remove(entry)
        }
        let root = Self.directory.appending(path: UUID().uuidString)
        try await LocalFileOperations.createDirectory(at: root, withIntermediateDirectories: true)
        let destination = root.appending(path: file.name)
        var transfers: [FileTransfer] = []
        do {
            try await DownloadExporter {
                transfers.append($0)
                register($0)
            }.downloadExport(file, to: destination, using: transport)
            try Task.checkCancellation()
            entries[file.path] = QuickLookCacheEntry(file: file, url: destination, transfers: transfers)
            return destination
        } catch {
            try? await LocalFileOperations.remove(at: root)
            for transfer in transfers { transfer.localURL = nil }
            throw error
        }
    }

    func retainOnly(_ paths: Set<String>) async {
        let obsolete = entries.filter { !paths.contains($0.key) }
        for (path, entry) in obsolete {
            entries[path] = nil
            await remove(entry)
        }
    }

    func scheduleCleanup() {
        cleanupTask?.cancel()
        cleanupTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) }
            catch { return }
            await self?.clear()
        }
    }

    func clear() async {
        let obsolete = entries.values
        entries = [:]
        transport = nil
        for entry in obsolete { await remove(entry) }
    }

    private func remove(_ entry: QuickLookCacheEntry) async {
        try? await LocalFileOperations.remove(at: entry.url.deletingLastPathComponent())
        for transfer in entry.transfers { transfer.localURL = nil }
    }
}
#endif

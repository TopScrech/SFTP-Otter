import Foundation

@MainActor
final class DirectoryDownload {
    func download(_ file: RemoteFile, to destination: URL, using transport: any SFTPTransport, depth: Int = 0, perform: (@MainActor @Sendable (RemoteFile, URL) async throws -> Void)? = nil) async throws {
        var entries: [DownloadTreeEntry] = []
        try await prepare(file, to: destination, using: transport, depth: depth, entries: &entries)
        try await withThrowingTaskGroup(of: Void.self) { group in
            var running = 0
            for entry in entries {
                if running >= TransferPreferences.parallelTransfers {
                    try await group.next()
                    running -= 1
                }
                try Task.checkCancellation()
                group.addTask {
                    if let perform {
                        try await perform(entry.file, entry.destination)
                    } else {
                        try await transport.download(remote: entry.file.path, local: entry.destination) { _, _ in }
                    }
                }
                running += 1
            }
            while try await group.next() != nil {}
        }
    }

    private func prepare(_ file: RemoteFile, to destination: URL, using transport: any SFTPTransport, depth: Int, entries: inout [DownloadTreeEntry]) async throws {
        try Task.checkCancellation()
        guard depth < 64, !file.permissions.hasPrefix("l") else { throw CocoaError(.featureUnsupported) }
        guard !(await LocalFileOperations.exists(at: destination)) else { throw CocoaError(.fileWriteFileExists) }
        if file.isDirectory {
            try await LocalFileOperations.createDirectory(at: destination)
            for child in try await transport.list(path: file.path).files {
                guard child.name != ".", child.name != ".." else { continue }
                guard !child.name.isEmpty, !child.name.contains("/"), !child.name.contains("\0") else {
                    throw CocoaError(.fileWriteInvalidFileName)
                }
                try await prepare(child, to: destination.appending(path: child.name), using: transport, depth: depth + 1, entries: &entries)
            }
        } else {
            entries.append(DownloadTreeEntry(file: file, destination: destination))
        }
    }
}

#if os(macOS)
import Foundation

extension FileActionsModel {
    func preview(_ files: [RemoteFile], using transport: (any SFTPTransport)? = nil) {
        if let previewTask {
            previewTask.cancel()
            return
        }
        if previewURL != nil {
            previewURL = nil
            return
        }
        guard !busy else { return }
        let files = files.filter { $0.name != ".." && !$0.isDirectory }
        guard !files.isEmpty else { return }
        previewCache.begin()
        self.transport = transport
        error = nil
        busy = true
        previewTask = Task {
            defer {
                busy = false
                previewTask = nil
            }
            do {
                await previewCache.retainOnly(Set(files.map(\.path)))
                var urls: [URL] = []
                for file in files {
                    try Task.checkCancellation()
                    if let transport {
                        urls.append(try await previewCache.materialize(file, using: transport, register: registerTransfer))
                    } else {
                        urls.append(URL(filePath: file.path))
                    }
                }
                try Task.checkCancellation()
                previewURLs = urls
                previewURL = urls.first
            } catch {
                await previewCache.clear()
                if !Task.isCancelled && !(error is CancellationError) {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
#endif

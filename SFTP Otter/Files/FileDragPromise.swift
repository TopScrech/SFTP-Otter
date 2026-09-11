#if os(macOS)
import AppKit
import UniformTypeIdentifiers

@MainActor
final class FileDragPromise: NSObject, NSFilePromiseProviderDelegate {
    private let file: RemoteFile
    private let download: (RemoteFile, URL) async throws -> Void
    private let reportError: (String) -> Void
    
    init(file: RemoteFile, download: @escaping (RemoteFile, URL) async throws -> Void, reportError: @escaping (String) -> Void) {
        self.file = file
        self.download = download
        self.reportError = reportError
        super.init()
    }
    
    func provider() -> NSFilePromiseProvider {
        let type = file.isDirectory ? UTType.folder : UTType(filenameExtension: URL(filePath: file.name).pathExtension) ?? .data
        let provider = NSFilePromiseProvider(fileType: type.identifier, delegate: self)
        provider.userInfo = self
        return provider
    }
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String { file.name }
    
    nonisolated func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue { .main }
    
    nonisolated func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping @Sendable (Error?) -> Void) {
        Task { @MainActor in
            let access = url.deletingLastPathComponent().startAccessingSecurityScopedResource()
            defer { if access { url.deletingLastPathComponent().stopAccessingSecurityScopedResource() } }
            do {
                try await download(file, url)
                completionHandler(nil)
            } catch {
                if !(error is CancellationError) {
                    reportError("Couldn’t export \(file.name): \(error.localizedDescription)")
                }
                completionHandler(error)
            }
        }
    }
}
#endif

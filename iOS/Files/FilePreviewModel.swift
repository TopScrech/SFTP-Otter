import Foundation
import UniformTypeIdentifiers

@Observable
final class FilePreviewModel {
    var url: URL?
    var error: String?
    private(set) var task: Task<Void, Never>?
    private var temporaryDirectory: URL?
    private var transfer: FileTransfer?
    var registerTransfer: (FileTransfer) -> Void = { _ in }

    func open(_ file: RemoteFile, using transport: (any SFTPTransport)? = nil) {
        guard !file.isDirectory,
              UTType(filenameExtension: URL(filePath: file.name).pathExtension)?.conforms(to: .image) == true,
              task == nil, url == nil else { return }
        error = nil
        guard let transport else {
            url = URL(filePath: file.path)
            return
        }

        task = Task {
            defer { task = nil }
            let root = URL.temporaryDirectory.appending(path: "SFTP Otter Image Preview-" + UUID().uuidString)
            do {
                try await LocalFileOperations.createDirectory(at: root, withIntermediateDirectories: true)
                let destination = root.appending(path: file.name)
                try await DownloadExporter {
                    self.transfer = $0
                    self.registerTransfer($0)
                }.downloadExport(file, to: destination, using: transport)
                try Task.checkCancellation()
                temporaryDirectory = root
                url = destination
            } catch {
                try? await LocalFileOperations.remove(at: root)
                transfer?.localURL = nil
                transfer = nil
                if !Task.isCancelled, !(error is CancellationError) {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func dismiss() {
        task?.cancel()
        url = nil
        guard let root = temporaryDirectory else { return }
        temporaryDirectory = nil
        transfer?.localURL = nil
        transfer = nil
        Task { try? await LocalFileOperations.remove(at: root) }
    }
}

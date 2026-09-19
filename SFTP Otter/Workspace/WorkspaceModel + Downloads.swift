#if os(macOS)
import Foundation

extension WorkspaceModel {
    func downloadExport(_ file: RemoteFile, to destination: URL, using transport: any SFTPTransport) async throws {
        let exporter = DownloadExporter { self.transfers.insert($0, at: 0) }
        try await exporter.downloadExport(file, to: destination, using: transport)
    }
}
#endif

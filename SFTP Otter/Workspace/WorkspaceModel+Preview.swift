#if DEBUG
import Foundation

extension WorkspaceModel {
    func loadLocalFilePreview() {
        do {
            let directory = URL.temporaryDirectory.appending(path: "SFTP Otter Preview/" + UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("Disposable local file for UI verification".utf8).write(to: directory.appending(path: "example.txt"))
            for name in ["second.txt", "third.txt", "fourth.txt"] {
                try Data("Disposable local file".utf8).write(to: directory.appending(path: name))
            }
            localPreviewURL = directory
        } catch { report(error) }
    }
    
    func loadVisualPreview() {
        let host = Host(name: "Backup server · Layout preview", address: "backup.example.com", username: "preview", initialPath: "/")
        let session = SFTPSession(host: host, transport: CitadelSFTPTransport { _, _ in throw CancellationError() })
        session.isPreview = true
        session.isConnected = true
        session.files = (1...10).map {
            RemoteFile(path: "/archive-\($0).tar.zst", name: "archive-\($0).tar.zst", isDirectory: false, size: UInt64($0) * 12_849_000_000, modified: Date(timeIntervalSince1970: 1_787_500_800 + Double($0 * 3600)), permissions: "-rw-r--r--")
        }
        activePane = .primary
        sessions.append(session)
        select(session)
    }
}
#endif

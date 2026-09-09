#if os(macOS)
import Foundation

extension FileActionsModel {
    func choose(_ action: FileMenuAction, file: RemoteFile, selectedIDs: Set<String>, session: SFTPSession) {
        guard !busy else { return }
        guard !session.isPreview, session.isConnected else {
            error = "Connect to a server to use file actions"
            return
        }
        self.file = file
        selectedFiles = session.browserFiles.filter { selectedIDs.contains($0.id) && $0.name != ".." }
        if action == .delete {
            guard let first = selectedFiles.first else { return }
            self.file = first
        }
        transport = session.transport
        directory = session.path
        refresh = { session.refresh() }
        navigate = { session.navigate(to: $0) }
        choose(action)
    }
    
    func choose(_ action: FileMenuAction, file: RemoteFile, selectedIDs: Set<String>, browser: LocalFileBrowserModel) {
        guard !busy else { return }
        
        self.file = file
        selectedFiles = browser.files.filter { selectedIDs.contains($0.id) && $0.name != ".." }
        if action == .delete {
            guard let first = selectedFiles.first else { return }
            self.file = first
        }
        transport = nil
        directory = browser.directory?.path(percentEncoded: false) ?? ""
        refresh = { if let directory = browser.directory { browser.navigate(to: directory) } }
        navigate = { browser.navigate(to: URL(filePath: $0)) }
        choose(action)
    }
}
#endif

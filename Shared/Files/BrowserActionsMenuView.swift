import SwiftUI

struct BrowserActionsMenuView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SFTPSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Binding var showImporter: Bool
    let selectedIDs: Set<String>
    let pane: BrowserPane

    var body: some View {
        BrowserActionsListView(
            titles: ["Upload files", "Download selected items", "Refresh", "Show hidden files", "Choose host", "Disconnect"],
            destructiveTitle: "Disconnect",
            checkedTitle: session.showHidden ? "Show hidden files" : nil,
            isEnabled: isEnabled,
            perform: perform
        )
    }

    private func isEnabled(_ title: String) -> Bool {
        switch title {
        case "Upload files", "Refresh": session.isConnected && !session.isPreview
        case "Download selected items": !session.isPreview && session.files.contains { selectedIDs.contains($0.id) }
        default: true
        }
    }

    private func perform(_ title: String) {
        guard isEnabled(title) else { return }
        dismiss()
        switch title {
        case "Upload files": showImporter = true
        case "Download selected items":
            for file in session.files where selectedIDs.contains(file.id) {
                workspace.download(file, from: session)
            }
        case "Refresh": workspace.refreshFiles()
        case "Show hidden files": session.showHidden.toggle()
        case "Choose host": workspace.chooseHost(for: pane)
        case "Disconnect": workspace.close(session)
        default: break
        }
    }

}

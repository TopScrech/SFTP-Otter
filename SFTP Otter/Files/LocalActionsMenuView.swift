import SwiftUI

struct LocalActionsMenuView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(LocalFileBrowserModel.self) private var browser
    @Environment(\.dismiss) private var dismiss
    @Binding var showFolderPicker: Bool
    @Binding var showImporter: Bool
    @Binding var showCopyDestination: Bool

    var body: some View {
        BrowserActionsListView(
            titles: ["Import files", "Copy selected items", "Refresh", "Show hidden files", "Choose folder", "Close"],
            destructiveTitle: "Close",
            checkedTitle: browser.showHidden ? "Show hidden files" : nil,
            isEnabled: { title in
                title == "Copy selected items" ? !browser.selectedURLs.isEmpty : browser.directory != nil
            }
        ) { title in
            dismiss()
            switch title {
            case "Import files": showImporter = true
            case "Copy selected items": showCopyDestination = true
            case "Refresh": workspace.refreshFiles()
            case "Show hidden files": browser.showHidden.toggle()
            case "Choose folder": showFolderPicker = true
            case "Close": browser.close()
            default: break
            }
        }
    }
}

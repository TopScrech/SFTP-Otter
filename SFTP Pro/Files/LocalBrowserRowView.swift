import SwiftUI

#if os(macOS)
import AppKit
#endif

struct LocalBrowserRowView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(LocalFileBrowserModel.self) private var browser
#if os(macOS)
    @Environment(FileActionsModel.self) private var actions
#endif
    let file: RemoteFile
    let width: CGFloat
    @Binding var keyboardNavigationActive: Bool
    
    var body: some View {
        Button {
            browser.selection.click(file.id, in: browser.files.map(\.id))
        } label: {
            DesktopFileRowView(file: file, width: width, isSelected: browser.selection.ids.contains(file.id))
                .contentShape(.rect)
        }
        .contentShape(.rect)
#if !os(macOS)
        .onTapGesture(count: 2) {
            if file.isDirectory { browser.navigate(to: URL(filePath: file.path)) }
        }
#endif
        
#if os(macOS)
        .overlay {
            FileMenuBridge(
                parentOnly: file.name == "..",
                keyboardFocused: browser.selection.cursor == file.id
                || (keyboardNavigationActive && browser.selection.cursor == nil && browser.files.first?.id == file.id),
                rowSelected: browser.selection.ids.contains(file.id),
                moveSelection: { browser.selection.move($0, in: browser.files.map(\.id), extending: $1) },
                openSelection: {
                    if let file = browser.files.first(where: {
                        $0.id == browser.selection.cursor && browser.selection.ids.contains($0.id) && $0.isDirectory
                    }) {
                        browser.navigate(to: URL(filePath: file.path))
                    }
                },
                goToParent: {
                    if let file = browser.files.first(where: { $0.name == ".." }) { browser.navigate(to: URL(filePath: file.path)) }
                },
                dragItems: {
                    let files = browser.files.filter {
                        (browser.selection.ids.contains(file.id) ? browser.selection.ids.contains($0.id) : $0.id == file.id)
                        && $0.name != ".."
                    }
                    return files.map { NSDraggingItem(pasteboardWriter: URL(filePath: $0.path) as NSURL) }
                },
                select: { shift, command, context in
                    keyboardNavigationActive = true
                    workspace.refreshFiles = browser.refresh
                    browser.selection.click(
                        file.id, in: browser.files.map(\.id), extending: shift, toggling: command, contextMenu: context)
                }
            ) { action in
                actions.choose(action, file: file, selectedIDs: browser.selection.ids, browser: browser)
            }
        }
#endif
    }
}

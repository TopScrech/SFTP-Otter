import SwiftUI

#if os(macOS)
import AppKit
#endif

struct RemoteBrowserRowView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SFTPSession.self) private var session
    @Binding var selection: FileSelection
#if os(macOS)
    @Environment(FileActionsModel.self) private var actions
#endif
    let file: RemoteFile
    let width: CGFloat
    @Binding var keyboardNavigationActive: Bool
    
    var body: some View {
        Button {
            selection.click(file.id, in: session.browserFiles.map(\.id))
        } label: {
            DesktopFileRowView(file: file, width: width, isSelected: selection.ids.contains(file.id))
                .contentShape(.rect)
        }
        .contentShape(.rect)
#if !os(macOS)
        .onTapGesture(count: 2) {
            if file.isDirectory { session.navigate(to: file.path) }
        }
#endif
        
#if os(macOS)
        .overlay {
            FileMenuBridge(
                parentOnly: file.name == "..",
                keyboardFocused: selection.cursor == file.id
                || (keyboardNavigationActive && selection.cursor == nil && session.browserFiles.first?.id == file.id),
                rowSelected: selection.ids.contains(file.id),
                moveSelection: { selection.move($0, in: session.browserFiles.map(\.id), extending: $1) },
                openSelection: {
                    if let file = session.browserFiles.first(where: {
                        $0.id == selection.cursor && selection.ids.contains($0.id) && $0.isDirectory
                    }) {
                        session.navigate(to: file.path)
                    }
                },
                goToParent: {
                    if let file = session.browserFiles.first(where: { $0.name == ".." }) { session.navigate(to: file.path) }
                },
                dragItems: {
                    guard session.isConnected, !session.isPreview else { return [] }
                    let files = session.browserFiles.filter {
                        (selection.ids.contains(file.id) ? selection.ids.contains($0.id) : $0.id == file.id) && $0.name != ".."
                    }
                    return files.map {
                        FileRowDragPreview.item(file: $0, width: width,
                            writer: FileDragPromise(file: $0, download: { file, destination in
                                try await workspace.downloadExport(file, to: destination, using: session.transport)
                            }, reportError: { actions.error = $0 }).provider())
                    }
                },
                select: { shift, command, context in
                    keyboardNavigationActive = true
                    selection.click(
                        file.id, in: session.browserFiles.map(\.id), extending: shift, toggling: command, contextMenu: context)
                }
            ) { action in
                actions.choose(action, file: file, selectedIDs: selection.ids, session: session)
            }
        }
#endif
    }
}

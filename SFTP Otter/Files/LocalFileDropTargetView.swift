#if os(macOS)
import AppKit

final class LocalFileDropTargetView: NSView {
    var targetChanged: (Bool) -> Void = { _ in }
    var destination: URL?
    var completed: (String?) -> Void = { _ in }

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) } + [.fileURL])
    }

    required init?(coder: NSCoder) { nil }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard NSApp.currentEvent?.type == .leftMouseDragged else { return nil }
        return super.hitTest(point)
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        targetChanged(destination != nil)
        return destination == nil ? [] : .copy
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation { draggingEntered(sender) }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) { targetChanged(false) }

    override func draggingEnded(_ sender: any NSDraggingInfo) { targetChanged(false) }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        targetChanged(false)
        guard let destination else { return false }
        let pasteboard = sender.draggingPasteboard
        let completion = completed
        if let receivers = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self]) as? [NSFilePromiseReceiver], !receivers.isEmpty {
            for receiver in receivers {
                receiver.receivePromisedFiles(atDestination: destination, options: [:], operationQueue: .main) { _, error in
                    let message = error?.localizedDescription
                    Task { @MainActor in completion(message) }
                }
            }
            return true
        }
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty else { return false }
        Task {
            for source in urls {
                let access = source.startAccessingSecurityScopedResource()
                do {
                    try FileManager.default.copyItem(at: source, to: destination.appending(path: source.lastPathComponent))
                    completion(nil)
                } catch { completion(error.localizedDescription) }
                if access { source.stopAccessingSecurityScopedResource() }
            }
        }
        return true
    }
}
#endif

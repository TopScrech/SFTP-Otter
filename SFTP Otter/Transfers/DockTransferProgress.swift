#if os(macOS)
import AppKit

final class DockTransferProgress {
    private var view: DockTransferProgressView?
    private var previous: CombinedTransferProgress?
    private var started = false

    func start(workspace: WorkspaceModel) {
        guard !started else { return }
        started = true
        observe(workspace: workspace)
    }

    private func observe(workspace: WorkspaceModel) {
        let progress = withObservationTracking {
            CombinedTransferProgress(transfers: workspace.transfers)
        } onChange: { [weak self, weak workspace] in
            Task { @MainActor in
                // Coalesce frequent chunk updates without redrawing the Dock for every request
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, let workspace else { return }
                self.observe(workspace: workspace)
            }
        }
        guard progress != previous else { return }
        previous = progress
        let tile = NSApplication.shared.dockTile
        if progress.activeCount == 0 {
            tile.contentView = nil
            view = nil
        } else {
            if view == nil {
                view = DockTransferProgressView(frame: NSRect(origin: .zero, size: tile.size))
                tile.contentView = view
            }
            view?.fraction = progress.fraction
        }
        tile.display()
    }
}
#endif

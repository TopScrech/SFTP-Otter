import Foundation

@MainActor
@Observable
final class UploadQueue {
    var conflict: UploadConflict?
    private var pending: [QueuedUpload] = []
    private var running = false
    private var decision: CheckedContinuation<UploadConflictChoice, Never>?
    private var choice = UploadConflictChoice.stop

    func enqueue(_ url: URL, session: SFTPSession, transfer: FileTransfer) {
        pending.append(QueuedUpload(url: url, directory: session.path, session: session, transfer: transfer))
        startNext()
    }

    func resolve(_ choice: UploadConflictChoice) {
        self.choice = choice
        conflict = nil
    }

    func dialogDismissed() {
        let continuation = decision
        decision = nil
        continuation?.resume(returning: choice)
    }

    private func ask(name: String) async -> UploadConflictChoice {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(returning: .stop)
                    return
                }
                choice = .stop
                decision = continuation
                conflict = UploadConflict(name: name)
            }
        } onCancel: {
            Task { @MainActor in
                self.resolve(.stop)
                self.dialogDismissed()
            }
        }
    }

    private func startNext() {
        guard !running, !pending.isEmpty else { return }
        running = true
        let item = pending.removeFirst()
        item.transfer.task = Task {
            await perform(item)
            item.transfer.finished = true
            item.transfer.task = nil
            running = false
            startNext()
        }
    }

    private func stopPending() {
        for item in pending {
            item.transfer.status = "Cancelled"
            item.transfer.finished = true
        }
        pending.removeAll()
    }

    static func duplicateName(_ name: String, existing: Set<String>) -> String {
        let url = URL(filePath: name)
        let ext = url.pathExtension
        let base = ext.isEmpty ? name : url.deletingPathExtension().lastPathComponent
        var number = 1
        while true {
            let suffix = number == 1 ? " copy" : " copy \(number)"
            let candidate = base + suffix + (ext.isEmpty ? "" : "." + ext)
            if !existing.contains(candidate) { return candidate }
            number += 1
        }
    }

    private func perform(_ item: QueuedUpload) async {
        let transfer = item.transfer
        let access = item.url.startAccessingSecurityScopedResource()
        defer { if access { item.url.stopAccessingSecurityScopedResource() } }
        do {
            if transfer.cancellationRequested {
                transfer.status = "Cancelled"
                return
            }
            try Task.checkCancellation()
            let listing = try await item.session.transport.list(path: item.directory)
            var name = item.url.lastPathComponent
            var replacing = false
            if let existing = listing.files.first(where: { $0.name == name }) {
                transfer.status = "Waiting for a decision"
                switch await ask(name: name) {
                case .stop:
                    stopPending()
                    transfer.status = "Cancelled"
                    return
                case .skip:
                    transfer.status = "Skipped"
                    return
                case .replace:
                    guard !existing.isDirectory else { throw CocoaError(.fileWriteFileExists) }
                    replacing = true
                case .duplicate:
                    let current = try await item.session.transport.list(path: item.directory)
                    name = Self.duplicateName(name, existing: Set(current.files.map(\.name)))
                }
            }
            try Task.checkCancellation()
            let destination = item.directory + (item.directory.hasSuffix("/") ? "" : "/") + name
            try await item.session.transport.upload(local: item.url, remote: destination, replacing: replacing) { completed, total in
                await MainActor.run {
                    if completed == 0 { transfer.started = Date() }
                    transfer.status = "Uploading"
                    transfer.completedBytes = completed
                    transfer.totalBytes = total
                }
            }
            transfer.status = "Uploaded"
            item.session.refresh()
        } catch {
            transfer.status = Task.isCancelled ? "Cancelled" : "Failed"
            transfer.failure = Task.isCancelled ? nil : error.localizedDescription
        }
    }
}

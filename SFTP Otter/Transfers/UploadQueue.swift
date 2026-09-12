import Foundation

@MainActor
@Observable
final class UploadQueue {
    var conflict: UploadConflict?
    private var pending: [QueuedUpload] = []
    private var running = false
    private var destinations: [String: (id: UUID, task: Task<Void, Never>)] = [:]
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
        let key = "\(item.session.host.id)/\(item.directory)/\(item.url.lastPathComponent)"
        let preceding = destinations[key]?.task
        let id = UUID()
        let task = Task {
            // Recheck collisions only after an earlier upload to this path finishes
            await preceding?.value
            await perform(item)
            item.transfer.task = nil
            if destinations[key]?.id == id { destinations[key] = nil }
        }
        item.transfer.task = task
        destinations[key] = (id, task)
    }

    private func stopPending() {
        for item in pending {
            item.transfer.updateState(.cancelled)
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
        var preparing = true
        defer {
            if preparing {
                running = false
                startNext()
            }
        }
        let access = item.url.startAccessingSecurityScopedResource()
        defer { if access { item.url.stopAccessingSecurityScopedResource() } }
        do {
            if transfer.state == .cancelled || transfer.state == .cancelling {
                transfer.updateState(.cancelled)
                return
            }
            try Task.checkCancellation()
            if try await UploadSource.isDirectory(item.url) {
                let uploaded = try await uploadFolder(item) {
                    preparing = false
                    running = false
                    startNext()
                }
                transfer.updateState(uploaded ? .uploaded : .skipped)
                item.session.refresh()
                return
            }
            let listing = try await item.session.transport.list(path: item.directory)
            var name = item.url.lastPathComponent
            var replacing = false
            if let existing = listing.files.first(where: { $0.name == name }) {
                transfer.updateState(.waitingForDecision)
                switch await ask(name: name) {
                case .stop:
                    stopPending()
                    transfer.updateState(.cancelled)
                    return
                case .skip:
                    transfer.updateState(.skipped)
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
            // Keep conflict decisions ordered while file data transfers in parallel
            preparing = false
            running = false
            startNext()
            try await item.session.transport.upload(local: item.url, remote: destination, replacing: replacing) { completed, total in
                await MainActor.run {
                    if completed == 0 { transfer.started = Date() }
                    transfer.updateState(.uploading)
                    transfer.completedBytes = completed
                    transfer.totalBytes = total
                }
            }
            transfer.updateState(.uploaded)
            item.session.refresh()
        } catch {
            let cancelled = Task.isCancelled || error is CancellationError
            transfer.updateState(cancelled ? .cancelled : .failed(error.localizedDescription))
        }
    }
    private func uploadFolder(_ item: QueuedUpload, startTransfers: () -> Void) async throws -> Bool {
        item.transfer.updateState(.preparingFolder)
        var plan: [FolderUploadFile] = []
        guard try await prepareFolder(source: item.url, parent: item.directory, transport: item.session.transport, plan: &plan) else { return false }
        try Task.checkCancellation()
        item.transfer.totalBytes = plan.reduce(0) { $0 + $1.size }
        item.transfer.started = Date()
        startTransfers()
        let progress = FolderTransferProgress(transfer: item.transfer)
        let transport = item.session.transport
        try await withThrowingTaskGroup(of: Void.self) { group in
            var running = 0
            for file in plan {
                if running >= TransferPreferences.parallelTransfers {
                    try await group.next()
                    running -= 1
                }
                try Task.checkCancellation()
                group.addTask {
                    try await transport.upload(local: file.source, remote: file.destination, replacing: file.replacing) { bytes, _ in
                        await progress.update(path: file.destination, bytes: bytes)
                    }
                }
                running += 1
            }
            while try await group.next() != nil {}
        }

        return true
    }

    private func prepareFolder(source: URL, parent: String, transport: any SFTPTransport, plan: inout [FolderUploadFile], depth: Int = 0) async throws -> Bool {
        try Task.checkCancellation()
        guard depth < 64 else { throw CocoaError(.featureUnsupported) }
        let listing = try await transport.list(path: parent)
        var name = source.lastPathComponent
        var exists = listing.files.first { $0.name == name }
        if exists != nil {
            switch await ask(name: name) {
            case .stop:
                stopPending()
                throw CancellationError()
            case .skip: return false
            case .duplicate:
                name = Self.duplicateName(name, existing: Set(listing.files.map(\.name)))
                exists = nil
            case .replace:
                // Merge directories, resolving each existing child separately
                guard exists?.isDirectory == true else { throw CocoaError(.fileWriteFileExists) }
            }
        }
        let directory = parent + (parent.hasSuffix("/") ? "" : "/") + name
        try Task.checkCancellation()
        if exists == nil { try await transport.createDirectory(path: directory) }
        var remoteFiles = try await transport.list(path: directory).files
        for child in try await UploadSource.children(of: source) {
            try Task.checkCancellation()
            if child.isDirectory {
                _ = try await prepareFolder(source: child.url, parent: directory, transport: transport, plan: &plan, depth: depth + 1)
                continue
            }
            var childName = child.url.lastPathComponent
            var replacing = false
            if let existing = remoteFiles.first(where: { $0.name == childName }) {
                switch await ask(name: childName) {
                case .stop:
                    stopPending()
                    throw CancellationError()
                case .skip: continue
                case .duplicate:
                    childName = Self.duplicateName(childName, existing: Set(remoteFiles.map(\.name)))
                case .replace:
                    guard !existing.isDirectory else { throw CocoaError(.fileWriteFileExists) }
                    replacing = true
                }
            }
            let path = directory + "/" + childName
            plan.append(FolderUploadFile(source: child.url, destination: path, replacing: replacing, size: child.size))
            remoteFiles.append(RemoteFile(path: path, name: childName, isDirectory: false, size: child.size, permissions: ""))
        }
        return true
    }

}

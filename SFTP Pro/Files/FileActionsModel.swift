#if os(macOS)
import AppKit
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class FileActionsModel {
    var file: RemoteFile?
    var selectedFiles: [RemoteFile] = []
    var permissionGroups = PermissionAccess.groups(mode: 0o644)
    var permissionOwner = "Unavailable"
    var permissionGroup = "Unavailable"

    var editedPermissionMode: UInt32 {
        let special = (UInt32(input, radix: 8) ?? 0) & 0o7000
        return permissionGroups.reduce(special) { $0 | ($1.bits << ((2 - $1.id) * 3)) }
    }

    var permissionsChanged: Bool { editedPermissionMode != UInt32(input, radix: 8) }

    func savePermissions() {
        guard permissionsChanged else { return }
        input = String(editedPermissionMode, radix: 8)
        run(.permissions)
    }

    var deletionTitle: String {
        selectedFiles.count > 1 ? "Delete \(selectedFiles.count) items?" : "Delete “\(file?.name ?? "")”?"
    }
    var transport: (any SFTPTransport)?
    var directory = ""
    var refresh: () -> Void = {}
    var navigate: (String) -> Void = { _ in }
    var prompt: FileMenuAction?
    var showDeleteConfirmation = false
    var input = ""
    var error: String?
    var busy = false

    func choose(_ action: FileMenuAction) {
        guard !busy, let file else { return }
        if action == .delete {
            guard file.name != "..", file.path != "/" else { return }
            showDeleteConfirmation = true
        } else if [.rename, .newFolder, .permissions].contains(action) {
            input = action == .rename ? file.name : action == .permissions ? Self.mode(from: file.permissions) : ""
            if action == .permissions, transport == nil,
               let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
               let mode = attributes[.posixPermissions] as? NSNumber {
                input = String(mode.uint32Value, radix: 8)
            }
            if action == .permissions {
                if let mode = file.mode { input = String(mode & 0o7777, radix: 8) }
                permissionOwner = file.owner ?? "Unavailable"
                permissionGroup = file.group ?? "Unavailable"
                if transport == nil, let attributes = try? FileManager.default.attributesOfItem(atPath: file.path) {
                    permissionOwner = attributes[.ownerAccountName] as? String ?? "Unavailable"
                    permissionGroup = attributes[.groupOwnerAccountName] as? String ?? "Unavailable"
                }
                permissionGroups = PermissionAccess.groups(mode: UInt32(input, radix: 8) ?? 0o644)
            }
            prompt = action
        } else {
            run(action)
        }
    }

    func run(_ action: FileMenuAction) {
        guard !busy, let file else { return }
        let targets = selectedFiles.isEmpty ? [file] : selectedFiles
        let input = self.input
        prompt = nil
        error = nil
        busy = true
        Task {
            defer { busy = false }
            do {
                switch action {
                case .refresh: refresh()
                case .open:
                    if file.isDirectory { navigate(file.path) }
                    else {
                        let url = try await materialize(file)
                        guard NSWorkspace.shared.open(url) else { throw CocoaError(.fileReadUnknown) }
                    }
                case .openWith:
                    let panel = NSOpenPanel()
                    panel.title = "Choose an application"
                    panel.directoryURL = URL(filePath: "/Applications")
                    panel.allowedContentTypes = [.application]
                    guard await panel.begin() == .OK, let application = panel.url else { return }
                    let url = try await materialize(file)
                    try await NSWorkspace.shared.open([url], withApplicationAt: application, configuration: .init())
                case .copy:
                    let panel = NSOpenPanel()
                    panel.title = "Copy to target directory"
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.canCreateDirectories = true
                    guard await panel.begin() == .OK, let target = panel.url else { return }
                    let access = target.startAccessingSecurityScopedResource()
                    defer { if access { target.stopAccessingSecurityScopedResource() } }
                    let destination = target.appending(path: file.name)
                    if let transport {
                        try await downloadTree(file, to: destination, using: transport)
                    } else {
                        try FileManager.default.copyItem(at: URL(filePath: file.path), to: destination)
                    }
                    refresh()
                case .rename:
                    let name = try Self.validName(input)
                    let target = Self.child(directory, name)
                    if let transport { try await transport.rename(path: file.path, to: target) }
                    else { try FileManager.default.moveItem(atPath: file.path, toPath: target) }
                    refresh()
                case .newFolder:
                    let name = try Self.validName(input)
                    let target = Self.child(directory, name)
                    if let transport { try await transport.createDirectory(path: target) }
                    else { try FileManager.default.createDirectory(atPath: target, withIntermediateDirectories: false) }
                    refresh()
                case .permissions:
                    guard (3...4).contains(input.count), input.allSatisfy({ "01234567".contains($0) }), let mode = UInt32(input, radix: 8), mode <= 0o7777 else {
                        throw FileActionError.invalidPermissions
                    }
                    if let transport { try await transport.setPermissions(path: file.path, mode: mode) }
                    else { try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: mode)], ofItemAtPath: file.path) }
                    refresh()
                case .delete:
                    for target in targets {
                        guard target.name != "..", target.path != "/" else { throw FileActionError.invalidName }
                        if let transport { try await removeTree(target, using: transport) }
                        else { try FileManager.default.trashItem(at: URL(filePath: target.path), resultingItemURL: nil) }
                    }
                    refresh()
                }
            } catch { self.error = error.localizedDescription }
        }
    }

    private func materialize(_ file: RemoteFile) async throws -> URL {
        guard let transport else { return URL(filePath: file.path) }
        let root = URL.temporaryDirectory.appending(path: "SFTP Pro Open/" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let destination = root.appending(path: file.name)
        try await downloadTree(file, to: destination, using: transport)
        return destination
    }

    private func downloadTree(_ file: RemoteFile, to target: URL, using transport: any SFTPTransport, depth: Int = 0) async throws {
        guard depth < 64, !file.permissions.hasPrefix("l") else { throw FileActionError.symbolicLink }
        guard !FileManager.default.fileExists(atPath: target.path(percentEncoded: false)) else { throw CocoaError(.fileWriteFileExists) }
        if file.isDirectory {
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
            for child in try await transport.list(path: file.path).files {
                guard child.name != ".", child.name != ".." else { continue }
                let name = try Self.validName(child.name)
                try await downloadTree(child, to: target.appending(path: name), using: transport, depth: depth + 1)
            }
        } else {
            try await transport.download(remote: file.path, local: target) { _, _ in }
        }
    }

    private func removeTree(_ file: RemoteFile, using transport: any SFTPTransport, depth: Int = 0) async throws {
        guard depth < 64 else { throw FileActionError.symbolicLink }
        let directory = file.isDirectory && !file.permissions.hasPrefix("l")
        if directory {
            for child in try await transport.list(path: file.path).files {
                guard child.name != ".", child.name != ".." else { continue }
                _ = try Self.validName(child.name)
                try await removeTree(child, using: transport, depth: depth + 1)
            }
        }
        try await transport.remove(path: file.path, isDirectory: directory)
    }

    static func validName(_ name: String) throws -> String {
        guard !name.isEmpty, name != ".", name != "..", !name.contains("/"), !name.contains("\0") else { throw FileActionError.invalidName }
        return name
    }

    static func child(_ parent: String, _ name: String) -> String { parent == "/" ? "/" + name : parent + "/" + name }

    static func mode(from permissions: String) -> String {
        let characters = Array(permissions)
        guard characters.count == 10 else { return "644" }
        var value = 0
        for index in 1...9 where characters[index] != "-" { value |= 1 << (9 - index) }
        return String(value, radix: 8)
    }
}
#endif

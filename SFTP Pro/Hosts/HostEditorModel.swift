import Foundation

@Observable
final class HostEditorModel {
    var host = Host()
    var savePassword = false
    var password = ""
    var port = "22"

    var canSave: Bool {
        !host.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !host.username.isEmpty
            && (1...65535).contains(Int(port) ?? 0)
    }

    func load(_ editingHost: Host?) {
        guard let editingHost else { return }
        host = editingHost
        port = String(editingHost.port)
        savePassword = editingHost.savedPassword != nil
        password = editingHost.savedPassword ?? ""
    }

    func save(to workspace: WorkspaceModel) -> Bool {
        guard canSave else { return false }
        host.port = Int(port) ?? 22
        host.savedPassword = savePassword ? password : nil
        return workspace.save(host)
    }
}

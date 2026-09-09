import Foundation

@Observable
final class SettingsModel {
    var keys: [String: String] = [:]
    var pendingRemoval: String?
    var showConfirmation = false
    var showTrustedHostsHelp = false
    var errorMessage: String?
    
    func load(from store: HostKeyTrustStore) {
        do {
            keys = try store.load()
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
    
    func requestRemoval(of endpoint: String) {
        pendingRemoval = endpoint
        showConfirmation = true
    }
    
    func forget(in store: HostKeyTrustStore) {
        guard let endpoint = pendingRemoval else { return }
        do {
            try store.forget(endpoint: endpoint)
            load(from: store)
            pendingRemoval = nil
        } catch { errorMessage = error.localizedDescription }
    }
}

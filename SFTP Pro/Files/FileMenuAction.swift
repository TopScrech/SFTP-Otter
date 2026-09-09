import Foundation

nonisolated enum FileMenuAction: String, CaseIterable, Identifiable {
    case open = "Open", openWith = "Open with…", copy = "Copy to target directory", rename = "Rename", refresh = "Refresh", newFolder = "New Folder", permissions = "Edit Permissions", delete = "Delete"
    var id: Self { self }
}

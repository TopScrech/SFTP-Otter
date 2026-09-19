import ScrechKit

struct UploadConflictView: View {
    @Environment(UploadQueue.self) private var uploads
    let name: String
    
    var body: some View {
        WorkspaceDialogView(desktopWidth: 660, title: "File already exists", close: { uploads.resolve(.stop) }) {
            Text("An item named \"\(name)\" already exists in this location\nDo you want to replace it with the one you’re uploading?")
                .fixedSize(horizontal: false, vertical: true)
            
            ViewThatFits(in: .horizontal) {
                UploadConflictActionsView()

                UploadConflictActionsView(vertical: true)
            }
        }
        .interactiveDismissDisabled()
    }
}

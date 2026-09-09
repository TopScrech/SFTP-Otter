import ScrechKit

struct UploadConflictView: View {
    @Environment(UploadQueue.self) private var uploads
    let name: String

    var body: some View {
        WorkspaceDialogView(title: "File already exists", close: { uploads.resolve(.stop) }) {
            Text("An item named \"\(name)\" already exists in this location\nDo you want to replace it with the one you’re uploading?")
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Stop", role: .destructive) { uploads.resolve(.stop) }
                    .buttonStyle(DialogActionStyle(destructive: true))

                Spacer()

                Button("Skip") { uploads.resolve(.skip) }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                Button("Replace") { uploads.resolve(.replace) }
                    .buttonStyle(DialogActionStyle(neutral: true))

                Button("Duplicate") { uploads.resolve(.duplicate) }
                    .buttonStyle(DialogActionStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 660)
        .interactiveDismissDisabled()
    }
}

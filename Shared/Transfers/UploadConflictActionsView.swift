import ScrechKit

struct UploadConflictActionsView: View {
    @Environment(UploadQueue.self) private var uploads
    var vertical = false

    var body: some View {
        let layout = vertical ? AnyLayout(VStackLayout()) : AnyLayout(HStackLayout())

        layout {
            Button("Stop", role: .destructive) {
                uploads.resolve(.stop)
            }
            .buttonStyle(DialogActionStyle(destructive: true))
            
            if !vertical {
                Spacer()
            }
            
            Button("Skip") {
                uploads.resolve(.skip)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            
            Button("Replace") {
                uploads.resolve(.replace)
            }
            .buttonStyle(DialogActionStyle(neutral: true))
            
            Button("Duplicate") {
                uploads.resolve(.duplicate)
            }
            .buttonStyle(DialogActionStyle())
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity)
    }
}

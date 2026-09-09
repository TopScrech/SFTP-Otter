import ScrechKit

struct FileRowView: View {
    @Environment(WorkspaceModel.self) private var workspace
    @Environment(SFTPSession.self) private var session
    let file: RemoteFile
    
    var body: some View {
        HStack {
            Button {
                if file.isDirectory { session.navigate(to: file.path) }
                else { workspace.download(file, from: session) }
            } label: {
                HStack {
                    Image(systemName: file.icon)
                        .title2()
                        .foregroundStyle(file.isDirectory ? Color(red: 0.72, green: 0.76, blue: 0.79) : WorkspaceTheme.muted)
                        .frame(width: 32)
                    VStack(alignment: .leading) {
                        Text(file.name).lineLimit(1)
                        Text(file.permissions)
                            .caption(design: .monospaced)
                            .foregroundStyle(WorkspaceTheme.muted)
                    }
                    Spacer()
                    if !file.isDirectory {
                        Text(Int64(clamping: file.size), format: .byteCount(style: .file))
                            .caption()
                            .foregroundStyle(WorkspaceTheme.muted)
                    }
                    if let date = file.modified {
                        Text(date, format: .dateTime.month(.abbreviated).day().year())
                            .caption()
                            .foregroundStyle(WorkspaceTheme.muted)
                    }
                }
                .padding(.vertical)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if !file.isDirectory {
                Button("Download", systemImage: "arrow.down.to.line") {
                    workspace.download(file, from: session)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            }
        }
    }
}

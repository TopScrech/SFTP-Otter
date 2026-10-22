import ScrechKit

struct FileRowView: View {
    let file: RemoteFile
    let width: CGFloat
    let isSelected: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                    .title2()
                    .foregroundStyle(file.isDirectory ? .cyan : .white)
                VStack(alignment: .leading, spacing: 0) {
                    Text(file.name).foregroundStyle(.white)
                    if !file.permissions.isEmpty {
                        Text(file.permissions).caption()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .frame(width: width * FileSortColumn.name.widthFraction(for: width), alignment: .leading)
            Group {
                if let date = file.modified {
                    Text(date.formatted(date: .numeric, time: .shortened))
                        .help(date.formatted(date: .complete, time: .standard))
                } else { Text("") }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .frame(width: width * FileSortColumn.modified.widthFraction(for: width))
            Group {
                if !file.isDirectory {
                    Text(Int64(clamping: file.size), format: .byteCount(style: .binary))
                } else { Text("") }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .frame(width: width * FileSortColumn.size.widthFraction(for: width))
            if FileSortColumn.visibleColumns(for: width).contains(.kind) {
                Text(file.name == ".." ? "" : file.isDirectory ? "Folder" : (file.name.split(separator: ".").dropFirst().last.map(String.init) ?? "File"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .frame(width: width * FileSortColumn.kind.widthFraction(for: width))
            }
        }
        .lineLimit(1)
        .frame(minHeight: 40)
        .foregroundStyle(isSelected ? .white : WorkspaceTheme.muted)
        .background(isSelected ? WorkspaceTheme.accent : (isHovered ? WorkspaceTheme.raised : .clear))
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

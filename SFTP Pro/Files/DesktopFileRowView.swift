import SwiftUI

struct DesktopFileRowView: View {
    let file: RemoteFile
    let width: CGFloat
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                    .font(.title2)
                    .foregroundStyle(file.isDirectory ? .cyan : .white)
                VStack(alignment: .leading, spacing: 0) {
                    Text(file.name).foregroundStyle(.white)
                    if !file.permissions.isEmpty {
                        Text(file.permissions).font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .frame(width: width * 0.44, alignment: .leading)
            Group {
                if let date = file.modified {
                    Text(date.formatted(date: .numeric, time: .shortened))
                        .help(date.formatted(date: .complete, time: .standard))
                } else { Text("") }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .frame(width: width * 0.24)
            Group {
                if !file.isDirectory {
                    Text(Int64(clamping: file.size), format: .byteCount(style: .binary))
                } else { Text("") }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .frame(width: width * 0.16)
            Text(file.name == ".." ? "" : file.isDirectory ? "Folder" : (file.name.split(separator: ".").dropFirst().last.map(String.init) ?? "File"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .frame(width: width * 0.16)
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

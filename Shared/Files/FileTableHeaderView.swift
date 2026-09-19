import ScrechKit

struct FileTableHeaderView: View {
    let width: CGFloat
    let showsColumnDividers: Bool
    let sortOrder: FileSortOrder
    let onSort: (FileSortColumn) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FileSortColumn.allCases, id: \.self) { column in
                Button {
                    onSort(column)
                } label: {
                    HStack {
                        Text(column.title)
                            .bold()

                        if sortOrder.column == column {
                            Image(systemName: sortOrder.ascending ? "chevron.up" : "chevron.down")
                                .caption()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .frame(width: width * column.widthFraction, height: 45)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityValue(sortOrder.column == column ? (sortOrder.ascending ? "Ascending" : "Descending") : "Not sorted")
                .help("Sort by " + column.title)
                .overlay(alignment: .trailing) {
                    if showsColumnDividers, column != .kind {
                        Rectangle().fill(WorkspaceTheme.raised).frame(width: 1)
                    }
                }
            }
        }
    }
}

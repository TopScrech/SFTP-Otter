import ScrechKit

struct FileBrowserHeaderView<Toolbar: View, Path: View>: View {
    @ViewBuilder let toolbar: Toolbar
    @ViewBuilder let path: Path
    @ScaledMetric private var toolbarHeight = 32
    @ScaledMetric private var pathHeight = 20

    var body: some View {
        VStack {
            toolbar
                .frame(minHeight: toolbarHeight)

            VStack {
                path
            }
            .frame(minHeight: pathHeight)
            .padding(.top)
        }
        .font(.body)
        .buttonStyle(.plain)
        .padding()
        .background(WorkspaceTheme.raised)
    }
}

import SwiftUI

struct BreadcrumbLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
            configuration.title
        }
        .contentShape(.rect)
    }
}

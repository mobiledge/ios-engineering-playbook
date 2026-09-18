import SwiftUI

/// A rounded surface container for grouping related content. Composes the
/// surface color with the radius and spacing tokens so every card in the app
/// shares the same padding and corner treatment.
struct CardView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}

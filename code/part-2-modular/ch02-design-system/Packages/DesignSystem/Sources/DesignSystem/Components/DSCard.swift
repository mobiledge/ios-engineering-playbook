import SwiftUI

/// A rounded surface container for grouping content. Composes the surface color
/// and radius/spacing tokens.
public struct DSCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(DSSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DSColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
    }
}

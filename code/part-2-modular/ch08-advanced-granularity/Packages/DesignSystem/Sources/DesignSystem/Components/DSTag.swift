import SwiftUI

/// A small pill/badge for short metadata such as a genre or media type.
/// Composes caption typography with a tinted background derived from a color token.
public struct DSTag: View {
    private let text: String
    private let color: Color

    public init(_ text: String, color: Color = DSColors.brand) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text.uppercased())
            .font(DSFont.caption)
            .fontWeight(.bold)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .foregroundStyle(color)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

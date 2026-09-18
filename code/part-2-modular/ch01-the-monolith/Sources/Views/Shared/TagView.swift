import SwiftUI

/// A small pill/badge for short metadata such as a genre or media type.
/// Composes caption typography with a tinted background derived from a color
/// token, defaulting to the brand color.
struct TagView: View {
    private let text: String
    private let color: Color

    init(_ text: String, color: Color = AppColor.brand) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(AppFont.caption)
            .fontWeight(.bold)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .foregroundStyle(color)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

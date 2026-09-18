import SwiftUI

/// Typographic tokens for the design system.
///
/// We build the type system from a few *primitives* — a single font design,
/// a fixed type scale, and a set of weights — and then compose them into a
/// handful of *semantic* styles (title, headline, body, …). Screens reference
/// the semantic styles, never raw point sizes, so the whole app can be
/// re-themed by editing this one file.
public enum DSFont {

    // MARK: Primitives

    /// The brand's chosen font design. Swapping this single value restyles the
    /// entire app. We use the system font with a rounded design for warmth.
    static let design: Font.Design = .rounded

    /// The primitive type scale, in points.
    public enum Size {
        public static let xs: CGFloat = 12
        public static let sm: CGFloat = 14
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 28
        public static let xxl: CGFloat = 34
    }

    /// The primitive builder. All semantic styles are composed from this.
    static func make(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: design)
    }

    // MARK: Semantic styles

    public static let largeTitle = make(Size.xxl, .bold)
    public static let title = make(Size.xl, .bold)
    public static let headline = make(Size.lg, .semibold)
    public static let body = make(Size.md, .regular)
    public static let callout = make(Size.sm, .medium)
    public static let caption = make(Size.xs, .regular)
}

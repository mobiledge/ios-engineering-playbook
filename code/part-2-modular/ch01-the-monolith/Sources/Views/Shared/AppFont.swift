import SwiftUI

/// The app's typographic scale.
///
/// We build the type system from a few *primitives* — a single font design, a
/// fixed size scale, and a set of weights — then compose them into a handful of
/// *semantic* styles (`title`, `headline`, `body`, …). Screens reference the
/// semantic styles, never raw point sizes, so the whole app can be re-themed by
/// editing this one file.
///
/// MONOLITH NOTE: like `AppColors`, this is global to the target today.
/// Chapter 2 moves it into the Design System module as `DSFont`.
enum AppFont {

    // MARK: Primitives

    /// The brand's chosen font design. Swapping this single value restyles every
    /// piece of text in the app. We use the system font with a rounded design.
    static let design: Font.Design = .rounded

    /// The primitive type scale, in points.
    enum Size {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 14
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 34
    }

    /// The primitive builder. Every semantic style is composed from this.
    static func make(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: design)
    }

    // MARK: Semantic styles

    static let largeTitle = make(Size.xxl, .bold)
    static let title = make(Size.xl, .bold)
    static let headline = make(Size.lg, .semibold)
    static let body = make(Size.md, .regular)
    static let callout = make(Size.sm, .medium)
    static let caption = make(Size.xs, .regular)
}

import CoreGraphics

/// Spacing tokens — a consistent rhythm used for padding and gaps everywhere.
///
/// Sticking to a small, fixed scale (multiples of 4) is what keeps layouts
/// looking aligned across unrelated screens. Reach for these instead of typing
/// literal numbers like `12` into a `padding` call.
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

/// Corner-radius tokens for consistent rounding across components.
enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
}

import SwiftUI

/// Semantic color tokens for the iTunesSearch design system.
///
/// These are the *foundation* of the design system: a small, named palette that
/// every component and screen draws from. Nothing here depends on app code —
/// only SwiftUI — which is exactly why the design system is safe to extract.
public enum DSColors {

    // MARK: Brand

    /// The primary brand color, used for key actions and accents.
    public static let brand = Color(red: 0.92, green: 0.18, blue: 0.36)
    /// A secondary brand color for gradients and supporting accents.
    public static let brandSecondary = Color(red: 0.45, green: 0.20, blue: 0.78)

    // MARK: Surfaces

    /// The base screen background.
    public static let background = Color(.systemBackground)
    /// A raised surface, e.g. cards and rows.
    public static let surface = Color(.secondarySystemBackground)
    /// A further-raised surface for layering.
    public static let surfaceElevated = Color(.tertiarySystemBackground)

    // MARK: Text

    public static let textPrimary = Color(.label)
    public static let textSecondary = Color(.secondaryLabel)
    public static let textTertiary = Color(.tertiaryLabel)
    /// Text/icons placed on top of the brand color.
    public static let onBrand = Color.white

    // MARK: Status

    public static let success = Color.green
    public static let danger = Color.red

    // MARK: Lines

    public static let separator = Color(.separator)
}

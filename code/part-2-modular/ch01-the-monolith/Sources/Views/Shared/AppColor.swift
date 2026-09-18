import SwiftUI

/// The app's semantic color palette — the foundation of the design system.
///
/// Colors are named for their *role* (brand, surface, text, status), never for
/// their literal hue. A screen asks for `AppColors.textSecondary`, not "gray",
/// so the whole app can be re-themed by editing this one file. Because the
/// neutral surfaces and text colors are backed by Apple's system colors, they
/// adapt to Light and Dark Mode for free.
///
/// MONOLITH NOTE: because this lives in the same target as everything else,
/// any view can use it freely — but there is also nothing stopping unrelated
/// code from depending on it. Chapter 2 extracts these into a Design System
/// module and renames `AppColors` to `DSColors`.
enum AppColor {

    // MARK: Brand

    /// The primary brand color, used for key actions and accents.
    static let brand = Color(red: 0.92, green: 0.18, blue: 0.36)
    /// A secondary brand color for gradients and supporting accents.
    static let brandSecondary = Color(red: 0.45, green: 0.20, blue: 0.78)

    // MARK: Surfaces

    /// The base screen background.
    static let background = Color(.systemBackground)
    /// A raised surface, e.g. cards and rows.
    static let surface = Color(.secondarySystemBackground)
    /// A further-raised surface for layering content on top of `surface`.
    static let surfaceElevated = Color(.tertiarySystemBackground)

    // MARK: Text

    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    /// Text/icons placed on top of the brand color.
    static let onBrand = Color.white

    // MARK: Status

    static let success = Color.green
    static let danger = Color.red

    // MARK: Lines

    static let separator = Color(.separator)
}

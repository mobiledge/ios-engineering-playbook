import SwiftUI
import Domain

/// The abstraction that lets `FeatureLibrary` navigate to a saved item's
/// detail screen WITHOUT importing the feature that owns that screen (e.g.
/// `FeatureMovies`).
///
/// `FeatureLibrary` declares *what should happen* — "open this saved item" —
/// not *where to go*. Something outside both features has to know that a
/// saved movie opens `FeatureMovies`' `MovieDetailScreen`; here, that's the
/// app target (see `AppLibraryRouter`). Chapter 6's Composition Root gives
/// that responsibility a proper home.
@MainActor
public protocol LibraryRouter {
    /// Returns the detail screen for a saved item, type-erased so the caller
    /// needn't know the concrete view type.
    func openSavedItem(_ item: SavedItem) -> AnyView
}

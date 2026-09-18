import SwiftUI
import Domain
import AppInterfaces

/// The app target's implementation of `LibraryRouter`. It owns no logic of
/// its own — it delegates to `AppFactory` to build the destination screen —
/// but it is the thing `FeatureLibrary` actually holds a reference to, via
/// the `LibraryRouter` protocol from `AppInterfaces`.
///
/// `AppRouter` plays the role SwiftUI needs in place of UIKit's imperative,
/// push-based navigation: a small struct handed to a `NavigationStack`-driven
/// feature, so the feature can ask for "the destination for this saved item"
/// without ever knowing what that destination is.
@MainActor
struct AppRouter: LibraryRouter {
    let factory: AppFactory

    func openSavedItem(_ item: SavedItem) -> AnyView {
        factory.destination(for: item)
    }
}

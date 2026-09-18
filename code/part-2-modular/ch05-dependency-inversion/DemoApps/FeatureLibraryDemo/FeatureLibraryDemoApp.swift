import SwiftUI
import Domain
import Infrastructure
import AppInterfaces
import FeatureLibrary

/// A "preview app" for the Library feature — and a perfect illustration that
/// a demo app is just a *miniature composition root*. It compiles
/// `FeatureLibrary` and its dependencies (`Domain`, `DesignSystem`,
/// `AppInterfaces`) — not `FeatureMusicSearch`, `FeaturePodcasts`, or
/// `FeatureMovies` — so it builds in seconds and lets the Library squad
/// iterate on their UI without booting the rest of the app. It injects a
/// real Core Data repository and a trivial stub router (no other features
/// required).
@main
struct FeatureLibraryDemoApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryScreen(
                libraryRepository: CoreDataLibraryRepository(),
                router: PreviewRouter()
            )
        }
    }
}

/// The demo doesn't need real cross-feature navigation, so it stubs the router.
@MainActor
struct PreviewRouter: LibraryRouter {
    func openSavedItem(_ item: SavedItem) -> AnyView {
        AnyView(Text(item.title).font(.title))
    }
}

import SwiftUI
import DesignSystem

/// The app's root tab bar, composing the four feature screens — Music,
/// Podcasts, Movies, and Library — that `AppFactory` builds.
///
/// This is what "trivial" looks like once a composition root exists:
/// `RootView` no longer constructs a single repository, service, or router,
/// and it no longer imports `Domain`, `Infrastructure`, `AppInterfaces`, or
/// any feature package. It asks the factory for each screen and lays them
/// out in a `TabView`. Compare this file to Chapter 5's `RootView` — the
/// wiring didn't disappear, it moved to exactly one other place.
struct RootView: View {
    let factory: AppFactory

    var body: some View {
        TabView {
            factory.makeMusicSearch()
                .tabItem { Label("Music", systemImage: "music.note") }

            factory.makePodcasts()
                .tabItem { Label("Podcasts", systemImage: "mic") }

            factory.makeMovies()
                .tabItem { Label("Movies", systemImage: "film") }

            factory.makeLibrary()
                .tabItem { Label("Library", systemImage: "books.vertical") }
        }
        .tint(DSColors.brand)
    }
}

#Preview {
    RootView(factory: AppFactory())
}

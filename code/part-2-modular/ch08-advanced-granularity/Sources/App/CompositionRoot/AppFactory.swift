import SwiftUI
import Domain
import Infrastructure
import AppInterfaces
import MusicSearchLogic
import MusicSearchUI
import FeatureMovies
import FeatureLibrary
import FeatureAudiobooks

/// The Composition Root.
///
/// This is the ONE type that imports every module and knows every concrete
/// implementation. It owns the shared repositories and services — so every
/// feature that needs, say, the library repository gets the *same* instance
/// — builds each feature's screen with its dependencies injected, and
/// supplies the routing destinations `AppRouter` hands to `FeatureLibrary`.
/// Nothing else in the app target constructs a concrete repository or
/// service; `RootView`, the previews, and `FeatureLibraryDemo` all go
/// through a factory instead.
///
/// This is also where Chapter 1's loop finally closes. The `Services` enum
/// and its `MOCK_SERVICES` flag are gone — mock vs. real was always a
/// composition-root decision wearing a global enum's clothes. Now it's an
/// initializer default, picked in exactly one place.
@MainActor
final class AppFactory {
    private let searchRepository: MediaSearchRepository
    private let libraryRepository: LibraryRepository
    private let analytics: AnalyticsTracker
    private let crashReporter: CrashReporter
    private let flags: FeatureFlagProvider

    init(
        searchRepository: MediaSearchRepository = ITunesSearchRepository(),
        libraryRepository: LibraryRepository = CoreDataLibraryRepository(),
        analytics: AnalyticsTracker = ConsoleAnalytics(),
        crashReporter: CrashReporter = ConsoleCrashReporter(),
        flags: FeatureFlagProvider = {
            // The MOCK_SERVICES decision Chapter 1's `Services` enum used to
            // make. It has exactly one home now.
            #if MOCK_SERVICES
            return LocalFeatureFlags([.offlineMode: true])
            #else
            return LocalFeatureFlags()
            #endif
        }()
    ) {
        self.searchRepository = searchRepository
        self.libraryRepository = libraryRepository
        self.analytics = analytics
        self.crashReporter = crashReporter
        self.flags = flags
    }

    /// The one caller left of the old `Services.crashReporter` breadcrumb —
    /// `iTunesSearchApp.init` uses it to mark app launch.
    func recordLaunchBreadcrumb() {
        crashReporter.breadcrumb("app_launch")
    }

    // MARK: Feature screens

    // FeatureMusicSearch is the one feature split into micro-targets
    // (Chapter 8): this factory is the only place that imports both
    // `MusicSearchLogic` and `MusicSearchUI` and wires one into the other.
    func makeMusicSearch() -> some View {
        MusicSearchScreen(
            viewModel: MusicSearchViewModel(
                searchRepository: self.searchRepository,
                libraryRepository: self.libraryRepository,
                analytics: self.analytics,
                crashReporter: self.crashReporter
            )
        )
    }

    func makeAudiobooks() -> some View {
        AudiobooksScreen(searchRepository: searchRepository, libraryRepository: libraryRepository)
    }

    func makeMovies() -> some View {
        MoviesScreen(searchRepository: searchRepository, libraryRepository: libraryRepository)
    }

    func makeLibrary() -> some View {
        LibraryScreen(libraryRepository: libraryRepository, router: AppRouter(factory: self))
    }

    // MARK: Routing destinations (used by AppRouter)

    /// The one place in the app that knows a saved *movie* opens
    /// `FeatureMovies`' `MovieDetailScreen` — while `FeatureLibrary` stays
    /// oblivious to `FeatureMovies` entirely.
    func destination(for item: SavedItem) -> AnyView {
        switch item.mediaType {
        case .movie:
            let movie = Movie(
                id: item.id,
                title: item.title,
                artist: item.subtitle ?? "",
                artworkURL: item.artworkURL
            )
            return AnyView(MovieDetailScreen(movie: movie, libraryRepository: libraryRepository))
        case .music, .audiobook:
            return AnyView(SavedItemDetailView(item: item))
        }
    }
}

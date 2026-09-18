import SwiftUI
import DesignSystem
import Domain
import Infrastructure
import AppInterfaces
import FeatureMusicSearch
import FeaturePodcasts
import FeatureMovies
import FeatureLibrary

/// The app's root tab bar, composing the four feature packages — Music,
/// Podcasts, Movies (born this chapter), and Library.
///
/// `RootView` is now the only place in the app that is allowed to import
/// `Infrastructure`. Every feature dropped that dependency, so `RootView`
/// constructs the concrete repositories and services ad hoc and injects them
/// into each screen's initializer — the same instances are handed to
/// whichever screens need them. It also builds `AppLibraryRouter`, the app's
/// implementation of `LibraryRouter`, so Library can open a saved movie's
/// detail screen without ever importing `FeatureMovies`.
///
/// This is deliberately messy: there is no composition root to isolate this
/// wiring yet — that's Chapter 6. For now it is all smeared across this one
/// file.
struct RootView: View {
    private let searchRepository: MediaSearchRepository = ITunesSearchRepository()
    private let libraryRepository: LibraryRepository = CoreDataLibraryRepository()
    private let analytics: AnalyticsTracker = ConsoleAnalytics()
    private let crashReporter: CrashReporter = ConsoleCrashReporter()
    private let flags: FeatureFlagProvider = {
        #if MOCK_SERVICES
        return LocalFeatureFlags([.newPodcastUI: true])
        #else
        return LocalFeatureFlags()
        #endif
    }()

    var body: some View {
        TabView {
            MusicSearchScreen(
                searchRepository: searchRepository,
                libraryRepository: libraryRepository,
                analytics: analytics,
                crashReporter: crashReporter
            )
            .tabItem { Label("Music", systemImage: "music.note") }

            PodcastsScreen(
                searchRepository: searchRepository,
                libraryRepository: libraryRepository,
                flags: flags
            )
            .tabItem { Label("Podcasts", systemImage: "mic") }

            MoviesScreen(
                searchRepository: searchRepository,
                libraryRepository: libraryRepository
            )
            .tabItem { Label("Movies", systemImage: "film") }

            LibraryScreen(
                libraryRepository: libraryRepository,
                router: AppLibraryRouter(libraryRepository: libraryRepository)
            )
            .tabItem { Label("Library", systemImage: "books.vertical") }
        }
        .tint(DSColors.brand)
    }
}

#Preview {
    RootView()
}

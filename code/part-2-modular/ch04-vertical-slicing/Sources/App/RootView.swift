import SwiftUI
import DesignSystem
import FeatureMusicSearch
import FeaturePodcasts
import FeatureLibrary

/// The app's root tab bar, composing the three feature packages.
///
/// `RootView` still knows about every feature directly — it imports and
/// instantiates `MusicSearchScreen`, `PodcastsScreen`, and `LibraryScreen` by
/// name. There is no composition root to isolate this wiring from the
/// features themselves; that's the Composition Root chapter, still ahead.
struct RootView: View {
    var body: some View {
        TabView {
            MusicSearchScreen()
                .tabItem { Label("Music", systemImage: "music.note") }

            PodcastsScreen()
                .tabItem { Label("Podcasts", systemImage: "mic") }

            LibraryScreen()
                .tabItem { Label("Library", systemImage: "books.vertical") }
        }
        .tint(DSColors.brand)
    }
}

#Preview {
    RootView()
}

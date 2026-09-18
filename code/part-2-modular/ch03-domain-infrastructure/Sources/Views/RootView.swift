import SwiftUI
import DesignSystem

/// The app's root tab bar, wiring together the three core features.
///
/// In the UIKit world this composition lived in the SceneDelegate; here it is
/// a SwiftUI `TabView`.
///
/// MONOLITH NOTE: `RootView` knows about every feature directly — it imports
/// and instantiates `MusicSearchView`, `PodcastsView`, and `LibraryView` by
/// name. There is no composition root to isolate this wiring from the features
/// themselves; another hallmark of the monolith we'll untangle in the
/// Composition Root chapter.
struct RootView: View {
    var body: some View {
        TabView {
            MusicSearchView()
                .tabItem { Label("Music", systemImage: "music.note") }

            PodcastsView()
                .tabItem { Label("Podcasts", systemImage: "mic") }

            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }
        }
        .tint(DSColors.brand)
    }
}

#Preview {
    RootView()
}

import SwiftUI

/// The app's root tab bar, wiring together the two core features.
///
/// In the UIKit world this composition lived in the SceneDelegate; here it is
/// a SwiftUI `TabView`.
///
/// MONOLITH NOTE: `RootView` knows about every feature directly — it imports
/// and instantiates `MusicSearchView` and `PodcastsView` by name. There is no
/// composition root to isolate this wiring from the features themselves;
/// another hallmark of the monolith we'll untangle in the Composition Root
/// chapter.
struct RootView: View {
    var body: some View {
        TabView {
            MusicSearchView()
                .tabItem { Label("Music", systemImage: "music.note") }

            PodcastsView()
                .tabItem { Label("Podcasts", systemImage: "mic") }
        }
        .tint(AppColor.brand)
    }
}

#Preview {
    RootView()
}

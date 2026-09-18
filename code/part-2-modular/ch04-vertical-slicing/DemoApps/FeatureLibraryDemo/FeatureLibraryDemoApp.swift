import SwiftUI
import FeatureLibrary

/// A "preview app" for the Library feature. It compiles only `FeatureLibrary`
/// and its dependencies (`Domain`, `Infrastructure`, `DesignSystem`) — not
/// `FeatureMusicSearch` or `FeaturePodcasts` — so it builds in seconds and
/// lets the Library squad iterate on their UI without booting the rest of
/// the app. The same pattern works for every feature; this chapter ships one
/// demo app as the proof.
@main
struct FeatureLibraryDemoApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryScreen()
        }
    }
}

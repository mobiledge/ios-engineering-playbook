import SwiftUI

/// A "preview app" for the Library feature — and a perfect illustration that
/// a demo app is just a *miniature composition root*. It compiles
/// `FeatureLibrary` and its dependencies (`Domain`, `DesignSystem`,
/// `AppInterfaces`) — not `FeatureMusicSearch`, `FeatureMovies`, or
/// `FeatureAudiobooks` — so it builds in seconds and lets the Library squad
/// iterate on their UI without booting the rest of the app. All the
/// construction that makes that possible lives in `DemoCompositionRoot`,
/// this demo's own ~10-line composition root, not here.
@main
struct FeatureLibraryDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoCompositionRoot.makeLibraryScreen()
        }
    }
}

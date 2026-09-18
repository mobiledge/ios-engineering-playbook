import SwiftUI

/// The app entry point.
///
/// With the SwiftUI app lifecycle, this single `App` struct replaces the
/// classic UIKit `AppDelegate` + `SceneDelegate` pair from the chapter's
/// anatomy. It is still part of the one-and-only monolith target.
@main
struct ITunesSearchApp: App {
    init() {
        // MONOLITH NOTE: app startup is where the real vendor SDKs would be
        // initialised today (Crashlytics.configure(), Amplitude(apiKey:), …).
        // Going through the `Services` facade keeps that detail out of every
        // feature — the seam we'll formalise into its own module later.
        Services.crashReporter.breadcrumb("app_launch")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

import SwiftUI

/// The app entry point.
///
/// With the SwiftUI app lifecycle, this single `App` struct replaces the
/// classic UIKit `AppDelegate` + `SceneDelegate` pair the book's anatomy
/// chapter described. It owns the one `AppFactory` for the app's lifetime —
/// the Composition Root, built as close to `@main` as possible — and hands
/// it to `RootView`.
///
/// Chapter 1's `Services` enum used to live in this file, picking mock vs.
/// real by build configuration. It's gone: that decision, and every
/// repository/service construction it used to gate, now lives in
/// `AppFactory` alone.
@main
struct ITunesSearchApp: App {
    private let factory = AppFactory()

    init() {
        factory.recordLaunchBreadcrumb()
    }

    var body: some Scene {
        WindowGroup {
            RootView(factory: factory)
        }
    }
}

import SwiftUI
import Domain
import Infrastructure

/// Cross-cutting service selection — still living in the app target for now.
///
/// Every feature used to reach this facade directly (`Services.analytics`,
/// `Services.crashReporter`, `Services.flags`). That stopped working the moment
/// those views moved into their own Swift packages: a package can't depend on
/// the app executable that hosts it. Each feature now constructs its own
/// `Infrastructure` types inline instead (see `FeatureMusicSearch` and
/// `FeaturePodcasts`), which leaves exactly one caller here — this file's own
/// app-launch breadcrumb. `Services` still picks the implementation by build
/// configuration; Chapter 6's composition root is what finally dissolves it.
enum Services {
    static let crashReporter: CrashReporter = ConsoleCrashReporter()
}

/// The app entry point.
///
/// With the SwiftUI app lifecycle, this single `App` struct replaces the
/// classic UIKit `AppDelegate` + `SceneDelegate` pair the book's anatomy
/// chapter described. It is one of the app target's two remaining files —
/// `RootView` is the other; every feature now lives in its own package.
@main
struct ITunesSearchApp: App {
    init() {
        Services.crashReporter.breadcrumb("app_launch")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

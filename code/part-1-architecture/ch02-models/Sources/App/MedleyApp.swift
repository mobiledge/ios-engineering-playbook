import SwiftUI

/// Medley — a media-discovery app built on Apple's keyless iTunes Search API.
///
/// Chapter 1 is the prototype: one screen, one file, no layers. Structure must
/// earn its place, and at this size it hasn't yet. Every extraction in the
/// chapters that follow starts from `ContentView`.
@main
struct MedleyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

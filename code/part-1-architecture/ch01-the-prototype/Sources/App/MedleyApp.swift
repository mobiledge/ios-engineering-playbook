import SwiftUI

/// Medley — a media-discovery app built on Apple's keyless iTunes Search API.
///
/// Chapter 1 is the prototype: one file, no layers, no abstractions. Structure
/// must earn its place, and at this size it hasn't yet. Every extraction in the
/// chapters that follow starts from here.
@main
struct MedleyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("Medley")
                .font(.largeTitle.bold())
                .navigationTitle("Search")
        }
    }
}

#Preview {
    ContentView()
}

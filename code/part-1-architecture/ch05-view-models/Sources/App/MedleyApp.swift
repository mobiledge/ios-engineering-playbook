import SwiftUI

/// Medley — a media-discovery app built on Apple's keyless iTunes Search API.
///
/// The app builds its dependencies here, at startup, and hands them to what needs them:
/// the search client to the screen's view model, the view model to the screen.
/// Nothing below this point creates a client or reaches for a global.
@main
struct MedleyApp: App {
    @State private var musicSearch = MusicSearchViewModel(client: MedleyApp.makeSearchClient())

    var body: some Scene {
        WindowGroup {
            MusicSearchView(viewModel: musicSearch)
        }
    }

    /// The one place the real search client is built. Previews use it too.
    static func makeSearchClient() -> any SearchClient {
        ITunesAPIClient(
            session: URLSession(configuration: .default),
            locale: .current,
            // Flip to `true` once we're happy showing explicit tracks in search.
            allowsExplicitResults: false
        )
    }
}

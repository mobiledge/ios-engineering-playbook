import SwiftUI

/// Medley — a media-discovery app built on Apple's keyless iTunes Search API.
///
/// The app builds its one dependency here, at startup, and hands it to the view
/// that needs it. Nothing below this point creates a client or reaches for a global.
@main
struct MedleyApp: App {
    private let client = MedleyApp.makeSearchClient()

    var body: some Scene {
        WindowGroup {
            MusicSearchView(client: client)
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

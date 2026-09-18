import SwiftUI
import DesignSystem

/// A single row in the podcasts list. Deliberately parallel to `TrackRow`: the
/// whole row is one `DSMediaRow` from the design system, so Music and Podcasts
/// look identical for free — the payoff of composing from shared tokens.
struct PodcastRow: View {
    let podcast: Podcast

    var body: some View {
        DSMediaRow(
            title: podcast.collectionName,
            subtitle: podcast.artistName,
            caption: podcast.releaseDate?.mediumString,
            artworkURL: podcast.artworkUrl100
        )
    }
}

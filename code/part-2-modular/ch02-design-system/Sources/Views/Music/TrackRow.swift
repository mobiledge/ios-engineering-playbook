import SwiftUI
import DesignSystem

/// A single row in the music list.
///
/// This is the whole point of Chapter 2: notice how little styling lives here
/// now. Before the extraction this row hand-built an `HStack` and reached for
/// `AppColors`; now the entire row is a single `DSMediaRow` from the design
/// system, so Music and Podcasts look identical for free.
struct TrackRow: View {
    let track: Track

    var body: some View {
        DSMediaRow(
            title: track.trackName,
            subtitle: track.artistName,
            caption: track.releaseDate?.mediumString,
            artworkURL: track.artworkUrl100
        )
    }
}

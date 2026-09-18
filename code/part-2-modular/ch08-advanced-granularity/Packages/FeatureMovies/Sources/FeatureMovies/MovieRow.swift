import SwiftUI
import DesignSystem
import Domain

/// A single row in the movies list. Unlike `TrackRow`/`AudiobookRow`, there is
/// no save affordance here — Movies is a browse-then-detail feature: tap
/// through to `MovieDetailScreen` to save.
struct MovieRow: View {
    let movie: Movie

    var body: some View {
        DSMediaRow(
            title: movie.title,
            subtitle: movie.artist,
            caption: movie.releaseDate?.mediumString,
            artworkURL: movie.artworkURL
        )
    }
}

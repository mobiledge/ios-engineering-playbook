import SwiftUI

/// One search result: artwork, title, artist, album, year, and duration.
///
/// Draws the `TrackRowModel` it's given, exactly as given: every string arrives ready to show.
/// What happens on tap is the list's business.
struct TrackRow: View {
    let row: TrackRowModel

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: row.artworkURL)

            VStack(alignment: .leading) {
                Text(row.title)
                    .font(.headline)
                    .lineLimit(2)
                Group {
                    Text(row.artist)
                    if let album = row.album {
                        Text(album)
                    }
                    if let year = row.year {
                        Text(year)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            if let duration = row.duration {
                Text(duration)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews: the rows a live search rarely shows you

#Preview("Everything present") {
    List { TrackRow(row: .letDown) }
}

#Preview("Longest plausible title") {
    List { TrackRow(row: .nightZombies) }
}

#Preview("Only the required fields") {
    List { TrackRow(row: .bare) }
}

#Preview("Empty strings") {
    List { TrackRow(row: .empty) }
}

#Preview("Largest accessibility text") {
    List {
        TrackRow(row: .letDown)
        TrackRow(row: .nightZombies)
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

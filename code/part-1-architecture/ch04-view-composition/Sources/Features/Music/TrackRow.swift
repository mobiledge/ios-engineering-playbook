import SwiftUI

/// One search result: artwork, title, artist, album, year, and duration.
///
/// Renders the `Track` it's given and nothing else. What happens on tap is the list's business.
struct TrackRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: track.artworkUrl100)

            VStack(alignment: .leading) {
                Text(track.trackName)
                    .font(.headline)
                    .lineLimit(2)
                Group {
                    Text(track.artistName)
                    if let album = track.collectionName {
                        Text(album)
                    }
                    if let released = track.releaseDate {
                        // Releases are stamped at midnight Pacific. Read the year in UTC,
                        // or a New Year's Day release shows last year in Hawaii.
                        Text(released, format: Date.FormatStyle(timeZone: .gmt).year())
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            if let millis = track.trackTimeMillis {
                Text("\(millis / 60_000):\(String(format: "%02d", millis / 1000 % 60))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews: the rows a live search rarely shows you

#Preview("Everything present") {
    List { TrackRow(track: .letDown) }
}

#Preview("Longest plausible title") {
    List { TrackRow(track: .nightZombies) }
}

#Preview("Only the required fields") {
    List { TrackRow(track: .bare) }
}

#Preview("Empty strings") {
    List { TrackRow(track: .empty) }
}

#Preview("Largest accessibility text") {
    List {
        TrackRow(track: .letDown)
        TrackRow(track: .nightZombies)
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

private extension Track {
    static let letDown = Track(
        trackId: 1, trackName: "Let Down", artistName: "Radiohead", collectionName: "OK Computer",
        artworkUrl100: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/07/60/ba/0760ba0f-148c-b18f-d0ff-169ee96f3af5/634904078164.png/100x100bb.jpg"),
        releaseDate: Date(timeIntervalSince1970: 864_198_000), trackTimeMillis: 299_560, trackViewUrl: nil)

    static let nightZombies = Track(
        trackId: 2,
        trackName: "They Are Night Zombies!! They Are Neighbors!! They Have Come Back from the Dead!! Ahhhh!",
        artistName: "Sufjan Stevens",
        collectionName: "Illinois (Deluxe Edition) [Remastered, with Bonus Tracks and Alternate Takes]",
        artworkUrl100: nil, releaseDate: Date(timeIntervalSince1970: 1_120_176_000),
        trackTimeMillis: 309_000, trackViewUrl: nil)

    static let bare = Track(
        trackId: 3, trackName: "Untitled Demo", artistName: "Unknown Band", collectionName: nil,
        artworkUrl100: nil, releaseDate: nil, trackTimeMillis: nil, trackViewUrl: nil)

    static let empty = Track(
        trackId: 4, trackName: "", artistName: "", collectionName: "",
        artworkUrl100: nil, releaseDate: nil, trackTimeMillis: 0, trackViewUrl: nil)
}

import Foundation

/// One search result, ready to draw: every value is already formatted for display.
///
/// `TrackRow` renders these and formats nothing, so everything a user reads in a row
/// is decided here, where a test can check it.
struct TrackRowModel: Identifiable, Equatable {
    let id: Int
    let title: String
    let artist: String
    let album: String?
    /// "1997".
    let year: String?
    /// "4:59".
    let duration: String?
    let artworkURL: URL?
    /// Where a tap goes. Not drawn; the list uses it.
    let link: URL?
}

extension TrackRowModel {
    init(track: Track) {
        id = track.trackId
        title = track.trackName
        artist = track.artistName
        album = track.collectionName
        // Releases are stamped at midnight Pacific. Read the year in UTC,
        // or a New Year's Day release shows last year in Hawaii.
        year = track.releaseDate?.formatted(Date.FormatStyle(timeZone: .gmt).year())
        // Truncate, like the catalog: 299,560 ms is 4:59, not 5:00.
        duration = track.trackTimeMillis.map {
            Duration.milliseconds($0)
                .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1, roundFractionalSeconds: .towardZero)))
        }
        artworkURL = track.artworkUrl100
        link = track.trackViewUrl
    }
}

/// Contrived rows for previews: the ones a live search rarely shows.
extension TrackRowModel {
    static let letDown = TrackRowModel(
        id: 1, title: "Let Down", artist: "Radiohead", album: "OK Computer", year: "1997",
        duration: "4:59",
        artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/07/60/ba/0760ba0f-148c-b18f-d0ff-169ee96f3af5/634904078164.png/100x100bb.jpg"),
        link: nil)

    static let nightZombies = TrackRowModel(
        id: 2,
        title: "They Are Night Zombies!! They Are Neighbors!! They Have Come Back from the Dead!! Ahhhh!",
        artist: "Sufjan Stevens",
        album: "Illinois (Deluxe Edition) [Remastered, with Bonus Tracks and Alternate Takes]",
        year: "2005", duration: "5:09", artworkURL: nil, link: nil)

    static let bare = TrackRowModel(
        id: 3, title: "Untitled Demo", artist: "Unknown Band", album: nil, year: nil,
        duration: nil, artworkURL: nil, link: nil)

    static let empty = TrackRowModel(
        id: 4, title: "", artist: "", album: "", year: nil, duration: "0:00", artworkURL: nil, link: nil)
}

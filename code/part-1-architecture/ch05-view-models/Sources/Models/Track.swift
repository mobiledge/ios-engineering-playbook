import Foundation

/// A song from the iTunes Search API (`media=music`, `entity=song`).
///
/// Property names match the API's JSON keys, so decoding needs no `CodingKeys`.
/// Optionality mirrors what the API actually promises: a result can't be shown
/// without an ID, a title, and an artist, so those are required. Apple guarantees
/// nothing else, so everything else is optional and the view copes without it.
struct Track: Decodable, Identifiable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let collectionName: String?
    /// Absent for some catalog entries. Force-casting it was the app's first crash — see `TrackDecodingTests`.
    let artworkUrl100: URL?
    let releaseDate: Date?
    let trackTimeMillis: Int?
    let trackViewUrl: URL?

    var id: Int { trackId }
}

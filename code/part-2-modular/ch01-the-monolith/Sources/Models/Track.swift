import Foundation

/// A music track returned by the iTunes Search API (`media=music`).
struct Track: Decodable, Identifiable, Hashable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let collectionName: String?
    let artworkUrl100: URL?
    let previewUrl: URL?
    let releaseDate: Date?
    let primaryGenreName: String?

    var id: Int { trackId }
}

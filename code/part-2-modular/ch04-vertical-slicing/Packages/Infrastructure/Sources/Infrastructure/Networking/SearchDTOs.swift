import Foundation
import Domain

/// Data Transfer Objects: the shape of the iTunes JSON. These `Decodable` types
/// know all about `trackName`, `artworkUrl100`, etc. — and they are the ONLY
/// place that knowledge lives. Each maps itself to a clean domain entity, so a
/// change to the API's JSON ripples no further than this file.
struct SearchResponseDTO<Item: Decodable>: Decodable {
    let resultCount: Int
    let results: [Item]
}

struct TrackDTO: Decodable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let collectionName: String?
    let artworkUrl100: URL?
    let previewUrl: URL?
    let releaseDate: Date?
    let primaryGenreName: String?

    func toDomain() -> Track {
        Track(
            id: trackId,
            name: trackName,
            artist: artistName,
            collection: collectionName,
            artworkURL: artworkUrl100,
            previewURL: previewUrl,
            releaseDate: releaseDate,
            genre: primaryGenreName
        )
    }
}

struct PodcastDTO: Decodable {
    let collectionId: Int
    let collectionName: String
    let artistName: String
    let artworkUrl100: URL?
    let releaseDate: Date?
    let primaryGenreName: String?

    func toDomain() -> Podcast {
        Podcast(
            id: collectionId,
            name: collectionName,
            artist: artistName,
            artworkURL: artworkUrl100,
            releaseDate: releaseDate,
            genre: primaryGenreName
        )
    }
}

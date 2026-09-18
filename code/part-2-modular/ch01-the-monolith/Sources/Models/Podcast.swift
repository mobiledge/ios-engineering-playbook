import Foundation

/// A podcast returned by the iTunes Search API (`media=podcast`).
/// Podcasts are keyed on `collectionId`/`collectionName` (the show), not on
/// individual episode fields.
struct Podcast: Decodable, Identifiable, Hashable {
    let collectionId: Int
    let collectionName: String
    let artistName: String
    let artworkUrl100: URL?
    let primaryGenreName: String?
    let releaseDate: Date?

    var id: Int { collectionId }
}

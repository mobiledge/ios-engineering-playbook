import Foundation

/// A movie — a pure domain entity.
///
/// Note the field names: `title`, `artist`, `artworkURL`. They describe the
/// concept, NOT the iTunes JSON (`trackName`, `artistName`, `artworkUrl100`).
/// That translation is an infrastructure detail and lives in a DTO, so the
/// domain never has to change if the API's JSON shape changes.
public struct Movie: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let artist: String
    public let artworkURL: URL?
    public let overview: String?
    public let releaseDate: Date?
    public let genre: String?
    public let price: Double?

    public init(
        id: Int,
        title: String,
        artist: String,
        artworkURL: URL? = nil,
        overview: String? = nil,
        releaseDate: Date? = nil,
        genre: String? = nil,
        price: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.overview = overview
        self.releaseDate = releaseDate
        self.genre = genre
        self.price = price
    }
}

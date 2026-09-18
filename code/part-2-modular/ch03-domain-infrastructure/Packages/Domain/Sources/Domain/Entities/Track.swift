import Foundation

/// A music track — a pure domain entity.
///
/// Note the field names: `name`, `artist`, `artworkURL`. They describe the
/// concept, NOT the iTunes JSON (`trackName`, `artistName`, `artworkUrl100`).
/// That translation is an infrastructure detail and lives in a DTO, so the
/// domain never has to change if the API's JSON shape changes.
public struct Track: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let artist: String
    public let collection: String?
    public let artworkURL: URL?
    public let previewURL: URL?
    public let releaseDate: Date?
    public let genre: String?

    public init(
        id: Int,
        name: String,
        artist: String,
        collection: String? = nil,
        artworkURL: URL? = nil,
        previewURL: URL? = nil,
        releaseDate: Date? = nil,
        genre: String? = nil
    ) {
        self.id = id
        self.name = name
        self.artist = artist
        self.collection = collection
        self.artworkURL = artworkURL
        self.previewURL = previewURL
        self.releaseDate = releaseDate
        self.genre = genre
    }
}

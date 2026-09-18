import Foundation

/// An audiobook — a pure domain entity.
///
/// Note the field names: `title`, `author`, `artworkURL`. They describe the
/// concept, NOT the iTunes JSON (`collectionName`, `artistName`,
/// `artworkUrl100`). That translation is an infrastructure detail and lives in
/// a DTO, so the domain never has to change if the API's JSON shape changes.
public struct Audiobook: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let author: String
    public let artworkURL: URL?
    public let releaseDate: Date?
    public let genre: String?

    public init(
        id: Int,
        title: String,
        author: String,
        artworkURL: URL? = nil,
        releaseDate: Date? = nil,
        genre: String? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.artworkURL = artworkURL
        self.releaseDate = releaseDate
        self.genre = genre
    }
}

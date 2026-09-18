import Foundation

/// An item the user has saved to their local library. A domain entity that is
/// deliberately storage-agnostic: it knows nothing about Core Data.
public struct SavedItem: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let subtitle: String?
    public let artworkURL: URL?
    public let mediaType: MediaType
    public let savedAt: Date

    public init(
        id: Int,
        title: String,
        subtitle: String? = nil,
        artworkURL: URL? = nil,
        mediaType: MediaType,
        savedAt: Date
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.artworkURL = artworkURL
        self.mediaType = mediaType
        self.savedAt = savedAt
    }
}

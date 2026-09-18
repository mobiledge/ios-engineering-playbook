import Foundation

/// What the domain needs in order to persist the user's library. The concrete
/// Core Data implementation lives in the infrastructure layer.
public protocol LibraryRepository {
    func save(_ item: SavedItem)
    func remove(id: Int, mediaType: MediaType)
    func isSaved(id: Int, mediaType: MediaType) -> Bool
    func fetchAll() -> [SavedItem]
}

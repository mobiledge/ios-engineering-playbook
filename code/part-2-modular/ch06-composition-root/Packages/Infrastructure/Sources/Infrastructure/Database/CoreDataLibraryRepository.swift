import Foundation
import Domain

/// The concrete `LibraryRepository`, backed by Core Data.
///
/// It is a thin, public adapter over the internal `CoreDataStack`. The app
/// depends on this type only to construct it; everywhere else it works through
/// the `LibraryRepository` protocol from the Domain.
public final class CoreDataLibraryRepository: LibraryRepository {
    private let stack: CoreDataStack

    public init() {
        self.stack = .shared
    }

    public func save(_ item: SavedItem) {
        stack.save(item)
    }

    public func remove(id: Int, mediaType: MediaType) {
        stack.remove(id: id, mediaType: mediaType)
    }

    public func isSaved(id: Int, mediaType: MediaType) -> Bool {
        stack.isSaved(id: id, mediaType: mediaType)
    }

    public func fetchAll() -> [SavedItem] {
        stack.fetchAll()
    }
}

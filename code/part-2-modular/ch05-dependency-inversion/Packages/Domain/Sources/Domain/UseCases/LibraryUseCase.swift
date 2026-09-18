import Foundation

/// The business rules for the user's saved Library: don't save the same item
/// twice, and always list saved items newest-first.
///
/// This is exactly the logic that used to have nowhere to live except inside a
/// SwiftUI view, next to whatever Core Data calls happened to be nearby. Here
/// it's plain Swift that depends only on the `LibraryRepository` protocol, so
/// it can be tested with a mock in microseconds — no disk, no simulator. See
/// `DomainTests`.
public struct LibraryUseCase {
    private let repository: LibraryRepository

    public init(repository: LibraryRepository) {
        self.repository = repository
    }

    /// Saves an item unless one with the same id/mediaType is already saved.
    /// Returns whether the item was actually saved (`false` means it was a
    /// no-op duplicate).
    @discardableResult
    public func save(_ item: SavedItem) -> Bool {
        guard !repository.isSaved(id: item.id, mediaType: item.mediaType) else { return false }
        repository.save(item)
        return true
    }

    public func remove(id: Int, mediaType: MediaType) {
        repository.remove(id: id, mediaType: mediaType)
    }

    public func isSaved(id: Int, mediaType: MediaType) -> Bool {
        repository.isSaved(id: id, mediaType: mediaType)
    }

    /// All saved items, newest first.
    public func list() -> [SavedItem] {
        repository.fetchAll().sorted { $0.savedAt > $1.savedAt }
    }
}

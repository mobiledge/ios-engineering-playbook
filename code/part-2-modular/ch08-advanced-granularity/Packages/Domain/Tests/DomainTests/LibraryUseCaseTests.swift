import XCTest
@testable import Domain

/// These tests prove the payoff of moving the Library's business rules into
/// the Domain: "don't save duplicates" and "list newest first" verified in
/// microseconds with an in-memory mock repository — no Core Data, no simulator.
final class LibraryUseCaseTests: XCTestCase {

    /// A hand-written in-memory mock — no Core Data.
    private final class MockLibraryRepository: LibraryRepository {
        private(set) var items: [SavedItem] = []
        private(set) var saveCallCount = 0

        func save(_ item: SavedItem) {
            saveCallCount += 1
            items.append(item)
        }

        func remove(id: Int, mediaType: MediaType) {
            items.removeAll { $0.id == id && $0.mediaType == mediaType }
        }

        func isSaved(id: Int, mediaType: MediaType) -> Bool {
            items.contains { $0.id == id && $0.mediaType == mediaType }
        }

        func fetchAll() -> [SavedItem] {
            items
        }
    }

    func testSavingTheSameItemTwiceDoesNotDuplicate() {
        let repo = MockLibraryRepository()
        let useCase = LibraryUseCase(repository: repo)
        let track = SavedItem(id: 1, title: "Banana Pancakes", subtitle: "Jack Johnson", mediaType: .music, savedAt: Date())

        XCTAssertTrue(useCase.save(track), "The first save should go through.")
        XCTAssertFalse(useCase.save(track), "Saving the same id/mediaType again must be a no-op.")

        XCTAssertEqual(repo.saveCallCount, 1)
        XCTAssertEqual(useCase.list().count, 1)
    }

    func testTwoDifferentMediaTypesWithTheSameIdAreNotDuplicates() {
        let repo = MockLibraryRepository()
        let useCase = LibraryUseCase(repository: repo)
        let track = SavedItem(id: 1, title: "Banana Pancakes", mediaType: .music, savedAt: Date())
        let audiobookEpisode = SavedItem(id: 1, title: "The Shining", mediaType: .audiobook, savedAt: Date())

        XCTAssertTrue(useCase.save(track))
        XCTAssertTrue(useCase.save(audiobookEpisode))
        XCTAssertEqual(useCase.list().count, 2)
    }

    func testListIsSortedNewestFirst() {
        let repo = MockLibraryRepository()
        let useCase = LibraryUseCase(repository: repo)
        let older = SavedItem(id: 1, title: "Older", mediaType: .music, savedAt: Date(timeIntervalSince1970: 0))
        let newer = SavedItem(id: 2, title: "Newer", mediaType: .audiobook, savedAt: Date(timeIntervalSince1970: 1_000))

        useCase.save(older)
        useCase.save(newer)

        XCTAssertEqual(useCase.list().map(\.id), [2, 1])
    }

    func testRemoveDeletesOnlyTheMatchingItem() {
        let repo = MockLibraryRepository()
        let useCase = LibraryUseCase(repository: repo)
        let track = SavedItem(id: 1, title: "Banana Pancakes", mediaType: .music, savedAt: Date())
        let audiobookEpisode = SavedItem(id: 1, title: "The Shining", mediaType: .audiobook, savedAt: Date())
        useCase.save(track)
        useCase.save(audiobookEpisode)

        useCase.remove(id: 1, mediaType: .music)

        XCTAssertFalse(useCase.isSaved(id: 1, mediaType: .music))
        XCTAssertTrue(useCase.isSaved(id: 1, mediaType: .audiobook))
        XCTAssertEqual(useCase.list().count, 1)
    }
}

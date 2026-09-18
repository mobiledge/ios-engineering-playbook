import XCTest
@testable import Domain

/// These tests prove the payoff of the Domain layer: real business logic,
/// verified in microseconds with a mock repository and zero I/O.
final class SearchMediaUseCaseTests: XCTestCase {

    /// A hand-written mock — no network, no Core Data. It records calls and
    /// returns canned data.
    private final class MockSearchRepository: MediaSearchRepository {
        private(set) var musicCallCount = 0
        private(set) var moviesCallCount = 0
        private(set) var lastTerm: String?
        var stubbedTracks: [Track] = []
        var stubbedMovies: [Movie] = []

        func searchMusic(term: String) async throws -> [Track] {
            musicCallCount += 1
            lastTerm = term
            return stubbedTracks
        }
        func searchPodcasts(term: String) async throws -> [Podcast] { [] }
        func searchMovies(term: String) async throws -> [Movie] {
            moviesCallCount += 1
            lastTerm = term
            return stubbedMovies
        }
    }

    func testBlankQueryReturnsEmptyAndNeverHitsRepository() async throws {
        let repo = MockSearchRepository()
        let useCase = SearchMediaUseCase(repository: repo)

        let results = try await useCase.music(matching: "   ")

        XCTAssertEqual(results, [])
        XCTAssertEqual(repo.musicCallCount, 0, "Blank queries should short-circuit.")
    }

    func testQueryIsTrimmedBeforeReachingRepository() async throws {
        let repo = MockSearchRepository()
        repo.stubbedTracks = [
            Track(id: 1, name: "Banana Pancakes", artist: "Jack Johnson")
        ]
        let useCase = SearchMediaUseCase(repository: repo)

        let results = try await useCase.music(matching: "  jack johnson  ")

        XCTAssertEqual(repo.lastTerm, "jack johnson")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Banana Pancakes")
    }

    func testBlankMovieQueryReturnsEmptyAndNeverHitsRepository() async throws {
        let repo = MockSearchRepository()
        let useCase = SearchMediaUseCase(repository: repo)

        let results = try await useCase.movies(matching: "   ")

        XCTAssertEqual(results, [])
        XCTAssertEqual(repo.moviesCallCount, 0, "Blank queries should short-circuit.")
    }

    func testMovieQueryIsTrimmedBeforeReachingRepository() async throws {
        let repo = MockSearchRepository()
        repo.stubbedMovies = [
            Movie(id: 1, title: "Star Wars", artist: "Lucasfilm")
        ]
        let useCase = SearchMediaUseCase(repository: repo)

        let results = try await useCase.movies(matching: "  star wars  ")

        XCTAssertEqual(repo.lastTerm, "star wars")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Star Wars")
    }
}

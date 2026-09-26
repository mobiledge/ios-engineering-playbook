@testable import Medley

/// A `SearchClient` that answers with whatever the test sets, and records what it was asked.
///
/// `whileSearching` runs after the request is made but before it answers — the moment a
/// real user is staring at the screen — so a test can look at the view model mid-search.
final class FakeSearchClient: SearchClient, @unchecked Sendable {
    /// What every search returns or throws.
    var result: Result<[Track], SearchError>
    /// Runs while a search is in flight, on the main actor.
    var whileSearching: (@MainActor () -> Void)?
    /// Every term searched, in order.
    private(set) var searchedTerms: [String] = []

    init(result: Result<[Track], SearchError> = .success([])) {
        self.result = result
    }

    func searchSongs(matching term: String) async throws -> [Track] {
        searchedTerms.append(term)
        if let whileSearching {
            await whileSearching()
        }
        return try result.get()
    }
}

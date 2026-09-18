import Foundation

/// A small piece of business logic that belongs to the domain: validate and
/// normalize a search query, then delegate to whatever `MediaSearchRepository`
/// it was given.
///
/// Because it depends only on the *protocol*, it can be tested with a mock
/// repository in microseconds — no network required. See `DomainTests`.
public struct SearchMediaUseCase {
    private let repository: MediaSearchRepository

    public init(repository: MediaSearchRepository) {
        self.repository = repository
    }

    public func music(matching query: String) async throws -> [Track] {
        guard let term = normalized(query) else { return [] }
        return try await repository.searchMusic(term: term)
    }

    public func movies(matching query: String) async throws -> [Movie] {
        guard let term = normalized(query) else { return [] }
        return try await repository.searchMovies(term: term)
    }

    public func audiobooks(matching query: String) async throws -> [Audiobook] {
        guard let term = normalized(query) else { return [] }
        return try await repository.searchAudiobooks(term: term)
    }

    /// Trims whitespace and treats an empty query as "no search".
    private func normalized(_ query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

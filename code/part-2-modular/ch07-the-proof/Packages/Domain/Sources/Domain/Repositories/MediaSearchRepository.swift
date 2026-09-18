import Foundation

/// What the domain *needs* in order to search for media — but not *how* it's done.
///
/// The domain defines this protocol; the infrastructure layer implements it
/// (e.g. against the iTunes API). This is the Dependency Rule in action:
/// the implementation depends on the domain, never the other way around.
public protocol MediaSearchRepository: Sendable {
    func searchMusic(term: String) async throws -> [Track]
    func searchMovies(term: String) async throws -> [Movie]
    func searchAudiobooks(term: String) async throws -> [Audiobook]
}

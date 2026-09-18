import Foundation
import Domain

/// The concrete `MediaSearchRepository` backed by the iTunes Search API.
///
/// It decodes DTOs and maps them to domain entities, so callers receive clean
/// `Track` / `Podcast` / `Movie` values and never touch JSON. This is what the
/// chapter calls `iTunesAPITrackRepository` — generalized to every media type.
public final class ITunesSearchRepository: MediaSearchRepository {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger: Logger

    public init(session: URLSession = .shared, logger: Logger = ConsoleLogger()) {
        self.session = session
        self.logger = logger
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func searchMusic(term: String) async throws -> [Track] {
        let dtos: [TrackDTO] = try await fetch(term: term, media: "music", entity: "song")
        return dtos.map { $0.toDomain() }
    }

    public func searchPodcasts(term: String) async throws -> [Podcast] {
        let dtos: [PodcastDTO] = try await fetch(term: term, media: "podcast", entity: "podcast")
        return dtos.map { $0.toDomain() }
    }

    public func searchMovies(term: String) async throws -> [Movie] {
        let dtos: [MovieDTO] = try await fetch(term: term, media: "movie", entity: "movie")
        return dtos.map { $0.toDomain() }
    }

    private func fetch<Item: Decodable>(term: String, media: String, entity: String) async throws -> [Item] {
        let url = Endpoints.search(term: term, media: media, entity: entity)
        logger.log("GET \(url.absoluteString)")

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(SearchResponseDTO<Item>.self, from: data).results
    }
}

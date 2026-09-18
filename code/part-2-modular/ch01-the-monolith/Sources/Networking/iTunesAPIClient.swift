import Foundation

/// Talks to the iTunes Search API.
final class iTunesAPIClient {
    static let shared = iTunesAPIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseURL = URL(string: "https://itunes.apple.com")!

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func searchMusic(term: String) async throws -> [Track] {
        // 1. Construct URL
        var components = URLComponents(
            url: baseURL.appendingPathComponent("search"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "25")
        ]
        let url = components.url!

        // 2. Construct Request
        let request = URLRequest(url: url)
        Services.logger.log("GET \(url.absoluteString)")

        // 3. Dispatch Request
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        // 4. Parse Response
        return try decoder.decode(SearchResponse<Track>.self, from: data).results
    }

    func searchPodcasts(term: String) async throws -> [Podcast] {
        // 1. Construct URL
        var components = URLComponents(
            url: baseURL.appendingPathComponent("search"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "25")
        ]
        let url = components.url!

        // 2. Construct Request
        let request = URLRequest(url: url)
        Services.logger.log("GET \(url.absoluteString)")

        // 3. Dispatch Request
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        // 4. Parse Response
        return try decoder.decode(SearchResponse<Podcast>.self, from: data).results
    }

    /// The iTunes Search API wraps every result set in a
    /// `{ "resultCount": …, "results": [...] }` envelope. This pulls out the
    /// `results` array, decoded as the element type the call site expects.
    private struct SearchResponse<T: Decodable>: Decodable {
        let results: [T]
    }
}

import Foundation

/// `SearchClient` backed by Apple's iTunes Search API.
///
/// Everything it depends on arrives through `init` — the session to send requests on,
/// the locale that picks the storefront, and whether explicit results are allowed.
/// It reaches for no globals, so a test can hand it a stubbed session and a fixed locale.
struct ITunesAPIClient: SearchClient {
    private let session: URLSession
    private let country: String
    private let allowsExplicitResults: Bool

    init(session: URLSession, locale: Locale, allowsExplicitResults: Bool) {
        self.session = session
        // The storefront is the locale's *region* ("GB"). The full identifier ("en_GB")
        // is rejected by the API with HTTP 400.
        self.country = locale.region?.identifier ?? "US"
        self.allowsExplicitResults = allowsExplicitResults
    }

    func searchSongs(matching term: String) async throws -> [Track] {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: songSearchURL(for: term))
        } catch {
            throw SearchError(transportError: error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SearchError.badStatus(http.statusCode)
        }

        do {
            return try SearchResponse.decoder.decode(SearchResponse.self, from: data).results
        } catch {
            throw SearchError.unreadableResponse(reason: String(describing: error))
        }
    }

    /// The request URL for a song search. Pure, so tests can check it without sending anything.
    func songSearchURL(for term: String) -> URL {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "explicit", value: allowsExplicitResults ? "Yes" : "No"),
        ]
        return components.url!
    }
}

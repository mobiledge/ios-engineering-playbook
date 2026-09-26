import Foundation

/// The envelope every iTunes Search API response arrives in: `{ "resultCount": …, "results": […] }`.
///
/// A wire-format detail of the iTunes API: `ITunesAPIClient` is its only caller in the app.
/// The decoding tests use `decoder` too, so they decode exactly as the client does.
struct SearchResponse: Decodable {
    let results: [Track]

    /// The one decoder for iTunes JSON. The app and the tests both decode through it,
    /// so a passing test means the app decodes the same way.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

import Foundation

/// The envelope every iTunes Search API response arrives in: `{ "resultCount": …, "results": […] }`.
///
/// It lives in `Models/` only until there is a client to own it.
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

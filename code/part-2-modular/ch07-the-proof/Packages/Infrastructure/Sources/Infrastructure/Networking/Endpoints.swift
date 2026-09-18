import Foundation

/// Builds URLs for the public iTunes Search API. Internal to the package —
/// the app never sees how requests are formed.
enum Endpoints {
    static let baseURL = URL(string: "https://itunes.apple.com")!

    static func search(term: String, media: String, entity: String? = nil, limit: Int = 25) -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("search"),
            resolvingAgainstBaseURL: false
        )!
        var items = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: media),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let entity {
            items.append(URLQueryItem(name: "entity", value: entity))
        }
        components.queryItems = items
        return components.url!
    }
}

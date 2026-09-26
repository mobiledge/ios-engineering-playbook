import Foundation

/// Everything that can go wrong with a search, in terms the app can act on.
enum SearchError: Error, Equatable {
    /// The device has no connection. Worth "check your connection" and a retry.
    case offline
    /// The request never got an HTTP answer: a timeout, DNS, TLS, or similar.
    case unreachable
    /// The API answered with a non-2xx status. 4xx means our request is wrong; 5xx means theirs is down.
    case badStatus(Int)
    /// The API answered 2xx, but the body didn't decode into our models.
    case unreadableResponse(reason: String)

    /// Classifies a failure from the transport layer (anything `URLSession` throws).
    init(transportError error: any Error) {
        switch (error as? URLError)?.code {
        case .notConnectedToInternet?, .networkConnectionLost?, .dataNotAllowed?:
            self = .offline
        default:
            self = .unreachable
        }
    }
}

extension SearchError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .offline:
            "You're offline. Check your connection and try again."
        case .unreachable:
            "The music catalog couldn't be reached. Try again in a moment."
        case .badStatus(let status) where (400..<500).contains(status):
            "Medley sent a search the catalog couldn't handle (HTTP \(status))."
        case .badStatus(let status):
            "The music catalog is unavailable right now (HTTP \(status))."
        case .unreadableResponse:
            "The music catalog sent results Medley couldn't read."
        }
    }
}

import Foundation

/// The kinds of media the app deals with. A domain concept, independent of how
/// any of them are fetched or stored.
public enum MediaType: String, CaseIterable, Hashable, Sendable {
    case music
    case movie
    case audiobook
}

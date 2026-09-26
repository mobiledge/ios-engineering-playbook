/// What the app needs from a music catalog, in the app's own terms.
///
/// Callers depend on this, never on a concrete client. It says nothing about URLs,
/// HTTP, or JSON — those are the conforming type's business.
protocol SearchClient {
    /// Songs matching `term`, in the order the catalog ranks them.
    /// - Throws: `SearchError`, and nothing else.
    func searchSongs(matching term: String) async throws -> [Track]
}

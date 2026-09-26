import Foundation
import Testing
@testable import Medley

/// `ITunesAPIClient`: the request it builds, how it maps failures, and one full round trip.
///
/// Tests cover *our* logic — query parameters, status handling, error mapping — not
/// Apple's networking. Nothing here touches the network: requests go to `StubURLProtocol`.
@Suite(.serialized)
struct ITunesAPIClientTests {
    // MARK: The request

    @Test func songSearchURLCarriesEveryQueryParameter() {
        let url = makeClient(locale: Locale(identifier: "en_US")).songSearchURL(for: "radiohead")

        #expect(url.host() == "itunes.apple.com")
        #expect(url.path() == "/search")
        #expect(queryItems(of: url) == [
            "term": "radiohead", "media": "music", "entity": "song",
            "country": "US", "limit": "50", "explicit": "No",
        ])
    }

    /// The bug that opened this chapter: the storefront is the region, not the locale identifier.
    @Test func countryIsTheLocaleRegionNotItsIdentifier() {
        let url = makeClient(locale: Locale(identifier: "en_GB")).songSearchURL(for: "radiohead")

        #expect(queryItems(of: url)["country"] == "GB")
    }

    @Test func explicitResultsFollowTheFlagItWasGiven() {
        let url = makeClient(allowsExplicitResults: true).songSearchURL(for: "radiohead")

        #expect(queryItems(of: url)["explicit"] == "Yes")
    }

    // MARK: A full round trip

    @Test func decodesTracksFromTheURLItBuilt() async throws {
        let session = StubURLProtocol.makeSession(stub: .response(status: 200, body: try fixture("track_search_response")))
        let client = makeClient(session: session)

        let tracks = try await client.searchSongs(matching: "radiohead")

        #expect(tracks.map(\.trackName) == ["Let Down", "All I Need"])
        #expect(StubURLProtocol.lastRequest?.url == client.songSearchURL(for: "radiohead"))
    }

    // MARK: Failures

    @Test(arguments: [400, 404, 500, 503])
    func non2xxStatusBecomesBadStatus(status: Int) async {
        let client = makeClient(session: StubURLProtocol.makeSession(stub: .response(status: status, body: Data())))

        await #expect(throws: SearchError.badStatus(status)) {
            try await client.searchSongs(matching: "radiohead")
        }
    }

    @Test(arguments: [
        (URLError.Code.notConnectedToInternet, SearchError.offline),
        (.networkConnectionLost, .offline),
        (.timedOut, .unreachable),
        (.cannotFindHost, .unreachable),
    ])
    func transportFailuresAreClassified(code: URLError.Code, expected: SearchError) async {
        let client = makeClient(session: StubURLProtocol.makeSession(stub: .failure(URLError(code))))

        await #expect(throws: expected) {
            try await client.searchSongs(matching: "radiohead")
        }
    }

    @Test func a200WithAnUndecodableBodyIsUnreadable() async {
        let body = Data("<html>Service Unavailable</html>".utf8)
        let client = makeClient(session: StubURLProtocol.makeSession(stub: .response(status: 200, body: body)))

        let error = await #expect(throws: SearchError.self) {
            try await client.searchSongs(matching: "radiohead")
        }
        guard case .unreadableResponse = error else {
            Issue.record("expected .unreadableResponse, got \(String(describing: error))")
            return
        }
    }

    /// 4xx is our fault and 5xx is theirs, and the message the user reads says so.
    @Test func statusMessagesBlameTheRightSide() {
        #expect(SearchError.badStatus(400).localizedDescription.contains("Medley sent a search"))
        #expect(SearchError.badStatus(503).localizedDescription.contains("unavailable right now"))
    }
}

// MARK: - Helpers

private func makeClient(
    session: URLSession = StubURLProtocol.makeSession(stub: .failure(URLError(.resourceUnavailable))),
    locale: Locale = Locale(identifier: "en_US"),
    allowsExplicitResults: Bool = false
) -> ITunesAPIClient {
    ITunesAPIClient(session: session, locale: locale, allowsExplicitResults: allowsExplicitResults)
}

private func queryItems(of url: URL) -> [String: String] {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
}

private func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle(for: StubURLProtocol.self).url(forResource: name, withExtension: "json"))
    return try Data(contentsOf: url)
}

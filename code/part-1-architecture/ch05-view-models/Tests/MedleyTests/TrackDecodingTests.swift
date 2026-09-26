import Foundation
import Testing
@testable import Medley

/// `Track` decoding, run against fixtures saved from real iTunes Search API responses.
///
/// A minimal fixture leaves out every optional field, the crash that paid for this
/// file has a fixture of its own, and a field that can arrive malformed has one that
/// breaks it. No network, no simulator UI.
struct TrackDecodingTests {
    @Test func decodesARealSearchResponse() throws {
        let tracks = try decode("track_search_response")

        #expect(tracks.map(\.trackName) == ["Let Down", "All I Need"])
        let letDown = try #require(tracks.first)
        #expect(letDown.trackId == 1_097_861_834)
        #expect(letDown.artistName == "Radiohead")
        #expect(letDown.collectionName == "OK Computer")
        #expect(letDown.artworkUrl100?.lastPathComponent == "100x100bb.jpg")
        #expect(letDown.releaseDate == Date(timeIntervalSince1970: 864_198_000))  // 1997-05-21T07:00:00Z
        #expect(letDown.trackTimeMillis == 299_560)
        #expect(letDown.trackViewUrl?.host() == "music.apple.com")
    }

    /// Only the three keys a result can't be shown without. Everything else is
    /// optional, so this fixture is `Track`'s contract in one file.
    @Test func minimalResultDecodesWithEveryOptionalNil() throws {
        let track = try #require(try decode("track_minimal").first)

        #expect(track.trackName == "Let Down")
        #expect(track.collectionName == nil)
        #expect(track.artworkUrl100 == nil)
        #expect(track.releaseDate == nil)
        #expect(track.trackTimeMillis == nil)
        #expect(track.trackViewUrl == nil)
    }

    /// The first crash, kept as a regression test. Chapter 1 read this key with
    /// `as! String`; a result without artwork took the whole app down.
    @Test func missingArtworkDecodesAsNil() throws {
        let track = try #require(try decode("track_missing_artwork").first)

        #expect(track.artworkUrl100 == nil)
        #expect(track.trackName == "Let Down")
    }

    /// A date without its time portion isn't ISO 8601. The boundary rejects the
    /// whole response with an error that says which result and what was wrong,
    /// instead of guessing. (Foundation's date strategy reports the result's
    /// index, not the key — the message is what names the problem.)
    @Test func malformedDateFailsWithAnErrorNamingTheResult() {
        let error = #expect(throws: DecodingError.self) {
            try decode("track_malformed_date")
        }

        guard case .dataCorrupted(let context) = error else {
            Issue.record("expected DecodingError.dataCorrupted, got \(String(describing: error))")
            return
        }
        #expect(context.codingPath.map(\.stringValue) == ["results", "Index 0"])
        #expect(context.debugDescription.contains("ISO8601"))
    }
}

/// Loads a fixture from the test bundle and decodes it exactly as the app does.
private func decode(_ fixture: String) throws -> [Track] {
    let url = try #require(Bundle(for: FixtureToken.self).url(forResource: fixture, withExtension: "json"))
    let data = try Data(contentsOf: url)
    return try SearchResponse.decoder.decode(SearchResponse.self, from: data).results
}

/// Exists only so `Bundle(for:)` can find the test bundle, where the fixtures are copied.
private final class FixtureToken {}

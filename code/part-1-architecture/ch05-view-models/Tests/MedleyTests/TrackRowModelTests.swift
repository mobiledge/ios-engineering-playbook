import Foundation
import Testing
@testable import Medley

/// `TrackRowModel(track:)`: everything a user reads in a row, checked as plain strings.
struct TrackRowModelTests {
    /// The test Chapter 1 couldn't write. Same song, same assertion.
    @Test func durationShowsAsMinutesAndSeconds() {
        let row = TrackRowModel(track: .lasting(milliseconds: 247_000))
        #expect(row.duration == "4:07")
    }

    /// Foundation's default rounds to 5:00; Apple Music shows 4:59. Truncate, like the catalog.
    @Test func durationTruncatesPartialSeconds() {
        #expect(TrackRowModel(track: .lasting(milliseconds: 299_560)).duration == "4:59")
        #expect(TrackRowModel(track: .lasting(milliseconds: 59_999)).duration == "0:59")
    }

    @Test func durationsOverAnHourKeepCountingMinutes() {
        #expect(TrackRowModel(track: .lasting(milliseconds: 5_400_000)).duration == "90:00")
    }

    @Test func aMissingDurationShowsNothing() {
        #expect(TrackRowModel(track: .lasting(milliseconds: nil)).duration == nil)
    }

    @Test func releaseYearComesFromTheDate() {
        #expect(TrackRowModel(track: .letDown).year == "1997")
    }

    /// Half an hour into 2007 in UTC is still 2006 anywhere in the Americas. The year is
    /// read in UTC, so it says 2007 on every device.
    @Test func releaseYearIsReadInUTC() throws {
        let newYear = try Date("2007-01-01T00:30:00Z", strategy: .iso8601)
        #expect(TrackRowModel(track: .released(newYear)).year == "2007")
    }

    @Test func everythingElsePassesThroughUnchanged() {
        let row = TrackRowModel(track: .letDown)

        #expect(row.id == 1_097_861_834)
        #expect(row.title == "Let Down")
        #expect(row.artist == "Radiohead")
        #expect(row.album == "OK Computer")
        #expect(row.artworkURL == Track.letDown.artworkUrl100)
        #expect(row.link == Track.letDown.trackViewUrl)
    }
}

private extension Track {
    static func lasting(milliseconds: Int?) -> Track {
        Track(trackId: 1, trackName: "Song", artistName: "Artist", collectionName: nil,
              artworkUrl100: nil, releaseDate: nil, trackTimeMillis: milliseconds, trackViewUrl: nil)
    }

    static func released(_ date: Date) -> Track {
        Track(trackId: 1, trackName: "Song", artistName: "Artist", collectionName: nil,
              artworkUrl100: nil, releaseDate: date, trackTimeMillis: nil, trackViewUrl: nil)
    }
}

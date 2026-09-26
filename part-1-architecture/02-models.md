# Chapter 2: Models

*Data becomes a type the moment it enters the app.*

Medley 1.0 goes live on the App Store on the Thursday after the weekend it was written.
The founder spends Friday watching the numbers: a few hundred downloads, and searches for everything
from Taylor Swift to Tuvan throat singing. On Saturday morning the first App Store review arrives:

> ★☆☆☆☆ **Crashes every single time**
> I searched for my cousin's band and the app just closed. Tried three times. Uninstalled.

The founder searches for the same band and gets the same result: the app vanishes to the home
screen. Nothing appears on screen and nothing prints to a console. The app is simply gone.

## Where we are

Chapter 1 left Medley as one view doing nine jobs, and argued that at that size this was correct.
Here is the project it shipped:

```text
ch01-the-prototype/
├── CLAUDE.md               # one law: structure must earn its place
├── .claude/skills/         # empty — on purpose
├── project.yml
├── Sources/
│   ├── App/MedleyApp.swift
│   └── ContentView.swift   # everything: 138 lines, nine jobs
└── Tests/MedleyTests/PlaceholderTests.swift   # proves only that the target links
```

And here is the ledger, with every row still live:

| # | Job the view is doing | Where it lives in Chapter 1 | Retired in |
|---|---|---|---|
| 1 | Parse API responses | `JSONSerialization` + six `item["…"]` casts | Ch 2 — Models |
| 2 | Talk to the network | `search()`: URL, `URLSession`, status check | Ch 3 — Networking |
| 3 | Render every pixel of the screen | one 70-line `body` | Ch 4 — View Composition |
| 4 | Shape data for display + hold screen state | seven `@State`s, inline formatting | Ch 5 — View Models |
| 5 | Be the whole app | `MedleyApp` → `ContentView`, nothing else | Ch 6 — Duplication and Abstraction |
| 6 | Define the app's look | a thumbnail size, a corner radius, a few modifiers | Ch 7 — Design Tokens |
| 7 | Decide where to go next | `openURL` inside a row's button | Ch 8 — Coordinators |
| 8 | Log, track, report, and flag | five `print`s, one hard-coded `let` | Ch 9 — Cross-Cutting Services |
| 9 | Describe the project itself | this file *is* the map | Ch 10 — Project Generation |

Chapter 1 ended by pointing at one line and saying it would be the first to go. It was.

## The pain

The crash report reaches Xcode's Organizer a day later, once enough users who share diagnostics have
hit it. Abridged, it says:

```text
Exception Type:  EXC_BREAKPOINT (SIGTRAP)
Termination Reason: Namespace SIGNAL, Code 5 Trace/BPT trap: 5

Thread 0 Crashed:
0   Medley   closure #1 in closure #2 in closure #1 in ContentView.body.getter  (ContentView.swift:31)
1   Medley   ContentView.body.getter  (ContentView.swift:21)
2   SwiftUI  …
```

Line 31 is the line Chapter 1 pointed at:

```swift
AsyncImage(url: URL(string: item["artworkUrl100"] as! String)) { image in
```

The cousin's band self-released a single, and their distributor never uploaded cover art. So
Apple's JSON for that song has no `artworkUrl100` key at all. Not an empty string or `null`; the
key is simply absent. `item["artworkUrl100"]` returns `nil`, `as! String` demands a `String`, and
Swift does exactly what `as!` promises when the promise is broken: it stops the process. A debug
build would at least print *"Unexpectedly found nil while unwrapping an Optional value."* The
release build on a stranger's phone just traps.

The cost is concrete:

- **A permanent 1-star review** on the 1.0 page, the first review anyone reads.
- **A hotfix.** Medley 1.0.1 is a one-line change, but it still needs a new build, an expedited-review
  request, and 26 hours in App Review during which every search that returns even one song
  without artwork kills the app.
- **An unknown number of silent uninstalls.** One person wrote a review. The crash report shows 212
  crashes from 61 devices.

The one-line fix is obvious: swap `as!` for `as?`. But look at why the bug existed at all. Parsing
in `ContentView` isn't one decision; it is six separate guesses about Apple's JSON, spread across
the row, each with its own idea of what to do when the guess is wrong:

| Line | Read | What happens if the key is missing |
|---|---|---|
| 25 | `item["trackViewUrl"] as? String` | the tap silently does nothing |
| 31 | `item["artworkUrl100"] as! String` | **the app crashes** |
| 40 | `item["trackName"] as? String ?? "Untitled"` | a row titled "Untitled" |
| 43 | `item["artistName"] as? String ?? "Unknown artist"` | a made-up artist |
| 44 | `item["releaseDate"] as? String` | the year disappears |
| 55 | `item["trackTimeMillis"] as? Int` | the duration disappears |

Nobody decided these six policies. Each one is whatever felt reasonable on the line where the value
happened to be needed. Fixing line 31 fixes one of them. The next person to read a new field (or the
assistant, copying the nearest example) will make a seventh guess, and nothing stops it from being
another `as!`.

## The extraction

The fix is to stop guessing six times and decide once. **Data becomes a type the moment it enters
the app.** Apple's JSON becomes a Swift type in exactly one place, where the bytes arrive, and
nothing after that point ever sees a dictionary.

Swift's `Decodable` does the work. You declare what a song *is*, and the compiler writes the
parsing:

```swift
// Sources/Models/Track.swift
import Foundation

/// A song from the iTunes Search API (`media=music`, `entity=song`).
///
/// Property names match the API's JSON keys, so decoding needs no `CodingKeys`.
/// Optionality mirrors what the API actually promises: a result can't be shown
/// without an ID, a title, and an artist, so those are required. Apple guarantees
/// nothing else, so everything else is optional and the view copes without it.
struct Track: Decodable, Identifiable {
    let trackId: Int
    let trackName: String
    let artistName: String
    /// Absent for some catalog entries. Force-casting it was the app's first crash — see `TrackDecodingTests`.
    let artworkUrl100: URL?
    let releaseDate: Date?
    let trackTimeMillis: Int?
    let trackViewUrl: URL?

    var id: Int { trackId }
}
```

Three decisions in these twenty lines are worth slowing down for.

**Honest optionality.** Each property's type states a fact about Apple's API, and every one of the
six old policies is now a single deliberate choice. `artworkUrl100` is `URL?` because the
Saturday crash proved that real responses leave it out, so the type says so and the compiler makes
every reader handle the `nil`. `trackName` and `artistName` go the other way. Chapter 1 papered over
a missing title with `"Untitled"`, but a nameless song isn't a result worth showing, and inventing a
title hides the problem. So they're required: if Apple ever sends a song without a name, decoding
fails and the app says so, instead of showing something made up. The rule is simple. A property is
required only if a result can't be shown without it, and optional in every other case. What's not
allowed is the in-between: an optional field force-unwrapped, or a required one quietly defaulted.

**Only the fields something uses.** Apple sends 31 keys per song: prices, disc numbers, censored
titles, three artwork sizes. `Track` declares the seven that `ContentView` reads, and `Decodable`
ignores the rest. Chapter 1's law still applies: a field arrives with its first caller, not before.

**Real types, raw units.** `artworkUrl100` is a `URL`, not a `String` to convert later. `releaseDate`
is a `Date`. `trackTimeMillis` stays an `Int` in milliseconds, because turning `299560` into `4:59`
is presentation, and presentation is row 4 of the ledger. That's Chapter 5's job, not this one.

`Track` is `Decodable`, not `Codable`. `Codable` is `Decodable` plus `Encodable`, and Medley never
turns a `Track` back into JSON. A type should claim only what it does. An `Encodable` conformance
nothing uses is an untested promise.

The API wraps its results in an envelope, `{ "resultCount": 2, "results": [ … ] }`, which needs a
type of its own. That type is also the right place for the one decoder that knows Apple's date
format:

```swift
// Sources/Models/SearchResponse.swift
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
```

The shared decoder is not a nicety. `JSONDecoder()` on its own expects dates as seconds since 2001,
not the ISO 8601 strings Apple sends, so a view that built its own decoder and forgot that one line
would fail *every* search. Worse, the tests would never notice if they had configured their own
decoder correctly. With one decoder used in both places, a passing test says something about the
app.

The doc comment is honest about something else too: `Models/` is a temporary home for the envelope
and the decoder. Both belong to whoever talks to the network, and in Chapter 3 that stops being the
view.

Now the view. The whole change to `search()` is one line:

```diff
-            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
-            let items = json?["results"] as? [[String: Any]] ?? []
-            print("got \(items.count) results")
+            let tracks = try SearchResponse.decoder.decode(SearchResponse.self, from: data).results
+            print("got \(tracks.count) results")
```

After that line, nothing in `ContentView` sees `Data`, JSON, or a string key. `results` becomes
`[Track]`, and the row reads properties instead of subscripts:

```diff
-    @State private var results: [[String: Any]] = []
+    @State private var results: [Track] = []
 …
-            List(results.indices, id: \.self) { index in
-                let item = results[index]
+            List(results) { track in
                 Button {
-                    if let link = item["trackViewUrl"] as? String, let url = URL(string: link) {
-                        print("opening \(link)")
+                    if let url = track.trackViewUrl {
+                        print("opening \(url)")
                         openURL(url)
                     }
 …
-                        AsyncImage(url: URL(string: item["artworkUrl100"] as! String)) { image in
+                        AsyncImage(url: track.artworkUrl100) { image in
 …
-                            Text(item["trackName"] as? String ?? "Untitled")
+                            Text(track.trackName)
 …
-                                Text(item["artistName"] as? String ?? "Unknown artist")
-                                if let released = item["releaseDate"] as? String {
-                                    Text(released.prefix(4))
+                                Text(track.artistName)
+                                if let released = track.releaseDate {
+                                    // Releases are stamped at midnight Pacific. Read the year in UTC,
+                                    // or a New Year's Day release shows last year in Hawaii.
+                                    Text(released, format: Date.FormatStyle(timeZone: .gmt).year())
                                 }
 …
-                        if let millis = item["trackTimeMillis"] as? Int {
+                        if let millis = track.trackTimeMillis {
```

The crash fix isn't a special case anywhere in that diff. `AsyncImage` already accepts an optional
`URL` and shows its placeholder for `nil`, so once the type told the truth, the crash had nowhere to
happen. `List(results)` works without an index because `Track` is `Identifiable` by `trackId`.

One line did get *longer*, and it's worth a sentence. `released.prefix(4)` read the year from the
front of a string. A `Date` is an instant, not a calendar day. Apple stamps releases at midnight
Pacific time (`1997-05-21T07:00:00Z`), so formatting the year in the user's own time zone would show
a New Year's Day release as the previous year anywhere west of California. Reading it in UTC keeps
the answer the string used to give. Moving to real types sometimes surfaces a question the string
was quietly answering for you.

## Prove it

Chapter 1 couldn't write a single real test, because there was nothing to call. Now there is:
`SearchResponse.decoder.decode(_:from:)` takes bytes and returns `[Track]`, with no view, no
network, and no simulator UI involved. That's the seam, and the tests go in while it's fresh.

The inputs are **fixtures**: real responses, saved once. The founder runs the app's own query with
`curl` (`term=radiohead`, trimmed to two results), saves it as
`Tests/MedleyTests/Fixtures/track_search_response.json`, and makes each bad case by editing a copy:

| Fixture | What it is | What it proves |
|---|---|---|
| `track_search_response.json` | the real response, untouched | the happy path decodes every field |
| `track_minimal.json` | only `trackId`, `trackName`, `artistName` | every optional really is optional |
| `track_missing_artwork.json` | the real song, artwork keys deleted | **the Saturday crash, as a test** |
| `track_malformed_date.json` | `"releaseDate": "1997-05-21"`, no time | bad data fails loudly at the boundary |

Real responses matter here. A hand-written fixture holds what you *think* Apple sends. A saved one
holds what Apple *does* send, including the 24 keys `Track` ignores, which proves that ignoring them
works.

These are the book's first tests, and they use Swift Testing (`import Testing`, `@Test`,
`#expect`), Xcode's current framework. Chapter 1's placeholder was XCTest because it had nothing
real to say. With the placeholder deleted, the project starts over on the current tool:

```swift
// Tests/MedleyTests/TrackDecodingTests.swift
import Foundation
import Testing
@testable import Medley

struct TrackDecodingTests {
    @Test func decodesARealSearchResponse() throws {
        let tracks = try decode("track_search_response")

        #expect(tracks.map(\.trackName) == ["Let Down", "All I Need"])
        let letDown = try #require(tracks.first)
        #expect(letDown.trackId == 1_097_861_834)
        #expect(letDown.artistName == "Radiohead")
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
```

```text
✔ Test decodesARealSearchResponse() passed after 0.001 seconds.
✔ Test minimalResultDecodesWithEveryOptionalNil() passed after 0.001 seconds.
✔ Test missingArtworkDecodesAsNil() passed after 0.001 seconds.
✔ Test malformedDateFailsWithAnErrorNamingTheResult() passed after 0.004 seconds.
✔ Test run with 4 tests in 1 suite passed after 0.006 seconds.
```

Four tests, six milliseconds. The Saturday crash is now `missingArtworkDecodesAsNil`, and it runs on
every build from here to the end of the book. Reintroduce an `as!` and nothing catches it, because
the view isn't tested. But reintroduce a non-optional `artworkUrl100` (the same wrong belief, stated
in the type instead) and this test fails in a millisecond.

The last test carries a small lesson of its own. Its first draft asserted that the error's coding
path ended in `releaseDate`. It failed: Foundation's date strategy reports the path to the *result*
(`results[0]`) and puts the explanation in the message. So the test now pins down what the framework
actually does, and the doc comment says so. A test that fails on your assumption about the
framework, rather than about your code, is still doing its job.

## Codify it

The standard now exists in the code. It needs to exist in writing too, or the next model (written
by the founder in a hurry, or by the assistant copying the nearest example) will be a guess again.
So this chapter writes the project's first **skill**.

Because it's the first, its shape is the template every later skill in the book copies. A skill is
one page with a fixed anatomy:

```markdown
---
name: add-model
description: Use when adding a type decoded from an iTunes Search API response, or adding or
  changing a field on an existing one (such as Track). Covers the model, its fixtures, and its
  decoding tests, which ship together.
---

# add-model

## Convention
Data becomes a type the moment it enters the app.

1. One `Decodable` struct per API payload, in `Sources/Models/`, named for the thing itself…
2. Property names are the JSON keys…
3. Optionality mirrors what the API promises…
…
7. Every model ships with fixtures and decoding tests, in the same change…
8. Adding a field to an existing model follows the same steps…

## Why
Chapter 2's first crash. The view read artwork with `item["artworkUrl100"] as! String`…

## Exemplar
`Sources/Models/Track.swift` — honest optionality, JSON-named properties, no helpers…

## Acceptance checks
- [ ] A minimal fixture with only the required keys decodes, and its test expects every
      optional property to be `nil` — including any property added in this change.
- [ ] `grep -rnE 'JSONSerialization|as! ' Sources` finds nothing.
- [ ] `xcodebuild test -scheme Medley` passes, including the new tests.
…
```

The full file is in the chapter's code folder. Each part has a job:

- **The frontmatter** is how the assistant *finds* the skill. The `description` is matched against
  the task in hand, so it names the situations ("adding a type decoded from an API response,
  or adding or changing a field"), not the contents.
- **Convention** is the rule, written so it can be followed without reading this chapter. Rule 8
  matters as much as rule 1: most model work isn't a new type, it's one more field on an old one.
- **Why** is the incident. A rule with its reason attached gets applied with judgment. A bare rule
  gets applied literally or argued with.
- **Exemplar** points at one real file that shows the rule followed. The assistant copies examples
  far more reliably than it follows prose. That's the lesson of Chapter 1's podcasts proposal, and
  here it works in our favor.
- **Acceptance checks** say how to tell the job is done. They're checks a person or a script can
  run, not adjectives.

`CLAUDE.md` gains its second law, worded as a rule with its reason, and its first skill:

```diff
 1. **We ship; structure must earn its place.** …
+2. **Data becomes a type the moment it enters the app.** Decode every API response into a
+   `Decodable` model once, where it arrives; nothing past that point reads JSON or a dictionary.
+   Model optionality on what the API really sends, and ship every model with fixture-based
+   decoding tests. We learned this from a crash: an `as!` on a missing artwork key.

 ## Skills

-Project skills live in `.claude/skills/`. There are none yet.
+Project skills live in `.claude/skills/`. Use the matching skill whenever a task falls under it.
+
+- `add-model` — add or change a type decoded from an API response, with its fixtures and tests.
```

Then the test that matters: a real request, the kind that used to produce a seventh guess. Two
friends have asked which album a song is from, so:

> **Founder:** Show the album name under the artist in each row.
>
> **Assistant:** This adds a field to an API model, so I'm following `add-model`.
>
> 1. `Track` gets `let collectionName: String?`. It's optional because nothing in the API
>    guarantees it, and a song is still showable without it.
> 2. The happy-path fixture already has `"collectionName": "OK Computer"`, since it's a saved real
>    response, so no fixture changes are needed. I've added `#expect(letDown.collectionName == "OK Computer")`
>    to `decodesARealSearchResponse` and `#expect(track.collectionName == nil)` to
>    `minimalResultDecodesWithEveryOptionalNil`.
> 3. Tests pass (4 of 4). Then the row: a `Text(album)` under the artist, shown only when present.

```diff
 struct Track: Decodable, Identifiable {
     let trackId: Int
     let trackName: String
     let artistName: String
+    let collectionName: String?
```

```diff
                                 Text(track.artistName)
+                                if let album = track.collectionName {
+                                    Text(album)
+                                }
```

Compare that with Monday's podcasts proposal in Chapter 1. Same assistant, same kind of request. The
difference is that this time there was a written standard and a real example to copy, so the field
arrived *with its test*, and the test came before the view change. The assistant didn't need to be
smarter. It needed the project to say what "done" means.

> **Tooling sidebar — skills in other assistants.** The `SKILL.md` format with `name`/`description`
> frontmatter is Claude Code's. Cursor rules, Copilot instruction files, and `AGENTS.md` sections
> take the same four parts (convention, why, exemplar, checks) with different packaging. The
> anatomy is what carries over.

## The ledger

Row 1 is the first to go.

| # | Job the view is doing | Where it lives today | Retired in |
|---|---|---|---|
| 1 | ~~Parse API responses~~ | ~~`JSONSerialization` + six `item["…"]` casts~~ → `Track` + `SearchResponse` | **Retired in this chapter** |
| 2 | Talk to the network | `search()`: URL, `URLSession`, status check | Ch 3 — Networking |
| 3 | Render every pixel of the screen | one 70-line `body` | Ch 4 — View Composition |
| 4 | Shape data for display + hold screen state | seven `@State`s, inline formatting | Ch 5 — View Models |
| 5 | Be the whole app | `MedleyApp` → `ContentView`, nothing else | Ch 6 — Duplication and Abstraction |
| 6 | Define the app's look | a thumbnail size, a corner radius, a few modifiers | Ch 7 — Design Tokens |
| 7 | Decide where to go next | `openURL` inside a row's button | Ch 8 — Coordinators |
| 8 | Log, track, report, and flag | five `print`s, one hard-coded `let` | Ch 9 — Cross-Cutting Services |
| 9 | Describe the project itself | this file *is* the map | Ch 10 — Project Generation |

## Is this worth it yet?

Yes, and it came cheap. Two files totalling 37 lines replaced one `JSONSerialization` call and six
casts. `ContentView` grew by three lines net, all of them the album name and the year's time zone. Clean
builds of Chapter 1 and Chapter 2 both take about 1.8 seconds on an M4 Pro with a warm module cache;
two small structs don't move that number. The test suite went from one test that proved nothing to
four that prove the one thing most likely to crash the app, in six milliseconds. Against that: a
1-star review that will sit on the 1.0 page forever.

The honest cost is the one the malformed-date test spells out. The boundary is strict: **one bad
result fails the whole response.** If Apple ever sends a date without its time, or a song without a
name, the user doesn't get 49 good rows and one gap; they get an error screen that says *"The data
couldn't be read because it isn't in the correct format."* That's a deliberate trade. The app
reports bad data instead of crashing on it or covering it up, and today Apple sends clean dates. If
Organizer ever shows decoding failures in the wild, the fix is to decode each result on its own and
drop the ones that fail. It's a small change at the one place decoding happens, and the fixture to
test it already exists. Until then it would be structure without a pain to justify it, and Law 1
says no.

The other cost is a rule nobody can skip: every model ships with fixtures and tests. For a
seven-field struct that's four JSON files and about 70 lines of tests, which is more test than model. It's
worth it here because the model is where Apple's data and your assumptions meet, and it's the
cheapest place in the app to catch the gap.

## The trap this leaves open

Look at where the new line sits:

```swift
private func search() async {
    …
    var components = URLComponents(string: "https://itunes.apple.com/search")!
    components.queryItems = [ … ]

    do {
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            …
        }

        let tracks = try SearchResponse.decoder.decode(SearchResponse.self, from: data).results
```

Decoding is tested now. Everything around it isn't. The endpoint, the five query parameters, the
status-code check, and the error message are still inside a SwiftUI view, where the tests from this
chapter can't reach. The HTTP-error branch has never run anywhere except on a user's phone.
`SearchResponse` sits in `Models/` with a doc comment admitting it doesn't belong there. The next
change to the *request* (a new query parameter, a different entity) will be made in the same file
as the row layout, by someone scrolling past the album name to find it.

Row 2, **networking**, is next.

## Hands-on

The code for this chapter is in
[`code/part-1-architecture/ch02-models`](../code/part-1-architecture/ch02-models/). It's the end
state, including the album name from the skill demo. You need a Mac with Xcode 16.3 or later (for
Swift Testing's `#expect(throws:)`) and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd code/part-1-architecture/ch02-models
xcodegen generate
open Medley.xcodeproj
```

Run it and search for an artist: each row now shows the album under the artist. To run the four
decoding tests (no network needed):

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

To see exactly what this chapter changed:

```bash
diff -r code/part-1-architecture/ch01-the-prototype code/part-1-architecture/ch02-models
```

### Exercises

1. **Break the contract.** Delete `"trackName"` from `track_minimal.json` and run the tests. Read
   the failure: which error case is it, and what does its coding path say? Then decide whether
   that's the behavior you want in the app. (It's the same trade as the malformed date.)
2. **Add a field with the skill.** Ask your assistant to "show each song's genre after the year"
   (`primaryGenreName`). Check its work against `add-model`'s acceptance checks: is the new property
   optional, and did the minimal test gain a `nil` expectation *before* the view changed?
3. **Audit the old policies.** For each of the six rows in the table under "The pain", find where
   that decision lives now: in a type, in the view, or nowhere. One of them moved from the view to
   the model in a way that changes what the user sees if Apple's data is bad. Which one, and is the
   new behavior better?

---

> **Next:** Chapter 3 — Networking. *The network hides behind a contract.*

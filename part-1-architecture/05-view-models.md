# Chapter 5: View Models

*Raw data never reaches a view.*

Two screenshots arrive in the same week.

The first is from the friend in London, sent from the Underground: a search that failed with no
signal, then **Try Again** tapped at the next station. The screenshot shows a spinning progress
indicator drawn *on top of* "Something Went Wrong — You're offline." Both at once, overlapping,
for as long as the retry takes.

The second is the founder's own. They searched "radiohead", got fifty songs, then searched
"radiohead live" just as the connection dropped. The error message appeared, but the fifty
Radiohead rows stayed in the list underneath it, the text of one drawn through the text of the
other.

Neither is a crash. Both make the app look broken, and both come from the same three lines.

## Where we are

Chapter 4 split the one big view into three that each draw one thing:

```text
ch04-view-composition/
├── CLAUDE.md                            # four laws; lists add-model, add-endpoint, extract-subview
├── .claude/skills/
├── project.yml
├── Sources/
│   ├── App/MedleyApp.swift              # builds the client, shows MusicSearchView
│   ├── Features/Music/
│   │   ├── MusicSearchView.swift        # seven @States, the search, the tap: 89 lines
│   │   └── TrackRow.swift               # draws a Track; formats year and duration inline
│   ├── DesignSystem/ArtworkView.swift
│   ├── Models/Track.swift
│   └── Networking/
└── Tests/MedleyTests/                   # 12 tests: decoding and the client
```

| # | Job the view is doing | Where it lives in Chapter 4 | Retired in |
|---|---|---|---|
| 1 | ~~Parse API responses~~ | ~~six `item["…"]` casts~~ → `Track` + `SearchResponse` | Ch 2 — Models |
| 2 | ~~Talk to the network~~ | ~~`search()`: URL, `URLSession`, status check~~ → `SearchClient` + `ITunesAPIClient` | Ch 3 — Networking |
| 3 | ~~Render every pixel of the screen~~ | ~~one 70-line `body`~~ → `MusicSearchView` + `TrackRow` + `ArtworkView` | Ch 4 — View Composition |
| 4 | Shape data for display + hold screen state | seven `@State`s in `MusicSearchView`; year and duration formatting in `TrackRow` | Ch 5 — View Models |
| 5 | Be the whole app | `MedleyApp` builds one client and shows `MusicSearchView` | Ch 6 — Duplication and Abstraction |
| 6 | Define the app's look | a thumbnail size and corner radius in `ArtworkView`, a few modifiers | Ch 7 — Design Tokens |
| 7 | Decide where to go next | `openURL` in `MusicSearchView`'s row button | Ch 8 — Coordinators |
| 8 | Log, track, report, and flag | four `print`s in the screen; the explicit flag, set at startup | Ch 9 — Cross-Cutting Services |
| 9 | Describe the project itself | the file tree is starting to be the map | Ch 10 — Project Generation |

Chapter 4 ended by pointing at what the views still *think* about: formatting, and which screen
state to show.

## The pain

Here is how `MusicSearchView` decides what to draw. It's the overlay on the results list:

```swift
.overlay {
    if isLoading {
        ProgressView()
    }
    if showError {
        ContentUnavailableView { … "Something Went Wrong" … Button("Try Again") { … } }
    } else if !hasSearched {
        ContentUnavailableView("Search for a Song", …)
    } else if !hasResults && !isLoading {
        ContentUnavailableView.search(text: query)
    }
}
```

And here is how the state gets set:

```swift
private func search() async {
    …
    isLoading = true
    hasSearched = true

    do {
        let tracks = try await client.searchSongs(matching: term)
        results = tracks
        hasResults = !tracks.isEmpty
        showError = false
        isLoading = false
    } catch {
        errorMessage = error.localizedDescription
        showError = true
        isLoading = false
    }
}
```

Now replay the screenshots against it.

**The retry.** The first search fails: `showError = true`. **Try Again** calls `search()`, which sets
`isLoading = true` and then waits. Nothing clears `showError` until the response arrives. The
overlay's two `if`s are independent, so while the retry is in flight both are true, and both draw.
That's Chapter 1's third exercise, answered.

**The stale results.** The first search succeeds: `results` holds fifty tracks. The second fails:
`showError = true`. Nothing clears `results`, and the list underneath the overlay is still drawing
them. The error message is drawn over fifty rows of text.

The screen has five real states: idle, loading, showing results, no results, and failed. It's
modelled with three booleans (`isLoading`, `showError`, `hasResults`), plus `hasSearched` to
tell idle from empty, and `results` and `errorMessage` alongside. Three independent booleans alone
make eight combinations for five states. The extra three aren't theoretical; the screenshots are two
of them.

Each fix is easy to write: `showError = false` at the top of `search()`, `results = []` in the
`catch`. Each fix is another assignment in the bookkeeping, and none of them can be tested. The
booleans are `private @State` properties on a SwiftUI view. There is no way to create the view, put
it in the "failed" state, trigger a retry, and look at what it's showing, short of a UI test driving
a simulator against a network you can switch off.

And one thing has been waiting since Chapter 1:

```swift
Text("\(millis / 60_000):\(String(format: "%02d", millis / 1000 % 60))")
```

The duration formatting. It moved from the mega-view to `TrackRow` in Chapter 4, and it's still an
expression inside a `Text` inside a `body`. The founder still can't write the test they wanted on
day one.

## The extraction

Both problems have the same root. The screen's **state** and the screen's **data shaping** live
inside views, the one kind of type that can't be created and inspected in a test. **Raw data never
reaches a view.** Something else holds the state, shapes the data, and hands the views values that
are ready to draw. That something is a **view model**, and it arrives in three steps.

**First, the row gets a model of its own.** Everything a user reads in a row is decided in one
initializer, as plain strings:

```swift
// Sources/Features/Music/TrackRowModel.swift
import Foundation

/// One search result, ready to draw: every value is already formatted for display.
///
/// `TrackRow` renders these and formats nothing, so everything a user reads in a row
/// is decided here, where a test can check it.
struct TrackRowModel: Identifiable, Equatable {
    let id: Int
    let title: String
    let artist: String
    let album: String?
    /// "1997".
    let year: String?
    /// "4:59".
    let duration: String?
    let artworkURL: URL?
    /// Where a tap goes. Not drawn; the list uses it.
    let link: URL?
}

extension TrackRowModel {
    init(track: Track) {
        id = track.trackId
        title = track.trackName
        artist = track.artistName
        album = track.collectionName
        // Releases are stamped at midnight Pacific. Read the year in UTC,
        // or a New Year's Day release shows last year in Hawaii.
        year = track.releaseDate?.formatted(Date.FormatStyle(timeZone: .gmt).year())
        // Truncate, like the catalog: 299,560 ms is 4:59, not 5:00.
        duration = track.trackTimeMillis.map {
            Duration.milliseconds($0)
                .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1, roundFractionalSeconds: .towardZero)))
        }
        artworkURL = track.artworkUrl100
        link = track.trackViewUrl
    }
}
```

The hand-rolled `millis / 60_000` arithmetic is gone. Foundation's `Duration` formats minutes and
seconds itself, with one catch the tests below pin down: by default it *rounds*. "Let Down" is
299,560 milliseconds, which Foundation's default shows as `5:00`, while Apple Music, and Chapter 1's
arithmetic, show `4:59`. So the rounding rule is spelled out: `.towardZero`. The plan for this
chapter once had a `Utilities/Duration+Formatting.swift` for this. Law 1 asked what pain a
`Utilities/` folder with one caller would solve, and the answer was none: Apple's formatter is the
utility.

`link` is on the row model but not in the row. The list needs it to open the song, and passing the
link down keeps `Track` out of the view entirely.

**Second, the screen's state becomes one value.** Five states, one enum, and exactly one of them at
a time:

```swift
// Sources/Features/Music/MusicSearchViewModel.swift
import Foundation
import Observation

/// The music search screen's state and behaviour, with no SwiftUI in it.
///
/// It owns the query and exactly one `ViewState`, fetches through the `SearchClient`
/// it's handed, and turns tracks into rows ready to draw. `MusicSearchView` renders
/// `state` and forwards what the user does; it decides nothing.
@Observable
@MainActor
final class MusicSearchViewModel {
    /// Everything the screen can show. One value at a time, so "loading *and* failed"
    /// or "failed over old results" can't be represented.
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([TrackRowModel])
        case empty(term: String)
        case failed(message: String)
    }

    var query = ""

    private(set) var state: ViewState

    private let client: any SearchClient

    /// - Parameter state: where the screen starts. Previews pass one; the app uses `.idle`.
    init(client: any SearchClient, state: ViewState = .idle) {
        self.client = client
        self.state = state
    }

    func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }

        print("searching for \(term)")
        state = .loading

        do {
            let tracks = try await client.searchSongs(matching: term)
            print("got \(tracks.count) results")
            state = tracks.isEmpty ? .empty(term: term) : .loaded(tracks.map(TrackRowModel.init(track:)))
        } catch {
            print("search error: \(error)")
            state = .failed(message: error.localizedDescription)
        }
    }
}
```

This is the chapter's key move, so it's worth spelling out. The results live *inside* `.loaded`,
and the message lives *inside* `.failed`. A retry sets `state = .loading`, which by construction is
not `.failed`: the spinner-over-error screenshot is no longer a bug that needs fixing, because it's
a state that can't be expressed. The same goes for the second screenshot. There's no `results`
array left over from an earlier search, because the earlier results were part of a state that has
been replaced. Two bugs weren't fixed with more bookkeeping. The bookkeeping was deleted.

The view model imports no SwiftUI. It's `@Observable`, so any view reading `state` redraws when it
changes, and `@MainActor`, because it's screen state and SwiftUI reads it on the main thread. Its
one dependency arrives through `init`, as Law 3 requires. The `state:` parameter defaults to
`.idle` for the app, and it's there for previews. More on that below.

**Third, the views go back to only drawing.** `TrackRow` takes a `TrackRowModel` instead of a
`Track`, and its two formatting expressions become `Text(year)` and `Text(duration)`. The screen
loses all seven `@State` properties and draws its state with a single `switch`:

```swift
// Sources/Features/Music/MusicSearchView.swift
struct MusicSearchView: View {
    @Bindable var viewModel: MusicSearchViewModel

    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Medley")
                .searchable(text: $viewModel.query, prompt: "Songs, artists, albums")
                .onSubmit(of: .search) {
                    Task { await viewModel.search() }
                }
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Search for a Song", systemImage: "music.note", …)
        case .loading:
            ProgressView()
        case .loaded(let rows):
            List(rows) { row in
                Button { … openURL(row.link) … } label: {
                    TrackRow(row: row)
                }
                .tint(.primary)
            }
        case .empty(let term):
            ContentUnavailableView.search(text: term)
        case .failed(let message):
            ContentUnavailableView { … Text(message) … } actions: {
                Button("Try Again") {
                    Task { await viewModel.search() }
                }
            }
        }
    }
}
```

The `.overlay` with its chain of `if`s becomes a `switch`, and the compiler checks it's exhaustive.
Add a sixth case to `ViewState` and this view doesn't build until it says what that case looks like.

Who creates the view model? Not the view. It receives one (`@Bindable`, so the search field can bind
to `query`), in the same way `TrackRow` receives its row and the client receives its session. The
app owns it:

```swift
// Sources/App/MedleyApp.swift
@main
struct MedleyApp: App {
    @State private var musicSearch = MusicSearchViewModel(client: MedleyApp.makeSearchClient())

    var body: some Scene {
        WindowGroup {
            MusicSearchView(viewModel: musicSearch)
        }
    }
    …
}
```

That's MVVM: the model (`Track`), the view model that shapes it for one screen, and views that
render what the view model says. It's arrived at without being planned, one pain at a time.

## Prove it

Here is the test from Chapter 1, exactly as the founder wrote it before they had to stop:

```swift
func testDurationShowsAsMinutesAndSeconds() {
    let row = /* a row for a 247-second song — built from what? */
    XCTAssertEqual(row.duration, "4:07")
}
```

The second line has an answer now. A row is built from a `Track`, and it has a `duration` property,
the exact name the founder guessed four chapters ago. Here is the same test in the project's Swift
Testing:

```swift
/// The test Chapter 1 couldn't write. Same song, same assertion.
@Test func durationShowsAsMinutesAndSeconds() {
    let row = TrackRowModel(track: .lasting(milliseconds: 247_000))
    #expect(row.duration == "4:07")
}
```

```text
✔ Test durationShowsAsMinutesAndSeconds() passed after 0.001 seconds.
```

It passes in a millisecond. Around it, `TrackRowModelTests` pins down each formatting decision the
founder made on purpose:

```swift
/// Foundation's default rounds to 5:00; Apple Music shows 4:59. Truncate, like the catalog.
@Test func durationTruncatesPartialSeconds() {
    #expect(TrackRowModel(track: .lasting(milliseconds: 299_560)).duration == "4:59")
    #expect(TrackRowModel(track: .lasting(milliseconds: 59_999)).duration == "0:59")
}

@Test func durationsOverAnHourKeepCountingMinutes() {
    #expect(TrackRowModel(track: .lasting(milliseconds: 5_400_000)).duration == "90:00")
}

/// Half an hour into 2007 in UTC is still 2006 anywhere in the Americas. The year is
/// read in UTC, so it says 2007 on every device.
@Test func releaseYearIsReadInUTC() throws {
    let newYear = try Date("2007-01-01T00:30:00Z", strategy: .iso8601)
    #expect(TrackRowModel(track: .released(newYear)).year == "2007")
}
```

Plus a missing duration, the year from a real date, and every pass-through field, seven tests in all.

The screen's state needs one more piece: something to stand in for the network. This is the moment
Chapter 3 said the `SearchClient` protocol was for. Nothing used it then; the view model's tests
need it now:

```swift
// Tests/MedleyTests/Support/FakeSearchClient.swift
/// A `SearchClient` that answers with whatever the test sets, and records what it was asked.
///
/// `whileSearching` runs after the request is made but before it answers — the moment a
/// real user is staring at the screen — so a test can look at the view model mid-search.
final class FakeSearchClient: SearchClient, @unchecked Sendable {
    /// What every search returns or throws.
    var result: Result<[Track], SearchError>
    /// Runs while a search is in flight, on the main actor.
    var whileSearching: (@MainActor () -> Void)?
    /// Every term searched, in order.
    private(set) var searchedTerms: [String] = []

    func searchSongs(matching term: String) async throws -> [Track] {
        searchedTerms.append(term)
        if let whileSearching {
            await whileSearching()
        }
        return try result.get()
    }
}
```

`whileSearching` is the interesting part. The first screenshot is about what the screen shows
*during* a request, and a fake that answers instantly can't show you that. So the fake runs a
closure at exactly the moment a user would be looking at a spinner. The view model is suspended
waiting for its answer, the main actor is free, and the test reads `state`. No sleeps, no
expectations with timeouts, and no flakiness. Here's the first screenshot as a regression test:

```swift
/// Chapter 1's third exercise: retrying after an error drew the spinner on top of the
/// error message. Now the retry shows loading, and only loading.
@Test func retryingAfterAFailureShowsOnlyLoading() async {
    let client = FakeSearchClient(result: .failure(.offline))
    let viewModel = MusicSearchViewModel(client: client)
    viewModel.query = "radiohead"
    await viewModel.search()

    client.result = .success([.letDown])
    var stateMidRetry: MusicSearchViewModel.ViewState?
    client.whileSearching = { stateMidRetry = viewModel.state }
    await viewModel.search()

    #expect(stateMidRetry == .loading)
    #expect(viewModel.state == .loaded([TrackRowModel(track: .letDown)]))
}
```

And the second:

```swift
/// A failure after a successful search replaces the old results; it never draws over them.
@Test func aFailureReplacesEarlierResults() async {
    let client = FakeSearchClient(result: .success([.letDown]))
    let viewModel = MusicSearchViewModel(client: client)
    viewModel.query = "radiohead"
    await viewModel.search()

    client.result = .failure(.badStatus(503))
    viewModel.query = "radiohead live"
    await viewModel.search()

    #expect(viewModel.state == .failed(message: SearchError.badStatus(503).localizedDescription))
}
```

The rest of `MusicSearchViewModelTests` walks every state and every transition a user can cause:
it starts idle, a blank query doesn't search, only `.loading` shows while a search is in flight,
results become rows (and the term is trimmed before it's sent), no results is `.empty` for the term
searched, and a failure shows the error's message. That's eight tests, one suite, run on the main
actor with no SwiftUI anywhere.

```text
✔ Test run with 27 tests in 4 suites passed after 0.041 seconds.
```

Twenty-seven tests, 15 of them new, in 41 milliseconds. None needs a network or a simulator
screen.

Then there's the gap Chapter 4 noticed and left alone: the screen's only preview needed the live
client and could only show idle. The view model's `state:` parameter closes it. A preview hands the
screen a view model parked in whichever state it wants:

```swift
#Preview("Idle")    { MusicSearchView(viewModel: .preview(.idle)) }
#Preview("Loading") { MusicSearchView(viewModel: .preview(.loading)) }
#Preview("Loaded")  { MusicSearchView(viewModel: .preview(.loaded([.letDown, .nightZombies, .bare]))) }
#Preview("Empty")   { MusicSearchView(viewModel: .preview(.empty(term: "zzzzqqq"))) }
#Preview("Failed")  {
    MusicSearchView(viewModel: .preview(.failed(message: SearchError.offline.localizedDescription)))
}
```

Five previews, one per case, none needing the network. The "Failed" preview is the first screenshot's
starting point, visible in the canvas. The preview rows (`.letDown`, `.nightZombies`, `.bare`) are
contrived `TrackRowModel`s, defined once next to the row model and shared by the screen's and the
row's previews. (They can't hide behind `#if DEBUG`: `#Preview` blocks are compiled in Release
builds too, and a Release build is how you'd find out.)

## Codify it

Law 5:

```diff
+5. **Raw data never reaches a view.** Every screen has an `@Observable` view model that owns its
+   state as one enum (never parallel `isLoading`/`showError` booleans), receives its dependencies
+   through `init`, and turns models into display models of preformatted strings. Views render the
+   state and forward what the user does; they format nothing and decide nothing. Every state and
+   every formatted value is tested through a fake. We learned this from a retry that drew a spinner
+   on top of an error, and a duration format nobody could test for four chapters.
```

The skill is the richest so far, because a view model is where the previous four chapters meet: it
receives a client (Chapter 3), maps models (Chapter 2), and feeds views that render values (Chapter
4). As before, it's portable, with no Medley in it:

```markdown
---
name: add-view-model
description: Use when a SwiftUI screen has state, loading, errors, or formatting to manage, when
  adding a new screen, or when a view is deciding what to show or how to format data. Covers the
  view model, its state enum, display models, the view's side, previews per state, and the tests,
  which ship together.
---

# add-view-model

## Best practices

**The view model**

1. **One view model per screen, `@Observable` and `@MainActor`.** …
2. **Every dependency arrives through `init`** — clients, services, clocks. Depend on protocols …
3. **One state enum, one case per real screen state** … Never parallel `isLoading` / `hasError` /
   `hasResults` booleans: three `Bool`s make eight combinations for five states, and the extra three
   are bugs ("spinner over the error", "error over stale results").
…
7. **Accept an initial state in `init`** (defaulting to idle) so previews can start the screen in
   any state without faking a dependency.

**Display models**

8. **Map domain models to display models of preformatted values** … the view formats nothing.
9. **Use the platform's formatters** … configured explicitly — rounding rule, time zone, padding —
   and don't assume their defaults match your product: check them in a test.
…

**The view**

11. **The view renders `state` with one `switch` and forwards intents** …
12. **Whoever owns the view model's lifetime creates it** … and hands it to the view.
13. **Previews: one per state case** …

**Tests ship with the view model, in the same change**

14. **Drive every state through a fake dependency** that … can run a closure *while a request is in
    flight*, so a test can assert on the state mid-request.
15. **Cover every state case and every transition a user can cause:** start, blank input,
    in-flight, success, empty, failure, retry after failure, failure after success, and clearing
    input.
…

## Acceptance checks
…
```

Rule 15 names a transition the code doesn't handle yet, "clearing input". That's the demo. Clear
the search field after a search and the old results stay on screen, under an empty search bar,
which is the kind of mismatch the enum was supposed to end. The founder asks:

> **Founder:** When I clear the search field, go back to the start screen.
>
> **Assistant:** That's screen behaviour, so I'm following `add-view-model`, with
> `MusicSearchViewModel` as the example `CLAUDE.md` points to.
>
> 1. Test first, in `MusicSearchViewModelTests`: after a successful search, setting `query` to `""`
>    must leave `state == .idle`. It fails.
> 2. The view model observes its own input: `query` gets a `didSet` that returns to `.idle` when the
>    query becomes empty. The view already binds the search field to `query`, so the ✕ button and
>    deleting the text both go through it.
> 3. 28 of 28 pass. `MusicSearchView` didn't change.

```diff
-    var query = ""
+    var query = "" {
+        didSet {
+            if query.isEmpty { state = .idle }
+        }
+    }
```

```swift
@Test func clearingTheQueryReturnsToIdle() async {
    let viewModel = MusicSearchViewModel(client: FakeSearchClient(result: .success([.letDown])))
    viewModel.query = "radiohead"
    await viewModel.search()

    viewModel.query = ""

    #expect(viewModel.state == .idle)
}
```

Four lines of behaviour, one test, and no view touched. That's what a screen change should cost
from here on.

## The ledger

| # | Job the view is doing | Where it lives today | Retired in |
|---|---|---|---|
| 1 | ~~Parse API responses~~ | ~~six `item["…"]` casts~~ → `Track` + `SearchResponse` | Ch 2 — Models |
| 2 | ~~Talk to the network~~ | ~~`search()`: URL, `URLSession`, status check~~ → `SearchClient` + `ITunesAPIClient` | Ch 3 — Networking |
| 3 | ~~Render every pixel of the screen~~ | ~~one 70-line `body`~~ → `MusicSearchView` + `TrackRow` + `ArtworkView` | Ch 4 — View Composition |
| 4 | ~~Shape data for display + hold screen state~~ | ~~seven `@State`s, inline formatting~~ → `MusicSearchViewModel` + `TrackRowModel` | **Retired in this chapter** |
| 5 | Be the whole app | `MedleyApp` builds the client and view model, shows `MusicSearchView` | Ch 6 — Duplication and Abstraction |
| 6 | Define the app's look | a thumbnail size and corner radius in `ArtworkView`, a few modifiers | Ch 7 — Design Tokens |
| 7 | Decide where to go next | `openURL` in `MusicSearchView`'s row button | Ch 8 — Coordinators |
| 8 | Log, track, report, and flag | three `print`s in the view model, one in the view; the explicit flag at startup | Ch 9 — Cross-Cutting Services |
| 9 | Describe the project itself | the file tree is starting to be the map | Ch 10 — Project Generation |

## Is this worth it yet?

Yes. This is the chapter where the structure pays for the chapters before it, but be clear about
what it cost.

What it bought: two bugs that aren't fixed but *impossible*, because the enum has no way to say
"loading and failed" or "failed over old results". Every formatted value in a row, including the
one from Chapter 1, is checked in milliseconds. Every screen state has a preview that needs no
network. And sixteen new tests cover the behaviour a user actually sees, with no simulator, no
sleeps and no network. The skill demo showed the per-change cost afterwards: four lines and a test,
with no view touched.

What it cost: two new types (`MusicSearchViewModel`, `TrackRowModel`) and a test fake, 117 lines of
production code where there were about 30 lines of `@State` and inline formatting spread across two
views. There's also some machinery to understand. `@Observable`, `@MainActor`, `@Bindable`, and a
fake with a closure that runs mid-request are four ideas a newcomer has to learn before they can
change a screen. And there's a ceremony tax on every future screen: a view model, a display model, a
fake, and a test suite, even for a screen that just shows a list. For a throwaway prototype screen
that tax is real. For the screen the whole app is built around, it's the cheapest insurance in the
book.

Notice, too, that `ViewState` is nested inside `MusicSearchViewModel` rather than shared. There's
one screen, so there's nothing to share it with. Whether the next screen should reuse it is a
judgment call, and it's the next chapter's whole subject.

## The trap this leaves open

The first friend's question from Chapter 1 has come back, from three people now: *"Could it do
podcasts too?"*

Medley is still one screen. `MedleyApp` shows `MusicSearchView`, and there's nowhere for a second
feature to go. But this time the assistant has five laws and four skills to follow, and a Music
folder that follows all of them: a view model with a state enum, a display model, a row, previews
for every state, and tests for all of it. Ask for podcasts and the path of least resistance is
clear. Copy the Music folder, rename everything, and change the query. Or, more tempting still,
"generalize" it: a `SearchViewModel<Item>`, a `MediaRowModel`, a shared `ViewState`.

One of those is right. Row 5, **being the whole app**, is next, and so is the question of which.

## Hands-on

The code for this chapter is in
[`code/part-1-architecture/ch05-view-models`](../code/part-1-architecture/ch05-view-models/). It's
the end state, including the clear-to-idle behaviour from the skill demo. You need a Mac with Xcode
16.3 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd code/part-1-architecture/ch05-view-models
xcodegen generate
open Medley.xcodeproj
```

Open `MusicSearchView.swift` and show the canvas (⌥⌘↩): five previews, one per state. Then run the
app (⌘R), search, turn Wi-Fi off, search again, turn it back on, and tap **Try Again**. You'll see
a spinner, and only a spinner. The tests:

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Twenty-eight tests in four suites, in well under a tenth of a second. To see exactly what this
chapter changed:

```bash
diff -r code/part-1-architecture/ch04-view-composition code/part-1-architecture/ch05-view-models
```

### Exercises

1. **Try to write the bug.** In `MusicSearchViewModel`, try to make the screen show a spinner and
   an error at the same time. What do you have to add to `ViewState` to express it? That's the
   enum doing its job.
2. **Change the rounding.** Remove `roundFractionalSeconds: .towardZero` and run the tests. Which
   test fails, and does its name tell you why the choice was deliberate?
3. **Find the transition the tests don't cover.** Start a search, then clear the field before the
   response arrives. Where does the screen end up? Write the test with `whileSearching` (clear
   `query` inside it), decide what *should* happen, and make it pass.

---

> **Next:** Chapter 6 — Duplication and Abstraction. *Duplication is cheaper than the wrong
> abstraction.*

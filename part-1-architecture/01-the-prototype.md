# Chapter 1: The Prototype

*Structure must earn its place.*

Friday, 9:40 p.m. The founder has spent the evening bouncing between three apps trying to remember
the name of a song, and has an idea: one search box over Apple's entire music catalog, fast and
pleasant, that drops you straight into Apple Music. They call it **Medley**. Apple's iTunes Search
API needs no key, no account, and no approval, so there is nothing standing between the idea and a
working app except a weekend.

Saturday is one SwiftUI view. Sunday is polish: an empty state, an error state, artwork, track
durations. At 11:52 p.m. on Sunday, TestFlight build 1 goes out to fourteen friends. By
Monday lunchtime nine of them have searched for something, two have sent screenshots, and one has
asked the question every product eventually hears: *"Could it do podcasts too?"*

This chapter is that weekend's code, and it is the starting line of the whole book. Every chapter
after this one takes the prototype apart one job at a time. This one doesn't take anything apart. It
does something harder: it looks at a single 138-line file doing everything, and says plainly that
**this is the right way to start**.

## The pain

There isn't any yet, and it's worth saying so out loud.

The app works. You type "radiohead", press Search, and fifty songs come back in well under a second,
each with artwork, artist, release year, and duration. Tap one and it opens in Apple Music.
The code is one `@main` struct and one view — 15 lines and 138 lines. It builds from clean in about
four seconds. There are no bug reports, because there is almost nothing to go wrong, and one person
holds all of it in their head at once.

The pain is *latent*, and it shows up on Monday in an unexpected place. The founder opens the AI
coding assistant they've been pairing with all weekend and asks for the obvious next feature:

> **Founder:** Add a podcasts screen.
>
> **Assistant:** Sure. I'll create `PodcastsView.swift` based on `ContentView`: same search bar,
> same loading, error and empty states, same row layout. I'll change the query to
> `entity=podcast`, read `collectionName` instead of `trackName`, drop the duration, and show the
> episode count. Then I'll put both screens in a `TabView`. That's about 130 new lines, most of them
> adapted from `ContentView`.

Read that answer again, because it isn't wrong. It is a faithful reading of the project. There is
exactly one example of how a screen is built here, so the assistant built another one like it: the
same seven `@State` variables, the same dictionary casts, the same inline formatting, the same
`print` statements, copied into a second file. It proposed the app's current conventions, and
those conventions are "whatever `ContentView` happens to do."

The assistant can't follow a standard nobody wrote down, and neither can the next developer. Nobody
decided that formatting happens inline, that network calls live inside views, or that parsing happens
wherever a value is needed. Those things are only true because the first file did them, and a
second file would make them look like policy.

That's the thesis of this part of the book, and it's the one sentence worth keeping from this
chapter:

> **An unwritten convention doesn't exist — not for the next developer, and not for the AI.**

The founder closes the chat without accepting the change. Podcasts can wait. For now there is
nothing to fix, but it's worth being able to see what a fix would eventually have to deal with.

## The extraction

None. This chapter extracts nothing, on purpose.

What it adds instead is a lens: the **Single Responsibility Principle**. The usual one-line version
is *a type should have one reason to change*. "Responsibility" here doesn't mean "thing it does"; it
means *a reason someone would come and edit it*. A designer asking for bigger artwork is one reason.
Apple renaming a JSON field is another. Deciding that tapping a song should open a detail screen
instead of Apple Music is a third. When those reasons all land in the same file, every change to one
of them risks all the others, and nobody can work on one without reading all of them.

Here is the whole of Medley. Read it once top to bottom, because every chapter in this part cuts a
piece out of it:

```swift
// Sources/ContentView.swift
import SwiftUI

/// The whole app: search the iTunes catalog for songs and open one in Apple Music.
///
/// Everything it takes lives in this one view — and at this size, that's the right call.
struct ContentView: View {
    @State private var query = ""
    @State private var results: [[String: Any]] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasResults = false
    @State private var hasSearched = false

    @Environment(\.openURL) private var openURL

    /// Flip to `true` once we're happy showing explicit tracks in search.
    private let allowsExplicitResults = false

    var body: some View {
        NavigationStack {
            List(results.indices, id: \.self) { index in
                let item = results[index]
                Button {
                    if let link = item["trackViewUrl"] as? String, let url = URL(string: link) {
                        print("opening \(link)")
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: item["artworkUrl100"] as! String)) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(.rect(cornerRadius: 6))

                        VStack(alignment: .leading) {
                            Text(item["trackName"] as? String ?? "Untitled")
                            Group {
                                Text(item["artistName"] as? String ?? "Unknown artist")
                                if let released = item["releaseDate"] as? String {
                                    Text(released.prefix(4))
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .lineLimit(1)

                        Spacer()

                        if let millis = item["trackTimeMillis"] as? Int {
                            Text("\(millis / 60_000):\(String(format: "%02d", millis / 1000 % 60))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(.primary)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
                if showError {
                    ContentUnavailableView {
                        Label("Something Went Wrong", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") {
                            Task { await search() }
                        }
                    }
                } else if !hasSearched {
                    ContentUnavailableView("Search for a Song", systemImage: "music.note",
                                           description: Text("Try an artist, an album, or a song title."))
                } else if !hasResults && !isLoading {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("Medley")
            .searchable(text: $query, prompt: "Songs, artists, albums")
            .onSubmit(of: .search) {
                Task { await search() }
            }
        }
    }

    private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }

        print("searching for \(term)")
        isLoading = true
        hasSearched = true

        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "explicit", value: allowsExplicitResults ? "Yes" : "No"),
        ]

        do {
            let (data, response) = try await URLSession.shared.data(from: components.url!)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                print("search failed with status \(http.statusCode)")
                errorMessage = "The music catalog is unavailable right now (HTTP \(http.statusCode))."
                showError = true
                isLoading = false
                return
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let items = json?["results"] as? [[String: Any]] ?? []
            print("got \(items.count) results")

            results = items
            hasResults = !items.isEmpty
            showError = false
            isLoading = false
        } catch {
            print("search error: \(error)")
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
```

It is not bad code. The search trims whitespace, builds its URL with `URLComponents` rather than
string concatenation, checks the HTTP status, and uses `async`/`await`. The screen leans on the
system wherever it can: a plain `List`, `ContentUnavailableView` for the idle, empty, and error
states, and default fonts and colors. For a weekend, it's tidy.

Now read it again and count the reasons it might change. The count is nine, and each one is a row
in the **responsibility ledger**, which this book keeps open until every row is retired:

1. **Parse API responses.** `JSONSerialization` on line 119, then six `item["…"]` dictionary casts
   scattered through the row (lines 25–54). The view knows the exact spelling of every field
   Apple's JSON uses.
2. **Talk to the network.** Lines 100–117: the endpoint, the query parameters, `URLSession`, and the
   status check, all inside `search()`.
3. **Render every pixel of the screen.** Lines 20–90. Five screen states and a complete result row,
   all in one 70-line `body`.
4. **Shape data for display and hold screen state.** Seven `@State` properties (lines 7–13) juggled
   by hand, including three separate booleans for "loading", "error", and "has results". Plus the
   formatting: `millis / 60_000` for minutes on line 55 and `released.prefix(4)` for a year on line
   44. And the rules for which state is showing, spelled out as boolean conditions on lines 64, 67,
   77, and 80.
5. **Be the whole app.** `MedleyApp` shows `ContentView` and nothing else. There is no second
   screen, no tab, no place for one to go. As the assistant just showed, the only way to add a
   feature is to copy this file.
6. **Define the app's look.** Very little, on purpose. Because the screen is built from system
   parts, it gets Dynamic Type, dark mode, and native spacing without a line of styling. What's left
   are the few customizations worth making (lines 30–61): a 56-point thumbnail with a 6-point corner
   radius, a gray placeholder, secondary text in `.subheadline`, and monospaced digits so durations
   line up. They're still bare numbers typed where they're used, though. Nothing says 56 is "the
   thumbnail size" rather than just this row's. This is the smallest row in the ledger today, and
   the one that grows fastest once someone other than the founder has opinions about the look.
7. **Decide where to go next.** Lines 25–27: tapping a row opens the track's `trackViewUrl` in Apple
   Music. It's a navigation decision, made inside a button's action, inside a row, inside a list.
8. **Log, track, report, and flag.** Five `print` calls are the only diagnostics: logging, error
   reporting, and usage tracking all in one. `allowsExplicitResults` on line 18 is a feature flag you
   change by editing the source and shipping a new build.
9. **Describe the project itself.** To learn what Medley is, what it depends on, and how it fits
   together, you read this file. It is the table of contents, the architecture diagram, and the
   documentation, because there is nothing else.

Nine jobs, one type. By the Single Responsibility Principle, `ContentView` should have one reason to
change, and it has nine. At this point, that's fine. The principle describes where the pressure will
come from; it doesn't say the pressure has arrived. Nothing in the chapter so far has actually cost
anybody anything.

## Prove it

The founder does want one thing on Monday: some confidence that the duration formatting is right.
`millis / 1000 % 60` inside a `String(format: "%02d", …)` is exactly the kind of expression that
shows `4:7` instead of `4:07` after a careless edit, and nobody would notice until a friend sent a
screenshot. It's a perfect first unit test: a pure input, a pure output, no network, no UI.

The project already has a `MedleyTests` target, so the founder opens a test file and starts typing:

```swift
func testDurationShowsAsMinutesAndSeconds() {
    let row = /* a row for a 247-second song — built from what? */
    XCTAssertEqual(row.duration, "4:07")
}
```

And stops, because the second line can't be written. There's no `row` to create and no function to
call. The formatting is an expression inside a `Text`, inside an `if let`, inside an `HStack`,
inside a `Button` label, inside a `List` row, inside `body`. It runs only when SwiftUI renders that
row, and it reads from a `[String: Any]` that exists only after a live network call.

What *can* you get hold of? `ContentView()`. You can create it, but its `body` is an opaque
`some View`, and you can't ask a SwiftUI view which strings it would display. The only remaining
route is a UI test: boot a simulator, launch the app, type a real query into the real search bar,
wait for Apple's live catalog to respond, then hunt the screen for a label that happens to look like
a duration. That test takes several seconds, fails whenever the network does, and depends on a song
whose length Apple could change. It doesn't test the formatting; it tests the whole world.

So here is the entire test suite for Chapter 1, in full:

```swift
// Tests/MedleyTests/PlaceholderTests.swift
import XCTest
@testable import Medley

/// The test target exists; the tests don't — yet.
///
/// The test we actually want is "a 247-second song shows as 4:07". It can't be
/// written: that formatting lives inside `ContentView.body`, on a dictionary, in
/// the middle of a `List` row. There is nothing to call and nothing to assert on.
///
/// So this file holds the only honest test available at this size: the app
/// target links into the test bundle and its one view can be created. It proves
/// nothing about behaviour. It stays as a promise — Chapter 2 writes the first
/// real tests, and Chapter 5 writes the one above.
final class PlaceholderTests: XCTestCase {
    func testTheAppLinksIntoTheTestBundle() {
        _ = ContentView()
    }
}
```

It passes in a millisecond and proves only that the test target is wired up. That's all the honest
test this code allows, and the doc comment says so rather than dressing it up.

The inability is the finding. **Code you can't test is usually code that's doing too many jobs to be
reached from outside.** The duration formatting can't be tested because it has no home of its own;
it's tangled into rows 3 and 4 of the ledger at once. The empty `MedleyTests` target stays in the
project as a promise. Chapter 2 writes the first real tests, and Chapter 5 comes back to this exact
test, word for word, and makes it pass.

## Codify it

There is only one standard so far, and it's the one this chapter has been arguing for: *ship first,
and don't add structure until it's paid for.* That goes into writing, because an unwritten
convention doesn't exist:

```markdown
# Medley — project rules

Medley is a media-discovery app for iOS, built in SwiftUI on Apple's keyless iTunes Search API.
Everything currently lives in `Sources/ContentView.swift`.

These are the project's laws. Follow every one of them. A law is added only when the project
has paid for it — each one records a lesson, not a preference.

## Laws

1. **We ship; structure must earn its place.** Do not introduce a type, file, folder, layer, or
   abstraction until a concrete pain in this project demands it. When a task seems to call for
   new structure, say which pain it solves; if there isn't one yet, don't add it.

## Skills

Project skills live in `.claude/skills/`. There are none yet.
```

`CLAUDE.md` sits at the root of the project, and the assistant reads it at the start of every
session. It is the project's rulebook, and the rule for the rulebook is the same as the rule for the
code: a law goes in only when the project has paid for it. Each chapter from here on adds at most
one.

Next to it goes an empty folder:

```text
ch01-the-prototype/
├── CLAUDE.md               # one law
├── .claude/
│   └── skills/             # empty — on purpose
├── project.yml
├── Sources/
│   ├── App/MedleyApp.swift
│   └── ContentView.swift   # everything else
└── Tests/MedleyTests/PlaceholderTests.swift
```

`.claude/skills/` is where the project's **skills** will live. A skill is a single page of
instructions the assistant follows when asked to do one kind of task — "add a model", "add an
endpoint", "add a route". It states the convention, explains *why* (with the incident that caused
it), points at one real file in the codebase as the example to copy, and lists the checks a finished
change has to pass. Every chapter from here on ends by writing one. By the end of Part I, "add a
podcasts screen" will be a request the assistant can carry out *in the house style, with tests* —
because by then the house style will be written down.

Today the folder is empty, because there's no house style yet. The empty folder is a promise, just
like the empty test target.

Be clear about what this law does and doesn't do. It won't make the assistant's podcasts proposal
any better. Nothing will until there's a better example to point at, and building one is what the
next five chapters do. What it prevents is the *opposite* failure. Ask an assistant to "clean up
this file" today and it may well propose a repository layer, a dependency-injection container, and
a protocol for every type, bringing in a big app's architecture because big apps are what most of
its training data looks like. The law turns the founder's judgment ("not yet") into the project's
judgment, which the assistant can read.

> **Tooling sidebar — where the rulebook lives.** This book uses Claude Code's conventions: a
> `CLAUDE.md` at the project root, and skills as `.claude/skills/<name>/SKILL.md`. Other assistants
> read the same kind of thing from different places — `AGENTS.md`, `.github/copilot-instructions.md`,
> or `.cursor/rules/`. The file names change from tool to tool; the idea (conventions written down
> where the assistant reads them, one lesson at a time) carries over unchanged.

## The ledger

The responsibility ledger opens with every row live. Each chapter in this part retires exactly one.

| # | Job the view is doing | Where it lives today | Retired in |
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

## Is this worth it yet?

No. And "no" is the correct engineering answer here, not an excuse.

Look at what the prototype costs today. It builds from clean in about 4.5 seconds and rebuilds after
an edit in about 1.2 (measured on an M4 Pro; yours will be in the same range). One person wrote
every line within the last 48 hours and can find anything in it without searching. There's one
screen, one endpoint, and no second developer to disagree with. Every one of the nine jobs is
visible on a single scroll.

Now look at what structure would cost. Pulling out a model, a client, a view model, and a design
system today means four or five new files, a handful of new names, and indirection a reader has to
follow. Worse, every one of those boundaries would be a *guess*. The founder doesn't yet know which
fields the app really needs, whether podcasts will ship, what the second screen will be, or whether
the idea survives the month. A boundary drawn before you know where the pressure comes from is
usually drawn in the wrong place, and moving a wrong boundary costs more than drawing one late.

So the prototype stays exactly as it is until something hurts. That's what "structure must earn its
place" means in practice: not *never*, but *not before there's a reason you can point at*. The
ledger is how you'll recognize that reason when it turns up. Each row is a job that will, sooner or
later, cause a specific problem, and each chapter waits for that problem before acting.

## The trap this leaves open

All of them. Every one of the nine rows is live, and any of them could be the first to go wrong.

The first one does, within the week. Look at line 31:

```swift
AsyncImage(url: URL(string: item["artworkUrl100"] as! String)) { image in
```

Every search result has artwork. Every result the founder has seen, anyway, across a weekend of
searching for bands they like. The `as!` says so with total confidence, and it's the one place in
the file where parsing is allowed to crash the app.

Row 1, **parsing**, is the first to fall. Chapter 2 starts with a crash report.

## Hands-on

The complete prototype is in
[`code/part-1-architecture/ch01-the-prototype`](../code/part-1-architecture/ch01-the-prototype/). You
need a Mac with Xcode 15 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen        # one time

cd code/part-1-architecture/ch01-the-prototype
xcodegen generate            # creates Medley.xcodeproj from project.yml
open Medley.xcodeproj
```

Pick an iOS Simulator and press **Run** (⌘R), then search for an artist. To run the (single)
test:

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

The project file is generated from `project.yml` rather than committed. Take that as given for now;
Chapter 10 explains why it matters.

### Exercises

1. **Audit the ledger yourself.** Before reading the annotations again, go through
   `ContentView.swift` with nine highlighter colors, one per ledger row. Which lines belong to more
   than one row? (Line 55 belongs to at least two.)
2. **Ask your assistant for podcasts.** Open the project in your own AI assistant and ask it to "add
   a podcasts screen." Count how many lines it proposes to copy from `ContentView`. Keep the number;
   Chapter 6 asks the same question again with five skills in place.
3. **Find the second bug.** The `as!` on line 31 is one latent bug. There's another hiding in how
   the three booleans are reset. Search for something with Wi-Fi off, turn Wi-Fi back on, and tap
   **Try Again**. What's on screen while the retry is loading? Write it down; Chapter 5 is about
   exactly that.

---

> **Next:** Chapter 2 — Models. *Data becomes a type the moment it enters the app.*

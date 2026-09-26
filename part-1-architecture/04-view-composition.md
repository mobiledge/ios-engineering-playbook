# Chapter 4: View Composition

*A view renders what it is given, and nothing else.*

The storefront fix goes out, and the friend in London sends a screenshot. This time it's the look,
not the search:

> The songs are right now! But look at this one — what's it called?

The screenshot shows a single row reading **They Are Night Zombies!! They Are Neighbors!! Th…**, a
Sufjan Stevens song whose full title runs to 88 characters. Every row in Medley shows exactly one
line of title, and long titles are cut off wherever the line ends. The founder's plan is to let
titles wrap onto a second line. That's a one-character change, and this chapter is about why it
wasn't one.

## Where we are

Chapter 3 moved the network behind a contract. The view no longer knows Apple's API exists:

```text
ch03-networking/
├── CLAUDE.md                        # three laws; lists add-model, add-endpoint
├── .claude/skills/{add-model,add-endpoint}/SKILL.md
├── project.yml
├── Sources/
│   ├── App/MedleyApp.swift          # builds the one ITunesAPIClient, hands it in
│   ├── Models/Track.swift
│   ├── Networking/                  # SearchClient, ITunesAPIClient, SearchError, SearchResponse
│   └── ContentView.swift            # the screen: 123 lines, a 70-line body
└── Tests/MedleyTests/               # 12 tests: decoding + the client, no network
```

| # | Job the view is doing | Where it lives in Chapter 3 | Retired in |
|---|---|---|---|
| 1 | ~~Parse API responses~~ | ~~six `item["…"]` casts~~ → `Track` + `SearchResponse` | Ch 2 — Models |
| 2 | ~~Talk to the network~~ | ~~`search()`: URL, `URLSession`, status check~~ → `SearchClient` + `ITunesAPIClient` | Ch 3 — Networking |
| 3 | Render every pixel of the screen | one 70-line `body` | Ch 4 — View Composition |
| 4 | Shape data for display + hold screen state | seven `@State`s, inline formatting | Ch 5 — View Models |
| 5 | Be the whole app | `MedleyApp` builds one client and shows `ContentView` | Ch 6 — Duplication and Abstraction |
| 6 | Define the app's look | a thumbnail size, a corner radius, a few modifiers | Ch 7 — Design Tokens |
| 7 | Decide where to go next | `openURL` inside a row's button | Ch 8 — Coordinators |
| 8 | Log, track, report, and flag | four `print`s in the view; the explicit flag, set at startup | Ch 9 — Cross-Cutting Services |
| 9 | Describe the project itself | this file *is* the map | Ch 10 — Project Generation |

Chapter 3 ended on row 3: every visual change to any part of the screen is an edit to the one
`body` that renders all of it.

## The pain

Here is the row, as it sits inside `ContentView`'s `body`, lines 28 to 63:

```swift
HStack(spacing: 12) {
    AsyncImage(url: track.artworkUrl100) { … }
        .frame(width: 56, height: 56)
        .clipShape(.rect(cornerRadius: 6))

    VStack(alignment: .leading) {
        Text(track.trackName)
            .font(.headline)
        Group {
            Text(track.artistName)
            if let album = track.collectionName {
                Text(album)
            }
            if let released = track.releaseDate { … }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .lineLimit(1)                          // line 54

    Spacer()
    …
}
```

The title is limited to one line, so the fix is to make the limit two:

```diff
-                        .lineLimit(1)
+                        .lineLimit(2)
```

Now look at where that modifier sits. It isn't on the title. It's on the `VStack`, and `lineLimit`,
like `font` and `foregroundStyle`, flows down into *every* view inside the container it's attached
to. Nobody decided that the title, artist, album, and year should share one line limit. It was just
the shortest place to write it on the Sunday the prototype shipped, when every value was short. The
fix does let the title wrap. It also lets every other line in the row wrap, so a Sufjan Stevens
album called *Illinois (Deluxe Edition) [Remastered, with Bonus Tracks and Alternate Takes]* now
takes two lines under the artist, and the row grows taller:

```text
┌──────────────────────────────────────────────────┐
│ ▢   They Are Night Zombies!!                     │
│     They Are Neighbors!! The…                    │
│     Sufjan Stevens                         5:09  │
│     Illinois (Deluxe Edition)                    │
│     [Remastered, with Bonus Track…               │   ← not meant to wrap
│     2005                                         │
└──────────────────────────────────────────────────┘
```

The founder didn't see that before shipping it. The reason is the more important half of this pain.
**There is no way to look at a row.** The file has one `#Preview`, and it's the whole screen: built
with the live client, starting in the idle state, showing "Search for a Song". To see a row you run
the app and type a search. To see *that* row, the one with the 88-character title and the long album
name, you need to know a search that returns it and scroll to it. Nobody does that for a
one-character change. The friend's next screenshot is how the founder finds out.

The cost is small but real: a build that made the list look broken, a second fix, and a founder who
now hesitates before touching the row at all. That hesitation matters more than the bug. The next
design request is already waiting.

## The extraction

The problem isn't `lineLimit`. The problem is that a row, one of the few things on screen with a
name, doesn't exist as a *thing*. It's lines 28 to 63 of a larger expression, sharing modifiers with
whatever happens to be nearby, and it can only be seen through the whole screen.

**A view renders what it is given, and nothing else.** So the extraction splits one view into three,
each drawing one concept from values handed to it. The first step is a pure move, with the
`lineLimit(1)` bug and all. The fix comes after, as a separate step. Moving code and changing
behavior at the same time is how you end up unsure which one broke something.

**The thumbnail** is the smallest piece and the most general. Nothing about it is specific to
tracks: it draws a square image from a URL. So it takes a `URL?` and not a `Track`, and it goes in a
folder for components that could be used anywhere:

```swift
// Sources/DesignSystem/ArtworkView.swift
import SwiftUI

/// A square artwork thumbnail. Knows nothing about tracks: give it a URL, or `nil`.
struct ArtworkView: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable()
        } placeholder: {
            Color.gray.opacity(0.2)
        }
        .frame(width: 56, height: 56)
        .clipShape(.rect(cornerRadius: 6))
    }
}
```

`Sources/DesignSystem/` is a big name for a folder with one file in it. It stays nearly that empty
until Chapter 7, when the app's look gets tokens of its own. The 56 and the 6 stay bare numbers
until then too. They're written once now, inside the one component that uses them, which is already
an improvement.

**The row** draws one search result. It takes the `Track` it's drawing, and that's all it takes:

```swift
// Sources/Features/Music/TrackRow.swift
/// One search result: artwork, title, artist, album, year, and duration.
///
/// Renders the `Track` it's given and nothing else. What happens on tap is the list's business.
struct TrackRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(url: track.artworkUrl100)

            VStack(alignment: .leading) {
                Text(track.trackName)
                    .font(.headline)
                Group { … artist, album, year … }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)

            Spacer()

            if let millis = track.trackTimeMillis { … }
        }
    }
}
```

Look at what it *doesn't* take. There's no `SearchClient`, so it can't fetch. There's no `openURL`,
so it can't decide what a tap does. That stays with the list, because deciding where to go is ledger
row 7, not the row's job. And it has no `@State`, because a row doesn't own anything; it's handed
a value and draws it. **State lives with the view that owns it**, not the view that displays it.

**The screen** keeps everything that belongs to the screen: the query, the results, the three
booleans, the search, and the tap. Its row is now one line:

```diff
             List(results) { track in
                 Button {
                     if let url = track.trackViewUrl {
                         print("opening \(url)")
                         openURL(url)
                     }
                 } label: {
-                    HStack(spacing: 12) {
-                        AsyncImage(url: track.artworkUrl100) { image in
-                        …35 lines…
-                    }
+                    TrackRow(track: track)
                 }
                 .tint(.primary)
             }
```

It also gets a new name. `ContentView` was Xcode's template name for "the whole app", and it
stopped being accurate a while ago. The file becomes
`Sources/Features/Music/MusicSearchView.swift`, named for the one feature it is. The Music folder
will have a Podcasts neighbor within two chapters. `MedleyApp` now shows `MusicSearchView(client:)`.
The name `ContentView` is retired here, and it doesn't come back.

Three views where there was one: 89 lines for the screen, about 40 for the row, about 20 for the
thumbnail. Is
that expensive? Not in the way it looks. SwiftUI views are small value types that *describe* UI,
and the framework diffs the description. Splitting a `body` into three structs costs nothing
measurable at runtime. The only costs are two more files and two more names, and in return each
piece can be read, and seen, on its own.

Now the fix the pain wanted, as its own step. In `TrackRow`, the line limits go on the views they
are meant for:

```diff
                 Text(track.trackName)
                     .font(.headline)
+                    .lineLimit(2)
                 Group { … }
                     .font(.subheadline)
                     .foregroundStyle(.secondary)
+                    .lineLimit(1)
             }
-            .lineLimit(1)
```

The title may wrap to two lines; the subtitles never wrap. The modifier's reach is now the view it
sits on, and the whole row fits on one screen, so you can see that at a glance.

## Prove it

Here the book has to be honest. **There is nothing here to unit test.** `TrackRow`, `ArtworkView`,
and the `body` of `MusicSearchView` contain no logic worth asserting on. They're descriptions of
layout: this text above that one, this modifier on that view. You could write a test that
instantiates `TrackRow` and checks it doesn't crash, but it would prove as little as Chapter 1's
placeholder did. You could add a snapshot-testing library and assert on pixels. That's a real tool
with real uses, but it brings a dependency, reference images to maintain, and failures on every
intentional change. It doesn't pay for itself at one screen. This chapter adds **no tests**, and the
count stays at Chapter 3's twelve.

What pure rendering needs isn't an assertion. It's **a fast way to look**, and SwiftUI has one:
previews. The pain was that the only preview was the whole screen, needing the network and starting
empty. `TrackRow` takes a plain `Track`, so its previews can hand it any `Track` at all, including
the ones a live search rarely shows:

```swift
// MARK: - Previews: the rows a live search rarely shows you

#Preview("Everything present") {
    List { TrackRow(track: .letDown) }
}

#Preview("Longest plausible title") {
    List { TrackRow(track: .nightZombies) }
}

#Preview("Only the required fields") {
    List { TrackRow(track: .bare) }
}

#Preview("Empty strings") {
    List { TrackRow(track: .empty) }
}

#Preview("Largest accessibility text") {
    List {
        TrackRow(track: .letDown)
        TrackRow(track: .nightZombies)
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

private extension Track {
    static let nightZombies = Track(
        trackId: 2,
        trackName: "They Are Night Zombies!! They Are Neighbors!! They Have Come Back from the Dead!! Ahhhh!",
        artistName: "Sufjan Stevens",
        collectionName: "Illinois (Deluxe Edition) [Remastered, with Bonus Tracks and Alternate Takes]",
        artworkUrl100: nil, releaseDate: Date(timeIntervalSince1970: 1_120_176_000),
        trackTimeMillis: 309_000, trackViewUrl: nil)
    // …letDown, bare, empty
}
```

These are **contrived states** on purpose. A live run shows you the data you happen to search for.
A preview shows you the data you're afraid of: the longest title, every optional field missing,
empty strings, the largest accessibility text size. The "Longest plausible title" preview is the
friend's screenshot, reproduced in the canvas with no network and no simulator, before a single
build ships. Put the naive fix back on the `VStack` and the canvas shows the album wrapping onto a
second line straight away. Put it on the title and the album stays on one line. The row is its own
feedback loop now.

`Track` gets these instances from its memberwise initializer, which Swift still generates alongside
the `Decodable` conformance. The preview data lives in a `private extension` at the bottom of the
file that uses it. It's preview scaffolding, not a fixture: Chapter 2's fixtures are saved real
responses for tests, and these are invented values for looking.

`ArtworkView` gets the same treatment: loaded artwork, and a URL that never answers, which is what
"still loading" looks like. `MusicSearchView` keeps its one preview, and that preview still needs
the live client. That's worth noticing rather than fixing. The screen is the one view here that
receives a *source* (the client) rather than *values*, so it's the one view that can't be previewed
in the states that matter: loading, failed, empty. Remember that. It comes back in Chapter 5.

And one thing to notice deliberately. The code in `TrackRow` that would be worth a test isn't
layout at all:

```swift
Text("\(millis / 60_000):\(String(format: "%02d", millis / 1000 % 60))")
```

That's Chapter 1's duration formatting, the test the founder couldn't write. It has moved from a
mega-view into a small view, and it's *still* untestable: it's an expression inside a `Text` inside
a `body`. Extracting views made rendering visible. It didn't give formatting a home. That itch is
where Chapter 5 starts.

## Codify it

The rule the row taught goes into `CLAUDE.md` as law 4:

```diff
+4. **A view renders what it is given, and nothing else.** Split screens into small views that each
+   draw one concept from values handed to them — never a client or other source. Put modifiers on
+   the narrowest view they're meant for, and give every extracted view `#Preview`s with contrived
+   states (longest text, missing data, largest type) that need no network. We learned this from a
+   one-character line-limit fix that silently reached every subtitle in the row, and could only be
+   seen with a live search.
```

The skill is for the task that will keep coming back: *a view has grown, or new UI is going onto a
screen*. It's portable like the others, with nothing about Medley in it:

```markdown
---
name: extract-subview
description: Use when a SwiftUI view's body has grown large, when a visual change to one part of a
  screen risks another, or when a new piece of UI is being added to an existing screen. Covers when
  to extract a subview, what it receives, where state and modifiers go, and the previews it ships
  with.
---

# extract-subview

## Best practices

**When to extract**

1. **Extract a concept, not a coincidence.** A subview earns its own type when it draws something
   with a name — a row, a thumbnail, a badge, an empty state — not when two stretches of code
   merely look alike.
2. **Extract when you need to see it alone.** …
3. **Small view structs are free.** …

**What it receives**

5. **Values, not sources.** A subview takes the data it draws (`let invoice: Invoice`,
   `let url: URL?`), never a client, a store, a session, or the environment object that produces
   the data. It renders what it is given, and nothing else.
6. **The narrowest type that works.** A reusable component takes primitives (`URL?`, `String`)
   rather than a feature's model, so it can be used anywhere and previewed with anything.
7. **Actions go out as closures, or stay with the parent.** …

**State and modifiers**

8. **`@State` lives with the view that owns the state**, not the view that displays it. …
9. **Put each modifier on the narrowest view it is meant for.** Environment-style modifiers
   (`lineLimit`, `font`, `foregroundStyle`, `tint`) flow into every descendant; on a container they
   silently reach views you didn't intend to change.
10. **Keep behaviour unchanged when extracting.** Move first, then change — in a separate step. …

**Previews ship with the view**

11. **Every extracted view has `#Preview`s with contrived states** — the ones a live run rarely
    shows: the longest plausible text, every optional missing, empty strings, zero values, still
    loading, the largest accessibility text size.
12. **Previews need no network or backend.** … a preview that needs a live service to show
    anything is a sign the view receives a source instead of values.
13. **Be honest about what previews are.** Pure rendering has no logic to unit test, so previews
    are the feedback loop. Don't dress them up as tests; when there *is* logic worth testing inside
    a view, that's a sign it belongs somewhere testable.

## Acceptance checks
…
```

Rule 1 is the one people get wrong in both directions. The row and the thumbnail are concepts:
they have names, and a designer would talk about them. The empty and error states in
`MusicSearchView`'s overlay could be extracted too, but today they're system
`ContentUnavailableView`s, one line each, and nobody has asked to change them. Law 1 still applies:
they get extracted when a pain asks for it.

`CLAUDE.md` lists the skill with two examples here: `TrackRow.swift` for a feature view and
`ArtworkView.swift` for a reusable component.

Then a design request the founder has been putting off: songs with no artwork show the same gray
box as artwork that's still loading, so a missing image looks like a slow connection.

> **Founder:** When a song has no artwork, show a music note instead of the gray box.
>
> **Assistant:** This is new UI on an existing screen, so I'm following `extract-subview`.
>
> 1. "No artwork" is part of the thumbnail concept, so the change goes in `ArtworkView`, not in
>    `TrackRow` or the screen. `ArtworkView` already receives a `URL?`, and `nil` *is* "no
>    artwork," so it needs no new input.
> 2. I've kept the two states distinct: a URL that's still loading shows the gray box as before; a
>    `nil` URL shows a `music.note` symbol on the same gray.
> 3. The previews now cover all three: loaded, missing, still loading. The frame and corner radius
>    stay on the outside, so both states are the same size and shape.
>
> `TrackRow` and `MusicSearchView` didn't need to change.

```diff
     var body: some View {
-        AsyncImage(url: url) { image in
-            image.resizable()
-        } placeholder: {
-            Color.gray.opacity(0.2)
-        }
+        Group {
+            if let url {
+                AsyncImage(url: url) { image in
+                    image.resizable()
+                } placeholder: {
+                    Color.gray.opacity(0.2)
+                }
+            } else {
+                Image(systemName: "music.note")
+                    .foregroundStyle(.secondary)
+                    .frame(maxWidth: .infinity, maxHeight: .infinity)
+                    .background(Color.gray.opacity(0.2))
+            }
+        }
         .frame(width: 56, height: 56)
         .clipShape(.rect(cornerRadius: 6))
     }
```

Compare it with where this change would have gone a chapter ago: somewhere in lines 28–35 of a
70-line `body`, checked by finding a search that returns a song without artwork. Here, it went into
the one view that owns the concept, and the "Only the required fields" row preview showed the music
note the moment the file saved.

## The ledger

| # | Job the view is doing | Where it lives today | Retired in |
|---|---|---|---|
| 1 | ~~Parse API responses~~ | ~~six `item["…"]` casts~~ → `Track` + `SearchResponse` | Ch 2 — Models |
| 2 | ~~Talk to the network~~ | ~~`search()`: URL, `URLSession`, status check~~ → `SearchClient` + `ITunesAPIClient` | Ch 3 — Networking |
| 3 | ~~Render every pixel of the screen~~ | ~~one 70-line `body`~~ → `MusicSearchView` + `TrackRow` + `ArtworkView` | **Retired in this chapter** |
| 4 | Shape data for display + hold screen state | seven `@State`s in `MusicSearchView`; year and duration formatting in `TrackRow` | Ch 5 — View Models |
| 5 | Be the whole app | `MedleyApp` builds one client and shows `MusicSearchView` | Ch 6 — Duplication and Abstraction |
| 6 | Define the app's look | a thumbnail size and corner radius in `ArtworkView`, a few modifiers | Ch 7 — Design Tokens |
| 7 | Decide where to go next | `openURL` in `MusicSearchView`'s row button | Ch 8 — Coordinators |
| 8 | Log, track, report, and flag | four `print`s in the screen; the explicit flag, set at startup | Ch 9 — Cross-Cutting Services |
| 9 | Describe the project itself | the file tree is starting to be the map | Ch 10 — Project Generation |

## Is this worth it yet?

Yes, and it came cheaper than it looks. The screen went from 123 lines to 89, and the row and
thumbnail together are about 70 lines of view code plus about 60 lines of previews. Nothing changed at
runtime, and the twelve tests pass untouched. In exchange, the two things on screen that change
most often, the row and the thumbnail, can each be seen in every state that matters without a
network or a simulator run. The line-limit fix and the music note both landed with their effect
visible in the canvas, and neither touched the screen.

The honest limits are about previews, not views. A preview is only as good as its contrived data:
nobody wrote a preview for a right-to-left language or a title made entirely of emoji, so nobody
has looked at those. Previews also check nothing on their own. They show you the row; you still have
to look. If Medley grew a dozen screens and a designer who cared about every pixel, snapshot tests
might start to earn their dependency. At one screen, a canvas you actually look at beats a suite of
reference images nobody updates.

And one cost carries forward: `DesignSystem/` now exists with one file in it. That's a folder named
for a future that hasn't arrived. It's here because `ArtworkView` genuinely isn't a Music-feature
view, not because the app has a design system. Chapter 7 decides whether it gets one.

## The trap this leaves open

`TrackRow` renders what it's given, but it still *thinks*. It turns milliseconds into `m:ss` and a
`Date` into a year, each inside a `Text`, and neither can be tested. And `MusicSearchView` still
holds seven `@State` properties and decides, through three independent booleans, which of five
screen states is showing:

```swift
if isLoading { ProgressView() }
if showError { … }
else if !hasSearched { … }
else if !hasResults && !isLoading { … }
```

Nothing stops `isLoading` and `showError` from being true at the same time. Chapter 1's third
exercise asked what's on screen during a retry after an error. The answer is both: a spinner on top
of the error message. The screen's one preview can't show that, because it needs the network to
reach any state but idle.

Row 4, **shaping data and holding screen state**, is next.

## Hands-on

The code for this chapter is in
[`code/part-1-architecture/ch04-view-composition`](../code/part-1-architecture/ch04-view-composition/).
It's the end state, including the music note from the skill demo. You need a Mac with Xcode 16.3 or
later and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd code/part-1-architecture/ch04-view-composition
xcodegen generate
open Medley.xcodeproj
```

Open `TrackRow.swift` and show the canvas (⌥⌘↩). Five previews render with no network. Then open
`ArtworkView.swift`: loaded, missing, and still loading. Run the app (⌘R) and search to see the
real thing. The tests are unchanged from Chapter 3:

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

To see exactly what this chapter changed:

```bash
diff -r code/part-1-architecture/ch03-networking code/part-1-architecture/ch04-view-composition
```

### Exercises

1. **Reproduce the pain in the canvas.** In `TrackRow`, move `.lineLimit(2)` back onto the `VStack`
   and watch the "Longest plausible title" preview. Then try `.font(.caption)` on the `HStack` and
   see which texts it reaches. (The duration's font changes too.)
2. **Write the preview nobody wrote.** Add a contrived state this chapter missed: a right-to-left
   title, an all-emoji title, or a 90-minute live track. Does the row hold up?
3. **Ask for an extraction that shouldn't happen.** Ask your assistant to "extract the empty state
   into its own view." Does it apply rule 1 and ask what pain that solves, or does it extract a
   one-line `ContentUnavailableView` because it was asked?

---

> **Next:** Chapter 5 — View Models. *Raw data never reaches a view.*

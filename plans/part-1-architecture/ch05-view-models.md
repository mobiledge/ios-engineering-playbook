# Chapter 5 Plan — View Models

*Raw data never reaches a view.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch04-view-composition.md`.

## Goal

Retire ledger row 4. MVVM enters. This is the book's **flagship test moment**: the test the founder
could not write in Chapter 1 gets written and passes in milliseconds.

## Start state

`ch04` end state: `MusicSearchView` (seven `@State`s, three independent `Bool`s choosing between five
screen states via an `.overlay`), `TrackRow` taking a `Track` and formatting year and duration
inline, `ArtworkView`; `MusicSearchView`'s one preview needs the live client and can only show idle;
12 tests; skills = `add-model`, `add-endpoint`, `extract-subview`; four laws.

## Prose tasks — `part-1-architecture/05-view-models.md`

- **Where we are** — ch04's ledger (rows 1–3 struck) and file tree.
- **The pain** — two screenshots from real use, both caused by the three `Bool`s (show the cause in
  code — separate `if isLoading` and `if showError` in the overlay):
  1. Chapter 1's third exercise, answered: offline search fails, connection returns, **Try Again**
     → spinner drawn *on top of* the error message, because `search()` sets `isLoading` and nothing
     clears `showError` until the response arrives.
  2. A search that fails after a successful one draws the error message *over the previous
     results*, which stay in the list underneath.
  Three `Bool`s make 8 combinations for 5 real states. The one-line fix for each is another `Bool`
  assignment, and none can be tested: the state is `private @State` inside a `View`. Tie in the
  other untestable thing, still waiting since Chapter 1: duration formatting inside `TrackRow`.
- **The extraction** —
  1. `TrackRowModel`: one result, every value preformatted (`title`, `artist`, `album?`, `year?`,
     `duration?`, `artworkURL?`, `link?`), built by `init(track:)`. Duration via Foundation's
     `Duration.formatted(.time(pattern: .minuteSecond…))`, truncating like the catalog (299,560 ms is
     4:59, not 5:00); year read in UTC. No `Utilities/` folder — Apple's formatter is the utility
     (Law 1).
  2. `MusicSearchViewModel`, `@Observable @MainActor`: owns `query` and a single nested `ViewState`
     enum (`idle / loading / loaded([TrackRowModel]) / empty(term:) / failed(message:)`) that makes
     both screenshots **unrepresentable**; fetches through the injected `SearchClient`; maps tracks
     to row models. `init(client:state:)` — the `state` parameter lets previews start anywhere.
  3. `MusicSearchView` receives the view model (`@Bindable`) and `switch`es over `state`;
     `MedleyApp` owns the view model (`@State`) and builds it with the client. `TrackRow` takes a
     `TrackRowModel` and formats nothing.
  State the law plainly: the view model shapes data for presentation; the view just renders it.
- **Prove it** — a `FakeSearchClient` (test support) drives the view model through every state; it
  can run a closure *while a search is in flight*, so the tests can look at the screen mid-search
  (the retry test is the first screenshot as a regression). Row-model tests cover formatting. Show
  Chapter 1's snippet verbatim, then the same test in Swift Testing, passing. Also: the screen's
  previews now show every state with no network (resolves Ch 4's noted limitation).
- **Codify it** — `add-view-model`, portable in the ch02 format: one state enum, dependencies through
  `init`, row models of preformatted values, the view renders and forwards intents, previews per
  state, fake-driven state + formatting tests. Law 5 in `CLAUDE.md`, skill listed with its example.
  Demo: "when I clear the search field, go back to the start screen" — lands in the view model
  (`query` observer → `.idle`) with its test first; the view doesn't change.
- **The ledger** — rows 1–4 struck, row 4 retired in this chapter.
- **Is this worth it yet?** — honest: a view model for one screen is a real layer; say what it
  bought (two bugs made impossible, formatting tested, previews for every state) and what it costs
  (the `@MainActor` + fake-with-a-closure test machinery; one more file per screen).
- **The trap this leaves open** — there is still only one feature, and podcasts are being asked for
  again; the assistant now has five skills to follow, and the obvious move is to copy the Music
  folder.
- **Hands-on** — link, build, test, exercises.

## Code tasks — `code/part-1-architecture/ch05-view-models`

Start from `ch04` verbatim, then apply the extraction above.

```manifest
+ Sources/Features/Music/MusicSearchViewModel.swift
+ Sources/Features/Music/TrackRowModel.swift
+ Tests/MedleyTests/MusicSearchViewModelTests.swift
+ Tests/MedleyTests/TrackRowModelTests.swift
+ Tests/MedleyTests/Support/FakeSearchClient.swift
+ .claude/skills/add-view-model/SKILL.md
~ Sources/Features/Music/MusicSearchView.swift
~ Sources/Features/Music/TrackRow.swift
~ Sources/App/MedleyApp.swift
~ CLAUDE.md
~ README.md
~ project.yml
```

`project.yml` changes in comments only.

## Skill — `add-view-model`

Portable best practices for a SwiftUI screen's view model: `@Observable`, main-actor, dependencies
through `init`; one state enum whose cases are the screen's real states; row/display models of
preformatted values so views format nothing; the view renders state and forwards intents; previews
per state without a network; tests drive every state through a fake dependency and assert on
formatted output.

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–4 struck through.
- [ ] Continuity equals the manifest, `~` lines included. Skill format per conventions.
- [ ] The Ch 1 "can't write this test" snippet appears verbatim in both Ch 1 and Ch 5 prose.
- [ ] Every line of the check block below passes (run from the code folder):

```check
! grep -rnE 'isLoading|showError|hasResults|hasSearched' Sources
! grep -n 'Track\b' Sources/Features/Music/TrackRow.swift
! grep -nE 'formatted|String\(format|60_000' Sources/Features/Music/TrackRow.swift Sources/Features/Music/MusicSearchView.swift
! grep -n '@State' Sources/Features/Music/MusicSearchView.swift
grep -q '@Observable' Sources/Features/Music/MusicSearchViewModel.swift
grep -q 'enum ViewState' Sources/Features/Music/MusicSearchViewModel.swift
for c in idle loading loaded empty failed; do grep -qE "case $c\b" Sources/Features/Music/MusicSearchViewModel.swift || exit 1; done
grep -q 'switch viewModel.state' Sources/Features/Music/MusicSearchView.swift
test "$(grep -c '#Preview' Sources/Features/Music/MusicSearchView.swift)" -ge 5
! test -e Sources/Utilities
test "$(grep -cE '^[0-9]+\. \*\*' CLAUDE.md)" -eq 5
grep -q '`add-view-model`' CLAUDE.md
grep -q '"4:07"' Tests/MedleyTests/TrackRowModelTests.swift
grep -qF 'let row = /* a row for a 247-second song — built from what? */' ../../../part-1-architecture/01-the-prototype.md
grep -qF 'let row = /* a row for a 247-second song — built from what? */' ../../../part-1-architecture/05-view-models.md
grep -rhE '^[[:space:]]*@Test' Tests | awk 'END { exit !(NR >= 24) }'
```

**mac**
- [ ] Builds; tests pass covering all five `ViewState` cases plus duration and date formatting;
      the view-model tests need no network and no UI.
- [ ] `MusicSearchView`'s previews render every state in the canvas without a network.

## Out of scope

- No second feature, no `TabView`, no navigation. One screen still.
- No shared/generic `ViewState` — it's nested in the one view model; whether it's shared is Ch 6's
  judgment call.
- No `Utilities/` folder.

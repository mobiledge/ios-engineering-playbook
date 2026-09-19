# Chapter 5 Plan — View Models

*Raw data never reaches a view.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch04-view-composition.md`.

## Goal

Retire ledger row 4. MVVM enters. This is the book's **flagship test moment**: the test the founder
could not write in Chapter 1 gets written verbatim and passes in milliseconds.

## Start state

`ch04` end state: decomposed views with previews; formatting and state still inside view code;
skills = `add-model`, `add-endpoint`, `extract-subview`.

## Prose tasks — `part-1-architecture/05-view-models.md`

- **The pain** — durations render as `247.0`, release dates as raw ISO strings, and three
  independent `Bool`s produce the famous "loading spinner and error message at once" screenshot.
  Show the screenshot's cause in code.
- **The extraction** — `MusicSearchViewModel`, `@Observable`: owns a single `ViewState` enum
  (`idle/loading/loaded/empty/failed`) that makes the three-Bool tangle **unrepresentable**, fetches
  through the injected `SearchClient`, and maps `Track` into a display-ready row model. State the
  law plainly: the view model shapes data for presentation; the view just renders it.
- **Prove it** — a fake `SearchClient` drives the view model through every state; assertions run on
  formatted output, no simulator. Show the Ch 1 test verbatim, now passing.
- **Codify it** — `add-view-model`, the richest skill yet: `ViewState` shape, init-injected
  dependencies, row-model mapping, and the non-negotiable fake-driven state + formatting suite.
- **The ledger** — row 4 struck through.
- **The trap** — there is still only one feature, and a request is incoming.

## Code tasks — `code/part-1-architecture/ch05-view-models`

```manifest
+ Sources/Features/Music/MusicSearchViewModel.swift
+ Sources/Features/Music/TrackRowModel.swift
+ Sources/Utilities/Duration+Formatting.swift
+ Tests/MedleyTests/MusicSearchViewModelTests.swift
+ Tests/MedleyTests/Support/FakeSearchClient.swift
+ .claude/skills/add-view-model/SKILL.md
```

**Modify** `MusicSearchView` to hold a `MusicSearchViewModel` and switch over `ViewState`; **modify**
`TrackRow` to take a `TrackRowModel` of preformatted strings rather than a `Track`.

## Skill — `add-view-model`

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–4 struck through.
- [ ] `grep -rnE 'isLoading|showError|hasResults' Sources` → 0 hits (the Bools are gone).
- [ ] `TrackRow` takes no `Track` — `grep -n 'Track\b' Sources/Features/Music/TrackRow.swift` → 0 hits.
- [ ] The Ch 1 "can't write this test" snippet appears verbatim in both Ch 1 and Ch 5 prose.

**mac**
- [ ] Builds; tests pass covering all five `ViewState` cases plus duration and date formatting;
      suite still runs in < 5s with no simulator boot for the view-model tests.

## Out of scope

- No second feature, no `TabView`, no navigation. One screen still.

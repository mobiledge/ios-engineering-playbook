# Chapter 2 Plan — Models

*Data becomes a type the moment it enters the app.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch01-the-prototype.md`.

## Goal

Retire ledger row 1 (parsing). Introduce `Codable` models decoded once at the boundary, the book's
first real tests, and its first skill — `add-model`, the template every later skill follows.

## Start state

`ch01` end state: one `ContentView` doing all nine jobs, `JSONSerialization` dictionaries,
`CLAUDE.md` with one law, empty `.claude/skills/`.

## Prose tasks — `part-1-architecture/02-models.md`

- **The pain** — the first crash, found by a user: a missing dictionary key. Show the exact
  subscript that trapped. The cost is concrete — a 1-star review and a hotfix.
- **The extraction** — `Codable` structs decoded once at the boundary. `Track` with **honest
  optionality**: `artworkUrl100` really is sometimes absent; model that, don't force-unwrap it.
  `Sources/Models/` appears. Explain why decoding at the boundary means the rest of the app never
  sees a dictionary again.
- **Prove it** — decode fixture JSON: happy case, missing artwork URL, malformed date. The crash
  becomes a regression test. These are the book's first tests and they run in milliseconds.
- **Codify it** — `add-model`, and because it is the first skill, walk through its anatomy as the
  template: convention, why (this crash), exemplar (`Track.swift`), acceptance checks (fixtures +
  decoding tests exist and pass). Then ask the assistant for the next model and watch it arrive
  *with its fixtures*.
- **The ledger** — row 1 struck through.
- **The trap** — the view still fetches.

## Code tasks — `code/part-1-architecture/ch02-models`

Start from `ch01` verbatim, then:

**Add** `Sources/Models/Track.swift`, test fixtures, and decoding tests.
**Modify** `ContentView.swift` to decode into `[Track]` instead of walking dictionaries — the
network call stays inline (that is Ch 3).

```manifest
+ Sources/Models/Track.swift
+ Tests/MedleyTests/TrackDecodingTests.swift
+ Tests/MedleyTests/Fixtures/track_search_response.json
+ Tests/MedleyTests/Fixtures/track_missing_artwork.json
+ .claude/skills/add-model/SKILL.md
- Tests/MedleyTests/PlaceholderTests.swift
```

## Skill — `add-model`

Convention: every API payload becomes a `Codable` struct decoded at the boundary; optionality
mirrors the API's real behaviour; every model ships with fixtures and decoding tests.

## Acceptance criteria

**cloud**
- [ ] All nine template headings, in order. Ledger row 1 struck through, rows 2–9 live.
- [ ] `.claude/skills/add-model/SKILL.md` exists, names its exemplar and acceptance checks.
- [ ] `grep -rn 'JSONSerialization' Sources` → 0 hits.
- [ ] `diff -qr ch01 ch02` equals this plan's manifest. Banned names → 0. Links resolve.

**mac**
- [ ] Builds; `xcodebuild … test` passes with ≥ 3 decoding tests.

## Out of scope

- No `SearchClient`, no API client type — Ch 3. The fetch stays inline in the view.

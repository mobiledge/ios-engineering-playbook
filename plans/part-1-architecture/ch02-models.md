# Chapter 2 Plan — Models

*Data becomes a type the moment it enters the app.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch01-the-prototype.md`.

## Goal

Retire ledger row 1 (parsing). Introduce `Decodable` models decoded once at the boundary, the book's
first real tests, and its first skill — `add-model`, the template every later skill follows.

## Start state

`ch01` end state: one `ContentView` doing all nine jobs, `JSONSerialization` dictionaries, the
`item["artworkUrl100"] as! String` on line 31 that ch01's trap section points at, `CLAUDE.md` with
one law, empty `.claude/skills/` (holding a `.gitkeep`), and one XCTest placeholder.

## Prose tasks — `part-1-architecture/02-models.md`

- **Where we are** — ch01's ledger (all nine rows live) and file tree.
- **The pain** — the first crash, found by a user: a search result with no `artworkUrl100` key.
  Show the exact line that trapped — the `as!` on the subscript — and the crash report pointing at
  it. The cost is concrete: a 1-star review and a hotfix.
- **The extraction** — `Decodable` structs decoded once at the boundary. Say why `Decodable` and not
  `Codable`: the app only reads, and a type should claim only what it does. `Track` with **honest
  optionality**: `artworkUrl100` really is sometimes absent, so it is `URL?` — model that, don't
  force-unwrap it. `Sources/Models/` appears with two files:
  - `Track.swift` — only the fields the view already uses: `trackId`, `trackName`, `artistName`,
    `artworkUrl100: URL?`, `releaseDate: Date?`, `trackTimeMillis: Int?`, `trackViewUrl: URL?`.
    `Identifiable` via `trackId`. No computed display helpers.
  - `SearchResponse.swift` — the API's `{ resultCount, results }` envelope, concrete
    (`let results: [Track]`, no generics until a second model exists), plus the one shared
    `static let decoder` with `.iso8601` dates. The view and the tests both decode through it, so
    the tests prove what the app does. Say plainly that this is a temporary home: Ch 3 moves the
    envelope and the decoder into the client.
  Explain why decoding at the boundary means the rest of the app never sees a dictionary again.
  Formatting stays in the view — the year and the `m:ss` duration are Ch 5's row, not this one.
- **Prove it** — decode three fixtures with Swift Testing (`import Testing`, `@Test`, `#expect`) —
  the book's first tests, and the moment the book switches from XCTest:
  1. happy case — a realistic response decodes into `[Track]` with the expected values;
  2. missing artwork — decodes, `artworkUrl100 == nil`. **The crash becomes this regression test.**
  3. malformed date — decoding **throws** `DecodingError` (`.dataCorrupted`). The boundary rejects
     bad data loudly instead of crashing deep in a view.
  They run in milliseconds.
- **Codify it** — `add-model`. Because it is the first skill, walk through its anatomy as the
  template every later skill copies: the frontmatter (`name`, `description` — what lets the
  assistant find it), then Convention, Why (this crash), Exemplar (`Sources/Models/Track.swift`),
  Acceptance checks (fixtures + decoding tests exist and pass). Then the demo: ask the assistant to
  **show the album name under the artist** and watch the skill work — it adds
  `collectionName: String?` to `Track`, adds it to the happy-path fixture, adds an assertion, and
  only then touches the view. The field lands in code. Add Law 2 to `CLAUDE.md`.
- **The ledger** — row 1 struck through, marked retired in this chapter.
- **Is this worth it yet?** — yes, and cheaply: two small files replaced six casts. Name the cost
  honestly: with a strict boundary, **one malformed date fails the whole search** (an error screen
  instead of 49 good rows). That is the right trade while the API sends clean dates; say what
  would change the answer.
- **The trap this leaves open** — the view still fetches: `URLSession`, URL building and status
  codes still live in `ContentView`.
- **Hands-on** — link to the code folder; build, run, `xcodebuild test`; exercises.

## Code tasks — `code/part-1-architecture/ch02-models`

Start from `ch01` verbatim, then:

- **Add** `Track.swift` and `SearchResponse.swift` as described above, three fixtures, and
  `TrackDecodingTests.swift` (Swift Testing). Load fixtures from the test bundle with a private
  class token (`Bundle(for: FixtureToken.self)`) — XcodeGen copies the `.json` files as resources
  flat into the bundle, so `project.yml` needs no new build phase.
- **Modify** `ContentView.swift`: `results` becomes `[Track]`, decoded with
  `SearchResponse.decoder`; the row reads properties, not subscripts; `AsyncImage` takes the
  optional URL directly. The network call stays inline (that is Ch 3). The year and duration
  formatting stay inline too (that is Ch 5). After the demo, the subtitle shows `collectionName`.
- **Modify** `CLAUDE.md`: add Law 2 — *Data becomes a type the moment it enters the app* — worded
  as a rule with its reason (the crash), and list `add-model` under Skills. Do not rewrite Law 1.
- **Modify** `README.md` and `project.yml`: chapter title, paths, file tree, and comments updated to
  ch02 (`project.yml` changes in comments only).
- **Remove** `PlaceholderTests.swift` (its promise is kept) and `.claude/skills/.gitkeep` (the
  folder is no longer empty).

```manifest
+ Sources/Models/Track.swift
+ Sources/Models/SearchResponse.swift
+ Tests/MedleyTests/TrackDecodingTests.swift
+ Tests/MedleyTests/Fixtures/track_search_response.json
+ Tests/MedleyTests/Fixtures/track_missing_artwork.json
+ Tests/MedleyTests/Fixtures/track_malformed_date.json
+ .claude/skills/add-model/SKILL.md
~ Sources/ContentView.swift
~ CLAUDE.md
~ README.md
~ project.yml
- Tests/MedleyTests/PlaceholderTests.swift
- .claude/skills/.gitkeep
```

## Skill — `add-model`

Convention: every API payload becomes a `Decodable` struct decoded at the boundary through the one
shared decoder; optionality mirrors the API's real behaviour; every model ships with fixtures and
decoding tests (happy path, each field that can be absent, each field that can be malformed).
Format per `00-conventions.md`: frontmatter, then Convention / Why / Exemplar / Acceptance checks.

## Acceptance criteria

**cloud**
- [ ] All nine template headings, in order. Ledger row 1 struck through, rows 2–9 live.
- [ ] `add-model/SKILL.md` has the frontmatter and four sections, and cites
      `Sources/Models/Track.swift` (checked by `verify.sh` for every skill).
- [ ] Continuity: the file-level diff against ch01 equals the manifest, `~` lines included.
- [ ] Banned names → 0. Links resolve. `swiftc -parse` clean.
- [ ] Every line of the check block below passes (run from the code folder):

```check
! grep -rn 'JSONSerialization' Sources
! grep -rn 'as! ' Sources
! grep -rn 'import XCTest' Tests
grep -q 'struct Track: Decodable' Sources/Models/Track.swift
! grep -rn 'Codable' Sources
grep -q 'collectionName' Sources/Models/Track.swift
grep -q 'static let decoder' Sources/Models/SearchResponse.swift
grep -q 'SearchResponse.decoder' Sources/ContentView.swift
grep -rhE '^[[:space:]]*@Test' Tests | awk 'END { exit !(NR >= 3) }'
grep -qE '^2\. ' CLAUDE.md
grep -q 'add-model' CLAUDE.md
```

**mac**
- [ ] Builds; `xcodebuild … test` passes with ≥ 3 Swift Testing decoding tests.
- [ ] A live search still shows results, including a track with no artwork (placeholder, no crash),
      and the album name under the artist.

## Out of scope

- No `SearchClient`, no API client type — Ch 3. The fetch stays inline in the view.
- No display formatting on the model (`duration`, `releaseYear`) — Ch 5.
- No `Podcast`, and no generic `SearchResponse<T>` — Ch 6 is where a second model arrives.

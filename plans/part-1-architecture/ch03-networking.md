# Chapter 3 Plan — Networking

*The network hides behind a contract.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch02-models.md`.

## Goal

Retire ledger row 2 (networking). Extract `ITunesAPIClient` behind a `SearchClient` protocol,
**handed to** whoever needs it rather than grabbed as a global — the injection law that graduates
into `CLAUDE.md` and governs the rest of the book.

## Start state

`ch02` end state: `Track` decoded at the boundary with four decoding tests; `SearchResponse` and its
shared decoder in `Sources/Models/` (a home its doc comment admits is temporary); `ContentView`
still builds the URL, calls `URLSession.shared`, and checks the status inline; the explicit-results
flag is a `let` in the view; skills = `add-model`; `CLAUDE.md` has two laws.

## Prose tasks — `part-1-architecture/03-networking.md`

- **Where we are** — ch02's ledger (row 1 struck) and file tree.
- **The pain** — UK friends tap songs and get "not available in your country": the API defaults to
  the US storefront. The fix is one `country` query item, and it lands in `ContentView.swift`, the
  file that also holds the row layout. The first attempt uses `Locale.current.identifier`
  (`en_GB`, or `en_US` on the founder's own simulator), which the API rejects with **HTTP 400** —
  verified against the live API — and the user-facing message blames Apple ("the catalog is
  unavailable"). The only way to check the URL is to run the app, switch the simulator's region,
  and search by hand. Show the diff and the cost: a one-line change that eats an afternoon of
  manual build-run-search loops, with nothing to stop the next edit from breaking it. The founder
  stashes the change: it shouldn't go in the view at all.
- **The extraction** — in the order performed:
  1. `SearchClient` — a one-method protocol in the app's terms
     (`searchSongs(matching:) async throws -> [Track]`).
  2. `ITunesAPIClient`, a struct conforming to it: URL building as a pure, testable method
     (`songSearchURL(for:)`), async/await, status-code handling, decoding through the shared
     decoder. Everything it needs arrives through `init`: the `URLSession`, the `Locale` (the
     client derives `country` from `locale.region`), and `allowsExplicitResults`. No `.shared`,
     no `Locale.current`, no globals inside the type.
  3. `SearchError` — typed errors the app can act on (`offline`, `unreachable`,
     `badStatus(Int)`, `unreadableResponse`), `LocalizedError` so the view's error text keeps
     working, and 4xx worded as *our* fault, 5xx as theirs.
  4. `SearchResponse` moves from `Models/` to `Networking/`: it's the wire envelope, and the
     client is now its only app caller. (The ch02 decoding tests still use its decoder unchanged.)
  5. `ContentView` receives `let client: any SearchClient` and calls it; `search()` shrinks to
     state handling. `MedleyApp` constructs the one `ITunesAPIClient` and hands it in; the
     explicit-results flag moves there with it.
  The extraction is behaviour-preserving: the query is exactly ch02's (no `country` yet).
  Emphasise the **hand it in, don't grab it** rule. Note that construction is quietly collecting
  at app startup — a thread Ch 9 picks up.
- **Prove it** — test *our* logic, not Apple's: the query parameters, error mapping (status codes, offline vs unreachable,
  undecodable body), and a full round trip through a stubbed `URLProtocol` that also checks the
  request the client actually sent. No network in any test. Swift Testing, with a parameterised
  test for the transport-error mapping.
- **Codify it** — `add-endpoint`, a portable skill in the ch02 format (frontmatter, Best practices,
  Acceptance checks; no project references): capability in the protocol in app terms, pure URL
  building, dependencies through `init`, typed errors, stubbed-protocol tests. Law 3 in
  `CLAUDE.md` (the injection rule), and `CLAUDE.md` lists `add-endpoint` with its example here.
  Demo: re-apply the stashed storefront fix through the skill. The founder asks for "search the
  user's own storefront"; the assistant adds `locale: Locale` to the client's `init` (handed in by
  `MedleyApp` as `.current`), derives `country` from `locale.region`, adds the `en_GB` → `GB`
  regression test and the parameter to the every-parameter test, and never opens `ContentView`.
  The change that ate an afternoon lands in minutes, with a test. The code's end state includes it.
- **The ledger** — rows 1–2 struck through, row 2 marked retired in this chapter.
- **Is this worth it yet?** — honest cost: a protocol with exactly one conformer is indirection
  today; say what it buys now (the URL is testable, errors are typed) and what it buys only later
  (a fake client for Ch 5's view model tests).
- **The trap this leaves open** — `ContentView` still renders every pixel in one `body`; a visual
  change to one part of the screen means editing the file that holds all of it.
- **Hands-on** — link, build, test, exercises.

## Code tasks — `code/part-1-architecture/ch03-networking`

Start from `ch02` verbatim, then apply the extraction above. `TrackDecodingTests` and the fixtures
stay unchanged. The client tests load `track_search_response.json` through the test bundle for the
round-trip test. `StubURLProtocol` holds static state, so the client suite is `.serialized`.

```manifest
+ Sources/Networking/SearchClient.swift
+ Sources/Networking/ITunesAPIClient.swift
+ Sources/Networking/SearchError.swift
+ Sources/Networking/SearchResponse.swift
+ Tests/MedleyTests/ITunesAPIClientTests.swift
+ Tests/MedleyTests/Support/StubURLProtocol.swift
+ .claude/skills/add-endpoint/SKILL.md
~ Sources/ContentView.swift
~ Sources/App/MedleyApp.swift
~ CLAUDE.md
~ README.md
~ project.yml
- Sources/Models/SearchResponse.swift
```

`project.yml` changes in comments only.

## Skill — `add-endpoint`

Portable best practices for adding a call to an HTTP API in a Swift app: describe the capability
in a protocol in the app's own terms; implement it in a concrete client whose dependencies all
arrive through `init`; build requests in a pure function; map transport, status, and decoding
failures into one typed error; decode through the shared decoder; test the request, the mapping,
and one round trip through a stubbed `URLProtocol`, never the network. `CLAUDE.md` names this
codebase's example.

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–2 struck through.
- [ ] Skill format per conventions (checked by `verify.sh`); `CLAUDE.md` has exactly 3 laws.
- [ ] Continuity: the file-level diff against ch02 equals the manifest, `~` lines included.
- [ ] Banned names → 0. Links resolve. `swiftc -parse` clean.
- [ ] Every line of the check block below passes (run from the code folder):

```check
! grep -nE 'URLSession|URLComponents|JSONDecoder|SearchResponse' Sources/ContentView.swift
! grep -rn '\.shared' Sources
! grep -rnE 'Locale\.current|URLSession\(' Sources/Networking
grep -q 'protocol SearchClient' Sources/Networking/SearchClient.swift
grep -q 'struct ITunesAPIClient: SearchClient' Sources/Networking/ITunesAPIClient.swift
grep -q 'enum SearchError' Sources/Networking/SearchError.swift
grep -q 'let client: any SearchClient' Sources/ContentView.swift
grep -q 'ITunesAPIClient(' Sources/App/MedleyApp.swift
test "$(grep -cE '^[0-9]+\. \*\*' CLAUDE.md)" -eq 3
grep -q '`add-endpoint`' CLAUDE.md
grep -q 'StubURLProtocol' Tests/MedleyTests/ITunesAPIClientTests.swift
grep -rhE '^[[:space:]]*@Test' Tests | awk 'END { exit !(NR >= 10) }'
```

**mac**
- [ ] Builds; tests pass, including URL-construction and error-mapping cases; no test hits the
      network.
- [ ] A live search still works; with the simulator's region set to the UK, results come from the
      GB storefront.

## Out of scope

- No view decomposition, no view model. `ContentView` is still one big view that fetches through a
  protocol.
- No fake `SearchClient` in tests — Ch 5 needs one for the view model; here the real client is
  tested through a stubbed session.
- No podcast endpoint — Ch 6.

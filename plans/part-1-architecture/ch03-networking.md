# Chapter 3 Plan — Networking

*The network hides behind a contract.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch02-models.md`.

## Goal

Retire ledger row 2 (networking). Extract `ITunesAPIClient` behind a `SearchClient` protocol,
**handed to** whoever needs it rather than grabbed as a global — the injection law that graduates
into `CLAUDE.md` and governs the rest of the book.

## Start state

`ch02` end state: `Track` decoded at the boundary with tests; `ContentView` still calls `URLSession`
inline; skills = `add-model`.

## Prose tasks — `part-1-architecture/03-networking.md`

- **The pain** — the search endpoint needs a new parameter (`limit`, or `entity=musicTrack`) and the
  change lands in *view* code. Show the diff touching a `body`.
- **The extraction** — `SearchClient` protocol + `ITunesAPIClient` conforming: URL building,
  async/await, status-code handling, typed errors (`SearchError`). Emphasise the **hand it in,
  don't grab it** rule: the client arrives through an initializer, never `.shared`. Note that this
  quietly starts concentrating construction at app startup — a thread Ch 9 picks up.
- **Prove it** — test *our* logic, not Apple's: URL and query construction, error mapping, and
  decoding through a stubbed `URLProtocol`. No network in tests.
- **Codify it** — `add-endpoint`: extend the protocol, implement in the client, map errors, test the
  URL and the decode. Add the injection law to `CLAUDE.md`.
- **The ledger** — row 2 struck through.
- **The trap** — the screen is still one 400-line view.

## Code tasks — `code/part-1-architecture/ch03-networking`

```manifest
+ Sources/Networking/SearchClient.swift
+ Sources/Networking/ITunesAPIClient.swift
+ Sources/Networking/SearchError.swift
+ Tests/MedleyTests/ITunesAPIClientTests.swift
+ Tests/MedleyTests/Support/StubURLProtocol.swift
+ .claude/skills/add-endpoint/SKILL.md
```

**Modify** `ContentView.swift` to receive a `SearchClient` and call it; `MedleyApp.swift` constructs
the concrete `ITunesAPIClient` and passes it in. **Modify** `CLAUDE.md` to add the injection law.

## Skill — `add-endpoint`

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–2 struck through.
- [ ] `grep -rn 'URLSession' Sources/ContentView.swift` → 0 hits.
- [ ] `grep -rn '\.shared' Sources` → 0 hits.
- [ ] `CLAUDE.md` has exactly 2 laws. `diff` equals manifest. Banned names → 0.

**mac**
- [ ] Builds; tests pass, including URL-construction and error-mapping cases; no test hits the network.

## Out of scope

- No view decomposition, no view model. `ContentView` is still one big view that fetches through a
  protocol.

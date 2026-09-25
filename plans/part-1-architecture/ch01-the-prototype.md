# Chapter 1 Plan — The Prototype

*Structure must earn its place.*

Read `plans/part-1-architecture/00-conventions.md` first. No prerequisite chapter.

## Goal

Write Chapter 1 and build `code/part-1-architecture/ch01-the-prototype`: Medley as a single
`ContentView` that does everything. This chapter is **honest praise for the mess** — shipping beat
structure — while introducing SRP as the book's lens and opening the responsibility ledger.

## Start state

The folder currently holds a skeleton (`project.yml` for the `Medley` target, a placeholder
`Sources/App/MedleyApp.swift`, `.gitignore`, `README.md`). Replace the placeholder with the real
one-file prototype.

## Prose tasks — `part-1-architecture/01-the-prototype.md`

Follow the template, minus "Where we are" (nothing precedes this chapter).

- **The pain** — there isn't any yet, and the chapter says so. Friday-night idea, Sunday-night
  TestFlight build. Frame the real pain as *latent*: the founder asks the assistant to "add a
  podcasts screen" and it offers to duplicate all 300 lines, because there are no standards to
  follow. Thesis: *an unwritten convention doesn't exist — not for the next developer, and not for
  the AI.*
- **The extraction** — none. This chapter extracts nothing on purpose. Instead it introduces the
  Single Responsibility Principle as the lens, and **opens the responsibility ledger** with all
  nine rows live. Show the whole `ContentView` and annotate which lines belong to which row.
- **Prove it** — the founder tries to unit-test "durations show as minutes:seconds" and **cannot**:
  there is nothing to instantiate but the entire screen. Show the test that can't be written. The
  empty `MedleyTests` target stays in the project as a promise.
- **Codify it** — seed `CLAUDE.md` with the single law so far ("we ship; structure must earn its
  place") and an empty `.claude/skills/` folder as the other promise.
- **Is this worth it yet?** — no, and that is the correct answer at 300 lines and one screen.
- **The trap this leaves open** — everything. Name the first row to fall: parsing.

## Code tasks — `code/part-1-architecture/ch01-the-prototype`

`ContentView.swift` is deliberately one file doing all nine jobs: an inline `URLSession` call,
`JSONSerialization` dictionaries (**not** `Codable` — that is Ch 2's payoff), system views and
styles with a few bare layout numbers, and a separate `Bool` for each of loading/error/empty. It
must compile and run, and search must actually work against the iTunes Search API. Make it
genuinely decent code *of its kind* — this is not a strawman.

```manifest
+ project.yml
+ CLAUDE.md
+ .claude/skills/.gitkeep
+ Sources/App/MedleyApp.swift
+ Sources/ContentView.swift
+ Tests/MedleyTests/PlaceholderTests.swift
+ README.md
- Sources/Models
- Sources/Networking
- Sources/Features
```

`project.yml` gains a `MedleyTests` unit-test target and a `Medley` scheme that runs it.

## Skill

No skill yet — `.claude/skills/` ships empty on purpose, and `CLAUDE.md` holds exactly one law. The
emptiness is the chapter's closing image.

## Acceptance criteria

**cloud**
- [ ] Prose has all template headings except "Where we are", in order.
- [ ] Ledger table present with all nine rows live (none struck through).
- [ ] `CLAUDE.md` exists with exactly one law; `.claude/skills/` exists and is empty.
- [ ] Banned-names grep → 0 hits. All markdown links resolve. `swiftc -parse` clean.

**mac**
- [ ] `xcodegen generate`; `Medley` scheme builds; app runs; music search returns live results.
- [ ] `xcodebuild … test` passes (the placeholder test target runs, even if trivial).

## Out of scope

- No `Codable`, no extracted types, no folders beyond `App/`. Every later chapter's payoff must
  still be available to extract.
- Do not touch `ch02`+ folders or `02-*.md`+ prose.

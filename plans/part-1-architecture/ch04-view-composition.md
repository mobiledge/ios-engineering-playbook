# Chapter 4 Plan — View Composition

*A view renders what it is given, and nothing else.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch03-networking.md`.

## Goal

Retire ledger row 3 (rendering every pixel). Decompose the mega-view into small view structs that
render values handed to them. This is the chapter that **refuses to fake a unit test**.

## Start state

`ch03` end state: models + injected `SearchClient`; one ~400-line `ContentView`; skills =
`add-model`, `add-endpoint`.

## Prose tasks — `part-1-architecture/04-view-composition.md`

- **The pain** — changing the artwork corner radius breaks the search-field layout, because both
  live in the same `body` and share modifiers by accident.
- **The extraction** — `MusicSearchView` owns flow; `TrackRow` and `ArtworkView` render what they
  are given. Cover where `@State` should live (with the thing that owns the state, not the thing
  that displays it) and why small view structs are free.
- **Prove it — honestly** — pure rendering has no logic to unit test, and the chapter **says so**.
  The feedback tool is previews: one per component, with contrived states (longest plausible title,
  missing artwork, empty string). Do **not** invent a snapshot-testing dependency. Then name the
  itch deliberately: *the formatting I actually want to test is still trapped in view code.* That
  itch is Ch 5's opening.
- **Codify it** — `extract-subview`: a view earns extraction when it renders a *concept*, not a
  coincidence; it receives values, not sources; every extracted view ships with contrived-state
  previews.
- **The ledger** — row 3 struck through.
- **The trap** — the view still *thinks*: formatting dates, juggling three Bools, deciding what
  "empty" means.

## Code tasks — `code/part-1-architecture/ch04-view-composition`

```manifest
+ Sources/Features/Music/MusicSearchView.swift
+ Sources/Features/Music/TrackRow.swift
+ Sources/DesignSystem/ArtworkView.swift
+ .claude/skills/extract-subview/SKILL.md
- Sources/ContentView.swift
```

`ContentView.swift` is retired into `MusicSearchView.swift` — call the rename out explicitly in
prose, since the continuity contract forbids silent disappearances. Every new view file carries a
`#Preview` with contrived states. Note that `Sources/DesignSystem/` appears here holding exactly one
generic component; it stays nearly empty until Ch 7 fills it.

## Skill — `extract-subview`

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–3 struck through.
- [ ] "Prove it" explicitly states that rendering has no unit-testable logic and uses previews.
- [ ] Every file under `Sources/Features` and `Sources/DesignSystem` contains a `#Preview`.
- [ ] No file exceeds 150 lines. `diff` equals manifest.

**mac**
- [ ] Builds; previews render; existing tests still pass (test count unchanged from Ch 3).

## Out of scope

- No view model, no `ViewState` enum, no formatting extraction — that is Ch 5's entire payoff.
- No design tokens: hex literals and magic paddings **stay** until Ch 7.

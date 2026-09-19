# Chapter 8 Plan — Coordinators

*A screen never decides where to go next.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch07-design-tokens.md`.

## Goal

Retire ledger row 7. The **C** arrives and MVVM-C is complete and named. Navigation becomes plain
logic — and therefore testable.

## Start state

`ch07` end state: two tokenised features; `NavigationLink`s hard-coded inside row views; skills
through `add-component`.

## Prose tasks — `part-1-architecture/08-coordinators.md`

- **The pain** — tap a track → detail screen; a settings sheet; and marketing wants a deep link to a
  specific track "someday". `NavigationLink`s inside row views are quietly binding screens to each
  other.
- **The extraction** — `AppCoordinator` (`@Observable`) owns the `NavigationStack` path and sheet
  state per tab. Views stop navigating and start **reporting intent** ("user tapped a track") via
  closures the coordinator wires. Destinations become a `Destination` enum the coordinator maps to
  screens. State the completed pattern: view models present, views render, the coordinator steers —
  **this is MVVM-C**.
- **Sidebar (the one permitted UIKit mention)** — `AppCoordinator` is SwiftUI's answer to UIKit's
  Coordinator pattern. One short sidebar. Nowhere else in Part I may UIKit appear.
- **Prove it** — navigation is now just logic: assert that an intent appends the right destination,
  that dismissal pops it, and that a deep-link URL parses to the right route. No simulator.
- **Codify it** — `add-route`: new destination = enum case + coordinator mapping + intent closure +
  route and deep-link tests. `CLAUDE.md` gains "views never construct destinations".
- **The ledger** — row 7 struck through.
- **The trap** — debugging is still `print("here 3")`, and the app has no idea what users do.

## Code tasks — `code/part-1-architecture/ch08-coordinators`

```manifest
+ Sources/App/AppCoordinator.swift
+ Sources/App/Destination.swift
+ Sources/App/DeepLink.swift
+ Sources/Features/Music/TrackDetailView.swift
+ Sources/Features/Settings/SettingsView.swift
+ Tests/MedleyTests/AppCoordinatorTests.swift
+ Tests/MedleyTests/DeepLinkTests.swift
+ .claude/skills/add-route/SKILL.md
```

**Modify** `RootView` to own the coordinator and drive a `NavigationStack` per tab; **modify**
`TrackRow`/`PodcastRow` to take an `onTap` closure instead of wrapping themselves in a
`NavigationLink`.

## Skill — `add-route`

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–7 struck through.
- [ ] `grep -rn 'NavigationLink' Sources/Features` → 0 hits.
- [ ] Exactly one UIKit mention in all of Part I prose, and it is the Ch 8 sidebar.
- [ ] `CLAUDE.md` has the "views never construct destinations" law.

**mac**
- [ ] Builds; tap-through to detail works; settings sheet presents; tests cover push, pop, and
      deep-link parsing.

## Out of scope

- No services or analytics (Ch 9). No `project.yml` restructuring (Ch 10).

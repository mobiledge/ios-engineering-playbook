# Chapter 2 Plan — Extracting the Design System

Read `plans/00-conventions.md` first. Prerequisite: `plans/ch01-the-monolith.md` completed.

## Goal

Bring Chapter 2 onto the chapter template and the company narrative; verify the ch02 code
folder is exactly ch01 + the DesignSystem package + the Catalog app, with Podcasts intact.

## Prerequisites & start state

- `code/part-2-modular/ch01-the-monolith` = monolith end state (Music + Podcasts, single target).
- `code/part-2-modular/ch02-design-system` already contains: monolith sources + `Packages/DesignSystem`
  (SwiftPM: Tokens + Components, `DS`-prefixed) + a `Catalog` app target. This is believed to
  already match the plan — this chapter is mostly verification + prose alignment.

## Prose tasks — `part-2-modular/02-extracting-design-system.md`

Apply the 9-beat template from conventions:

1. **Where we are**: restate Ch1 end state — one target, Music + Podcasts, baseline scoreboard.
2. **Pain**: designer joins (team of 3); brand refresh means daily token/component churn; each
   color tweak = ~40s full-target rebuild (measured); designer cannot preview components
   without running the whole app. Keep the existing Maya/Sam dialogue if it fits this frame.
3. **Diagnosis**: the book's key principle — extract code with **many incoming, few outgoing**
   dependencies first. `Views/Shared` is the textbook case.
4. **Refactor** (order): create local SwiftPM package `Packages/DesignSystem` → move
   `Views/Shared` contents in as `DS`-prefixed tokens/components (three tiers per
   `/DESIGN-SYSTEM.md`: Tokens → Styles → Components; reference that doc) → app imports the
   package → add the `Catalog` app target rendering every token and component.
5. **Verify**: scorecard — color-change loop 40s → ~5s via the Catalog scheme. State
   explicitly: *features unchanged — still Music + Podcasts.*
6. **Try it yourself**: edit a `DS` color token, build the `Catalog` scheme, observe the app
   target does not rebuild.
7. **Sidebar**: "Is this worth it yet?" — one package is cheap; the Catalog alone often
   justifies it once a designer joins.
8. **Cliffhanger**: PM signs off "Save to Library" — persistence. Business logic currently
   lives inside SwiftUI views and the only tests need a simulator. Nowhere sane to put it.
9. **Hands-On**: `code/part-2-modular/ch02-design-system`, schemes `iTunesSearchApp` + `Catalog`.

Update the dependency diagram to the canonical style: App → DesignSystem; Catalog → DesignSystem.

## Code tasks — `code/part-2-modular/ch02-design-system`

Verification-first; change only what fails:

- Confirm the folder = ch01 sources (minus `Views/Shared`) + `Packages/DesignSystem` +
  `Catalog` target. Podcasts feature MUST be present and working.
- Confirm `project.yml` defines schemes `iTunesSearchApp` and `Catalog`.
- Confirm DesignSystem package matches `/DESIGN-SYSTEM.md` tiering (Tokens/, Components/) and
  `DS` prefixes. Fix drift only; do not redesign.
- Update the folder `README.md` (packages, schemes, "the trap this leaves open" = business
  logic trapped in views).

## Acceptance criteria

- [ ] `xcodegen generate`; both schemes build (`iTunesSearchApp`, `Catalog`).
- [ ] `diff -qr code/part-2-modular/ch01-the-monolith code/part-2-modular/ch02-design-system` shows ONLY: `Views/Shared`
      removed, `Packages/DesignSystem` + Catalog sources added, `project.yml`/README deltas,
      and import-line changes in files that used shared tokens/components.
- [ ] Prose follows the 9 beats; states "features unchanged: Music + Podcasts".
- [ ] Banned-names grep over the prose file and code folder → 0 hits.
- [ ] `hugo build` succeeds.
- [ ] Commit: `ch02: design system chapter on template; verify code delta`.

## Out of scope

- Do not touch Domain/Infrastructure concepts (Ch3), any feature packages, or later folders.
- Do not rename the prose file (URL stays `02-extracting-design-system`).

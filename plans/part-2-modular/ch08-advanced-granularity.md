# Chapter 8 Plan — Advanced Granularity, and When to Stop

Read `plans/00-conventions.md` first. Prerequisite: `plans/ch07-the-proof.md` completed
(which renamed the old ch07 folder/prose to ch08).

## Goal

Rewrite the final chapter as a double-header — micro-targets inside one feature package, AND
the promoted "when to stop" material — and reconcile `code/part-2-modular/ch08-advanced-granularity` so it is
exactly ch07-the-proof's end state + the FeatureMusicSearch three-way split. This plan also
performs the final whole-book pass.

## Prerequisites & start state

- `code/part-2-modular/ch07-the-proof` end state: features {MusicSearch, Library, Movies, Audiobooks};
  CompositionRoot; no Podcasts.
- `code/part-2-modular/ch08-advanced-granularity` (renamed old ch07) already has `FeatureMusicSearch` split
  into three targets (`MusicSearchInterface` / `MusicSearchLogic` / `MusicSearchUI`) and
  features {MusicSearch, Movies, Audiobooks, Library} — close to correct, but it predates the
  ch05–ch07 reworks, so it must be reconciled against ch07's actual end state.

## Prose tasks — `part-2-modular/08-advanced-granularity.md`

Full rewrite on the 9-beat template. Title: "Chapter 8: Advanced Granularity — and When to
Stop" (weight 8, already set by ch07 plan).

1. **Where we are**: Ch7 end state; the offsite demo landed; the team grew again.
2. **Pain**: four devs now work *inside* `FeatureMusicSearch` and collide — UI polish and
   logic changes block each other; a UI-only PR re-runs the logic tests in CI.
3. **Diagnosis**: slicing recurses — but *within* the package this time: Interface / Logic /
   UI as separate SPM **targets** (library products) of the SAME package. UI and Logic both
   depend on Interface; **never on each other**.
4. **Refactor**: split `FeatureMusicSearch` into `MusicSearchInterface`
   (`MusicSearchViewModeling` protocol + view-state types), `MusicSearchLogic`
   (`MusicSearchViewModel`, no SwiftUI import), `MusicSearchUI` (`MusicSearchScreen`,
   `TrackRow`); `AppFactory` composes Logic into UI. Explicitly do NOT split the other three
   features — **the restraint is the lesson**; one sentence naming why (no collision pain there).
5. **Verify**: scorecard — logic tests build zero SwiftUI; a UI-only change never recompiles
   Logic; final fully-grown canonical diagram closes the book.
6. **Try it yourself**: add `import SwiftUI` to `MusicSearchLogic` — the target's dependency
   list makes CI fail; the boundary is enforced.
7. **When to stop** (promoted co-headline, not a sidebar): the granularity cost curve;
   honest-costs recap (boilerplate, composition-root growth, XcodeGen upkeep, onboarding,
   graph complexity); "modularize to solve human problems, not as an academic exercise";
   closing **decision checklist** the reader applies to their own app (team size, conflict
   rate, build times, test needs → which chapters to apply).
8. **No cliffhanger** — closing recap of the Ch1 scoreboard, fully knocked down, and the
   final diagram.
9. **Hands-On**: `code/part-2-modular/ch08-advanced-granularity`.

## Code tasks — `code/part-2-modular/ch08-advanced-granularity`

Reconcile to: **ch07-the-proof end state + ONLY the MusicSearch split**.

- Diff against `code/part-2-modular/ch07-the-proof`; carry over every ch05–ch07 improvement the old folder
  predates (canonical protocol names, AppInterfaces shape, CompositionRoot contents,
  FeaturePodcasts absent, screen naming, project.yml schemes).
- `Packages/FeatureMusicSearch/Package.swift` keeps its three targets/products
  (`MusicSearchInterface`, `MusicSearchLogic`, `MusicSearchUI`); type names per canon
  (`MusicSearchViewModeling`, `MusicSearchViewModel`, `MusicSearchScreen`, `TrackRow`).
  `MusicSearchLogic` must not import SwiftUI.
- Other three features remain single-target — verify none were accidentally split.
- Schemes: `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo`. README updated (final state;
  the restraint note).

## Final whole-book pass (this plan only)

- `README.md` (repo root): update the table of contents to the 8 chapters.
- `part-2-modular/README.md`: 8-chapter list consistent with titles/weights.
- Every chapter's Next/Previous `relref` links form an unbroken 1→8 chain.
- Global banned-names grep over `part-2-modular/` and all `code/part-2-modular/ch*` → 0 hits (except the one
  Ch6 Coordinator sidebar).
- Continuity sweep: for N in 2…8, `diff -qr code/ch(N-1)* code/chN*` matches each plan's
  stated delta; every folder's `xcodegen generate` + app scheme build passes;
  `swift test --package-path Packages/Domain` passes in ch03–ch08 folders.
- `hugo build --gc --minify` clean.

## Acceptance criteria

- [ ] `diff -qr code/part-2-modular/ch07-the-proof code/part-2-modular/ch08-advanced-granularity` shows ONLY the
      FeatureMusicSearch split (+ README/project.yml lines).
- [ ] `grep -rn "import SwiftUI" code/part-2-modular/ch08-advanced-granularity/Packages/FeatureMusicSearch/Sources/MusicSearchLogic` → 0 hits.
- [ ] All builds/tests in the whole-book pass succeed; all greps clean; hugo builds.
- [ ] Prose contains the decision checklist and the restraint lesson.
- [ ] Commit: `ch08: MusicSearch micro-targets + when-to-stop; final whole-book pass`.

## Out of scope

- Nothing after this — but do not "improve" earlier chapters' prose here beyond the link/TOC
  fixes listed in the whole-book pass; content fixes belong to their own chapter's plan.

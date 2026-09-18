# Chapter 6 Plan — The Composition Root

Read `plans/00-conventions.md` first. Prerequisite: `plans/ch05-dependency-inversion.md` completed.

## Goal

Rewrite Chapter 6 around the stop-the-line wiring cleanup (`AppFactory` + `AppRouter`), close
the `Services`-enum loop opened in Ch1, and rework `code/part-2-modular/ch06-composition-root` (add
FeaturePodcasts, remove FeatureAudiobooks; keep the existing CompositionRoot code).

## Prerequisites & start state

- `code/part-2-modular/ch05-dependency-inversion` end state: features {MusicSearch, Podcasts, Library,
  Movies} → {Domain, DesignSystem, AppInterfaces}; app implements `LibraryRouter` ad hoc;
  wiring smeared across `RootView`, previews, and the demo app.
- Current `code/part-2-modular/ch06-composition-root` already has `Sources/App/CompositionRoot/{AppFactory,
  AppRouter}` — keep and adapt. It lacks FeaturePodcasts and still has FeatureAudiobooks — fix.

## Prose tasks — `part-2-modular/06-composition-root.md`

Full rewrite on the 9-beat template. Canonical names: `AppFactory`, `AppRouter`
(`MainCoordinator` is banned). SwiftUI navigation only, with ONE permitted sidebar:
"`AppRouter` is SwiftUI's answer to UIKit's Coordinator" — the single place a UIKit term may
appear in the book.

1. **Where we are**: Ch5 end state; the compile errors that ended Ch5.
2. **Pain**: the tech lead calls a stop-the-line day. Wiring is duplicated in `RootView`,
   previews, and `FeatureLibraryDemo`; a mock/real mixup ships console analytics from a debug
   configuration (small incident narrative). Evidence: count the construction sites.
3. **Diagnosis**: the Composition Root pattern — exactly one place, as close to `@main` as
   possible, where the object graph is built. DI without a framework: initializer injection +
   one factory.
4. **Refactor** (order): create `Sources/App/CompositionRoot/` with `AppFactory` (constructs
   repositories, services, and each feature's screens) and `AppRouter` (implements
   `LibraryRouter` via `NavigationStack` path state) → move ALL construction there → Ch1's
   `Services` enum + `MOCK_SERVICES` flag **dissolves into AppFactory** (state this explicitly
   — it closes the loop opened in Ch1) → `RootView` becomes trivial (a `TabView` of
   factory-made screens) → `FeatureLibraryDemo` gets its own ~10-line composition root.
5. **Verify**: scorecard — the entire object graph readable in one file; mock/real swap is one
   line in one place.
6. **Try it yourself**: in `FeatureLibraryDemo`'s tiny composition root, swap in a fake
   `LibraryRouter` that just prints; observe the feature is fully drivable without the app.
7. **Sidebar**: honest costs — the composition root tends toward a god object; mitigations
   (per-feature factory extensions, keeping it boring/declarative). "Is this worth it yet?" —
   this chapter costs little and pays immediately; it's the cheapest chapter in the book.
8. **Cliffhanger**: the architecture is "done" — so the business immediately tests it:
   leadership wants **Audiobooks** demoed at the offsite in a week, and analytics says
   Podcasts is under 1% of sessions. Can we add fast and delete safely? → Chapter 7.
9. **Hands-On**: schemes `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo`.

Diagram: identical module graph to Ch5 (CompositionRoot lives inside the app box — say so).

## Code tasks — `code/part-2-modular/ch06-composition-root`

Target end state = ch05 end state + this delta:

**Add / adapt**
- `Sources/App/CompositionRoot/{AppFactory.swift, AppRouter.swift}` — keep the existing
  implementations, adapted to the ch05 feature set (must construct MusicSearch, Podcasts,
  Library, Movies; `AppRouter` implements `LibraryRouter`).
- `Packages/FeaturePodcasts` — carried over from ch05; `AppFactory` builds `PodcastsScreen`.
- `RootView` reduced to a trivial `TabView` over factory-made screens.
- `DemoApps/FeatureLibraryDemo` gains a small composition root file.

**Remove**
- `Packages/FeatureAudiobooks` — delete (vs the folder's current drifted contents); no
  `Audiobook` type in Domain.
- All ad hoc construction outside `CompositionRoot` (previews use preview factories/fakes).

**Project**
- Schemes: `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo`. README updated (trap = none
  architecturally; the next test is speed of change).

## Acceptance criteria

- [ ] All schemes build; app behavior identical to ch05 (four tabs, movie detail from Library).
- [ ] All repository/service/screen construction lives under `Sources/App/CompositionRoot/`
      (grep for repository/service initializers outside it → only the demo app's mini-root).
- [ ] `Services` enum no longer exists; `MOCK_SERVICES` decision lives in `AppFactory`.
- [ ] No `FeatureAudiobooks`/`Audiobook` anywhere in the folder.
- [ ] `diff -qr code/part-2-modular/ch05-dependency-inversion code/part-2-modular/ch06-composition-root` shows only this delta.
- [ ] `swift test --package-path Packages/Domain` passes; banned-names grep → 0 hits except
      the one Coordinator sidebar in prose; `hugo build` succeeds.
- [ ] Commit: `ch06: composition root; Services dissolves into AppFactory; feature set restaged`.

## Out of scope

- No Audiobooks feature, no Podcasts deletion (both are Ch7's plot).
- Do not touch `code/part-2-modular/ch07-advanced-granularity` (it is renamed by the ch07 plan) or ch07+ prose.

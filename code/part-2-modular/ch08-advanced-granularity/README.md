# iTunesSearchApp — Chapter 8: Advanced Granularity — and When to Stop

A fully working iOS app that we refactor chapter by chapter. It searches the
public **iTunes Search API** (no API key needed) for **music**, **movies**,
and **audiobooks**, and lets you save any of the three to a local **Core
Data** library.

This folder is the **final end state of the playbook**: `code/part-2-modular/ch07-the-proof`
plus exactly one delta — `FeatureMusicSearch` is split into three SPM
targets. Every other feature, every Domain/Infrastructure type, and the
composition root are byte-for-byte what Chapter 7 left them.

- **`Packages/FeatureMovies`** — `MoviesScreen` + `MovieDetailScreen` +
  `MovieRow`.
- **`Packages/FeatureMusicSearch`** — now three targets/products, see below.
- **`Packages/FeatureAudiobooks`** — `AudiobooksScreen` + `AudiobookRow`.
- **`Packages/FeatureLibrary`** — `LibraryScreen`, navigating via the
  `LibraryRouter` protocol from `AppInterfaces`.

## The micro-target split

Four developers were colliding *inside* `FeatureMusicSearch`: a UI polish PR
and a search-ranking PR kept touching the same target, so a UI-only change
recompiled — and re-ran the tests for — logic it never touched.
`Packages/FeatureMusicSearch` now produces three libraries instead of one:

- **`MusicSearchInterface`** — the `MusicSearchViewModeling` protocol (the
  contract) + the Domain types it references. No SwiftUI, no business logic.
  Depends only on `Domain`.
- **`MusicSearchLogic`** — `MusicSearchViewModel`, conforming to the
  interface, using injected Domain use cases (`SearchMediaUseCase`,
  `LibraryUseCase`) and service contracts (`AnalyticsTracker`,
  `CrashReporter`). **No SwiftUI import** — the target's own dependency list
  makes that a build failure, not a code-review nit.
- **`MusicSearchUI`** — `MusicSearchScreen` (generic over
  `MusicSearchViewModeling`) + `TrackRow`. Pure SwiftUI. Depends on
  `MusicSearchInterface` + `DesignSystem` + `Domain` — never on
  `MusicSearchLogic`.

```text
        iTunesSearchApp (Composition Root: AppFactory)
          │                        │
          ▼                        ▼
   MusicSearchUI            MusicSearchLogic
          │                        │
          └───────────┬────────────┘
                       ▼
              MusicSearchInterface
```

`MusicSearchUI` and `MusicSearchLogic` **do not depend on each other** — only
on `MusicSearchInterface`. `AppFactory.makeMusicSearch()` is the one place
that imports both `MusicSearchLogic` and `MusicSearchUI`: it builds the
`MusicSearchViewModel` from Logic and hands it to `MusicSearchScreen` from
UI.

The other three features — Movies, Library, Audiobooks — are deliberately
left as single modules. Nobody is colliding inside them, so splitting them
would only add XcodeGen upkeep and composition-root ceremony for no reader
of the diff to benefit from. **The restraint is the lesson**, as much as the
split itself.

## Why it's worth it here (and not everywhere)

- Change a color or spacing value in `MusicSearchUI` → only `MusicSearchUI`
  recompiles. `MusicSearchLogic` and its tests are untouched.
- Unit-test `MusicSearchViewModel` in `MusicSearchLogic` without linking
  SwiftUI — the target has no SwiftUI dependency to link.
- It is physically impossible to put business logic in `TrackRow` or
  `MusicSearchScreen`, because `MusicSearchUI` never links a repository or a
  use case — there is nothing for it to call.

## Run it

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-2-modular/ch08-advanced-granularity
xcodegen generate            # creates iTunesSearchApp.xcodeproj from project.yml
open iTunesSearchApp.xcodeproj

swift test --package-path Packages/Domain
```

Pick a scheme:

- **iTunesSearchApp** — the full app (Music, Movies, Library, Audiobooks
  tabs). Nothing about the app's behavior changed this chapter.
- **Catalog** — the design system in isolation, unchanged since Chapter 2.
- **FeatureLibraryDemo** — Library alone, built by its own
  `DemoCompositionRoot`, unchanged since Chapter 6.

## Try it yourself

Add `import SwiftUI` to any file in
`Packages/FeatureMusicSearch/Sources/MusicSearchLogic` and build. It fails —
`MusicSearchLogic`'s target dependencies don't include anything that vends
SwiftUI, so the boundary this chapter draws in prose is also enforced by the
compiler, not just code review.

## The dependency graph (final form)

```text
                    ┌─────────────────────────────┐
                    │        iTunesSearchApp       │
                    │  (App target: CompositionRoot│
                    │   = AppFactory + AppRouter)  │
                    └──┬────┬────┬────┬────┬────┬──┘
                       │    │    │    │    │    │
        ┌──────────────┘    │    │    │    │    └───────────────┐
        ▼                   ▼    ▼    ▼    ▼                    ▼
 FeatureMusicSearch  FeatureMovies FeatureLibrary FeatureAudiobooks  Infrastructure
  (Interface/Logic/UI)     │    │    │    │                     │
        │                  │    │    │    │                     │
        └───────┬──────────┴────┴──┬─┴────┘                     │
                ▼                  ▼                            │
          AppInterfaces ────▶   Domain   ◀──────────────────────┘
                │
                ▼
          DesignSystem  ◀── (all features)      Catalog ──▶ DesignSystem
```

Every feature still depends only on `Domain`, `DesignSystem`, and (for
Library's cross-feature navigation) `AppInterfaces`. `Infrastructure`
depends only on `Domain`. The only new edges are internal to
`FeatureMusicSearch`'s three targets.

## What changed from Chapter 7

- **Added**: `Packages/FeatureMusicSearch` now declares three targets —
  `MusicSearchInterface`, `MusicSearchLogic`, `MusicSearchUI` — in place of
  one; `AppFactory.makeMusicSearch()` composes `MusicSearchViewModel`
  (Logic) into `MusicSearchScreen` (UI); `project.yml` links the `UI` and
  `Logic` products instead of a single `FeatureMusicSearch` product; Debug
  builds now set `MOCK_SERVICES` in `SWIFT_ACTIVE_COMPILATION_CONDITIONS` so
  `AppFactory`'s `#if MOCK_SERVICES` branch is live, matching Chapter 1.
- **Removed**: nothing — no feature, screen, or Domain member was retired
  this chapter.
- **Unchanged**: `FeatureMovies`, `FeatureLibrary`, `FeatureAudiobooks`,
  `Domain`, `Infrastructure`, `AppInterfaces`, `AppRouter`,
  `SavedItemDetailView`, `RootView`, `FeatureLibraryDemo`, `Catalog`.

## The trap this chapter leaves open

None — this is the last chapter. The book's closing question isn't a new
pain, it's a discipline: knowing when *not* to apply the next technique. See
["When to Stop"](../../../part-2-modular/08-advanced-granularity.md) in the prose for
the decision checklist.

## Chapter map

1. Ch.1 — the monolith (`ch01-the-monolith`).
2. Ch.2 — extract the Design System (`ch02-design-system`).
3. Ch.3 — extract Domain & Infrastructure, Library arrives (`ch03-domain-infrastructure`).
4. Ch.4 — vertical slicing into feature packages (`ch04-vertical-slicing`).
5. Ch.5 — Movies born modular; dependency inversion behind protocols (`ch05-dependency-inversion`).
6. Ch.6 — the composition root: `AppFactory` + `AppRouter`, `Services` dissolves (`ch06-composition-root`).
7. Ch.7 — add Audiobooks, retire a sunset feature (`ch07-the-proof`).
8. Ch.8 — advanced granularity: splitting `FeatureMusicSearch`, and when to stop (**this folder**).

> The `.xcodeproj` is intentionally **not** committed — it's generated. Re-run
> `xcodegen generate` any time the source layout changes.

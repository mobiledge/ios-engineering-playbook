# Chapter 8: Advanced Granularity — and When to Stop

**The pain this chapter attacks: a feature module that has itself become a mini-monolith.** `FeatureMusicSearch` was one package for seven chapters; now it has four developers landing PRs in it the same week, and a UI-only color change re-runs the logic tests in CI because they share a target. By the end of this chapter, a UI change recompiles nothing but UI, a logic change never touches SwiftUI, and — because restraint is also a lesson — the other three features are still exactly one module each.

## Where We Are

[Chapter 7](07-the-proof.md) proved the graph under real pressure: `FeatureAudiobooks` shipped in a day from a template, `FeaturePodcasts` came out cleanly with the compiler naming every touchpoint, and `FeatureMusicSearch`, `FeatureMovies`, and `FeatureLibrary` didn't change shape to allow either. The offsite demo landed well — well enough that the team grew again, and most of the new hires landed on the app's oldest, most-used feature.

```text
                    ┌─────────────────────────────┐
                    │        iTunesSearchApp       │
                    │  (App target: CompositionRoot│
                    │   = AppFactory + AppRouter)  │
                    └──┬────┬────┬────┬────┬────┬──┘
                       │    │    │    │    │    │
        ┌──────────────┘    │    │    │    │    └───────────────┐
        ▼                   ▼    ▼    ▼    ▼                    ▼
 FeatureMusicSearch  FeatureAudiobooks FeatureMovies FeatureLibrary  Infrastructure
        │                  │    │    │    │                     │
        └───────┬──────────┴────┴──┬─┴────┘                     │
                ▼                  ▼                            │
          AppInterfaces ────▶   Domain   ◀──────────────────────┘
                │
                ▼
          DesignSystem  ◀── (all features)      Catalog ──▶ DesignSystem
```

Every feature still depends only on `Domain`, `DesignSystem`, and — for Library — `AppInterfaces`; `AppFactory` is still the one place that constructs concretes. Nothing about that graph is wrong. The pain this chapter attacks lives *inside* one box on this diagram, not between the boxes.

## Pain: Four Developers, One Target

> **Tech lead:** Music Search merge conflicts, three weeks running. Walk me through what's actually landing.
>
> **Sam (Music Search):** Search ranking. I'm tuning how results get scored and cached — it's real logic, it has its own test suite, and every change to it needs the full `MusicSearchViewModel` test run before I can trust it.
>
> **Priya (recently moved to Music Search UI):** And I'm doing the visual refresh — new row layout, save-button animation, spacing. None of it touches how a track gets fetched or scored. But it's all in the same Swift target as Sam's ranking code.
>
> **Tech lead:** So a pure color change—
>
> **Priya:** —recompiles the whole feature. Caching, ranking, analytics, all of it. And CI re-runs Sam's logic test suite on my PR, because the target that contains the tests is the target my one-line change also touched. Twelve minutes for a corner radius.
>
> **Sam:** And from my side: twice this month a UI PR touched a file I was mid-refactor on, because "the search screen" and "the search logic" are the same file today. Not a design disagreement — an accident of where the code happens to live.
>
> **Tech lead:** This is the same shape as Chapter 4's problem — two people, one shared file, merge conflicts for no design reason — just one level down. We sliced the monolith into features. Does slicing work again *inside* a feature?

## Diagnosis: Slicing Recurses

Chapter 4 sliced the monolith **vertically**, by feature: one package per feature, each a Swift module boundary the compiler enforces. This time the cut is **inside** one vertical slice, along a different axis — UI vs. business logic — using the exact same mechanism: separate SPM **targets** (and library **products**) of the *same* package.

Three targets, one package:

- **`MusicSearchInterface`** — the contract: the `MusicSearchViewModeling` protocol and the view-state it exposes. No SwiftUI, no business logic — just the shape both other targets agree on.
- **`MusicSearchLogic`** — `MusicSearchViewModel`, the real implementation: search, caching, save/remove, analytics. Depends on `MusicSearchInterface` and `Domain`. **Never imports SwiftUI.**
- **`MusicSearchUI`** — `MusicSearchScreen` and `TrackRow`. Pure SwiftUI, generic over `MusicSearchViewModeling`. Depends on `MusicSearchInterface` and `DesignSystem`. **Never imports `MusicSearchLogic`.**

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

`MusicSearchUI` and `MusicSearchLogic` both depend on `MusicSearchInterface` — **never on each other**. That's the whole rule, and it's the same Dependency Rule from Chapter 5 applied at a smaller radius: point dependencies at an abstraction, not at each other's concretes. `AppFactory` is the one place that imports both UI and Logic and wires the view model into the screen — the same composition-root discipline from Chapter 6, now doing double duty one level down.

## Refactor

1. **Carve out `MusicSearchInterface`.** Move `MusicSearchViewModeling` — `query`, `tracks`, `isLoading`, `errorMessage`, `search()`, `isSaved(_:)`, `toggleSave(_:)` — into its own target. It depends only on `Domain` (for `Track`).
2. **Carve out `MusicSearchLogic`.** `MusicSearchViewModel` conforms to `MusicSearchViewModeling`, and now owns everything the old single-target `MusicSearchScreen` used to do itself: run `SearchMediaUseCase`, de-dupe saves through `LibraryUseCase`, and call `AnalyticsTracker`/`CrashReporter`. It depends on `MusicSearchInterface` + `Domain` — nothing that vends SwiftUI.
3. **Carve out `MusicSearchUI`.** `MusicSearchScreen<ViewModel: MusicSearchViewModeling>` becomes generic over the interface instead of owning a concrete view model. `TrackRow` becomes purely presentational — track, a `isSaved` flag, and an `onToggleSave` closure; it has no repository to call even if someone wanted to sneak logic in.
4. **`Package.swift` declares three products.** `MusicSearchInterface`, `MusicSearchLogic`, `MusicSearchUI` — each its own `.library` product, so the app target (and CI) can link and test them independently.
5. **`AppFactory` composes them.** `makeMusicSearch()` builds a `MusicSearchViewModel` (Logic) and hands it to `MusicSearchScreen` (UI) — the one function in the app that imports both.
6. **Leave the other three features alone.** `FeatureMovies`, `FeatureLibrary`, and `FeatureAudiobooks` stay single-target. Nobody is colliding inside them — Movies and Audiobooks each have one owner, Library's churn is all cross-feature routing, not internal UI/logic contention. Splitting them would add three more `Package.swift` files, three more composition-root wiring points, and zero relief for a collision that doesn't exist. **The restraint is the lesson**, as much as the split itself.

## Verify

**Features: MusicSearch, Movies, Library, Audiobooks — unchanged app behavior. Only `FeatureMusicSearch`'s internal shape changed.**

| What you do | One `FeatureMusicSearch` target | Split into Interface / Logic / UI |
| --- | --- | --- |
| Change a color/spacing value in `TrackRow` | Recompiles caching, ranking, analytics, everything | Recompiles `MusicSearchUI` only |
| Run `MusicSearchViewModel`'s tests | Links SwiftUI to build the target that contains them | `MusicSearchLogic` links zero SwiftUI |
| CI on a UI-only PR | Re-runs the logic test suite (same target) | Logic tests don't even rebuild |
| Put a repository call inside `TrackRow` | Possible, just discouraged | Impossible — `MusicSearchUI` has no repository to call |
| Movies / Library / Audiobooks | — | Untouched — still one target each |

*Illustrative; verify mechanically in [`code/part-2-modular/ch08-advanced-granularity`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch08-advanced-granularity):*

```bash
grep -rn "import SwiftUI" Packages/FeatureMusicSearch/Sources/MusicSearchLogic
# 0 hits

diff -qr code/part-2-modular/ch07-the-proof code/part-2-modular/ch08-advanced-granularity
# FeatureMusicSearch's Package.swift + Sources swap from one target to three,
# AppFactory composes Logic into UI, project.yml links two products instead
# of one, READMEs updated — nothing else
```

The final, fully-grown dependency diagram — the shape every earlier chapter's diagram has been building toward:

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

## Try It Yourself

Add `import SwiftUI` to `MusicSearchViewModel.swift` in `Packages/FeatureMusicSearch/Sources/MusicSearchLogic` and build the `iTunesSearchApp` scheme (or just `swift build --package-path Packages/FeatureMusicSearch`). It still compiles — SwiftUI doesn't *forbid* the import — but now open `Package.swift` and delete `DesignSystem` from `MusicSearchLogic`'s dependency list, matching what it actually declares today. Nothing changes, because `MusicSearchLogic` never listed `DesignSystem` as a dependency in the first place: the boundary isn't "don't import SwiftUI," it's "the target graph makes importing SwiftUI-*dependent* code (DesignSystem, or any view) impossible without editing `Package.swift` in a code review anyone would flag." Try the real version of the exercise: add a call to a `DSColors` token inside `MusicSearchViewModel` — it fails to build immediately, because `MusicSearchLogic` never depends on `DesignSystem`. The dependency list is the enforcement mechanism, not a comment asking nicely.

## When to Stop Modularizing

Every chapter in this book had a cost the prose didn't hide: Chapter 2 added a Catalog app and a token layer for a one-person design team; Chapter 3 added protocols and a use-case layer before there were two implementations to swap; Chapter 6 added a 100-line `AppFactory` to fix a bug that discipline alone might have caught. Each time, the honest answer to "is this worth it yet?" was "barely — but the team is about to outgrow not having it." This chapter is no different, except now there's no Chapter 9 to defer to. So: when do you stop?

**The granularity cost curve.** Every split — monolith → features (Ch4), feature → Interface/Logic/UI (Ch8) — buys parallelism and buys back build time, at a fixed cost that doesn't scale with team size: another `Package.swift` to maintain, another set of `project.yml` lines, another composition-root wiring point, another thing a new hire has to learn the shape of before their first PR. Below some team size or churn rate, that fixed cost is pure overhead — nobody was colliding, so nothing was relieved. Above it, the split pays for itself in the first month. The curve doesn't have a universal crossing point; it has *this app's* crossing point, and you find it by watching for actual pain (merge conflicts, CI time, "who owns this file" confusion), not by pattern-matching to what a bigger company's engineering blog described.

**Honest costs, all seven chapters, recapped:**

- **Boilerplate.** Every module is a `Package.swift`, a folder, and at least one `project.yml` entry — multiplied by three for `FeatureMusicSearch` alone as of this chapter.
- **Composition-root growth.** `AppFactory` grows one `make…()` per feature and now composes two products for Music Search instead of one. It's still one file, still readable top to bottom — but it's the one file that *does* grow with every split, forever.
- **XcodeGen upkeep.** `project.yml` is hand-maintained. Every new target is a new entry someone has to remember to add, correctly, dependencies and all.
- **Onboarding.** A new hire on Chapter 1's app reads one file. A new hire on this app needs to understand Domain, Infrastructure, `AppInterfaces`, five feature packages, three of `FeatureMusicSearch`'s targets, and a composition root — before their first meaningful PR.
- **Graph complexity.** The final diagram above has more boxes and arrows than Chapter 1 had files. Every arrow is a real decision this book justified in the chapter it was drawn — but a diagram nobody needs to read is a diagram that shouldn't exist.

**The rule of thumb:** modularize to solve a **human** scaling problem you can point to — a merge-conflict count, a build-time measurement, a "which of us broke this" incident — not because an architecture blog said a "properly" built app looks a certain way. Every chapter in this book opened with a *measured* pain, not a principle. Chapter 8 split one feature, out of five, because that was the one with four developers landing PRs in the same target. It would have been over-engineering to do this in Chapter 4, when Music Search had one owner and zero collisions.

**A closing decision checklist**, applied to your own app, chapter by chapter:

| Question | If yes, apply |
| --- | --- |
| Does more than one person touch UI code regularly, and does styling drift because nobody can point at a single source of truth? | Ch2 — extract a `DesignSystem` + Catalog app |
| Does business logic live only inside views, untestable without booting a simulator? | Ch3 — extract `Domain` + `Infrastructure` |
| Do two or more people routinely conflict on files that belong to different features? | Ch4 — vertical slicing into feature packages |
| Does adding a feature require another feature to change, because of a direct import? | Ch5 — dependency inversion behind `Domain`/`AppInterfaces` protocols |
| Is "which service is really wired in" a live incident risk, or is construction logic copy-pasted across previews/targets? | Ch6 — a composition root (`AppFactory` + `AppRouter`) |
| Do you not yet know if the above paid off? | Ch7 — ship something and delete something for real, and measure it |
| Is one specific feature package itself colliding — one target, multiple owners, UI PRs re-running logic tests? | Ch8 — split *that* feature into Interface/Logic/UI, and leave the rest alone |

If the answer to a row is "no," the corresponding chapter is not yet worth applying to your app — not "worth applying eventually," not "worth applying because it's best practice." No.

## The Ch1 Scoreboard, Fully Knocked Down

| What you do | Ch1 baseline | Final state (Ch8) |
| --- | --- | --- |
| Clean build | ~3m10s | Feature-scoped builds in single-digit seconds; only a from-scratch build touches everything |
| Change one color | ~40s | ~5s, `DesignSystem` only ([Ch2](02-extracting-design-system.md)) |
| Music logic tests | ~1m+, simulator-bound | ~0.01s, no simulator, and now zero SwiftUI linked at all ([Ch3](03-domain-and-infrastructure.md), this chapter) |
| Two devs, two features | Merge conflicts on shared files | Zero shared files between features ([Ch4](04-vertical-slicing.md)) |
| Four devs, one feature | (not yet a problem in Ch1's two-person team) | Zero shared *target* between UI and logic work (this chapter) |
| Add a feature | Touch `RootView`, `Models`, `Networking`, `Utilities` | One dev, one day, zero other files change shape ([Ch7](07-the-proof.md)) |
| Delete a feature | Hand-grep 6 files, hope you got them all | One package folder, compiler names the rest ([Ch7](07-the-proof.md)) |

There is no cliffhanger here. The team that shipped a two-person v1 in Chapter 1 is now several squads deep, and every measurement above is a receipt, not a promise. The next pain this app hits isn't in this book — it's whatever your app's version of Chapter 2's designer, Chapter 3's persistence request, or this chapter's four-developers-one-target collision turns out to be. Apply the technique that matches the pain you actually have, in the order you actually feel it, and stop when the checklist above stops saying yes.

## Hands-On

[`code/part-2-modular/ch08-advanced-granularity`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch08-advanced-granularity) is `code/part-2-modular/ch07-the-proof` plus exactly this chapter's delta — diff the two folders to see it; it's the whole lesson. Schemes:

- **`iTunesSearchApp`** — the full app (Music, Movies, Library, Audiobooks tabs), behavior identical to Chapter 7. `AppFactory.makeMusicSearch()` now composes `MusicSearchLogic` into `MusicSearchUI`.
- **`Catalog`** — the design system in isolation, unchanged since Chapter 2.
- **`FeatureLibraryDemo`** — Library alone, built by its own `DemoCompositionRoot`, unchanged since Chapter 6.

```bash
cd code/part-2-modular/ch08-advanced-granularity
xcodegen generate
open iTunesSearchApp.xcodeproj   # choose iTunesSearchApp, Catalog, or FeatureLibraryDemo

swift test --package-path Packages/Domain
```

---

**Congratulations.** You've followed **iTunesSearchApp** from a single Xcode target a two-person team could ship in a weekend, to a graph of independently buildable, independently testable modules that survived a real feature launch and a real feature deletion — and you've seen, in this chapter, that the same idea recurses one level further when the pain actually shows up there, and that it should stop the moment it doesn't. That restraint is the last lesson of the book: modularize to solve human scaling problems, measured, one boundary at a time — never as an academic exercise.

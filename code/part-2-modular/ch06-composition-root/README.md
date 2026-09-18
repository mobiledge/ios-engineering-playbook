# iTunesSearchApp — Chapter 6: The Composition Root

A fully working iOS app that we refactor chapter by chapter. It searches the
public **iTunes Search API** (no API key needed) for **music**, **podcasts**,
and **movies**, and lets you save any of the three to a local **Core Data**
library.

This folder is the **end state of Chapter 6**. The module graph is
**unchanged from Chapter 5** — same four feature packages, same
`Domain`/`Infrastructure`/`DesignSystem`/`AppInterfaces` layers. This chapter
is entirely about *where* the object graph gets built, not what's in it:

- **`Packages/FeatureMovies`** — `MoviesScreen` + `MovieDetailScreen` +
  `MovieRow`.
- **`Packages/FeatureMusicSearch`** — `MusicSearchScreen` + `TrackRow`.
- **`Packages/FeaturePodcasts`** — `PodcastsScreen` + `PodcastRow`.
- **`Packages/FeatureLibrary`** — `LibraryScreen`, navigating via the
  `LibraryRouter` protocol from `AppInterfaces`.

## The Composition Root

Chapter 5 left the wiring smeared across `RootView` (four repositories and
services, constructed ad hoc and threaded through every screen's
initializer) plus a duplicate of that same wiring in `FeatureLibraryDemo`.
Nothing enforced that two features got the *same* repository instance, and
nothing stopped a debug build from quietly picking the wrong mix of mock and
real services — exactly the kind of mixup that once shipped console
analytics from a "test" build.

`Sources/App/CompositionRoot/` fixes that by being the **one place** the
object graph is built, as close to `@main` as possible:

- **`AppFactory`** — the only type that imports every module and knows every
  concrete implementation. It owns the shared repositories and services, and
  exposes one `make…()` method per feature screen plus a `destination(for:)`
  used for routing. Picking mock vs. real (Chapter 1's `MOCK_SERVICES` flag)
  is now a single default parameter in `AppFactory.init`.
- **`AppRouter`** — implements `LibraryRouter` by delegating to the factory
  that built it. It owns no logic of its own; it's the thing `FeatureLibrary`
  actually holds. (`AppRouter` plays the role SwiftUI needs in place of
  UIKit's imperative, push-based navigation.)

Chapter 1's `Services` enum — the global facade every feature used to reach
into directly for `Services.analytics`, `Services.crashReporter`,
`Services.flags` — no longer exists anywhere in this app. Every one of its
responsibilities now lives in `AppFactory`.

`RootView` is now trivial: a `TabView` over four screens the factory builds.
It doesn't import `Domain`, `Infrastructure`, `AppInterfaces`, or any feature
package.

`FeatureLibraryDemo` gets the same treatment at a smaller scale: a ~10-line
`DemoCompositionRoot` (`DemoApps/FeatureLibraryDemo/CompositionRoot.swift`)
is the only place in that target that constructs a repository or a router.

## What changed from Chapter 5

- **Added**: `Sources/App/CompositionRoot/{AppFactory.swift, AppRouter.swift,
  SavedItemDetailView.swift}`. `DemoApps/FeatureLibraryDemo/CompositionRoot.swift`.
- **Removed**: `Sources/App/AppLibraryRouter.swift` (folded into `AppRouter`
  + `AppFactory.destination(for:)`). The `Services` enum that lived in
  `iTunesSearchApp.swift`.
- **Changed**: `RootView` reduced to a trivial `TabView` over
  `AppFactory`-built screens. `iTunesSearchApp` owns the one `AppFactory` for
  the app's lifetime. `FeatureLibraryDemoApp` now delegates to
  `DemoCompositionRoot` instead of constructing `LibraryScreen` inline.
- **Unchanged**: every package under `Packages/` — no feature, protocol, or
  entity moved. The dependency diagram is identical to Chapter 5;
  `CompositionRoot` lives inside the app target's box.

## Run it

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-2-modular/ch06-composition-root
xcodegen generate            # creates iTunesSearchApp.xcodeproj from project.yml
open iTunesSearchApp.xcodeproj
```

Pick a scheme:

- **iTunesSearchApp** — the full app (Music, Podcasts, Movies, Library tabs).
  Save a movie in the Movies tab, then tap it in Library — it opens the same
  `MovieDetailScreen`. Behavior is identical to Chapter 5; only the wiring
  moved.
- **Catalog** — the design system in isolation, unchanged from Chapter 2.
- **FeatureLibraryDemo** — Library alone, built by its own
  `DemoCompositionRoot`.

## Try it yourself

Open `DemoApps/FeatureLibraryDemo/CompositionRoot.swift` and swap
`PreviewRouter` for a fake `LibraryRouter` that just prints the tapped item to
the console instead of returning a view. Run the `FeatureLibraryDemo` scheme
and confirm the feature is fully drivable without booting the rest of the
app, or touching `AppFactory`/`AppRouter` at all.

## The dependency graph

Identical to Chapter 5 — `CompositionRoot` is not a new module, it's a
folder inside the app target's own box:

```text
                    ┌───────────────────────────────────────┐
                    │     iTunesSearchApp (CompositionRoot   │
                    │        = AppFactory + AppRouter)       │
                    └──┬─────┬──────┬──────┬──────┬──────┬──┘
                       │     │      │      │      │      │
        ┌──────────────┘     │      │      │      └──────┘
        ▼                    ▼      ▼      ▼             ▼
 FeatureMusicSearch   FeaturePodcasts FeatureMovies  FeatureLibrary   Infrastructure
        │                    │            │               │               │
        └──────────┬─────────┴─────┬──────┘               │               │
                    ▼               ▼                      ▼               │
                    ------------ Domain <───────────────────────────────────
                                   ▲
                                   │
                            AppInterfaces ◄── FeatureLibrary
                                   │
                              DesignSystem  ◄── (all features)   Catalog ──► DesignSystem
```

Every feature depends only on `Domain`, `DesignSystem`, and (for
`FeatureLibrary`) `AppInterfaces`. `AppInterfaces` depends only on `Domain`.
`Infrastructure` depends only on `Domain`. The app target is still the only
node that touches everything — now with exactly one type (`AppFactory`) that
does the touching.

## The payoff: fast, isolated tests (unchanged since Chapter 3)

```bash
swift test --package-path Packages/Domain
```

## The trap this chapter leaves open

None, architecturally — this is the cheapest chapter in the book: little
cost, immediate payoff. The next test isn't a structural one. Leadership
wants **Audiobooks** demoed at the offsite in a week, and analytics says
**Podcasts** is under 1% of sessions. Can the graph this chapter built add a
feature fast and delete one safely? Chapter 7 finds out.

## Chapter map

1. Ch.1 — the monolith (`ch01-the-monolith`).
2. Ch.2 — extract the Design System (`ch02-design-system`).
3. Ch.3 — extract Domain & Infrastructure, Library arrives (`ch03-domain-infrastructure`).
4. Ch.4 — vertical slicing into feature packages (`ch04-vertical-slicing`).
5. Ch.5 — Movies born modular; dependency inversion behind protocols (`ch05-dependency-inversion`).
6. Ch.6 — the composition root: `AppFactory` + `AppRouter`, `Services` dissolves (**this folder**).
7. Ch.7 — add Audiobooks, retire Podcasts.

> The `.xcodeproj` is intentionally **not** committed — it's generated. Re-run
> `xcodegen generate` any time the source layout changes.

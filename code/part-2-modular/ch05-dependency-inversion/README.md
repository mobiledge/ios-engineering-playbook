# iTunesSearchApp — Chapter 5: The Feature That Broke the Graph

A fully working iOS app that we refactor chapter by chapter. It searches the
public **iTunes Search API** (no API key needed) for **music**, **podcasts**,
and now **movies**, and lets you save any of the three to a local
**Core Data** library.

This folder is the **end state of Chapter 5**. **Movies** is born this
chapter as the first feature that arrives already as a package — it never
lived in the monolith or in an app-target view:

- **`Packages/FeatureMovies`** — `MoviesScreen` + `MovieDetailScreen` +
  `MovieRow`. Movies owns its own detail screen; "MovieDetail" is never a
  standalone module.
- **`Packages/FeatureMusicSearch`** — `MusicSearchScreen` + `TrackRow`.
- **`Packages/FeaturePodcasts`** — `PodcastsScreen` + `PodcastRow`.
- **`Packages/FeatureLibrary`** — `LibraryScreen`. Now the only feature that
  needs cross-feature navigation: tapping a saved movie must open
  `FeatureMovies`' detail screen.

## The two inversions

Product wants a saved movie in Library to open the Movies detail screen. The
naive fix — `FeatureLibrary` importing `FeatureMovies` — makes the Library
demo transitively build Movies and everything Movies touches, and draws a
horizontal feature-to-feature edge on the dependency diagram. Instead:

1. **Data.** Every feature package **dropped its `Infrastructure`
   dependency**. They depend only on `Domain`'s abstractions
   (`MediaSearchRepository`, `LibraryRepository`) — repositories (and the
   cross-cutting service contracts: `AnalyticsTracker`, `CrashReporter`,
   `FeatureFlagProvider`) are now injected via each screen's initializer
   instead of constructed inline. Dropping the import is *deleting* a
   dependency, not adding one.
2. **Navigation.** A new **`Packages/AppInterfaces`** package holds the
   `LibraryRouter` protocol (`openSavedItem(_:)`). It depends only on
   `Domain`. `FeatureLibrary` depends on `AppInterfaces` and calls
   `router.openSavedItem(item)` — it declares *what should happen*, never
   *where to go*. The app target's `AppLibraryRouter` (`Sources/App`)
   implements the protocol and is the only place that knows a saved movie
   opens `FeatureMovies`' `MovieDetailScreen`.

No feature module imports another feature module, and no feature module
imports `Infrastructure`.

## What changed from Chapter 4

- **Added**: `Packages/FeatureMovies` (Movies born as a package) and
  `Packages/AppInterfaces` (the `LibraryRouter` navigation abstraction). The
  `Domain` layer gains a `Movie` entity and movie search support on
  `MediaSearchRepository` / `SearchMediaUseCase`. `Infrastructure`'s
  `ITunesSearchRepository` learns to search movies.
- **Removed**: the `Infrastructure` dependency from every feature package
  manifest (`FeatureMusicSearch`, `FeaturePodcasts`, `FeatureLibrary`,
  `FeatureMovies`).
- **App target**: `RootView` gains a Movies tab and constructs every concrete
  repository/service ad hoc, injecting them into each screen. It also
  implements `LibraryRouter` (`AppLibraryRouter`) — messy on purpose; there
  is still no composition root.

## Run it

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-2-modular/ch05-dependency-inversion
xcodegen generate            # creates iTunesSearchApp.xcodeproj from project.yml
open iTunesSearchApp.xcodeproj
```

Pick a scheme:

- **iTunesSearchApp** — the full app (Music, Podcasts, Movies, Library tabs).
  Save a movie in the Movies tab, then tap it in Library — it opens the same
  `MovieDetailScreen`.
- **Catalog** — the design system in isolation, unchanged from Chapter 2.
- **FeatureLibraryDemo** — Library alone. It's now a *miniature composition
  root*: it links `Infrastructure` directly to construct a real Core Data
  repository, and stubs `LibraryRouter` since it has no other features to
  navigate to. Change something in `Packages/FeatureLibrary`, build only
  this scheme, and watch `FeatureMusicSearch`/`FeaturePodcasts`/
  `FeatureMovies` never even compile.

## Try it yourself

Add `import FeatureMovies` inside `FeatureLibrary`. The build fails — the
package manifest doesn't list `FeatureMovies` as a dependency, so Swift
Package Manager won't resolve the import. The compiler is now the reviewer
that used to be a code-review comment.

## The dependency graph

```text
                    ┌───────────────────────────────────────┐
                    │             iTunesSearchApp            │
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
`Infrastructure` depends only on `Domain`. The app target is the only node
that touches everything — no horizontal feature-to-feature edges remain.

## The payoff: fast, isolated tests (unchanged since Chapter 3)

```bash
swift test --package-path Packages/Domain
```

Now includes `Movie` search tests alongside the Music and Library tests.

## The trap this chapter leaves open

`RootView` constructs every concrete repository and service by hand and
threads them through every screen's initializer — and it just grew an
`AppLibraryRouter` on top. Nothing enforces that two features get the *same*
repository instance, or that a mock and a real implementation aren't
accidentally mixed. That wiring has no home. Chapter 6 gives it one: a
Composition Root (`AppFactory` + `AppRouter`).

## Chapter map

1. Ch.1 — the monolith (`ch01-the-monolith`).
2. Ch.2 — extract the Design System (`ch02-design-system`).
3. Ch.3 — extract Domain & Infrastructure, Library arrives (`ch03-domain-infrastructure`).
4. Ch.4 — vertical slicing into feature packages (`ch04-vertical-slicing`).
5. Ch.5 — Movies born modular; dependency inversion behind protocols (**this folder**).
6. Ch.6 — the composition root.

> The `.xcodeproj` is intentionally **not** committed — it's generated. Re-run
> `xcodegen generate` any time the source layout changes.

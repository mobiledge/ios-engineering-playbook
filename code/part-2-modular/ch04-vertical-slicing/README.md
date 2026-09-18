# iTunesSearchApp — Chapter 4: Vertical Slicing

A fully working iOS app that we refactor chapter by chapter. It searches the
public **iTunes Search API** (no API key needed) for **music** and
**podcasts**, and lets you save either kind of item to a local **Core Data**
library.

This folder is the **end state of Chapter 4**. Music, Podcasts, and Library
are no longer views sharing one app target — each is its own Swift package:

- **`Packages/FeatureMusicSearch`** — `MusicSearchScreen` + `TrackRow`.
  (Renamed from `MusicSearchView` at extraction.)
- **`Packages/FeaturePodcasts`** — `PodcastsScreen` + `PodcastRow`.
  (Renamed from `PodcastsView` at extraction.)
- **`Packages/FeatureLibrary`** — `LibraryScreen`. (Renamed from
  `LibraryView` at extraction; extracted first, proven by
  `FeatureLibraryDemo`.)

Each depends on the same three horizontal layers:

- **`Packages/DesignSystem`** (Ch.2) — colors, typography, and components.
- **`Packages/Domain`** (Ch.3) — entities, repository protocols, the
  cross-cutting service contracts, and the use cases (`SearchMediaUseCase`,
  `LibraryUseCase`). **Depends on nothing.**
- **`Packages/Infrastructure`** (Ch.3) — DTOs + the concrete implementations
  (`ITunesSearchRepository`, `CoreDataLibraryRepository`, the console
  observability services). **Depends on Domain.**

The app target itself shrinks to two files: `Sources/App/iTunesSearchApp.swift`
(the `@main` entry) and `Sources/App/RootView.swift` (the `TabView` that
composes the three features). It knows nothing else about how any feature
works internally.

## Run it

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-2-modular/ch04-vertical-slicing
xcodegen generate            # creates iTunesSearchApp.xcodeproj from project.yml
open iTunesSearchApp.xcodeproj
```

Pick a scheme:

- **iTunesSearchApp** — the full app (Music, Podcasts, Library tabs).
- **Catalog** — the design system in isolation, unchanged from Chapter 2.
- **FeatureLibraryDemo** — Library alone, compiling only `FeatureLibrary` and
  its dependencies. This is the fast inner loop the chapter is about: change
  something in `Packages/FeatureLibrary`, build only this scheme, and watch
  `FeatureMusicSearch`/`FeaturePodcasts` never even compile.

## The dependency graph

```text
                              ┌─────────────────────┐
                              │    iTunesSearchApp   │
                              └──┬─────┬─────┬───────┘
                                 │     │     │
              ┌──────────────────┘     │     └──────────────────┐
              ▼                        ▼                        ▼
     FeatureMusicSearch          FeaturePodcasts            FeatureLibrary  ◄── FeatureLibraryDemo
              │                        │                        │
              └───────────┬────────────┴────────────┬───────────┘
                           ▼                         ▼
                     Infrastructure ───────────►   Domain
                           │
                           ▼
                     DesignSystem ◄── (all three features)   Catalog ──► DesignSystem
```

Each feature package depends on `Domain`, `DesignSystem`, and
`Infrastructure`. That last edge is a **deliberate flaw**, called out in the
package comments: a feature has no business depending on the concrete
networking/database layer directly, only on the protocols `Domain` declares.
Chapter 5 fixes it with dependency inversion.

## The payoff: fast, isolated tests (unchanged since Chapter 3)

```bash
swift test --package-path Packages/Domain
```

## The trap this chapter leaves open

Every feature package points straight at `Infrastructure` — the
`FeatureLibraryDemo` app links Core Data and networking code the Library
screen never calls. And next sprint brings **Movies**, whose detail screen
Library will need to open: a feature importing another feature's package by
name. Chapter 5 replaces both straight-line dependencies with protocols the
features don't own.

## Chapter map

1. Ch.1 — the monolith (`ch01-the-monolith`).
2. Ch.2 — extract the Design System (`ch02-design-system`).
3. Ch.3 — extract Domain & Infrastructure, Library arrives (`ch03-domain-infrastructure`).
4. Ch.4 — vertical slicing into feature packages (**this folder**).
5. Ch.5 — dependency inversion behind protocols.
6. Ch.6 — the composition root.

> The `.xcodeproj` is intentionally **not** committed — it's generated. Re-run
> `xcodegen generate` any time the source layout changes.

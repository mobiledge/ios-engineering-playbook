# Chapter 5: The Feature That Broke the Graph

**The pain this chapter attacks: features chained to each other and to concrete data.** Vertical slicing bought us isolated features — but the moment one feature imports another to navigate, or grabs a concrete API client to fetch, we've smuggled the spaghetti back in at the module level and made the feature untestable. By the end of this chapter, a feature depends only on protocols: change a sibling and it won't recompile; test it against a mock instead of the network.

## Where We Are

[Chapter 4](04-vertical-slicing.md) split the app into feature packages —
`FeatureMusicSearch`, `FeaturePodcasts`, and `FeatureLibrary` — sitting on top of `DesignSystem`,
`Domain`, and `Infrastructure`. The app target shrank to two files (`iTunesSearchApp.swift`,
`RootView.swift`), and two squads stopped colliding on the same `RootView.swift`/`project.yml`.
The module graph, with the flaw Chapter 4 named and deliberately left in place:

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

Every feature package depends on `Domain`, `DesignSystem`, **and `Infrastructure`** — that last
edge is the deliberate flaw. Each feature package constructs its own `ITunesSearchRepository`,
`CoreDataLibraryRepository`, `ConsoleAnalytics`, and friends inline, which only works because it
can still import the concrete `Infrastructure` package directly.

## Pain: Movies Needs a Screen It Doesn't Own

> **Deepa (new hire, Movies squad):** Product wants a Movies tab — browse, search, save to
> Library, same as Music and Podcasts. I'm starting from scratch, so I did it right: brand-new
> `FeatureMovies` package, depends on `Domain` and `DesignSystem` only, no `Infrastructure`
> import. Clean.
>
> **Priya (Library squad):** Nice. One thing, though — when someone saves a movie and taps it in
> their Library, product wants that to open the *real* movie detail screen, not just a generic
> row. That's `MovieDetailScreen`, right? In your package?
>
> **Deepa:** Right, Movies owns its own detail screen. So you'd just `import FeatureMovies` in
> `FeatureLibrary` and push it.
>
> **Priya:** I tried that. Watch what happens to the `FeatureLibraryDemo` build.
>
> ```swift
> // FeatureLibrary/Package.swift — the naive fix
> dependencies: [
>     .package(path: "../DesignSystem"),
>     .package(path: "../Domain"),
>     .package(path: "../Infrastructure"),
>     .package(path: "../FeatureMovies")   // <-- to reach MovieDetailScreen
> ]
> ```
>
> **Priya:** `FeatureLibraryDemo` used to build in seconds, touching only `FeatureLibrary` and its
> three dependencies. The moment I add that import, it transitively pulls in `FeatureMovies` and
> everything Movies touches — the "fast, isolated" demo app Chapter 4 promised isn't isolated
> anymore. And the dependency diagram just grew a horizontal edge: `FeatureLibrary → FeatureMovies`.
> That's exactly the shape Chapter 4 warned about — a feature importing another feature's package
> by name.
>
> **Sam (Search & Podcasts squad):** So every time Deepa touches anything in `FeatureMovies`, your
> `FeatureLibrary` — and its demo app — has to recompile too. Vertical slicing was supposed to stop
> that.
>
> **Priya:** It did, for Music and Podcasts, because neither of them needs to reach into the
> other. Library is the first feature that actually needs to navigate into a sibling. We can't
> just not solve the navigation problem — but importing the sibling module by name is the wrong
> way to solve it.

The measured cost: one `import FeatureMovies` line in `FeatureLibrary/Package.swift` turns a
three-package build (`FeatureLibrary` + `Domain` + `DesignSystem` + `Infrastructure`) into a
five-package one, and draws a feature-to-feature edge on the dependency diagram that didn't exist
before. Multiply that by every future feature Library might need to open, and the "isolated
feature" promise from Chapter 4 quietly erodes.

## Diagnosis: Dependency Inversion, Applied Twice

The Dependency Inversion Principle: high-level modules and low-level modules should both depend on
abstractions, not on each other directly. This chapter applies it in two places that look
different but are the same fix:

**Data.** Every feature already talks to `MediaSearchRepository` / `LibraryRepository` —
protocols that live in `Domain`. The `Infrastructure` import each feature still has is not
buying anything new; the feature could just as well receive an already-built repository through
its initializer. Dropping the `Infrastructure` dependency isn't adding an abstraction — it's
*deleting* one that was never needed, because the abstraction (the protocol) already existed one
layer down.

**Navigation.** `FeatureLibrary` doesn't need to know that a saved movie's detail screen is called
`MovieDetailScreen`, or that it lives in `FeatureMovies`. It only needs to say "open whatever this
saved item opens" — a protocol. That protocol can't live in `Domain` (screens aren't a domain
concept) and it can't live in `FeatureMovies` (that's the module `FeatureLibrary` isn't allowed to
import). It needs a new, small home: `Packages/AppInterfaces`, holding a `LibraryRouter` protocol
that depends only on `Domain`. `FeatureLibrary` declares *what should happen*
(`router.openSavedItem(item)`), never *where to go*.

## Refactor: Two Inversions, One Package

We did this in the order it actually has to happen — Domain first, since every package below
depends on it:

1. **Add `Movie` to `Domain`.** A new entity (`Movie`), plus `searchMovies(term:)` on
   `MediaSearchRepository` and a matching `movies(matching:)` method on `SearchMediaUseCase`. This
   is the first entity introduced *for* a feature that's arriving as a package rather than one
   migrating out of an app-target folder.
2. **Build `Packages/FeatureMovies`.** `MoviesScreen` + `MovieDetailScreen` + `MovieRow`, depending
   only on `{Domain, DesignSystem}`. It never depends on `Infrastructure` — there is no Chapter-4
   -style flaw to unwind here, because Movies never had an app-target phase to inherit one from.
3. **Show, and reject, the naive fix.** `FeatureLibrary` importing `FeatureMovies` compiles, but
   it reintroduces feature-to-feature coupling and blows up `FeatureLibraryDemo`'s build (see
   Pain, above). Revert it.
4. **Create `Packages/AppInterfaces`.** One protocol: `LibraryRouter`, with a single method,
   `openSavedItem(_:)`, returning a type-erased view. It depends only on `Domain`.
5. **`FeatureLibrary` depends on `AppInterfaces`, not `FeatureMovies`.** `LibraryScreen` is
   injected with a `LibraryRouter` and calls `router.openSavedItem(item)` instead of constructing
   any concrete detail screen. It has no idea `FeatureMovies` exists.
6. **Strip `Infrastructure` from all four feature packages.** `FeatureMusicSearch`,
   `FeaturePodcasts`, `FeatureLibrary`, and `FeatureMovies` all drop the dependency. Every
   concrete type each feature used to construct inline — `ITunesSearchRepository`,
   `CoreDataLibraryRepository`, `ConsoleAnalytics`, `ConsoleCrashReporter`, `LocalFeatureFlags` —
   becomes a parameter on the screen's public initializer instead:

   ```swift
   // FeatureMusicSearch — Chapter 4 (constructs its own concretes)
   public struct MusicSearchScreen: View {
       private let search = SearchMediaUseCase(repository: ITunesSearchRepository())
       private let analytics: AnalyticsTracker = ConsoleAnalytics()
       public init() {}
   }

   // FeatureMusicSearch — this chapter (dependencies injected)
   public struct MusicSearchScreen: View {
       private let search: SearchMediaUseCase
       private let libraryRepository: LibraryRepository
       private let analytics: AnalyticsTracker
       private let crashReporter: CrashReporter

       public init(
           searchRepository: MediaSearchRepository,
           libraryRepository: LibraryRepository,
           analytics: AnalyticsTracker,
           crashReporter: CrashReporter
       ) {
           self.search = SearchMediaUseCase(repository: searchRepository)
           self.libraryRepository = libraryRepository
           self.analytics = analytics
           self.crashReporter = crashReporter
       }
   }
   ```

   Something still has to build an `ITunesSearchRepository` and pass it in — that's `RootView`,
   the only place in the app now allowed to import `Infrastructure`. More on that below.

### The new architecture

```text
                    ┌─────────────────────────────┐
                    │        iTunesSearchApp       │
                    └──┬────┬────┬────┬────┬────┬──┘
                       │    │    │    │    │    │
        ┌──────────────┘    │    │    │    │    └───────────────┐
        ▼                   ▼    ▼    ▼    ▼                    ▼
 FeatureMusicSearch  FeaturePodcasts FeatureMovies FeatureLibrary  Infrastructure
        │                  │    │    │    │                     │
        └───────┬──────────┴────┴──┬─┴────┘                     │
                ▼                  ▼                            │
          AppInterfaces ────▶   Domain   ◀──────────────────────┘
                │
                ▼
          DesignSystem  ◀── (all features)      Catalog ──▶ DesignSystem
```

`AppInterfaces` depends only on `Domain`. `FeatureLibrary` is the only feature that depends on
`AppInterfaces`. No feature package depends on another feature package, and no feature package
depends on `Infrastructure` — the horizontal edges from Chapter 4's diagram are gone.

## Verify

**Features: Music, Podcasts, Library — unchanged — plus Movies, arriving this chapter.**

| What you do | Before this chapter | After this chapter |
| --- | --- | --- |
| `FeatureLibraryDemo` links | `FeatureLibrary`, `Domain`, `DesignSystem`, `Infrastructure` | `FeatureLibrary`, `Domain`, `DesignSystem`, `AppInterfaces` (`Infrastructure` only in the demo app itself, to build a real repo) |
| Library → a saved movie's detail screen | Not possible without `import FeatureMovies` | `router.openSavedItem(item)` — no `FeatureMovies` import |
| Trace what a feature can reach | Domain, DesignSystem, Infrastructure (concrete!) | Domain, DesignSystem, (AppInterfaces for Library) — zero concrete types |
| Horizontal edges on the diagram | 4 (one per feature → `Infrastructure`) | 0 |

*Illustrative figures; verify the boundary mechanically in [`code/part-2-modular/ch05-dependency-inversion`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch05-dependency-inversion):*

```bash
grep -rn "import Infrastructure" Packages/Feature*   # 0 hits
```

## Try It Yourself

1. Open `code/part-2-modular/ch05-dependency-inversion`, run `xcodegen generate`.
2. Add `.package(path: "../FeatureMovies")` back to `FeatureLibrary/Package.swift`'s
   `dependencies`, and add `import FeatureMovies` to `LibraryScreen.swift`.
3. Build. It compiles — Swift doesn't stop you from adding the dependency back by hand.
4. Now remove the line you added from `Package.swift` (but leave the `import` in the source
   file) and build again. It fails: `no such module 'FeatureMovies'`. The package manifest is the
   actual boundary — the compiler enforces it the moment the manifest doesn't list the import,
   and a reviewer no longer has to catch a stray `import` by eye.

## "Is This Worth It Yet?" — Interfaces Packages Multiply

One `AppInterfaces` package for one `LibraryRouter` protocol is cheap: a `Package.swift`, one
file, a dependency on `Domain` and nothing else. But every new cross-feature need is tempting to
solve the same way, and a dozen tiny `*Interfaces` packages is its own kind of clutter — more
manifests to keep straight than the protocols they hold are worth. The rule this chapter leaves
in place: **one `AppInterfaces` package until it hurts.** Chapter 8 revisits when — and whether —
to split it further, once granularity itself becomes the problem instead of the solution.

## The Next Crack: Nobody Wires Any of This

Run the app target right now and it doesn't compile. Every feature screen has grown an
initializer full of protocol parameters — `MediaSearchRepository`, `LibraryRepository`,
`AnalyticsTracker`, `CrashReporter`, `FeatureFlagProvider`, `LibraryRouter` — and *something* has
to construct the concrete instances and pass them in. That something is currently `RootView`,
which now imports `Infrastructure` directly, builds every concrete type by hand, and threads them
through four screens' worth of initializers — plus an ad hoc `AppLibraryRouter` it wrote itself to
satisfy `LibraryRouter`. It works, but it's smeared across one file with no enforcement that two
features get the same repository instance, or that a mock and a real implementation don't get
mixed by accident. Who's actually responsible for wiring an app together? Chapter 6 gives that
question a name: the Composition Root.

## Hands-On: Movies Born Modular

The [`code/part-2-modular/ch05-dependency-inversion`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch05-dependency-inversion)
project is `code/part-2-modular/ch04-vertical-slicing` plus exactly this chapter's delta — diff the two folders
to see it. Schemes:

- **`iTunesSearchApp`** — the full app (Music, Podcasts, Movies, Library tabs). Save a movie in
  Movies, then tap it in Library — it opens `MovieDetailScreen`.
- **`Catalog`** — the design system in isolation, unchanged from Chapter 2.
- **`FeatureLibraryDemo`** — Library alone. Now a miniature composition root itself: it links
  `Infrastructure` to build a real Core Data repository, and stubs `LibraryRouter` since it has no
  other features to open.

```bash
cd code/part-2-modular/ch05-dependency-inversion
xcodegen generate
open iTunesSearchApp.xcodeproj   # choose iTunesSearchApp, Catalog, or FeatureLibraryDemo

# The Domain payoff, now covering Movie search too:
swift test --package-path Packages/Domain
```

## Checkpoint: Feature Coupling, Relieved

`FeatureMovies` was born depending on nothing but `Domain` and `DesignSystem` — the pattern the
other three features had to retrofit, it got for free. `FeatureLibrary` can route to a saved
movie's detail screen without ever importing `FeatureMovies`, and no feature package imports
`Infrastructure` anymore. What's still unresolved is *who* builds all those concrete repositories
and routers in the first place — right now, it's `RootView`, ad hoc, and that's the thread
Chapter 6 picks up.

---

> **Next:** [Chapter 6: The Composition Root](06-composition-root.md)

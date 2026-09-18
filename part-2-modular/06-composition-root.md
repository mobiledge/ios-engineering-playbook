# Chapter 6: The Composition Root

**The pain this chapter attacks: a perfectly decoupled app that wires itself back together, badly, in three different places.** Chapter 5 hid every concrete type behind a protocol — which means *something* still has to instantiate the real repositories and services and hand them to the right screens. Right now that something is `RootView`, copied by hand into every preview and into `FeatureLibraryDemo` too. By the end of this chapter, the entire object graph is buildable by reading one file, and swapping mock for real is a one-line change in exactly one place.

## Where We Are

[Chapter 5](05-dependency-inversion.md) left the module graph in good shape: `FeatureMusicSearch`, `FeaturePodcasts`, `FeatureMovies`, and `FeatureLibrary` each depend only on `Domain`, `DesignSystem`, and — for Library's cross-feature navigation — `AppInterfaces`. No feature imports another feature, and no feature imports `Infrastructure`. The compile errors that ended Chapter 5 were the honest cost of that boundary: every screen now takes protocols in its initializer (`MediaSearchRepository`, `LibraryRepository`, `AnalyticsTracker`, `CrashReporter`, `FeatureFlagProvider`, `LibraryRouter`), and *something* has to construct the concretes and pass them in.

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

That "something" was `RootView` — the only place left that imports `Infrastructure` — plus an ad hoc `AppLibraryRouter` it wrote to satisfy `LibraryRouter`. It worked. It was also the trap Chapter 5 left open.

## Pain: A Stop-the-Line Day

> **Tech lead:** I'm calling a stop-the-line day. Walk me through every place this app constructs an `ITunesSearchRepository`.
>
> **Sam (Search & Podcasts squad):** `RootView` builds one. Every SwiftUI preview for `MusicSearchScreen` and `PodcastsScreen` builds its own, usually with slightly different init arguments because whoever wrote the preview copy-pasted from a different screen. `FeatureLibraryDemo` builds a `CoreDataLibraryRepository` too, separately.
>
> **Priya (Library squad):** And none of those are guaranteed to be the *same* instance. If `RootView` and a preview ever needed to share state — which they don't today, but nothing stops it — we'd have two Core Data stacks pointed at the same store.
>
> **Tech lead:** That's the theoretical problem. Here's the real one. Somebody on the release build last week shipped a TestFlight build with `ConsoleAnalytics` still wired in — every tap event printed to the device console instead of going to the real vendor SDK, in what was supposed to be a release candidate. Not a huge deal by itself, except: which of the three files that construct `AnalyticsTracker` was the one somebody forgot to update when we swapped in the real SDK? `RootView`? One of the previews? Nobody could say for certain, because there's no single place that makes that call.
>
> **Deepa (Movies squad):** So the actual bug isn't "wrong analytics service" — it's "no single place decides which analytics service."
>
> **Tech lead:** Right. Find every file in this app that writes `ITunesSearchRepository()`, `CoreDataLibraryRepository()`, `ConsoleAnalytics()`, or `AppLibraryRouter(...)` and report back.

The count: `RootView` (four repositories/services plus a router), every preview across four feature screens (each rebuilding its own set, inconsistently), and `FeatureLibraryDemo` (a fifth, separate copy). Zero of those sites agree with each other by construction — only by developer discipline, which is exactly what broke last week.

## Diagnosis: The Composition Root

The fix has a name: the **Composition Root** — exactly one place, as close to the app's entry point as possible, where the object graph is built. Everywhere else receives its dependencies through initializer parameters; nowhere else calls a concrete type's initializer. This isn't a new framework or a new abstraction — it's discipline about *where* dependency injection's plumbing lives, applied to code that was already using constructor injection since Chapter 5. Two pieces do the whole job:

- **`AppFactory`** — the one type that imports every module. It owns the shared repository and service instances, and exposes one `make…()` method per feature screen.
- **`AppRouter`** — implements `LibraryRouter` by asking the factory for a destination. It carries no logic of its own.

And Chapter 1's loop finally closes here. The `Services` enum and its `MOCK_SERVICES` flag — the facade every feature used to reach into directly for `Services.analytics`, back when everything lived in one target — never really went away; Chapter 4's extraction just made it unreachable from inside a feature package, so each screen grew its own inline construction instead (the very thing that caused this chapter's incident). `AppFactory` is where that decision belongs: mock vs. real is now a single default parameter, picked once, in one initializer.

## Refactor

In the order it actually happened:

1. **Create `Sources/App/CompositionRoot/`.** Two files: `AppFactory.swift` and `AppRouter.swift`.
2. **`AppFactory` constructs every repository and service exactly once**, as stored properties, with the mock/real decision as an initializer default:

   ```swift
   @MainActor
   final class AppFactory {
       private let searchRepository: MediaSearchRepository
       private let libraryRepository: LibraryRepository
       private let analytics: AnalyticsTracker
       private let crashReporter: CrashReporter
       private let flags: FeatureFlagProvider

       init(
           searchRepository: MediaSearchRepository = ITunesSearchRepository(),
           libraryRepository: LibraryRepository = CoreDataLibraryRepository(),
           analytics: AnalyticsTracker = ConsoleAnalytics(),
           crashReporter: CrashReporter = ConsoleCrashReporter(),
           flags: FeatureFlagProvider = {
               #if MOCK_SERVICES
               return LocalFeatureFlags([.newPodcastUI: true])
               #else
               return LocalFeatureFlags()
               #endif
           }()
       ) { /* assign */ }
   }
   ```

   This is the *entire* mock/real decision for the whole app, in one initializer. It closes the loop Chapter 1 opened: `Services` no longer exists anywhere in this codebase.
3. **`AppFactory` grows one `make…()` per screen** (`makeMusicSearch()`, `makePodcasts()`, `makeMovies()`, `makeLibrary()`), each handing the shared instances to the screen's initializer, plus a `destination(for:)` that knows a saved movie opens `FeatureMovies`' `MovieDetailScreen` — the one piece of routing knowledge from Chapter 5's `AppLibraryRouter`, now living beside everything else it needs.
4. **`AppRouter` implements `LibraryRouter`** by delegating straight to the factory:

   ```swift
   @MainActor
   struct AppRouter: LibraryRouter {
       let factory: AppFactory
       func openSavedItem(_ item: SavedItem) -> AnyView {
           factory.destination(for: item)
       }
   }
   ```

   > **Sidebar:** `AppRouter` is SwiftUI's answer to UIKit's Coordinator — a small type that owns navigation decisions so a feature never has to know where it's navigating to.
5. **`RootView` shrinks to a `TabView` of factory-made screens** — no imports of `Domain`, `Infrastructure`, `AppInterfaces`, or any feature package:

   ```swift
   struct RootView: View {
       let factory: AppFactory
       var body: some View {
           TabView {
               factory.makeMusicSearch().tabItem { Label("Music", systemImage: "music.note") }
               factory.makePodcasts().tabItem { Label("Podcasts", systemImage: "mic") }
               factory.makeMovies().tabItem { Label("Movies", systemImage: "film") }
               factory.makeLibrary().tabItem { Label("Library", systemImage: "books.vertical") }
           }
       }
   }
   ```
6. **`iTunesSearchApp` owns the one `AppFactory` for the app's lifetime** and hands it to `RootView` — the Composition Root, built as close to `@main` as this codebase gets.
7. **`FeatureLibraryDemo` gets its own composition root** — a ~10-line `DemoCompositionRoot` that is the *only* place in that target constructing a `CoreDataLibraryRepository` or a stub router. Previews that need a screen now call through a factory (or a preview-only fake) instead of constructing concretes inline.

## Verify

| What you do | Before this chapter | After this chapter |
| --- | --- | --- |
| Find every repository/service construction | `RootView`, every preview, `FeatureLibraryDemo` — five-plus sites, disagreeing | `Sources/App/CompositionRoot/AppFactory.swift` — one site (plus the demo's own mini-root) |
| Swap mock analytics for a real vendor SDK | Find and edit every construction site by hand | Edit one default parameter in `AppFactory.init` |
| `Services` enum / `MOCK_SERVICES` flag | Alive since Chapter 1, unreachable from features since Chapter 4 | Gone — dissolved into `AppFactory` |
| Read the whole object graph | Not possible from one file | `AppFactory.swift`, top to bottom |

*Illustrative; verify mechanically in [`code/part-2-modular/ch06-composition-root`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch06-composition-root):*

```bash
grep -rnE 'ITunesSearchRepository\(\)|CoreDataLibraryRepository\(\)|ConsoleAnalytics\(\)|ConsoleCrashReporter\(\)|LocalFeatureFlags\(' \
  --include='*.swift' . | grep -v CompositionRoot
# 0 hits outside Sources/App/CompositionRoot and the demo app's own mini-root
```

## Try It Yourself

1. Open `code/part-2-modular/ch06-composition-root/DemoApps/FeatureLibraryDemo/CompositionRoot.swift`.
2. Swap `PreviewRouter` for a fake `LibraryRouter` whose `openSavedItem(_:)` just `print()`s the tapped item's title and returns an empty view.
3. Run the `FeatureLibraryDemo` scheme. Save an item, tap it — watch the console. You never touched `AppFactory`, `AppRouter`, or any other feature package: the whole demo app is drivable through its own ten-line composition root.

## "Is This Worth It Yet?" — The Cheapest Chapter in the Book

The composition root pattern has a well-known failure mode: `AppFactory` tends toward a god object as the app grows, because every new feature adds another `make…()` method and another constructor argument to keep straight. The mitigations are boring on purpose — split it into per-feature factory extensions (`extension AppFactory { func makeMovies() -> some View { ... } }` in a file next to `FeatureMovies`'s own code, if it ever gets that big) and keep the file declarative: construction only, no business logic, no conditionals beyond the mock/real switch. At this app's size, none of that is needed yet — one file, under a hundred lines, reads top to bottom in one sitting. This chapter costs almost nothing (move code, don't invent abstractions) and pays back immediately (the stop-the-line incident becomes structurally impossible). It's the cheapest chapter in the book.

## The Next Crack: Now We Test the Architecture

The architecture is "done," in the sense that every dependency flows one direction and exactly one file builds the whole graph. So naturally, the business immediately tests it: leadership wants **Audiobooks** demoed at the offsite in a week, and the analytics `AppFactory` now reports honestly (no more console/mock mixups) says **Podcasts** is under 1% of sessions. Can this graph add a feature fast and delete one safely — proving the last five chapters of work were worth it, or exposing what they missed? Chapter 7 finds out.

## Hands-On

[`code/part-2-modular/ch06-composition-root`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch06-composition-root) is `code/part-2-modular/ch05-dependency-inversion` plus exactly this chapter's delta — diff the two folders to see it. Same module graph as Chapter 5; `CompositionRoot` is a folder inside the app target's own box, not a new module. Schemes:

- **`iTunesSearchApp`** — the full app (Music, Podcasts, Movies, Library tabs), behavior identical to Chapter 5. Save a movie in Movies, tap it in Library — same `MovieDetailScreen`, now built by `AppFactory`.
- **`Catalog`** — the design system in isolation, unchanged since Chapter 2.
- **`FeatureLibraryDemo`** — Library alone, built by its own `DemoCompositionRoot`.

```bash
cd code/part-2-modular/ch06-composition-root
xcodegen generate
open iTunesSearchApp.xcodeproj   # choose iTunesSearchApp, Catalog, or FeatureLibraryDemo

swift test --package-path Packages/Domain
```

## Checkpoint: Scattered Wiring, Relieved

`AppFactory` is now the only type in the app that imports every module and constructs a concrete repository or service; `AppRouter` is the only place that decides what a saved movie opens. `RootView` doesn't know either exists beyond calling `factory.make…()`. Chapter 1's `Services` enum and its `MOCK_SERVICES` flag are gone — dissolved into `AppFactory`'s initializer. What's untested is whether this graph holds up under real product pressure: adding a feature under deadline, and deleting one without breaking the rest.

---

> **Next:** [Chapter 7: The Proof: Add One, Delete One](07-the-proof.md)

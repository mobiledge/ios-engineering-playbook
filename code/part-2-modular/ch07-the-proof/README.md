# iTunesSearchApp — Chapter 7: The Proof

A fully working iOS app that we refactor chapter by chapter. It searches the
public **iTunes Search API** (no API key needed) for **music**, **movies**,
and (new this chapter) **audiobooks**, and lets you save any of the three to
a local **Core Data** library.

This folder is the **end state of Chapter 7**. There is no new architecture
here — this chapter is the proof that Chapter 6's composition root pays off
under real product pressure. The diff against `code/part-2-modular/ch06-composition-root`
**is** the lesson, and it is deliberately small:

- **Added** — `FeatureAudiobooks` (`AudiobooksScreen` + `AudiobookRow`), an
  `Audiobook` Domain entity, `searchAudiobooks` on `MediaSearchRepository`
  (+ test), the `Infrastructure` implementation, one `AppFactory.makeAudiobooks()`
  method, and one `RootView` tab line.
- **Removed** — the sunset feature's package in its entirety, its Domain
  entity and repository method (+ tests), its `Infrastructure` support, its
  `AppFactory` method, and its `RootView` tab line. See
  `code/part-2-modular/ch06-composition-root` for what it looked like before removal.

That is the whole chapter: **one dev, one day** to add a feature; **compiler-guided
deletion** to remove one — no other squad blocked, no grep archaeology.

- **`Packages/FeatureMovies`** — `MoviesScreen` + `MovieDetailScreen` +
  `MovieRow`.
- **`Packages/FeatureMusicSearch`** — `MusicSearchScreen` + `TrackRow`.
- **`Packages/FeatureAudiobooks`** — `AudiobooksScreen` + `AudiobookRow`.
- **`Packages/FeatureLibrary`** — `LibraryScreen`, navigating via the
  `LibraryRouter` protocol from `AppInterfaces`.

## Add one: the new-feature template

`FeatureAudiobooks` was built from the exact recipe every feature package
has followed since Chapter 5 — nothing new to invent:

1. Add the domain entity (`Audiobook`) and a repository method
   (`searchAudiobooks(term:)` on `MediaSearchRepository`) + a Domain test.
2. Implement it in `Infrastructure` (`ITunesSearchRepository` + a DTO).
3. Create the feature package — `{Domain, DesignSystem, AppInterfaces}` only,
   never `Infrastructure` — with one screen (`AudiobooksScreen`) and one row
   (`AudiobookRow`).
4. Wire it into `AppFactory` (`makeAudiobooks()`) and add one `TabView` line
   in `RootView`.

Every step is additive; nothing else in the app had to change to accommodate
it.

## Delete one: compiler-guided deletion

Deleting the sunset feature ran in the opposite order:

1. Delete the feature package's folder, its `project.yml` entry, its
   `AppFactory` method, and its `RootView` tab line.
2. The compiler immediately flags every remaining reference to the now-gone
   screen and Domain types — no `grep` treasure hunt required.
3. Follow the compiler to the orphaned Domain entity and repository method
   and delete those too.
4. Green build.

Compare this to Chapter 1's "try deleting a feature" exercise, where the same
job meant grepping the whole monolith folder and hoping you found every
reference by hand. Today the compiler does that work.

## Run it

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-2-modular/ch07-the-proof
xcodegen generate            # creates iTunesSearchApp.xcodeproj from project.yml
open iTunesSearchApp.xcodeproj
```

Pick a scheme:

- **iTunesSearchApp** — the full app (Music, Movies, Library, Audiobooks
  tabs). Save a movie in the Movies tab, then tap it in Library — it opens
  the same `MovieDetailScreen`. Save an audiobook and it round-trips through
  Library exactly like a track.
- **Catalog** — the design system in isolation, unchanged from Chapter 2.
- **FeatureLibraryDemo** — Library alone, built by its own
  `DemoCompositionRoot`, unchanged from Chapter 6.

## Try it yourself

Re-add a toy `FeatureFavorites` feature from the template above in under an
hour: a `Favorite` entity + repository method, a package depending only on
`{Domain, DesignSystem, AppInterfaces}`, one `AppFactory` method, one tab
line. Or go the other way — delete `FeatureMovies` on a branch and read the
compiler's error list; it names every touchpoint you'd otherwise have to
grep for.

## The dependency graph

Identical shape to Chapter 6, with the sunset feature's package swapped for
`FeatureAudiobooks`:

```text
                    ┌───────────────────────────────────────┐
                    │     iTunesSearchApp (CompositionRoot   │
                    │        = AppFactory + AppRouter)       │
                    └──┬─────┬──────┬──────┬──────┬──────┬──┘
                       │     │      │      │      │      │
        ┌──────────────┘     │      │      │      └──────┘
        ▼                    ▼      ▼      ▼             ▼
 FeatureMusicSearch  FeatureAudiobooks FeatureMovies FeatureLibrary  Infrastructure
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

Every feature depends only on `Domain`, `DesignSystem`, and `AppInterfaces`.
`Infrastructure` depends only on `Domain`. The app target is still the only
node that touches everything, through `AppFactory`.

## The payoff: fast, isolated tests (unchanged since Chapter 3)

```bash
swift test --package-path Packages/Domain
```

## What changed from Chapter 6

- **Added**: `Packages/FeatureAudiobooks` (`AudiobooksScreen`,
  `AudiobookRow`, `Date+Formatting.swift`); `Audiobook` entity;
  `searchAudiobooks` on `MediaSearchRepository` (+ `Infrastructure`
  implementation + `AudiobookDTO`); `AppFactory.makeAudiobooks()`; one
  `RootView` tab.
- **Removed**: the sunset feature's package entirely; its Domain entity and
  repository method (+ tests); its support in `Infrastructure`; its
  `AppFactory` method; its `RootView` tab; its feature flag.
- **Unchanged**: `FeatureMusicSearch`, `FeatureMovies`, `FeatureLibrary`,
  `AppRouter`, `SavedItemDetailView` (beyond a doc-comment update),
  `FeatureLibraryDemo`, `Catalog`.

## The trap this chapter leaves open

None, architecturally — the graph passed its first real product test. The
next pressure isn't structural at the app level, it's inside one package:
four devs now collide *inside* `FeatureMusicSearch` — UI polish work stepping
on logic work in the same files. Does slicing recurse into a feature module?
Chapter 8 finds out.

## Chapter map

1. Ch.1 — the monolith (`ch01-the-monolith`).
2. Ch.2 — extract the Design System (`ch02-design-system`).
3. Ch.3 — extract Domain & Infrastructure, Library arrives (`ch03-domain-infrastructure`).
4. Ch.4 — vertical slicing into feature packages (`ch04-vertical-slicing`).
5. Ch.5 — Movies born modular; dependency inversion behind protocols (`ch05-dependency-inversion`).
6. Ch.6 — the composition root: `AppFactory` + `AppRouter`, `Services` dissolves (`ch06-composition-root`).
7. Ch.7 — add Audiobooks, retire a sunset feature (**this folder**).
8. Ch.8 — advanced granularity: splitting `FeatureMusicSearch` (`ch08-advanced-granularity`).

> The `.xcodeproj` is intentionally **not** committed — it's generated. Re-run
> `xcodegen generate` any time the source layout changes.

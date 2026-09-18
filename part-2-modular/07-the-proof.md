# Chapter 7: The Proof: Add One, Delete One

**The pain this chapter attacks: none — this is the chapter that finds out whether the last five chapters of pain were worth it.** No new architecture gets introduced here. Leadership wants a brand-new feature demoed at an offsite in a week, and the same sprint kills a feature nobody uses anymore. By the end of this chapter, both have happened, and the diff for each is small enough to read in one sitting.

## Where We Are

[Chapter 6](06-composition-root.md) left the graph "done": `FeatureMusicSearch`, `FeaturePodcasts`, `FeatureMovies`, and `FeatureLibrary` each depend only on `Domain`, `DesignSystem`, and — for Library's cross-feature navigation — `AppInterfaces`. `Infrastructure` depends only on `Domain`. Exactly one type, `AppFactory`, imports every module and constructs every concrete repository and service; `RootView` is a four-line `TabView` over screens the factory builds.

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

(`FeaturePodcasts` still occupies the slot on the left as this chapter opens — the diagram above already shows where it's headed.) Chapter 6 closed with a question, not a trap: does this graph hold up under real product pressure — adding a feature under a deadline, deleting one without breaking the rest — or was the whole exercise since Chapter 1 decoration on an app too small to need it?

## Pain: The Double Dare

> **Tech lead:** Two things landed on my desk this morning, same sprint, and I think that's not a coincidence. Leadership wants Audiobooks in the app for the partner offsite — one week from today. And analytics finally has clean numbers, now that Chapter 6 killed the mock/real mixups: Podcasts is under 1% of sessions. It's getting cut.
>
> **Sam (Search & Podcasts squad):** So I'm building the thing that replaces the thing I've been maintaining.
>
> **Tech lead:** Basically. One week for Audiobooks — and I want to know, honestly, whether "one week" is realistic or whether we're going to be gutting `RootView` and half of `Domain` to make room for it like we would have in Chapter 4.
>
> **Priya (Library squad):** And Podcasts — do I need to block on that? Library reads `SavedItem`s across every media type; if Podcasts entries are sitting in someone's Core Data store—
>
> **Tech lead:** That's exactly the question. If deleting Podcasts touches `FeatureLibrary`, or `FeatureMovies`, or anything outside its own package and the couple of `Domain` seams it plugs into, we didn't build what we think we built.
>
> **Deepa (Movies squad):** So this sprint is a test, not a feature request.
>
> **Tech lead:** It's both. But yes — track how much of the app *nobody else has to touch* for either one. That number is the whole point of this chapter.

Two requests, same sprint, deliberately: **add a feature fast**, **delete a feature safely**. They are the two halves of the same architectural claim, and this chapter runs both experiments for real.

## Diagnosis: There Is No New Concept

Every other chapter in this book taught something — a boundary, a layer, an inversion, a root. This one teaches nothing new. If Chapters 1 through 6 did their job, adding and deleting a feature is just *following the shape that already exists*: a **template** for arrival, and the **compiler** for departure. If either of those turns out to need special-casing, that's a real finding too — it means the architecture has a gap this app's size hasn't exposed yet.

## Refactor

### Add one — the feature template (one dev, one day)

Sam builds `FeatureAudiobooks` by copying the recipe every feature package has followed since Movies was born modular in Chapter 5 — nothing here is new, which is the point:

1. **Domain, first.** Add the `Audiobook` entity and a `searchAudiobooks(term:)` method on `MediaSearchRepository`, plus a `SearchMediaUseCase.audiobooks(matching:)` use case — and a test, written against a mock repository before any network code exists.
2. **Infrastructure implements it.** `ITunesSearchRepository.searchAudiobooks(term:)` fetches and decodes an `AudiobookDTO`, mapping iTunes' `collectionName`/`artistName` JSON to the clean `title`/`author` domain fields. Nothing else in the app knows this file exists.
3. **The feature package.** `FeatureAudiobooks` depends on `{Domain, DesignSystem, AppInterfaces}` — never `Infrastructure` — with one screen, `AudiobooksScreen`, and one row, `AudiobookRow`, built exactly like `TrackRow`: a `DSMediaRow` with a save-to-Library affordance.
4. **Wire it in.** One `AppFactory.makeAudiobooks()` method, one `TabView` line in `RootView`, one `project.yml` package entry.

That's the whole template:

```text
┌─────────────────────────────────────────────────────────────────┐
│  New-feature template                                            │
│  1. Domain: entity + repository method + use case (+ test)       │
│  2. Infrastructure: implement the repository method               │
│  3. Package: {Domain, DesignSystem, AppInterfaces} + Screen + Row │
│  4. AppFactory.make…() + one RootView tab line                   │
└─────────────────────────────────────────────────────────────────┘
```

Every step is purely additive. No existing file changes shape — `MusicSearchScreen`, `MoviesScreen`, `LibraryScreen`, and every test written before this week keep compiling and keep passing without modification. Sam ships it inside the week.

### Delete one — compiler-guided deletion

Deleting Podcasts runs the template backwards, and it starts at the opposite end from where you'd guess:

1. **Delete the package folder first** — `Packages/FeaturePodcasts`, gone — plus its `project.yml` entry, its `AppFactory` method, and its `RootView` tab line.
2. **Run the build.** The compiler doesn't ask politely — it *refuses to build* until every dangling reference is gone, and it names every one: `MediaSearchRepository`'s now-unused `searchPodcasts(term:)` requirement, `SearchMediaUseCase.podcasts(matching:)`, the `Podcast` entity, the `Podcast`-typed test doubles, the podcast-specific feature flag.
3. **Follow the compiler, not a search box.** Delete each flagged Domain member and its `Infrastructure` implementation. No `grep` step, no "did I get everything" doubt — the build either succeeds or points at the next thing.
4. **Green build.**

> **The Chapter 1 callback.** Chapter 1's "try to delete Podcasts" exercise had you grep the monolith for `Podcast`, `PodcastsView`, `PodcastRow`, and `.newPodcastUI` by hand and write down how many files you'd have to touch to remove the feature cleanly. In `code/part-2-modular/ch01-the-monolith` that grep hits **6 files** — `Models/Podcast.swift`, `Networking/iTunesAPIClient.swift`, `Utilities/Services.swift`, `Views/Podcasts/PodcastRow.swift`, `Views/Podcasts/PodcastsView.swift`, `Views/RootView.swift` — every one of them a manual judgment call about whether you'd missed a reference. Today's deletion touches **one package folder** plus **two lines of `RootView`** and a handful of now-orphaned `Domain`/`Infrastructure` members the *compiler* names for you. Same feature. Same app. The difference is five chapters of boundaries.

## Verify

**Features: MusicSearch, Movies, Library — unchanged — Audiobooks arrives, Podcasts retires.**

| What you do | Before this chapter | After this chapter |
| --- | --- | --- |
| Add a feature (Audiobooks) | One dev, one day; zero other files change shape | Confirmed — `MusicSearchScreen`, `MoviesScreen`, `LibraryScreen` untouched |
| Delete a feature (Podcasts) | Ch1 baseline: 6 files, hand-checked by grep | 1 package removed, ~2 lines elsewhere, 0 grep archaeology — the compiler lists every touchpoint |
| Does any *other* feature notice? | — | `FeatureMusicSearch`, `FeatureMovies`, `FeatureLibrary` — zero changes to their source |
| Domain test suite | 8 tests (Ch6) | 10 tests — Podcast-specific coverage replaced by Audiobook coverage, `swift test` still ~0.01s |

*Illustrative; verify mechanically in [`code/part-2-modular/ch07-the-proof`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch07-the-proof):*

```bash
diff -qr code/part-2-modular/ch06-composition-root code/part-2-modular/ch07-the-proof
# FeaturePodcasts removed, FeatureAudiobooks added, a Domain/Infrastructure
# entity swap, and a handful of factory/tab/project.yml lines — nothing else

grep -rin podcast code/part-2-modular/ch07-the-proof
# 0 hits
```

## Try It Yourself

Pick one:

1. **Re-add, from the template.** Build a toy `FeatureFavorites` in under an hour: a `Favorite` entity + repository method + test in `Domain`, an `Infrastructure` implementation, a package depending on `{Domain, DesignSystem, AppInterfaces}` only, one `AppFactory` method, one `RootView` tab line. Time yourself against Sam's one-day Audiobooks build, scaled down.
2. **Delete, and watch the compiler talk.** On a throwaway branch, delete `Packages/FeatureMovies`, its `project.yml` entry, and its `AppFactory`/`RootView` lines. Run a build and read the error list top to bottom — it's a checklist of every remaining touchpoint, generated for free.

## "Is This Worth It Yet?" — Yes, With Receipts

Every chapter so far asked this question honestly, including the times the answer was "barely, at this app's size." This chapter *is* the receipt. The Chapter 1 baseline — clean build ~3m10s, change one color ~40s, Music logic tests ~1m+ (simulator-bound), two devs on two features means merge conflicts on shared files — is now fully knocked down: colors in ~5s ([Ch2](02-extracting-design-system.md)), business-rule tests in ~0.01s with zero simulator boot ([Ch3](03-domain-and-infrastructure.md)), a single feature building in ~8s instead of ~3m10s with no shared files left to conflict on ([Ch4](04-vertical-slicing.md)), and now: a feature shipped in a day, a feature deleted with the compiler doing the archaeology ([Ch5](05-dependency-inversion.md), [Ch6](06-composition-root.md)). None of that was free — six chapters of boundaries, protocols, and a composition root to get here — but the bill came due exactly once, and every feature since has paid a smaller one.

## The Next Crack: Success Scales the Team, Again

The graph survived a real product test. So the team grows to match — and four developers now collide *inside* a single package. `FeatureMusicSearch` has caching, animations, analytics instrumentation, and view logic all landing in the same target: a UI polish PR and a search-ranking PR keep touching the same files, for the same reason two devs once collided in one shared `RootView.swift`. Does the "vertical slice" idea from Chapter 4 recurse — can a feature package split *itself* into smaller pieces the same way the monolith split into features — or does slicing hit a floor? Chapter 8 finds out.

## Hands-On

[`code/part-2-modular/ch07-the-proof`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch07-the-proof) is `code/part-2-modular/ch06-composition-root` plus exactly this chapter's delta — diff the two folders to see it, it's the whole lesson. Schemes:

- **`iTunesSearchApp`** — the full app (Music, Movies, Library, Audiobooks tabs). Search and save an audiobook; it round-trips through Library exactly like a track or a movie.
- **`Catalog`** — the design system in isolation, unchanged since Chapter 2.
- **`FeatureLibraryDemo`** — Library alone, built by its own `DemoCompositionRoot`, unchanged since Chapter 6.

```bash
cd code/part-2-modular/ch07-the-proof
xcodegen generate
open iTunesSearchApp.xcodeproj   # choose iTunesSearchApp, Catalog, or FeatureLibraryDemo

swift test --package-path Packages/Domain
```

## Checkpoint: The Thesis, Tested

Audiobooks shipped in a day, following a template that needed no invention. Podcasts came out with the compiler naming every remaining touchpoint, not a grep session. Every other feature — Music, Movies, Library — is byte-for-byte unchanged in source. The architecture this book has been building since Chapter 1 just paid for itself, on camera, in one sprint. What it hasn't been tested against yet is pressure from *inside* a single feature package, once that package is popular enough to need more than one team.

---

> **Next:** [Chapter 8: Advanced Granularity — and When to Stop](08-advanced-granularity.md)

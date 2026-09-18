# iTunesSearchApp — Chapter 3: Domain & Infrastructure

A fully working iOS app that we refactor chapter by chapter. It searches the
public **iTunes Search API** (no API key needed) for **music** and
**podcasts**, and lets you save either kind of item to a local **Core Data**
library.

This folder is the **end state of Chapter 3**. The app now sits on top of
three local Swift packages:

- **`Packages/DesignSystem`** (Ch.2) — colors, typography, and components.
- **`Packages/Domain`** (Ch.3) — pure entities (`Track`, `Podcast`,
  `SavedItem`, `MediaType`), repository protocols (`MediaSearchRepository`,
  `LibraryRepository`), the cross-cutting service contracts (`Logger`,
  `CrashReporter`, `AnalyticsTracker`, `FeatureFlagProvider`), and two use
  cases: `SearchMediaUseCase` and `LibraryUseCase` (the dedupe/sort rules).
  **Depends on nothing.**
- **`Packages/Infrastructure`** (Ch.3) — DTOs + the concrete implementations
  (`ITunesSearchRepository`, `CoreDataLibraryRepository`, the console
  observability services). **Depends on Domain.**

The **Library** feature is new this chapter: search results in Music and
Podcasts can now be saved, and the Library tab lists everything saved,
newest-first, with swipe-to-remove.

## Run it

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-2-modular/ch03-domain-infrastructure
xcodegen generate            # creates iTunesSearchApp.xcodeproj from project.yml
open iTunesSearchApp.xcodeproj
```

Pick a scheme — **iTunesSearchApp** for the full app (Music, Podcasts,
Library), or **Catalog** to browse the design system in isolation — choose a
simulator, and press **Run** (⌘R).

## The dependency rule

```
        iTunesSearchApp
          │        │
          ▼        ▼
   Infrastructure  Domain ◄── (Domain depends on nothing)
          │        ▲
          └────────┘
```

Source dependencies point inward, toward the Domain. Concretely:

- The **Domain** has no `import` of SwiftUI, Core Data, or networking. It only
  declares *what* it needs via protocols, and hosts the business rules
  (`SearchMediaUseCase`, `LibraryUseCase`) that used to have nowhere sane to
  live.
- The **Infrastructure** implements those protocols. The iTunes JSON field
  names (`trackName`, `collectionName`, `artworkUrl100`, …) exist only in
  `SearchDTOs.swift`; everything else speaks in clean domain entities.
- The **app** depends on both — on Domain to use entities and use cases, and
  on Infrastructure only to *construct* the concrete repositories (inline for
  now; Chapter 6 moves construction into a single composition root).
- The `Services` enum still lives in the app target, but it has thinned to
  one job: picking which `Infrastructure` implementation wins, via
  `MOCK_SERVICES`. Chapter 6 dissolves it into the composition root.

## The payoff: fast, isolated tests

`Packages/Domain/Tests/DomainTests` unit-tests `SearchMediaUseCase` and
`LibraryUseCase` (the "don't save duplicates" and "newest first" rules) with
hand-written mock repositories — no network, no Core Data, no simulator. Run
them from the `Domain` scheme, or:

```bash
swift test --package-path Packages/Domain
```

## The trap this chapter leaves open

Music, Podcasts, and Library are three different features now sharing one
`Sources/Views/` folder and one app target. Two developers touching two
different features can still collide on the same files, and any change to
one feature still triggers a rebuild of the whole app. Chapter 4 cuts that
along feature lines.

## Chapter map

1. Ch.1 — the monolith (`ch01-the-monolith`).
2. Ch.2 — extract the Design System (`ch02-design-system`).
3. Ch.3 — extract Domain & Infrastructure, Library arrives (**this folder**).
4. Ch.4 — vertical slicing into feature modules.
5. Ch.5 — dependency inversion behind protocols.
6. Ch.6 — the composition root.

> The `.xcodeproj` is intentionally **not** committed — it's generated. Re-run
> `xcodegen generate` any time the source layout changes.

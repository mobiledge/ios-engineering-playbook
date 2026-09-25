# Chapter 3: Domain and Infrastructure

## Where We Are

[Chapter 2](02-extracting-design-system.md) left **iTunesSearchApp** as a single
application target on top of one local package: `Packages/DesignSystem`, plus a standalone
**Catalog** app that renders it in isolation. The features are unchanged — still just **Music**
and **Podcasts**, both search-and-list screens against the public iTunes Search API. The module
graph:

```text
              ┌─────────────────┐        ┌───────────┐
              │  iTunesSearchApp │        │  Catalog  │
              └────────┬─────────┘        └─────┬─────┘
                       │                         │
                       └───────────┬─────────────┘
                                   ▼
                             DesignSystem
```

Everything else — models, networking, the four cross-cutting service contracts, the `Services`
facade — still lives inside the app target, tangled together the way it was in Chapter 1. That's
the trap Chapter 2 left open: business logic has nowhere sane to live except inside a SwiftUI
view, next to whatever CoreData or URLSession calls happen to be nearby.

## Pain: The Company's First Business Rule

The startup just closed a small funding round and hired a fourth engineer. The product team's
first request for them: **"Save to Library."** Users want to save tracks and podcasts and see
them later, offline, deduplicated, sorted newest-first. It's the app's first feature that isn't
just "fetch JSON, show a list" — it has real rules to get wrong.

> **Priya (new hire):** I've got Library mostly working — tap a track, it saves to Core Data,
> shows up in a new tab. But I want a test for "don't save the same track twice" before I ship
> it. Where do I even put that?
>
> **Sam (dev):** Where's the dedupe check right now?
>
> **Priya:** Inside `TrackRow`'s button action — I check `CoreDataStack.isSaved` before calling
> `save`. It's like four lines.
>
> **Sam:** Okay, so to test those four lines...
>
> **Priya:** I have to instantiate the view, which touches `ITunesAPIClient` because
> `MusicSearchView` builds one, which means the whole networking stack has to compile. And
> `CoreDataStack` is a singleton wrapping a real `NSPersistentContainer`, so the test also spins
> up an actual Core Data store. I timed it — compiling the app target plus running one
> `XCTestCase` in the simulator: **one minute, ten seconds.** For four lines of logic that don't
> touch the network or the UI at all.
>
> **Sam:** And that's *before* you've written the assertion.
>
> **Priya:** Right. And it gets worse — the rule isn't even only in `TrackRow`. `PodcastRow` has
> its own copy, because I couldn't find anywhere shared to put it. If product asks for "cap the
> library at 500 items" next month, that's two places to change, two views to re-test, and the
> same 70-second tax each time.
>
> **Sam:** That's the shape of every business rule we're going to add from here — dedupe, sort,
> caps, whatever's next. None of them care about SwiftUI, and none of them care about Core Data.
> They care about *data*. Right now the only place they can live is wedged between the two.
>
> **Priya:** So I can't test "is this rule correct" without also testing "does the simulator
> boot, does the view compile, does the database connect." Three unrelated questions, one slow
> answer.

The measured cost is concrete: a rule with **zero** dependencies on network or UI takes **70+
seconds** to verify, because there is no seam that separates it from either. That's worse than
the Chapter 1 baseline for Music Search's tests (~1m+, itself already too slow) — and this time
the rule isn't even about I/O.

## Diagnosis: The Dependency Rule

The fix is the same idea Chapter 2 applied to UI — find the code with the fewest reasons to
change, and pull it out — but turned inside-out. Instead of extracting what everything depends
on, we extract what should depend on *nothing*: the business rules.

This is the Dependency Rule from Clean Architecture: **source code dependencies must point only
inward, toward policy, never outward toward detail.** Concretely:

- **Entities** are plain-data concepts (`Track`, `Podcast`, `SavedItem`) — never `Decodable`,
  never aware of JSON field names. Decoding the iTunes API's `trackName` / `artworkUrl100` shape
  is a **DTO's** job, and DTOs live with the networking code, not the entities.
- **Repository protocols** (`MediaSearchRepository`, `LibraryRepository`) are owned by the
  domain, not the networking or database code. The domain says *what* it needs — "search for
  tracks," "persist a saved item" — and never *how*. The four cross-cutting service contracts
  (`Logger`, `CrashReporter`, `AnalyticsTracker`, `FeatureFlagProvider`) move into Domain for the
  same reason: they describe what the app needs without naming a vendor.
- **Use cases** are where business rules actually live: `SearchMediaUseCase` (trim/validate a
  query) and, new this chapter, `LibraryUseCase` (don't save duplicates, list newest-first).
  They depend only on the repository *protocol*, so a test can hand them an in-memory fake and
  never touch a simulator.

Two new modules fall out of this directly: **Domain** (entities, protocols, use cases — depends
on nothing) and **Infrastructure** (the concrete networking and Core Data code — depends on
Domain, never the reverse).

## Refactor: Extracting Domain and Infrastructure

We did this in the following order:

1. **Create `Packages/Domain`, depending on nothing.** Its `Package.swift` declares zero
   dependencies — that isolation is the whole point. Into it moved:
   - **Entities**: `Track`, `Podcast`, `SavedItem`, and a `MediaType` enum (`.music` / `.podcast`).
   - **Repository protocols**: `MediaSearchRepository` (`searchMusic`, `searchPodcasts`) and
     `LibraryRepository` (`save`, `remove`, `isSaved`, `fetchAll`).
   - **Use cases**: `SearchMediaUseCase`, and the new `LibraryUseCase`, which is where "don't
     save a duplicate id/mediaType" and "list saved items newest-first" now actually live —
     exactly the two rules Priya couldn't find a home for.
   - **The cross-cutting service contracts** — `Logger`, `CrashReporter`, `AnalyticsTracker`,
     `FeatureFlagProvider`, plus the typed `AnalyticsEvent` / `FeatureFlag` — move here too, into
     `Observability/Contracts.swift`. They were already vendor-agnostic protocols in the Chapter
     1 monolith; this chapter just moves them to the layer that owns contracts, for the same
     reason the repositories moved: they describe what the app needs without naming a vendor.
2. **Create `Packages/Infrastructure`, depending only on Domain.** Into it moved:
   - `SearchDTOs.swift` — the `Decodable` shapes that know the iTunes JSON (`trackName`,
     `collectionName`, `artworkUrl100`, …) and map themselves to Domain entities. This is now the
     *only* file that changes if the API's response shape changes.
   - `ITunesSearchRepository`, implementing `MediaSearchRepository` with `URLSession`.
   - `CoreDataStack` + `CoreDataLibraryRepository`, implementing `LibraryRepository`.
   - `ConsoleServices.swift` — the same console implementations of the four service contracts
     from Chapter 1, now sitting where the real vendor adapters would eventually go.
3. **Thin the app's `Services` enum down to a build-config switch.** It no longer declares the
   protocols or the console implementations — those live in Domain and Infrastructure now.
   `Services` just picks which `Infrastructure` implementation wins, via the same
   `#if MOCK_SERVICES` flag from Chapter 1. (It still lives in the app target — that global
   selection is exactly what Chapter 6's composition root removes.)
4. **Build the Library UI on top of the use cases.** `Sources/Views/Library/LibraryView.swift`
   is new: a list of everything saved, swipe-to-remove, backed by a `LibraryViewModel` that talks
   only to `LibraryUseCase`. `TrackRow` and `PodcastRow` each gain a save/unsave button that also
   goes through `LibraryUseCase` — never straight to Core Data.

### The new architecture

```text
              ┌───────────────────────────────┐
              │         iTunesSearchApp        │
              └──┬──────────────┬──────────────┘
                 │              │
                 ▼              ▼
          ┌─────────────┐  ┌────────┐      ┌───────────┐
          │Infrastructure│  │ Domain │◄─────┤  Catalog  │
          └──────┬──────┘  └───▲────┘      └─────┬─────┘
                 │             │                 │
                 └─────────────┘           DesignSystem ◄──┘
```

`iTunesSearchApp` depends on `DesignSystem`, `Domain`, and `Infrastructure`. `Infrastructure`
depends on `Domain`. `Domain` depends on nothing. `Catalog` is unchanged, still depending only on
`DesignSystem`.

## Verify

**Features: Music + Podcasts unchanged, plus Library — new this chapter.** Nobody removed
anything; Library is the first arrival since Chapter 1.

| What you do | Ch1 baseline | After this chapter |
| --- | --- | --- |
| Test "don't save duplicates" | ~1m 10s — compiles app, boots simulator, hits Core Data | `swift test --package-path Packages/Domain`, ~0.01s, no simulator |
| Test the search query rule | Compile whole app first | Same `Domain` test target, milliseconds |
| Change the API's JSON shape | Ripples into every view that decodes it | Touches `SearchDTOs.swift` only |
| Reach the database from a domain rule | Easy — nothing stops it | Won't compile — `Domain` imports nothing |

*Illustrative figures; measure your own in [`code/part-2-modular/ch03-domain-infrastructure`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch03-domain-infrastructure). The headline: a sub-second, simulator-free test suite for the exact rules that used to need a minute-plus.*

## Try It Yourself

1. Open `code/part-2-modular/ch03-domain-infrastructure`, run `xcodegen generate`.
2. Open `Packages/Domain/Sources/Domain/UseCases/LibraryUseCase.swift` and comment out the guard
   in `save(_:)` that checks `isSaved` — i.e. make it always insert.
3. Run `swift test --package-path Packages/Domain`.
4. Watch `LibraryUseCaseTests.testSavingTheSameItemTwiceDoesNotDuplicate` fail — in under a
   second, with no simulator, no app build, no Core Data store touched. That's the loop Priya was
   missing.

## Is This Worth It Yet?

Two more packages is more ceremony than Chapter 2's one: a second `Package.swift`, a dependency
between them, DTOs to keep separate from entities. What it buys is a **~100x faster** test loop
for exactly the kind of code most likely to have bugs — business rules, not plumbing. At this
app's size that trade is worth it the moment a rule shows up that isn't "fetch and display" —
which, for this company, is this chapter. If Library were still just "fetch a list of saved IDs
and show them," you could reasonably wait. It's the *dedupe and sort logic* that tips the scale.

## The Next Crack: One Giant Feature Bucket

Domain and Infrastructure are clean now — but Music, Podcasts, and Library are three different
features sharing one `Sources/Views/` folder and one app target. The team just grew to six and
split into two squads, one owning Music + Podcasts, the other owning Library. Both squads' first
week ends with the same complaint: a merge conflict in `RootView.swift` from adding an unrelated
tab, and a feature change that still recompiles the entire app because everything is one target.
Chapter 4 cuts the app along those feature seams.

## Hands-On: Extract Domain and Infrastructure

The [`code/part-2-modular/ch03-domain-infrastructure`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch03-domain-infrastructure)
project is `code/part-2-modular/ch02-design-system` plus exactly this chapter's delta — diff the two folders to
see it. Schemes: **`iTunesSearchApp`** (Music, Podcasts, Library) and **`Catalog`** (design system
in isolation, unchanged from Chapter 2).

```bash
cd code/part-2-modular/ch03-domain-infrastructure
xcodegen generate
open iTunesSearchApp.xcodeproj    # choose iTunesSearchApp or Catalog

# The payoff, on its own:
swift test --package-path Packages/Domain
```

### The Domain package

[`Packages/Domain`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch03-domain-infrastructure/Packages/Domain)
is plain Swift — no SwiftUI, no Core Data, no networking import anywhere in it:

- **Entities** — `Track`, `Podcast`, `SavedItem`, `MediaType`. Concept-first field names
  (`name`, `artist`, `artworkURL`), not the iTunes JSON's.
- **Repository protocols** — `MediaSearchRepository`, `LibraryRepository`.
- **Use cases** — `SearchMediaUseCase` and `LibraryUseCase`. `LibraryUseCase` is the new one:
  ```swift
  public struct LibraryUseCase {
      private let repository: LibraryRepository

      @discardableResult
      public func save(_ item: SavedItem) -> Bool {
          guard !repository.isSaved(id: item.id, mediaType: item.mediaType) else { return false }
          repository.save(item)
          return true
      }

      public func list() -> [SavedItem] {
          repository.fetchAll().sorted { $0.savedAt > $1.savedAt }
      }
      // remove(id:mediaType:), isSaved(id:mediaType:) …
  }
  ```
- **Observability contracts** — `Logger`, `CrashReporter`, `AnalyticsTracker`,
  `FeatureFlagProvider`, `AnalyticsEvent`, `FeatureFlag`.

[`Packages/Domain/Tests/DomainTests`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch03-domain-infrastructure/Packages/Domain/Tests/DomainTests)
tests both use cases with hand-written in-memory mocks — no network, no disk:

```swift
func testSavingTheSameItemTwiceDoesNotDuplicate() {
    let repo = MockLibraryRepository()
    let useCase = LibraryUseCase(repository: repo)
    let track = SavedItem(id: 1, title: "Banana Pancakes", mediaType: .music, savedAt: Date())

    XCTAssertTrue(useCase.save(track))
    XCTAssertFalse(useCase.save(track), "Saving the same id/mediaType twice must be a no-op.")
}
```

### The Infrastructure package

[`Packages/Infrastructure`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch03-domain-infrastructure/Packages/Infrastructure)
depends on Domain and supplies every concrete detail:

- `ITunesSearchRepository` implements `MediaSearchRepository` over `URLSession`; `SearchDTOs.swift`
  holds the `Decodable` DTOs and their `toDomain()` mapping.
- `CoreDataStack` + `CoreDataLibraryRepository` implement `LibraryRepository` over Core Data.
- `ConsoleServices.swift` holds `ConsoleLogger`, `ConsoleAnalytics`, `ConsoleCrashReporter`,
  `LocalFeatureFlags` — Chapter 1's console stand-ins, now living beside where the real vendor
  adapters will eventually go.

### What the app looks like now

Views import `Domain` and `Infrastructure`, program against the protocols and use cases, and only
reach for a concrete type to construct it:

```swift
private let search = SearchMediaUseCase(repository: ITunesSearchRepository())
private let library = LibraryUseCase(repository: CoreDataLibraryRepository())
```

That inline construction is the last bit of coupling; Chapter 6's composition root removes it.

## Checkpoint: Untestable Logic, Relieved

Music, Podcasts, and Library all work, and the app has three tabs to prove it. But the real win is
underneath: the rules the product team keeps changing — "don't duplicate," "sort by date,"
whatever comes after — now live in `Domain`, verified in milliseconds, with the outside world
fully swappable behind `Infrastructure`.

---

> **Next:** [Chapter 4: Vertical Slicing](04-vertical-slicing.md)

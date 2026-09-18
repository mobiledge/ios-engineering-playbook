# Chapter 3 Plan — Domain and Infrastructure

Read `plans/00-conventions.md` first. Prerequisite: `plans/ch02-extracting-the-design-system.md` completed.

## Goal

Rewrite Chapter 3 around the arrival of the **Library** feature (the narrative motivation for
the layers), and rework `code/part-2-modular/ch03-domain-infrastructure` — the **largest code delta in the
whole revision** — so its feature set is Music + Podcasts + Library (no Movies, no Audiobooks,
no MovieDetail yet).

## Prerequisites & start state

- `code/part-2-modular/ch02-design-system` end state: app target (Music + Podcasts views) + `Packages/DesignSystem` + `Catalog`.
- Current `code/part-2-modular/ch03-domain-infrastructure` has drifted: its views are
  MusicSearch/MovieDetail/Library/Audiobooks and its Domain has Movie/Audiobook entities.
  Podcasts is missing. This plan fixes all of that.

## Prose tasks — `part-2-modular/03-domain-and-infrastructure.md`

Apply the 9-beat template:

1. **Where we are**: Ch2 end state (App + DesignSystem + Catalog; Music + Podcasts).
2. **Pain**: team of 4 builds **Library** — save tracks/podcasts, view them offline. First
   feature needing persistence and real business rules (dedupe, sort, remove). Show the
   "monolith way" attempt briefly: logic inside a SwiftUI view, CoreData calls next to
   URLSession calls; a unit test of "don't save duplicates" needs the simulator and takes
   1m+. That measured test time is the pain.
3. **Diagnosis**: the Clean Architecture dependency rule — policy must not depend on detail;
   entities vs DTOs; repository protocols owned by the domain; use cases as the home for
   business rules.
4. **Refactor** (order):
   - Create `Packages/Domain` (zero dependencies): entities `Track`, `Podcast`, `SavedItem`,
     `MediaType`; protocols `MediaSearchRepository`, `LibraryRepository`; use cases (search +
     library save/remove/list with the dedupe/sort rules); the observability contracts
     (`Logger`, `CrashReporter`, `AnalyticsTracker`, `FeatureFlagProvider` + typed
     `AnalyticsEvent`/`FeatureFlag`) move here from the app target.
   - Create `Packages/Infrastructure` (depends only on Domain): `ITunesSearchRepository`
     (URLSession + DTOs/endpoints), `CoreDataStack` + `CoreDataLibraryRepository`, console
     service implementations.
   - The app's `Services` enum thins to *selecting* Infrastructure implementations via
     `MOCK_SERVICES` (it still lives in the app target — foreshadow: it fully dissolves in Ch6).
   - Build the Library UI in `Sources/Views/Library` on top of the use cases.
5. **Verify**: scorecard — `swift test` on Domain runs sub-second with no simulator (vs 1m+).
6. **Try it yourself**: break a dedupe rule in a Domain use case, run
   `swift test --package-path Packages/Domain`, watch it fail in under a second.
7. **Sidebar**: "Is this worth it yet?" — two more packages of ceremony, bought a test loop
   ~100x faster; worth it exactly when business rules appear.
8. **Cliffhanger**: funding round → team of 6 → squads. But all three features share one
   target and one `Views/` folder — merge-conflict anecdote → Chapter 4.
9. **Hands-On**: `code/part-2-modular/ch03-domain-infrastructure`; schemes `iTunesSearchApp`, `Catalog`;
   `swift test --package-path Packages/Domain`.

Diagram (canonical style): App → {DesignSystem, Domain, Infrastructure}; Infrastructure → Domain;
Catalog → DesignSystem.

## Code tasks — `code/part-2-modular/ch03-domain-infrastructure`

Target end state = ch02 end state + this delta and nothing else:

**Add**
- `Packages/Domain` — entities limited to `Track`, `Podcast`, `SavedItem`, `MediaType`;
  protocols `MediaSearchRepository`, `LibraryRepository` (rename existing protocols to these
  canonical names if they differ); use cases; `Observability/` contracts; `Tests/DomainTests`
  covering the library rules and search use case.
- `Packages/Infrastructure` — `ITunesSearchRepository` + DTOs, `CoreDataStack` +
  `CoreDataLibraryRepository`, console observability implementations.
- `Sources/Views/Library/` — Library UI (list of saved items, remove, uses use cases).

**Remove (relative to the folder's current drifted contents)**
- `Movie` and `Audiobook` entities and any movie/audiobook repository methods from Domain.
- `Sources/Views/MovieDetail/`, `Sources/Views/Audiobooks/` (and any Movies views).

**Restore / keep**
- `Sources/Views/Music` and `Sources/Views/Podcasts` exactly as they ended in ch02 (copy from
  `code/part-2-modular/ch02-design-system` and re-point them at Domain entities + injected repositories where
  the chapter's refactor requires; keep monolith-era `…View` type names).
- App still a single target; `Services` enum remains in the app, now choosing Infrastructure impls.

**Project**
- `project.yml`: app target depends on the three local packages; keep schemes
  `iTunesSearchApp`, `Catalog`. Folder `README.md` updated (packages, schemes, trap = one
  `Views/` folder shared by three features).

## Acceptance criteria

- [ ] `xcodegen generate`; `iTunesSearchApp` and `Catalog` schemes build; app runs with three
      working tabs/sections: Music, Podcasts, Library (persistence works).
- [ ] `swift test --package-path Packages/Domain` passes in ~1s, no simulator.
- [ ] Domain contains NO `Movie`/`Audiobook` types; `grep -rn "Movie\|Audiobook" code/part-2-modular/ch03-domain-infrastructure/Sources code/part-2-modular/ch03-domain-infrastructure/Packages` → 0 hits.
- [ ] `diff -qr code/part-2-modular/ch02-design-system code/part-2-modular/ch03-domain-infrastructure` shows only this plan's delta.
- [ ] Prose follows the 9 beats; protocols named `MediaSearchRepository`/`LibraryRepository`.
- [ ] Banned-names grep → 0 hits. `hugo build` succeeds.
- [ ] Commit: `ch03: Library arrives; Domain+Infrastructure extracted; feature set restaged`.

## Out of scope

- No feature packages (`Feature*`) — that's Ch4. No `AppInterfaces`, no `CompositionRoot`.
- Do not touch `code/ch04+` folders or `part-2-modular/04+` prose.

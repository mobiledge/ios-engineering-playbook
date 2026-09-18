# Conventions — Shared Reference for All Chapter Plans

Read this before executing any `chNN-*.md` plan. On any conflict, this file wins.

## The design in one paragraph

The book is a single company story. Every chapter opens with a team/product event that *causes*
that chapter's pain, and each chapter's start state equals the previous chapter's end state,
verbatim. Features arrive and depart only as explicit plot points: Library arrives in Ch3 to
motivate Domain/Infrastructure, Movies is born in Ch5 to motivate dependency inversion, and
Ch7 adds Audiobooks and retires Podcasts on camera as the proof the architecture works. Each
`code/part-2-modular/chNN` folder is the runnable end state of chapter N.

## The continuity contract (the core rule)

For every chapter N ≥ 2:

- `code/part-2-modular/chNN`'s contents = `code/ch(N-1)`'s contents + **exactly** the delta stated in
  chapter N's plan. `diff -r` between the two folders must show that delta — no more, no less.
- Chapter N's prose must open by restating chapter N−1's end state (module graph + feature
  set) before introducing new pain.
- No module, feature, protocol, or name may appear in prose or code without having been
  introduced, or disappear without being explicitly retired.

## Chapter list

| # | Prose file (`part-2-modular/`) | Title | Inciting event |
|---|---|---|---|
| 1 | `01-the-monolith.md` | The Monolith | 2-person startup ships v1 |
| 2 | `02-extracting-design-system.md` | Extracting the Design System | Designer joins; brand refresh |
| 3 | `03-domain-and-infrastructure.md` | Domain and Infrastructure | "Save to Library" needs persistence |
| 4 | `04-vertical-slicing.md` | Vertical Slicing | Team of 6 splits into squads |
| 5 | `05-dependency-inversion.md` | The Feature That Broke the Graph | Movies needs cross-feature nav |
| 6 | `06-composition-root.md` | The Composition Root | Wiring smeared everywhere; mock/real incident |
| 7 | `07-the-proof.md` | The Proof: Add One, Delete One | Audiobooks deadline + Podcasts sunset |
| 8 | `08-advanced-granularity.md` | Advanced Granularity — and When to Stop | Devs collide inside one package |

## Feature arrival/retirement schedule

| Feature | Arrives | As | Departs |
|---|---|---|---|
| MusicSearch | Ch1 | monolith folder → `FeatureMusicSearch` (Ch4) → 3 targets (Ch8) | never |
| Podcasts | Ch1 | monolith folder → `FeaturePodcasts` (Ch4) | **Ch7 — retired** (<1% usage) |
| Library | Ch3 | monolith folder → `FeatureLibrary` (Ch4) | never |
| Movies | Ch5 | born as `FeatureMovies` (owns MoviesScreen + MovieDetailScreen) | never |
| Audiobooks | Ch7 | born as `FeatureAudiobooks` | never |

## Canonical naming glossary

Use ONLY the canonical names. The "banned" column lists names that must never appear in prose
or code (they are leftovers from earlier drafts).

| Concept | Canonical | Banned |
|---|---|---|
| UI paradigm | SwiftUI (`NavigationStack`, `TabView`) | UIKit teaching: `UIViewController`, `pushViewController`, `Coordinator`* |
| Interfaces package | `AppInterfaces` | `FeatureInterfaces`, `iTunesSearchInterfaces` |
| Navigation protocol | `LibraryRouter` (pattern: `<Feature>Router`) | `MusicSearchRouter` |
| Data protocols | `MediaSearchRepository`, `LibraryRepository` (in Domain) | `LibraryDataService` |
| Composition root | `AppFactory` + `AppRouter` in `Sources/App/CompositionRoot` | `MainCoordinator` |
| Horizontal layers | `Domain`, `Infrastructure`, `DesignSystem` | `CoreUtilities`, `CoreDataLayer` |
| Feature packages | `FeatureMusicSearch`, `FeaturePodcasts`, `FeatureLibrary`, `FeatureMovies`, `FeatureAudiobooks` | — |
| Movies scope | `FeatureMovies` owns `MoviesScreen` + `MovieDetailScreen`; "MovieDetail" is never a module | standalone "Movie Details" feature |
| Demo apps | `Catalog` (DesignSystem), `<FeatureName>Demo` (e.g. `FeatureLibraryDemo`) | — |
| Services facade | `Services` enum + `MOCK_SERVICES` flag (Ch1), dissolved into `AppFactory` in Ch6 | — |
| Micro-targets (Ch8) | `MusicSearchInterface` / `MusicSearchLogic` / `MusicSearchUI` | — |
| Screens | package screens `<Feature>Screen`; rows `<Thing>Row`; monolith-era `…View` names are fine until extraction | — |

\* Exception: Chapter 6 contains ONE sidebar that says "`AppRouter` is SwiftUI's answer to
UIKit's Coordinator" — the only place a UIKit term may appear.

## Chapter prose template

Every chapter (2–8) follows this beat structure, in order:

1. **Where we are** — restate previous chapter's end state (graph + features).
2. **Pain (with evidence)** — the team/product event and a measured cost.
3. **Diagnosis** — the concept being taught.
4. **Refactor** — the steps, in the order actually performed.
5. **Verify** — scorecard table diffing against the Ch1 baseline (below).
6. **Try it yourself** — a concrete repo exercise: which scheme, what to change, what to observe.
7. **"Is this worth it yet?" sidebar** — honest cost/benefit at this app size.
8. **New trap / cliffhanger** — the pain that opens the next chapter.
9. **Hands-On** — link to `code/part-2-modular/chNN-*` with build instructions.

**Ch1 baseline scoreboard** (all later scorecards diff against these): clean build ~3m10s ·
change one color ~40s · Music logic tests ~1m+ (simulator-bound) · two devs on two features =
merge conflicts on shared files.

## Canonical dependency diagram

ONE diagram, drawn the same way in every chapter, growing by the modules that exist at that
point. Final form (Ch8):

```text
                    ┌─────────────────────────────┐
                    │        iTunesSearchApp       │
                    │  (App target: CompositionRoot│
                    │   = AppFactory + AppRouter)  │
                    └──┬────┬────┬────┬────┬────┬──┘
                       │    │    │    │    │    │
        ┌──────────────┘    │    │    │    │    └───────────────┐
        ▼                   ▼    ▼    ▼    ▼                    ▼
 FeatureMusicSearch  FeatureMovies FeatureLibrary FeatureAudiobooks  Infrastructure
  (Interface/Logic/UI)     │    │    │    │                     │
        │                  │    │    │    │                     │
        └───────┬──────────┴────┴──┬─┴────┘                     │
                ▼                  ▼                            │
          AppInterfaces ────▶   Domain   ◀──────────────────────┘
                │
                ▼
          DesignSystem  ◀── (all features)      Catalog ──▶ DesignSystem
```

Per chapter, show only what exists: Ch1 = one box; Ch2 adds DesignSystem + Catalog; Ch3 adds
Domain + Infrastructure; Ch4 adds the three feature packages (+ FeatureLibraryDemo, with the
deliberate Feature→Infrastructure edges); Ch5 adds FeatureMovies + AppInterfaces and removes
the Feature→Infrastructure edges; Ch6 unchanged (CompositionRoot is inside the app box);
Ch7 swaps FeaturePodcasts for FeatureAudiobooks; Ch8 splits FeatureMusicSearch internally.

## Verification commands (used by every chapter's acceptance criteria)

```bash
# In the chapter's code folder:
xcodegen generate
xcodebuild -project iTunesSearchApp.xcodeproj -scheme iTunesSearchApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
# Domain tests (Ch3+): from the folder containing Packages/Domain
swift test --package-path Packages/Domain

# Continuity (Ch2+): the diff must equal the plan's stated delta
diff -qr code/part-2-modular/ch0N-… code/part-2-modular/ch0(N+1)-… | sort

# Banned names (prose + chapter code folder; zero hits expected outside the Ch6 sidebar)
grep -rnE 'CoreUtilities|CoreDataLayer|FeatureInterfaces|iTunesSearchInterfaces|LibraryDataService|MusicSearchRouter|MainCoordinator|pushViewController|UIViewController' part-2-modular code/part-2-modular/chNN-*

# Intra-repo links (any chapter that touches links): every relative .md target must exist
grep -rhoE '\]\([^)#:]+\.md' part-2-modular code
```

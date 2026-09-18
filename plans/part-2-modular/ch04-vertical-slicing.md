# Chapter 4 Plan — Vertical Slicing

Read `plans/00-conventions.md` first. Prerequisite: `plans/ch03-domain-and-infrastructure.md` completed.

## Goal

Rewrite Chapter 4 (the worst continuity offender in the old draft — it referenced modules that
never existed and taught UIKit) and rework `code/part-2-modular/ch04-vertical-slicing` so the three features
extracted are MusicSearch, **Podcasts**, and Library — Movies and Audiobooks must NOT exist yet.

## Prerequisites & start state

- `code/part-2-modular/ch03-domain-infrastructure` end state: single app target with `Views/{Music, Podcasts,
  Library}` + packages `DesignSystem`, `Domain`, `Infrastructure` + `Catalog`.
- Current `code/part-2-modular/ch04-vertical-slicing` has `FeatureMusicSearch`, `FeatureMovies`,
  `FeatureAudiobooks`, `FeatureLibrary` and no Podcasts — this plan restages it.

## Prose tasks — `part-2-modular/04-vertical-slicing.md`

Full rewrite on the 9-beat template. Critical corrections from the old draft:

- The horizontal layers are `Domain`, `Infrastructure`, `DesignSystem`. The names
  `CoreUtilities` and `CoreDataLayer` must not appear anywhere.
- All code and navigation talk is SwiftUI (`TabView`, views) — no `UIViewController`, no
  Coordinator language.

Beats:

1. **Where we are**: Ch3 end state restated.
2. **Pain**: team of 6 splits into a Search squad and a Library squad (Podcasts goes into
   maintenance mode — one quiet sentence, foreshadowing Ch7). Evidence: merge conflicts in the
   shared `Views/` folder and `project.yml`; any feature change rebuilds every feature; you
   cannot run Library without booting the whole app.
3. **Diagnosis**: horizontal layers vs vertical slices; feature packages as team-ownership
   boundaries; demo apps as the fast inner loop.
4. **Refactor** (order): extract `FeatureLibrary` first (smallest, newest) → prove it with the
   `FeatureLibraryDemo` app target → extract `FeatureMusicSearch` (rename `MusicSearchView` →
   `MusicSearchScreen` at extraction; note the rename) → extract `FeaturePodcasts`
   (`PodcastsScreen`) → app target shrinks to `Sources/App/{iTunesSearchApp.swift, RootView.swift}`
   (a `TabView`).
   Each feature package depends on `{Domain, DesignSystem, Infrastructure}` — the
   Infrastructure edge is a **deliberate flaw**; name it as such in one sentence.
5. **Verify**: scorecard — `FeatureLibraryDemo` clean build ~8s vs 3m10s; each squad builds
   only its slice; app target is 2 files.
6. **Try it yourself**: change Library's row layout, build only `FeatureLibraryDemo`; observe
   MusicSearch/Podcasts never compile.
7. **Sidebar**: worth it at team ≥ 2 squads; a solo dev gains little from feature packages.
8. **Cliffhanger**: two smells — every feature points at Infrastructure (the Library demo
   links CoreData + networking it never uses), and next sprint brings **Movies**, whose detail
   screen Library will need to open → Chapter 5.
9. **Hands-On**: schemes `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo`.

Diagram: App → {FeatureMusicSearch, FeaturePodcasts, FeatureLibrary, Infrastructure, Domain,
DesignSystem}; each Feature → {Domain, DesignSystem, Infrastructure}; FeatureLibraryDemo →
FeatureLibrary; Infrastructure → Domain; Catalog → DesignSystem.

## Code tasks — `code/part-2-modular/ch04-vertical-slicing`

Target end state = ch03 end state + this delta:

**Add**
- `Packages/FeatureMusicSearch` — from ch03's `Views/Music`; root view renamed
  `MusicSearchScreen`; row stays `TrackRow`.
- `Packages/FeaturePodcasts` — NEW package from ch03's `Views/Podcasts`; `PodcastsScreen`,
  `PodcastRow`.
- `Packages/FeatureLibrary` — from ch03's `Views/Library`; `LibraryScreen`.
- `DemoApps/FeatureLibraryDemo` — minimal app target hosting `FeatureLibrary` (in-memory or
  real repo, whichever is simpler; keep it tiny).
- Each feature package depends on `Domain`, `DesignSystem`, `Infrastructure` (deliberate flaw,
  fixed in Ch5).

**Remove (vs the folder's current drifted contents)**
- `Packages/FeatureMovies`, `Packages/FeatureAudiobooks` — delete entirely.
- `Sources/Views/` — gone; app target reduces to `Sources/App/{iTunesSearchApp.swift, RootView.swift}`.

**Keep**
- `Packages/{Domain, Infrastructure, DesignSystem}` exactly as ch03 left them (no Movie/
  Audiobook types). `Services` enum still in the app target.

**Project**
- `project.yml` schemes: `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo`. Folder README
  updated (trap = feature→Infrastructure edges + upcoming cross-feature navigation).

## Acceptance criteria

- [ ] `xcodegen generate`; schemes `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo` all build;
      app runs with Music/Podcasts/Library tabs.
- [ ] App target contains exactly 2 Swift files.
- [ ] No `FeatureMovies` or `FeatureAudiobooks` anywhere in the folder.
- [ ] `diff -qr code/part-2-modular/ch03-domain-infrastructure code/part-2-modular/ch04-vertical-slicing` shows only this delta.
- [ ] Prose: zero occurrences of `CoreUtilities`, `CoreDataLayer`, or UIKit teaching terms.
- [ ] `swift test --package-path Packages/Domain` still passes. `hugo build` succeeds.
- [ ] Commit: `ch04: vertical slices = MusicSearch, Podcasts, Library; demo app; drift removed`.

## Out of scope

- No `AppInterfaces`, no router protocols, no dependency inversion (Ch5).
- No `CompositionRoot` (Ch6). Do not touch ch05+ folders/prose.

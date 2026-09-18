# Chapter 5 Plan — The Feature That Broke the Graph (Dependency Inversion & Interfaces)

Read `plans/00-conventions.md` first. Prerequisite: `plans/ch04-vertical-slicing.md` completed.

## Goal

Rewrite Chapter 5 around the birth of **Movies** — the first feature born as a package, whose
cross-feature navigation need (Library opens a saved movie's detail) motivates dependency
inversion — and rework `code/part-2-modular/ch05-dependency-inversion` accordingly (add FeaturePodcasts,
remove FeatureAudiobooks, introduce Movie in Domain here).

## Prerequisites & start state

- `code/part-2-modular/ch04-vertical-slicing` end state: app (2 files) + `Feature{MusicSearch, Podcasts,
  Library}` + `Domain`/`Infrastructure`/`DesignSystem` + `Catalog` + `FeatureLibraryDemo`;
  every feature depends on Infrastructure (the deliberate flaw); Domain has NO Movie type.
- Current `code/part-2-modular/ch05-dependency-inversion` already has `Packages/AppInterfaces` with
  `LibraryRouter` — keep that. It lacks FeaturePodcasts and still has FeatureAudiobooks — fix.

## Prose tasks — `part-2-modular/05-dependency-inversion.md`

Full rewrite on the 9-beat template. Retitle (front matter `title:`) to
**"Chapter 5: The Feature That Broke the Graph"** — keep the filename/URL unchanged. All
SwiftUI; canonical names only (`AppInterfaces`, `LibraryRouter` — the old draft's
`FeatureInterfaces`, `iTunesSearchInterfaces`, `LibraryDataService`, `MusicSearchRouter` are
banned).

1. **Where we are**: Ch4 end state, including the named flaw (Feature→Infrastructure edges).
2. **Pain**: a third squad builds **Movies** — first feature *born* as a package:
   `FeatureMovies` containing `MoviesScreen` + `MovieDetailScreen` (Movies is a browse feature
   that owns its detail screen; "MovieDetail" is never a module). Product rule: a saved movie
   in Library must open the Movies detail screen. Show the naive fix — `FeatureLibrary`
   imports `FeatureMovies` — and measure the damage: the Library demo now transitively builds
   Movies and everything Movies touches; the diagram grows a horizontal feature→feature edge.
3. **Diagnosis**: the Dependency Inversion Principle, applied twice —
   **data**: features already talk to `MediaSearchRepository`/`LibraryRepository` protocols
   that live in Domain, so dropping the Infrastructure import is *deleting* a dependency
   (repositories injected via initializers), and
   **navigation**: features declare *what should happen*, not *where to go* — router
   protocols in a small `AppInterfaces` package.
4. **Refactor** (order): add `Movie` entity + movie search support to Domain → build
   `FeatureMovies` depending only on {Domain, DesignSystem} → show and reject the
   Library→Movies import → create `Packages/AppInterfaces` with `LibraryRouter`
   (`openSavedItem(_:)`), depending only on Domain → `FeatureLibrary` depends on
   `AppInterfaces` and calls the router → strip the `Infrastructure` dependency from all four
   feature packages.
5. **Verify**: scorecard — the Library demo no longer links CoreData/URLSession (show the
   build-log/product-size evidence); diagram has no horizontal edges; features are siblings.
6. **Try it yourself**: try adding `import FeatureMovies` inside FeatureLibrary — the build
   fails because the package manifest doesn't allow it. The compiler is now the reviewer.
7. **Sidebar**: interfaces packages are cheap but multiply — the rule: one `AppInterfaces`
   until it hurts (Ch8 revisits granularity).
8. **Cliffhanger**: the app target no longer compiles — *someone* must implement
   `LibraryRouter`, build repositories, and inject everything; that wiring is currently
   smeared ad hoc across `RootView`. Who wires it? → Chapter 6.
9. **Hands-On**: schemes `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo`.

Diagram: Features → {Domain, DesignSystem, AppInterfaces}; AppInterfaces → Domain;
Infrastructure → Domain; App → everything.

## Code tasks — `code/part-2-modular/ch05-dependency-inversion`

Target end state = ch04 end state + this delta:

**Add**
- `Domain`: `Movie` entity + movie search capability on `MediaSearchRepository` (+ tests).
- `Packages/FeatureMovies` — `MoviesScreen`, `MovieDetailScreen`, `MovieRow`; depends only on
  {Domain, DesignSystem}; repositories injected.
- `Packages/FeaturePodcasts` — carried over from ch04 (copy; then strip its Infrastructure dep
  like the others).
- `Packages/AppInterfaces` — `LibraryRouter` protocol (keep the existing implementation in the
  current folder if it matches; canonical method: `openSavedItem(_:)`); depends only on Domain.
- `Infrastructure`: `ITunesSearchRepository` learns movie search (implements the new protocol
  method).
- App target: RootView gains a Movies tab; app implements `LibraryRouter` ad hoc (messy on
  purpose — Ch6 cleans it up); Library saves movies.

**Remove**
- `Packages/FeatureAudiobooks` — delete entirely (vs the folder's current drifted contents).
- The `Infrastructure` dependency from ALL feature package manifests.

**Project**
- Schemes: `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo`. README updated (trap = wiring
  has no home).

## Acceptance criteria

- [ ] All schemes build; app runs with Music/Podcasts/Library/Movies tabs; saving a movie in
      Library and tapping it opens `MovieDetailScreen`.
- [ ] `grep -rn "import Infrastructure" code/part-2-modular/ch05-dependency-inversion/Packages/Feature*` → 0 hits.
- [ ] No `FeatureAudiobooks`; no `Audiobook` type in Domain.
- [ ] `diff -qr code/part-2-modular/ch04-vertical-slicing code/part-2-modular/ch05-dependency-inversion` shows only this delta.
- [ ] `swift test --package-path Packages/Domain` passes (including new Movie tests).
- [ ] Prose retitled; banned-names grep → 0 hits; `hugo build` succeeds.
- [ ] Commit: `ch05: Movies born modular; AppInterfaces + inversion; feature set restaged`.

## Out of scope

- No `AppFactory`/`AppRouter`/`CompositionRoot` (Ch6) — the app-side wiring stays ad hoc here.
- Do not touch ch06+ folders/prose.

# Chapter 7 Plan — The Proof: Add One, Delete One (NEW chapter)

Read `plans/00-conventions.md` first. Prerequisite: `plans/ch06-the-composition-root.md` completed.

## Goal

Create the book's new payoff chapter — **no new architecture**, pure proof: add Audiobooks in
a day, delete Podcasts safely — with a brand-new prose file and a brand-new code folder. This
plan also performs the two renames that make room for it (old chapter 7 → chapter 8).

## Prerequisites & start state

- `code/part-2-modular/ch06-composition-root` end state: features {MusicSearch, Podcasts, Library, Movies};
  CompositionRoot in place; no Audiobook anywhere.
- `code/part-2-modular/ch07-advanced-granularity` still exists under its old name and still contains a
  `FeatureAudiobooks` package and an `Audiobook` Domain entity — this plan uses it as the
  SOURCE for the Audiobooks code, and renames it to ch08.

## Step 0 — renames (do these first)

1. `git mv code/part-2-modular/ch07-advanced-granularity code/part-2-modular/ch08-advanced-granularity`
2. `git mv part-2-modular/07-advanced-granularity.md part-2-modular/08-advanced-granularity.md`
   and set its front matter `weight: 8`. Fix any `relref` links pointing at it. (Its content
   is rewritten later by the ch08 plan — do not rewrite it here.)

## Prose tasks — NEW `part-2-modular/07-the-proof.md` (front matter: title "Chapter 7: The Proof: Add One, Delete One", weight: 7)

Follow the 9-beat template, with the twist that there is no refactor — the "work" is a timed
demonstration:

1. **Where we are**: Ch6 end state; the architecture is "done."
2. **The double dare**: the offsite deadline (**Audiobooks** in a week) and the sunset
   decision (**Podcasts** <1% of sessions) land in the same sprint — deliberately, because
   they are the two halves of the book's thesis: cheap addition, safe deletion.
3. **Add one — the feature template**, presented as a timed walkthrough (one dev, one day):
   `Audiobook` entity + repository method in Domain (+ test) → `Infrastructure` implements it →
   new `FeatureAudiobooks` package ({Domain, DesignSystem, AppInterfaces} only) with
   `AudiobooksScreen` → `AppFactory` registration + one `TabView` line in `RootView`.
   Codify this as the reusable **new-feature template** box.
4. **Delete one — compiler-guided deletion**: remove the `FeaturePodcasts` package folder, its
   `project.yml` entry, its `AppFactory` line and tab entry → the compiler then finds the
   orphaned `Podcast` entity and repository method in Domain → remove them → green build.
   **Explicit callback to Ch1**: quote the file count the reader wrote down in the monolith's
   "try deleting Podcasts" exercise, next to today's diff: −1 package, ~2 lines elsewhere,
   zero grep archaeology.
5. **Verify**: scorecard rows — "add a feature: one dev, one day, no other squad blocked" and
   "delete a feature: −1 package, −2 lines, 0 archaeology."
6. **Try it yourself**: re-add a toy feature (e.g. `FeatureFavorites`) from the template in
   under an hour; or delete `FeatureMovies` on a branch and watch the compiler list every
   touchpoint.
7. **Sidebar**: "Is this worth it yet?" flips to *yes, with receipts* — this chapter IS the
   receipt. Reference the Ch1 scoreboard, now fully knocked down.
8. **Cliffhanger**: success scales the team again — four devs now collide *inside*
   `FeatureMusicSearch` (UI polish vs logic work). Does slicing recurse? → Chapter 8.
9. **Hands-On**: `code/part-2-modular/ch07-the-proof`; schemes `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo`.

Diagram: Ch6 diagram with `FeaturePodcasts` replaced by `FeatureAudiobooks`.

## Code tasks — NEW `code/part-2-modular/ch07-the-proof`

Build it as: **copy `code/part-2-modular/ch06-composition-root` → `code/part-2-modular/ch07-the-proof`**, then apply exactly:

**Add** (source the implementations from `code/part-2-modular/ch08-advanced-granularity`, which already has
them — adapt names to canon, don't rewrite from scratch)
- `Domain`: `Audiobook` entity + audiobook search on `MediaSearchRepository` (+ test);
  `Infrastructure` implements it.
- `Packages/FeatureAudiobooks` — `AudiobooksScreen`, `AudiobookRow`; depends on {Domain,
  DesignSystem, AppInterfaces}.
- `AppFactory` builds it; `RootView` gains its tab.

**Remove**
- `Packages/FeaturePodcasts` (folder + `project.yml` entry + `AppFactory` line + tab entry).
- `Podcast` entity and its repository method/tests from Domain; podcast support from
  Infrastructure.

**Project**
- Schemes: `iTunesSearchApp`, `Catalog`, `FeatureLibraryDemo`. New folder `README.md`: this is
  the proof chapter; the diff vs ch06 IS the lesson — keep it minimal and legible.

## Acceptance criteria

- [ ] `code/part-2-modular/ch08-advanced-granularity` exists (renamed); `code/part-2-modular/ch07-advanced-granularity` gone;
      `part-2-modular/08-advanced-granularity.md` exists with weight 8.
- [ ] `code/part-2-modular/ch07-the-proof` builds (all three schemes); app tabs: Music, Library, Movies,
      Audiobooks. No Podcasts anywhere: `grep -rin podcast code/part-2-modular/ch07-the-proof` → 0 hits.
- [ ] `diff -qr code/part-2-modular/ch06-composition-root code/part-2-modular/ch07-the-proof` shows exactly: FeaturePodcasts
      removed, FeatureAudiobooks added, Podcast→Audiobook Domain/Infrastructure swap,
      factory/tab/scheme/README lines.
- [ ] `swift test --package-path Packages/Domain` passes in ch07.
- [ ] New prose file follows the beats, contains the feature-template box and the Ch1 callback.
- [ ] Banned-names grep → 0 hits; `hugo build` succeeds (all relrefs resolve).
- [ ] Commit: `ch07: new proof chapter — add Audiobooks, retire Podcasts; old ch07 renamed to ch08`.

## Out of scope

- Do not rewrite `part-2-modular/08-advanced-granularity.md` beyond front-matter weight/links —
  its rewrite is the ch08 plan.
- Do not split FeatureMusicSearch (Ch8).

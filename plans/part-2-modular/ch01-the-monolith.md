# Chapter 1 Plan — The Monolith

Read `plans/00-conventions.md` first.

## Goal

Align the (already strong) Chapter 1 with the new 8-chapter arc: the startup narrative frame,
the updated roadmap, the "delete Podcasts" exercise that Ch7 calls back to, and the audience
front matter. Code is essentially unchanged.

## Prerequisites & start state

- First chapter — no prior plans required.
- `code/part-2-modular/ch01-the-monolith` exists: a single-app-target SwiftUI monolith with
  `Sources/{App, Models(Track, Podcast), Networking(iTunesAPIClient), Utilities(Services, DateFormatter+Extensions), Views/{Music, Podcasts, Shared}}`,
  built with XcodeGen (`project.yml`). Features: Music search + Podcasts tabs.

## Prose tasks — `part-2-modular/01-the-monolith.md`

Keep the existing structure and voice (this is the book's most polished chapter). Make these
edits only:

1. **Narrative frame**: open with the company story — a two-person startup ships
   iTunesSearchApp v1 (Music + Podcasts). State plainly that at this size the monolith is the
   *right* choice (this seeds the recurring "Is this worth it yet?" sidebar — answer here: no).
2. **Roadmap table** ("The roadmap, on one page"): update chapter references to the 8-chapter
   arc. Features row → Ch4; note that Ch5 adds Movies (born modular), **Ch7 is the proof
   chapter (add Audiobooks, retire Podcasts)**, and advanced granularity is now **Ch8**. Any
   in-text references to "Chapter 7" meaning granularity become Chapter 8.
3. **"Feel the Coupling" hands-on**: add an explicit exercise — *try to delete the Podcasts
   feature; grep and count every file you'd have to touch; write the number down*. Add one
   sentence of foreshadowing: "keep that number — we'll delete Podcasts for real near the end
   of the book, and it will take minutes." Do NOT reveal chapter 7's plot beyond this.
4. **Scoreboard**: keep the existing baseline table exactly (clean build ~3m10s, color ~40s,
   logic tests ~1m+, merge conflicts). It is the canonical baseline all later chapters diff.
5. **Cliffhanger**: keep/sharpen — a designer joins (team of 3) and a brand refresh lands;
   every token tweak rebuilds the world → Chapter 2.
6. Verify no banned names appear (see conventions glossary).

## Prose tasks — `part-2-modular/README.md`

Add a short **Who this book is for / Prerequisites** section: growing teams feeling
merge-conflict and build-time pain (a solo dev on a 5-screen app should *not* apply all of
this — say so); assumes Swift + SwiftUI basics; SwiftPM and XcodeGen are introduced as used.
List the 8 chapters.

## Code tasks — `code/part-2-modular/ch01-the-monolith`

- No structural changes. Only:
  - Ensure the `MONOLITH NOTE` comments cover the three coupling points the prose names
    (views instantiate `iTunesAPIClient` directly; `RootView` knows every feature; features
    reach the global `Services` facade).
  - Update `README.md` in the folder if it disagrees with the prose (schemes: `iTunesSearchApp`).

## Acceptance criteria

- [ ] `cd code/part-2-modular/ch01-the-monolith && xcodegen generate` and the `iTunesSearchApp` scheme builds.
- [ ] Prose mentions Ch2/Ch3/Ch4/Ch6 destinies per the roadmap and says granularity = Ch8.
- [ ] The "delete Podcasts" counting exercise exists and foreshadows a later payoff.
- [ ] `_index.md` has the audience/prerequisites section listing 8 chapters.
- [ ] Banned-names grep over `part-2-modular/01-the-monolith.md` and `code/part-2-modular/ch01-the-monolith` → 0 hits.
- [ ] `hugo build` succeeds.
- [ ] Commit: `ch01: align monolith chapter with 8-chapter arc`.

## Out of scope

- Do not edit `part-2-modular/02…08*.md` or any other `code/part-2-modular/chNN` folder.
- Do not restructure ch01 code, rename types, or add packages.

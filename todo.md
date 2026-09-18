# TODO

## Done — new-repo setup

Rebuilt from `the-modular-ios-playbook` as a blueprint: structure, conventions, and roadmap
carried forward; git history and half-migrated state left behind.

- [x] **Series structure** — one book, four parts (`SERIES-ROADMAP.md`).
- [x] **Series title** — "The iOS Engineering Playbook" (Part II keeps "The Modular iOS Playbook").
- [x] **One carried app** — Medley, a media-discovery startup.
- [x] **House style** — chapter titles as `[Technical Concept] — [Engineering Law]`; pain-first
      openings; tools quarantined in swappable sidebars; per-part signature payoff
      (skills → modules → automations → decision records).
- [x] **Runnable code per chapter** — `code/part-N-*/chNN-*/`, XcodeGen/SwiftPM, scorecards
      (see `code/README.md`).
- [x] **Reference docs** — `SERIES-ROADMAP.md`, `PREQUEL-OUTLINE.md`, `EDITORIAL-MEMO.md`,
      `DESIGN-SYSTEM.md`.
- [x] **Chapter numbering** — restarts per part.
- [x] **Part II ported** — 8 chapters + code, copied verbatim.
- [x] **Medley skeleton** — `code/part-1-architecture/ch01-the-prototype/`.

### Decisions taken

- **No Hugo, no site.** Plain markdown read on GitHub — one file per chapter, one runnable project
  per chapter. The old repo's Hugo/hugo-book/GitHub Pages setup was deliberately dropped.
- **Prose and code separate**, so `diff -r` between two chapter code folders shows exactly that
  chapter's delta and nothing else.
- **`Medley` from day one** for new code (Part I onward).

## Open

- [ ] **Rename `iTunesSearchApp` → `Medley` across Part II.** Prose in `part-2-modular/*.md` and
      all eight code end states. The canonical naming glossary is in
      `plans/part-2-modular/00-conventions.md`; the continuity contract means the rename must be
      applied uniformly so chapter-to-chapter diffs stay clean.
- [ ] **Create the GitHub repo** `mobiledge/ios-engineering-playbook`, then add the remote and push.

## First writing task

- [ ] Draft **Part I, Chapter 1 — The Prototype** (*Structure must earn its place.*), one chapter
      at a time. Outline: `PREQUEL-OUTLINE.md`.

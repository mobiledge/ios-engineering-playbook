# Chapter 6 Plan — Duplication and Abstraction

*Duplication is cheaper than the wrong abstraction.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch05-view-models.md`.

## Goal

Retire ledger row 5 (the view being the whole app). Add Podcasts as a second feature — and make the
chapter about **judgment**: what to share, what to duplicate. Mint the book's first *composite*
skill, `add-feature`.

## Start state

`ch05` end state: Music feature with view model, `ViewState`, row model, and a fake-driven test
suite; one screen; skills = `add-model`, `add-endpoint`, `extract-subview`, `add-view-model`.

## Prose tasks — `part-1-architecture/06-duplication-and-abstraction.md`

- **The pain** — users want podcasts. The founder's cursor hovers over ⌘C, then over the skills
  folder instead.
- **The extraction** — `Podcast` model, `PodcastsView` + `PodcastsViewModel` + `PodcastRow`, and a
  `RootView` `TabView`. Feature folders that mean something: `Sources/Features/Music/`,
  `Sources/Features/Podcasts/` — view, view model, and rows together. Say out loud that this is the
  shape Part II will later cut along.
- **The judgment** — *share* the `SearchClient`; *duplicate* the row views. Rule of three versus
  premature abstraction: `TrackRow` and `PodcastRow` look similar today and will diverge tomorrow;
  a shared `MediaRow` with six configuration parameters is the wrong abstraction. Be concrete about
  what would have to be true before merging them.
- **Prove it** — the feature ships with its own state-machine and formatting suite. A feature is not
  done when it renders; it is done when its tests pass.
- **Codify it** — `add-feature`, composing `add-model`, `add-endpoint`, `add-view-model`, and
  `extract-subview`. Build Podcasts largely by *invoking* the standards codified so far, and be
  transparent about the division of labour: the skills produce scaffolding and tests, the founder
  makes the judgment calls. **Skills encode standards; they don't replace taste.**
- **The ledger** — row 5 struck through.
- **The trap** — two features now disagree about what "brand blue" is.

## Code tasks — `code/part-1-architecture/ch06-duplication-and-abstraction`

```manifest
+ Sources/Models/Podcast.swift
+ Sources/Features/Podcasts/PodcastsView.swift
+ Sources/Features/Podcasts/PodcastsViewModel.swift
+ Sources/Features/Podcasts/PodcastRow.swift
+ Sources/Features/Podcasts/PodcastRowModel.swift
+ Sources/App/RootView.swift
+ Tests/MedleyTests/PodcastDecodingTests.swift
+ Tests/MedleyTests/PodcastsViewModelTests.swift
+ Tests/MedleyTests/Fixtures/podcast_search_response.json
+ .claude/skills/add-feature/SKILL.md
```

**Modify** `SearchClient` to gain a podcast search method (via `add-endpoint`); **modify**
`MedleyApp.swift` to show `RootView`. Move Music's files into `Sources/Features/Music/` if Ch 4 left
any outside it.

## Skill — `add-feature` (composite)

Must explicitly delegate to the four earlier skills rather than restating them — that composition is
the chapter's point.

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–5 struck through.
- [ ] `add-feature/SKILL.md` references all four earlier skills by name.
- [ ] Both features have identical folder shape under `Sources/Features/`.
- [ ] No shared `MediaRow`/`GenericRow` type exists — the duplication is deliberate and survives.
- [ ] `diff` equals manifest.

**mac**
- [ ] Builds; two working tabs; tests pass for both features' view models.

## Out of scope

- No design tokens (Ch 7), no coordinator (Ch 8). Navigation stays local to each tab.
- Do not unify the two row views. That is the chapter's thesis.

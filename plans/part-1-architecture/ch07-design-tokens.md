# Chapter 7 Plan — Design Tokens

*A value used twice is a token.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch06-duplication-and-abstraction.md`.

## Goal

Retire ledger row 6 (views defining the app's look). Give the few visual decisions the app actually
makes (one brand color, one thumbnail size, one corner radius, one row spacing) a single home in
`Sources/DesignSystem/`. Second chapter that **refuses to fake a test**. The chapter is as much about
restraint as extraction: tokenize what is reused or carries a decision, and leave the system alone.

## Start state

`ch06` end state: two features and a `RootView` `TabView`, built from system views, text styles,
and colors. There is no brand color yet. A handful of bare layout numbers have drifted between the
two rows: `TrackRow` uses a 56-point thumbnail with 12 points of spacing, `PodcastRow` 64 and 16.
`Sources/DesignSystem/` holds only `ArtworkView`. Skills through `add-feature`.

## Prose tasks — `part-1-architecture/07-design-tokens.md`

- **The pain** — the first design pass before the App Store launch. A designer friend asks for two
  things: a brand color, so Medley stops looking like a template, and rows that match across tabs.
  The second request is where it hurts. The designer can't tell whether 56 versus 64 is intentional,
  and neither can the founder. Worse: asked for a new "Recently Played" row, the AI picks a
  *60-point* thumbnail, a third size, because bare numbers are all it has ever seen in this
  codebase. The assistant is exactly as good as the conventions it was given.
- **The extraction** — tokens named by *role*, not value: `AppColors` (`accent`, the app's one custom
  color, applied once as the tint in `RootView`; `artworkPlaceholder`), `AppSpacing` (row spacing),
  and `AppRadius` (artwork corner radius), plus the thumbnail size wherever it reads best. Settle the
  drift with the designer (one thumbnail size, one row spacing) and route both rows and
  `ArtworkView` through the tokens. The rows stay separate views; Ch 6's thesis survives. *Share
  values, not views.* Note deliberately that `DesignSystem/` is one target-internal *folder*, named
  for what Part II will one day make a package.
- **The restraint** — say out loud what does **not** become a token. Apple's text styles and semantic
  colors (`.subheadline`, `.secondary`) are already tokens: they name a role and adapt to Dynamic
  Type and dark mode. Wrapping them in `AppFont` would add a name without adding a decision. A value
  used once, in one place, stays where it is.
- **Prove it — honestly** — tokens are looked at, not asserted on. The feedback tool is a **preview
  catalog** rendering every token and component on one screen, the embryo of Part II's Catalog app.
  Do not write assertions about color or size values.
- **Codify it** — `add-design-token` and `add-component`. A value becomes a token when it is used
  twice or carries a brand decision; tokens are named by role; system styles are used directly.
  Components build only from tokens and system styles, receive values rather than sources, ship
  contrived-state previews, and register in the catalog; `ArtworkView` is the exemplar. `CLAUDE.md`
  gains the law: no custom colors or bare layout numbers in feature code. They come from
  `DesignSystem`, or they're system styles. Show the exchange: asked for the "Recently Played" row
  again, the assistant uses `ArtworkView` and the tokens, and asks whether a new size should become a
  token instead of inventing one.
- **The ledger** — row 6 struck through.
- **The trap** — a track detail screen just got approved, and nobody owns the word "navigate".

## Code tasks — `code/part-1-architecture/ch07-design-tokens`

```manifest
+ Sources/DesignSystem/AppColors.swift
+ Sources/DesignSystem/AppSpacing.swift
+ Sources/DesignSystem/AppRadius.swift
+ Sources/DesignSystem/Catalog.swift
+ .claude/skills/add-design-token/SKILL.md
+ .claude/skills/add-component/SKILL.md
```

**Modify** `ArtworkView`, `TrackRow`, and `PodcastRow` to take their size, radius, spacing, and
placeholder from the tokens; **modify** `RootView` to apply `AppColors.accent` as the tint. Keep
every token file small. A token file with one constant is fine; a token nobody uses is not.

## Skill — `add-design-token`, `add-component`

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–6 struck through.
- [ ] `grep -rnE 'Color\(red:|#[0-9a-fA-F]{6}|\.frame\((width|height): [0-9]|(size|spacing|cornerRadius): [0-9]|\.padding\([^)]*[0-9]' Sources/Features` → 0 hits.
- [ ] No `AppFont`, `AppText`, `CardView`, `TagView`, or `PrimaryButton` exists. Nothing wraps system
      text styles.
- [ ] `TrackRow` and `PodcastRow` are still separate views.
- [ ] `Catalog.swift` has a `#Preview` and references every token and every `DesignSystem`
      component by name.
- [ ] `CLAUDE.md` has the no-literals law. "Prove it" states tokens are not unit-tested and why.

**mac**
- [ ] Builds; the catalog preview renders every token and component; the accent shows in the tab bar;
      both rows use the same thumbnail size; tests pass, count unchanged.

## Out of scope

- No SwiftPM package. `DesignSystem` is a folder in the app target — extracting it is Part II Ch 2.
- No navigation work.
- No restyling. The brand color and the settled row metrics are the whole design pass; everything
  else stays system.

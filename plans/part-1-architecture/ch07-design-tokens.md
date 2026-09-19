# Chapter 7 Plan — Design Tokens

*A value used twice is a token.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch06-duplication-and-abstraction.md`.

## Goal

Retire ledger row 6 (views defining the app's look). Extract tokens and the components built from
them into `Sources/DesignSystem/`. Second chapter that **refuses to fake a test**.

## Start state

`ch06` end state: two features, `RootView` `TabView`, hex literals and magic paddings scattered
across both features; skills through `add-feature`.

## Prose tasks — `part-1-architecture/07-design-tokens.md`

- **The pain** — a designer friend counts three slightly different blues and four paddings. Worse:
  the AI, asked for a new card, invents a *fourth* blue — because hex literals are all it has ever
  seen in this codebase. The assistant is exactly as good as the conventions it was given.
- **The extraction** — tokens (`AppColors`, `AppFont`, `AppSpacing`, `AppRadius`) and the components
  built from them (`AppText`, `CardView`, `TagView`, `PrimaryButton`) into `Sources/DesignSystem/`.
  Note deliberately that this is one target-internal *folder*, named for what Part II will one day
  make a package.
- **Prove it — honestly** — tokens are looked at, not asserted on. The feedback tool is a **preview
  catalog** rendering every token and component on one screen — the embryo of Part II's Catalog app.
  Do not write assertions about hex values.
- **Codify it** — `add-design-token` and `add-component`: new visual values enter through tokens;
  components build only from tokens; every component registers in the catalog. `CLAUDE.md` gains the
  law banning raw hex and padding literals in feature code. The AI that invented a blue now refuses
  to — show that exchange.
- **The ledger** — row 6 struck through.
- **The trap** — a track detail screen just got approved, and nobody owns the word "navigate".

## Code tasks — `code/part-1-architecture/ch07-design-tokens`

```manifest
+ Sources/DesignSystem/AppColors.swift
+ Sources/DesignSystem/AppFont.swift
+ Sources/DesignSystem/AppSpacing.swift
+ Sources/DesignSystem/AppRadius.swift
+ Sources/DesignSystem/AppText.swift
+ Sources/DesignSystem/CardView.swift
+ Sources/DesignSystem/TagView.swift
+ Sources/DesignSystem/PrimaryButton.swift
+ Sources/DesignSystem/Catalog.swift
+ .claude/skills/add-design-token/SKILL.md
+ .claude/skills/add-component/SKILL.md
```

**Modify** every feature view to consume tokens and components instead of literals.

## Skill — `add-design-token`, `add-component`

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–6 struck through.
- [ ] `grep -rnE '#[0-9a-fA-F]{6}|Color\(red:|\.padding\([0-9]' Sources/Features` → 0 hits.
- [ ] Every component file has a `#Preview`; `Catalog.swift` references every component by name.
- [ ] `CLAUDE.md` has the no-literals law. "Prove it" states tokens are not unit-tested and why.

**mac**
- [ ] Builds; catalog preview renders every token and component; tests pass, count unchanged.

## Out of scope

- No SwiftPM package. `DesignSystem` is a folder in the app target — extracting it is Part II Ch 2.
- No navigation work.

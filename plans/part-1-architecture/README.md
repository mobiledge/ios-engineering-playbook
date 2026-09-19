# Part I Plans — How They Execute

One plan file per chapter, executed strictly in order, one chapter per day, by a scheduled cloud
agent following [`BOOKBOT.md`](../../BOOKBOT.md).

## Rules

1. **Strictly in order**: `ch01` → `ch02` → … → `ch10`. Each chapter's code folder starts as a
   verbatim copy of the previous chapter's and receives only that plan's delta.
2. **Always read `00-conventions.md` first.** Naming glossary, responsibility ledger, skill library,
   prose template, continuity contract, verification tiers. Conventions beat the chapter plan on any
   conflict.
3. **Two-tier acceptance.** Every plan states `cloud` criteria (checkable on Linux) and `mac`
   criteria (build, run, test). A chapter is done only when both are green.
4. **Stay in scope.** Each plan's "Out of scope" section is binding — it exists to protect later
   chapters' payoffs from being spent early.
5. **Never weaken a check** to make a chapter pass.

## Plan files

| Order | Plan | Prose target | Code target | Skill gained |
|---|---|---|---|---|
| 0 | `00-conventions.md` | — (shared reference) | — | — |
| 1 | `ch01-the-prototype.md` | `part-1-architecture/01-the-prototype.md` | `code/part-1-architecture/ch01-the-prototype` | `CLAUDE.md` seeded |
| 2 | `ch02-models.md` | `…/02-models.md` | `…/ch02-models` | `add-model` |
| 3 | `ch03-networking.md` | `…/03-networking.md` | `…/ch03-networking` | `add-endpoint` |
| 4 | `ch04-view-composition.md` | `…/04-view-composition.md` | `…/ch04-view-composition` | `extract-subview` |
| 5 | `ch05-view-models.md` | `…/05-view-models.md` | `…/ch05-view-models` | `add-view-model` |
| 6 | `ch06-duplication-and-abstraction.md` | `…/06-duplication-and-abstraction.md` | `…/ch06-duplication-and-abstraction` | `add-feature` |
| 7 | `ch07-design-tokens.md` | `…/07-design-tokens.md` | `…/ch07-design-tokens` | `add-design-token`, `add-component` |
| 8 | `ch08-coordinators.md` | `…/08-coordinators.md` | `…/ch08-coordinators` | `add-route` |
| 9 | `ch09-cross-cutting-services.md` | `…/09-cross-cutting-services.md` | `…/ch09-cross-cutting-services` | `add-analytics-event`, `add-service` |
| 10 | `ch10-project-generation.md` | `…/10-project-generation.md` + `epilogue.md` | `…/ch10-project-generation` | `update-project` |

## Editing a plan

Plans are meant to be sharpened before their day comes up. The agent reads whatever is on `main`
that morning, so an edit pushed tonight lands in tomorrow's run. The parts that matter most:

- **The manifest block** — the verifier parses it literally. `+ path` must exist afterwards,
  `- path` must not. Get this right and most of the continuity contract enforces itself.
- **Acceptance criteria** — anything you can express as a grep belongs in the `cloud` tier, where it
  gates the daily loop. Anything needing a compiler goes in `mac`.
- **Out of scope** — the cheapest way to stop a chapter from spending a later chapter's payoff.

# Chapter 10 Plan — Project Generation

*If it isn't in a text file, it isn't under control.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch09-cross-cutting-services.md`.

## Goal

Retire ledger row 9 — the last row. The project file becomes code, the test suite becomes
infrastructure, and the skill library becomes onboarding. Then write the epilogue.

## Start state

`ch09` end state: full MVVM-C monolith with services; skills through `add-service`.

## Prose tasks — `part-1-architecture/10-project-generation.md`

- **The pain** — a second developer is about to join, and the `.xcodeproj` just caused its first
  merge conflict. The founder cleans house.
- **The extraction** — XcodeGen and `project.yml` as the single source of truth (where
  `MOCK_SERVICES` visibly lives); folder layout as the app's table of contents; `Utilities/` for the
  boring helpers. Note that `project.yml` has been present since Ch 1 — this chapter is where the
  reader is told *why*, and where GUI edits are formally banned.
- **Prove it** — the suite built across Chs 2–9 becomes infrastructure: one scheme runs every test
  in seconds, wired into CI on every push. Show the CI file and a real run time.
- **Codify it** — `update-project`: targets, schemes, and flags change through `project.yml`, never
  through Xcode's GUI. Then the payoff of the whole device: **the skill library is the onboarding.**
  The second developer's assistant reads the same `CLAUDE.md` and skills, and their first PR arrives
  in the house style with tests attached, judged by CI before a human looks.
- **Restraint sidebar** — "you may be itching for repositories, use cases, and modules — hold that
  thought."
- **The ledger** — row 9 struck through. The ledger is empty.
- **The trap** — none the founder can see. That is the point.

## Also write — `part-1-architecture/epilogue.md`

Tour the finished app; show the empty ledger and the full skill library. Then the turn: every
boundary here is still a *convention*. A skill is a convention with a helper; a test is a convention
with an alarm; but nothing **stops** a tired developer — or a confidently wrong AI — from calling
the client inside a view. The compiler has no opinion about your folders. Measure and record the
baseline scoreboard (clean build, colour-change loop, test time) that Part II Ch 1 will diff
against, and hand off.

## Code tasks — `code/part-1-architecture/ch10-project-generation`

```manifest
+ .github/workflows/ci.yml
+ Sources/Utilities/README.md
+ .claude/skills/update-project/SKILL.md
+ SCOREBOARD.md
```

**Modify** `project.yml` with documented schemes and flags; **modify** `README.md` with the full
tour and the onboarding story. `SCOREBOARD.md` records the four baseline numbers Part II Ch 1 uses.

## Skill — `update-project`

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger all nine rows struck through.
- [ ] `epilogue.md` exists and contains the baseline scoreboard with four measured numbers.
- [ ] `.claude/skills/` contains all eleven skills from the conventions table.
- [ ] `CLAUDE.md` law count equals the number of chapters that added one.

**mac**
- [ ] `xcodegen generate` from a clean checkout; builds; full suite passes in one scheme.
- [ ] The four scoreboard numbers are real measurements taken on this machine, not invented.

## Out of scope

- The `diff -r ch10 … part-2-modular/ch01` reconciliation is a **Part II** revision task. Note the
  gap; do not edit Part II to close it.

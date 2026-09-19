# Chapter 9 Plan — Cross-Cutting Services

*Depend on what you need, not on who provides it.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch08-coordinators.md`.

## Goal

Retire ledger row 8. Four small protocols with typed vocabularies and console implementations,
injected the same way `SearchClient` is — which quietly concentrates construction at app startup, a
de facto assembly point Part II will formalise.

## Start state

`ch09` starts from `ch08`: MVVM-C complete, `print`-based debugging, no analytics; skills through
`add-route`.

## Prose tasks — `part-1-architecture/09-cross-cutting-services.md`

- **The pain** — the app misbehaves on a stranger's phone. No logs, no crash reports, no analytics.
  The founder is debugging by imagination.
- **The extraction** — `Logger`, `CrashReporter`, `AnalyticsTracker`, `FeatureFlagProvider`, with
  typed `AnalyticsEvent` and `FeatureFlag` vocabularies (a typo cannot invent an event) and console
  implementations selected by a `MOCK_SERVICES` build flag, so debug builds never ship real
  analytics. Services arrive through initializers, exactly like `SearchClient`. Point at the
  consequence: construction is now concentrated in the app struct and the coordinator — an assembly
  point nobody has named yet.
- **Prove it** — the spy pattern. `SpyAnalyticsTracker` records events; tests assert the view model
  tracks a search and logs a failure.
- **Codify it** — `add-analytics-event` and `add-service`: events are typed, side effects arrive by
  injection, every new event ships with a spy test.
- **The ledger** — row 8 struck through.
- **The trap** — the `.xcodeproj` just caused its first merge conflict.

## Code tasks — `code/part-1-architecture/ch09-cross-cutting-services`

```manifest
+ Sources/Services/Logger.swift
+ Sources/Services/CrashReporter.swift
+ Sources/Services/AnalyticsTracker.swift
+ Sources/Services/FeatureFlagProvider.swift
+ Sources/Services/AnalyticsEvent.swift
+ Sources/Services/FeatureFlag.swift
+ Sources/Services/Console/ConsoleServices.swift
+ Tests/MedleyTests/Support/SpyAnalyticsTracker.swift
+ Tests/MedleyTests/AnalyticsTests.swift
+ .claude/skills/add-analytics-event/SKILL.md
+ .claude/skills/add-service/SKILL.md
```

**Modify** view models to take the services they need; **modify** `MedleyApp.swift` to construct
them behind `MOCK_SERVICES`; **modify** `project.yml` to define the flag for Debug only.

## Skill — `add-analytics-event`, `add-service`

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–8 struck through.
- [ ] `grep -rn 'print(' Sources` → 0 hits.
- [ ] `AnalyticsEvent` is an enum or struct with named cases — no raw `String` event names anywhere.
- [ ] `project.yml` defines `MOCK_SERVICES` for Debug only.

**mac**
- [ ] Builds in both configurations; spy tests pass.

## Out of scope

- No composition root, no factory type. Naming the assembly point is Part II Ch 6.

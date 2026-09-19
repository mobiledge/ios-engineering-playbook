# Part I Conventions — Shared Reference for All Chapter Plans

Read this before executing any `chNN-*.md` plan in this directory. On any conflict, this file wins.

## The design in one paragraph

Part I is a single company story told by a solo founder building **Medley**, a media-discovery app
on Apple's keyless iTunes Search API. Chapter 1 is one giant SwiftUI view; Chapter 10 is a
well-factored, tested MVVM-C monolith. Each chapter retires **exactly one row** of the
responsibility ledger and mints **exactly one** AI skill. Each `code/part-1-architecture/chNN-*`
folder is the runnable end state of chapter N.

There are **no SwiftPM packages, no repositories, no use cases, and no modules** in Part I. One
target, one team, one job per type — and the taste to stop there. Anything that smells like the
sequel belongs in Part II.

## The continuity contract (the core rule)

For every chapter N ≥ 2:

- `chNN`'s contents = `ch(N-1)`'s contents + **exactly** the delta stated in chapter N's plan.
  `diff -r` between the two folders must show that delta — no more, no less.
- Chapter N's prose must open by restating chapter N−1's end state (ledger + file tree) before
  introducing new pain.
- No type, folder, skill, or convention may appear in prose or code without having been
  introduced, or disappear without being explicitly retired.

The defining acceptance test of the whole two-book arc:

```bash
diff -r code/part-1-architecture/ch10-project-generation code/part-2-modular/ch01-the-monolith
# → empty, after the Part II revision (which is NOT Part I's job)
```

## Chapter list

Titles come from the book's house style — **[Technical Concept] — [Engineering Law]** — as listed
in `README.md`. The older working titles in `PREQUEL-OUTLINE.md` are content source, not naming
authority.

| # | Prose file (`part-1-architecture/`) | Title | Law | Inciting beat |
|---|---|---|---|---|
| 1 | `01-the-prototype.md` | The Prototype | Structure must earn its place. | Friday idea, Sunday TestFlight |
| 2 | `02-models.md` | Models | Data becomes a type the moment it enters the app. | First crash: missing dictionary key |
| 3 | `03-networking.md` | Networking | The network hides behind a contract. | New query parameter touches view code |
| 4 | `04-view-composition.md` | View Composition | A view renders what it is given, and nothing else. | Corner-radius change breaks the search field |
| 5 | `05-view-models.md` | View Models | Raw data never reaches a view. | `247.0` durations; loading-and-error at once |
| 6 | `06-duplication-and-abstraction.md` | Duplication and Abstraction | Duplication is cheaper than the wrong abstraction. | Podcasts requested; cursor hovers over ⌘C |
| 7 | `07-design-tokens.md` | Design Tokens | A value used twice is a token. | Designer counts three blues; AI invents a fourth |
| 8 | `08-coordinators.md` | Coordinators | A screen never decides where to go next. | Track detail + settings sheet + "deep link someday" |
| 9 | `09-cross-cutting-services.md` | Cross-Cutting Services | Depend on what you need, not on who provides it. | Misbehaves on a stranger's phone; no logs |
| 10 | `10-project-generation.md` | Project Generation | If it isn't in a text file, it isn't under control. | Second developer joining; `.xcodeproj` conflict |

Code folders match one-to-one: `code/part-1-architecture/ch01-the-prototype` …
`ch10-project-generation`.

## The responsibility ledger

Chapter 1 opens it; each chapter retires exactly one row; the epilogue shows it empty.

| # | Job the one view is doing | Retired in |
|---|---|---|
| 1 | Parse API responses | Ch 2 |
| 2 | Talk to the network | Ch 3 |
| 3 | Render every pixel of the screen | Ch 4 |
| 4 | Shape data for display + hold screen state | Ch 5 |
| 5 | Be the whole app | Ch 6 |
| 6 | Define the app's look | Ch 7 |
| 7 | Decide where to go next | Ch 8 |
| 8 | Log, track, report, and flag | Ch 9 |
| 9 | Describe the project itself | Ch 10 |

Every chapter's prose must render the ledger with the rows retired so far struck through, and the
chapter's own row marked as retired *in this chapter*.

## The skill library

Each chapter codifies its standard as a skill under `.claude/skills/<name>/SKILL.md` inside that
chapter's code folder. A skill is one page: the convention, its **why** (the pain from this
chapter), one exemplar file path in the codebase, and acceptance checks.

| Chapter | Skill gained |
|---|---|
| 1 | `CLAUDE.md` rulebook seeded + empty `.claude/skills/` |
| 2 | `add-model` |
| 3 | `add-endpoint` |
| 4 | `extract-subview` |
| 5 | `add-view-model` |
| 6 | `add-feature` (composes 2–5) |
| 7 | `add-design-token`, `add-component` |
| 8 | `add-route` |
| 9 | `add-analytics-event`, `add-service` |
| 10 | `update-project` |

`CLAUDE.md` grows by one law per chapter and is never rewritten wholesale.

## Chapter prose template

Every chapter follows this beat structure, in order. Headings must match exactly — the verifier
greps for them.

1. `## Where we are` — restate the previous chapter's end state (ledger + file tree).
2. `## The pain` — the beat from the table above, with a concrete cost the reader can feel.
3. `## The extraction` — the concept and the refactor, in the order actually performed.
4. `## Prove it` — test the type just created, while the seam is fresh. Chapters whose output is
   not unit-testable logic (Ch 4 rendering, Ch 7 tokens) must say so **honestly** and use previews
   instead — do not fake a test.
5. `## Codify it` — distill the standard into the chapter's skill file; show the skill and one
   example of the assistant applying it.
6. `## The ledger` — the table, with this chapter's row retired.
7. `## Is this worth it yet?` — honest cost/benefit at this app size.
8. `## The trap this leaves open` — the pain that opens the next chapter.
9. `## Hands-on` — link to `code/part-1-architecture/chNN-*` with build and test instructions.

Chapter 1 has no "Where we are" (nothing precedes it) and its "Prove it" is the test the founder
*cannot* write — that is the point.

## Canonical naming glossary

Use ONLY the canonical names. The banned column lists names that must never appear in Part I prose
or code.

| Concept | Canonical | Banned |
|---|---|---|
| App target | `Medley` | `iTunesSearchApp`, `MedleyApp` as a target name |
| App entry point | `MedleyApp` (the `@main struct`) | — |
| Root view | `RootView` (a `TabView`, from Ch 6) | — |
| Models | `Track`, `Podcast` | `TrackModel`, `TrackDTO`, `TrackEntity` |
| Networking | `SearchClient` protocol, `ITunesAPIClient` conforming | `NetworkManager`, `APIService`, `.shared` singletons |
| View models | `<Feature>ViewModel`, `@Observable` | `<Feature>VM`, `ObservableObject` |
| Screen state | one `ViewState` enum: `idle/loading/loaded/empty/failed` | loose `isLoading`/`error` Bools after Ch 5 |
| Navigation | `AppCoordinator` (`@Observable`), `Destination` enum | `Router`, `NavigationManager`, `MainCoordinator` |
| Design system | `AppColors`, `AppFont`, `AppSpacing`, `AppRadius`; `AppText`, `CardView`, `TagView`, `PrimaryButton` | raw hex or padding literals in feature code after Ch 7 |
| Services | `Logger`, `CrashReporter`, `AnalyticsTracker`, `FeatureFlagProvider` + typed `AnalyticsEvent`/`FeatureFlag` | `Analytics.shared`, stringly-typed events |
| Folders | `Sources/{App,Models,Networking,Features,DesignSystem,Services,Utilities}` | `ViewControllers/`, `Helpers/`, `Managers/` |
| Feature folders | `Sources/Features/Music/`, `Sources/Features/Podcasts/` | `Sources/Views/Music/` |

**Sequel leakage — banned in Part I entirely:** `Packages/`, `Package.swift`, `Repository`,
`UseCase`, `Domain`, `Infrastructure`, `AppInterfaces`, `CompositionRoot`, `AppFactory`,
`Feature*` as a module name, `import DesignSystem`.

**UIKit teaching is banned.** This is a SwiftUI book: `NavigationStack`, `TabView`, `@Observable`.
`UIViewController`/`pushViewController` may never appear. Chapter 8 contains the single permitted
exception: one sidebar noting that `AppCoordinator` is SwiftUI's answer to UIKit's Coordinator.

## Verification tiers

Chapter plans state acceptance criteria in two tiers, because the daily agent runs in a **Linux
cloud sandbox with no Xcode**.

**Tier `cloud`** — runs anywhere, and is what the daily agent gates itself on:

```bash
./scripts/verify.sh --tier cloud <NN>
```

- continuity `diff -qr` against chapter N−1 equals the plan's stated delta
- every file in the plan's file manifest exists (and every file it says to delete is gone)
- banned-names grep over prose + code → 0 hits
- prose contains all nine template headings, in order
- ledger table present with the right rows struck through
- the chapter's skill file exists at `.claude/skills/<name>/SKILL.md`
- all relative markdown links resolve
- `swiftc -parse` syntax check on every `.swift` file, if a Swift toolchain is present

**Tier `mac`** — requires Xcode, run on the founder's machine:

```bash
./scripts/verify.sh --tier mac <NN>
```

- `xcodegen generate` succeeds (Ch 10 onward; earlier chapters use a committed project or none)
- `xcodebuild -scheme Medley … build` succeeds
- `xcodebuild -scheme Medley … test` passes, and the test count is ≥ the previous chapter's
- the app runs and the chapter's "Hands-on" instructions are accurate

A chapter is **not done** until both tiers are green. The pipeline tracks this: `cloud` green marks
the chapter `awaiting-mac`; `mac` green marks it `done`.

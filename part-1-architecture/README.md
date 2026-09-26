# Part I · iOS Architecture, One Skill at a Time

**Where should this *code* live?** · 1 → 2 people

A solo founder refactors a one-file SwiftUI app into a tested MVVM-C monolith — one
Single-Responsibility extraction per chapter, each codified as a reusable AI skill.

This is **Part I** of a four-part book that follows one company, Medley, from a solo prototype to a
full product organization. For the whole arc, see the [Series Roadmap](../README.md).

> **In progress.** Chapter 1 is drafted; the rest of the chapter list and the beat-by-beat outline
> below are the plan. Per-chapter execution plans live in
> [`plans/part-1-architecture/`](../plans/part-1-architecture/).

The reader finishes with a disciplined, tested MVVM-C monolith — plus an AI skill library that can
rebuild any part of it on demand — the app Part II picks up on its first page.

The title means it both ways: each chapter grows a skill the reader keeps (an extraction, a testing
pattern, a judgment call) and mints a literal AI skill the project keeps — one row of the ledger
retired, one skill gained, until the architecture is something both the team and its tools know how
to build.

> **Contract with Part II:** Part II will be revised so its Chapter 1 monolith IS this part's end
> state (that revision is planned separately). Part I therefore owns the road from "one giant view"
> to "well-factored MVVM-C monolith"; Part II owns the road from there to compiler-enforced modules.

## Why this part

Almost every architecture book starts at chapter three of the real story: the app already has
models, view models, a navigation layer, tidy folders. This part is chapters one and two — the craft
of getting there. It begins with everything crammed into a single SwiftUI view and, one Single
Responsibility Principle extraction at a time, arrives at a monolith with a clear architecture:
**MVVM-C** — views that only render, view models that shape data for presentation and hold screen
state, and a coordinator that owns navigation.

Two habits get installed along the way, chapter by chapter:

- **Tests are not a chapter; they are a habit.** Every time a responsibility gets its own type,
  that chapter tests it — because *testability is the proof that the extraction worked*.
- **Conventions are not tribal knowledge; they are skills.** Every standard the reader adopts gets
  codified, right then, into an **AI skill** — a short, versioned instruction file an AI coding
  assistant can execute — so the *next* model, view model, route, or feature is built to the same
  standard by asking for it. The reader ends the part with a skill library that is the executable
  documentation of their architecture.

No SwiftPM packages, no repositories, no use cases, no dependency graphs. One target, one team, one
job per type — and the taste to stop there.

## Who this part is for

You can build SwiftUI screens, manage `@State`, and call an API with async/await — but your
projects grow into one enormous view file and you can feel it. You use (or want to use) an AI coding
assistant and suspect it could do more than autocomplete. This part teaches structure, judgment,
testing as you go, codifying conventions, and restraint. It does not teach Swift or SwiftUI. The
running examples use Claude Code-style skills (a folder of `SKILL.md` files plus a project
`CLAUDE.md` rulebook), but the pattern ports to any assistant that reads project-level
instructions.

## The narrative

A solo founder builds **Medley** — a media-discovery app: music search, then podcasts, backed by
Apple's free iTunes Search API — from weekend prototype to the v1 a two-person startup ships at the
start of Part II. The founder works alongside an AI assistant the whole way, and keeps noticing the
same thing: *the assistant is exactly as good as the conventions it's been given.* Every chapter
opens with a real moment in that growth (a crash, a feature request, a bug that ships twice, an AI
suggestion that ignores a standard nobody wrote down) that motivates exactly one extraction.

## The recurring devices

**1. The responsibility ledger.** Chapter 1 writes down every job the one-and-only view is doing.
Each chapter retires exactly one row. The epilogue shows the empty ledger — and then asks what the
compiler thinks of all these tidy boundaries. (Answer: nothing. That's Part II.)

| # | Job the view is doing | Retired in |
|---|---|---|
| 1 | Parse API responses | Ch 2 — Models |
| 2 | Talk to the network | Ch 3 — Networking |
| 3 | Render every pixel of the screen | Ch 4 — View Composition |
| 4 | Shape data for display + hold screen state | Ch 5 — View Models |
| 5 | Be the whole app | Ch 6 — Duplication and Abstraction |
| 6 | Define the app's look | Ch 7 — Design Tokens |
| 7 | Decide where to go next | Ch 8 — Coordinators |
| 8 | Log, track, report, and flag | Ch 9 — Cross-Cutting Services |
| 9 | Describe the project itself | Ch 10 — Project Generation |

**2. The "Prove it" beat.** Every chapter that isolates a responsibility closes by testing the type
it just created — right there, while the seam is fresh: *extract → inject what it needs → prove it
in milliseconds*. Chapters whose output isn't unit-testable logic (pure rendering, tokens) say so
honestly and use the right feedback tool instead (previews).

**3. The "Codify it" beat.** After the proof comes the skill: the chapter distills the standard it
just established — naming, file placement, required tests, the things reviewers would otherwise
repeat forever — into a skill file the AI assistant applies from then on. The rhythm completes:
*extract → prove → codify*. Each skill is small (a page) and portable: a list of best
practices, each with its reason, that would hold in any Swift app, plus acceptance checks (which the
"Prove it" tests provide). The project-specific half — the law, and which file in *this* codebase to
copy — goes in `CLAUDE.md`. Later skills compose earlier ones, so by Ch 6 "add a feature" is one request. The
skill library grows in lockstep with the ledger — one row retired, one skill gained.

| Chapter | Skill gained |
|---|---|
| Ch 1 | `CLAUDE.md` rulebook seeded (+ empty `.claude/skills/` as a promise) |
| Ch 2 | `add-model` |
| Ch 3 | `add-endpoint` |
| Ch 4 | `extract-subview` |
| Ch 5 | `add-view-model` |
| Ch 6 | `add-feature` (composes add-model, add-endpoint, add-view-model, extract-subview) |
| Ch 7 | `add-design-token` / `add-component` |
| Ch 8 | `add-route` |
| Ch 9 | `add-analytics-event` / `add-service` |
| Ch 10 | `update-project` + the library becomes team onboarding |

## Chapters in this part

Each chapter title follows the series house style — **[Technical Concept] — [Engineering Law]** —
and ends with an AI skill.

1. [The Prototype](01-the-prototype.md) — *Structure must earn its place.*
2. **Models** — *Data becomes a type the moment it enters the app.*
3. **Networking** — *The network hides behind a contract.*
4. **View Composition** — *A view renders what it is given, and nothing else.*
5. **View Models** — *Raw data never reaches a view.*
6. **Duplication and Abstraction** — *Duplication is cheaper than the wrong abstraction.*
7. **Design Tokens** — *A value used twice is a token.*
8. **Coordinators** — *A screen never decides where to go next.*
9. **Cross-Cutting Services** — *Depend on what you need, not on who provides it.*
10. **Project Generation** — *If it isn't in a text file, it isn't under control.*

*Epilogue — The Limits of Convention: a rule the compiler can't see is a rule waiting to break.*

## Chapter outlines

### 1. The Prototype — *Structure must earn its place.*
**Beat:** Friday night idea, Sunday night TestFlight build. A single `ContentView` holds an inline
`URLSession` call, `JSONSerialization` dictionaries, a few bare layout numbers, and a `Bool` for
every screen condition. The AI assistant, asked to "add a podcasts screen," cheerfully
offers to duplicate all of it — it has no standards to follow because none exist. The chapter is
honest: *this is the right way to start* — shipping beats structure. Introduce SRP as the part's
lens and open the responsibility ledger. **Prove it:** the founder tries to write a single unit test
for "durations show as minutes:seconds" — and can't; nothing exists to instantiate except the
entire screen. The empty test target stays in the project as a promise. **Codify it:** the other
promise — a `CLAUDE.md` with the only rule so far ("we ship; structure must earn its place") and an
empty `.claude/skills/` folder. The thesis lands: *an unwritten convention doesn't exist — not for
the next developer, and not for the AI.* **Trap left open:** everything.

### 2. Models — *Data becomes a type the moment it enters the app.*
**Beat:** the first crash — a missing dictionary key, found by a user. **Extraction:** `Codable`
structs (`Track`), decoded once at the boundary; optionality modeled honestly. `Models/` appears.
**Prove it:** the first real tests — decode fixture JSON (happy case, missing artwork URL, malformed
date); the crash becomes a regression test. **Codify it:** `add-model` — the part's first skill, and
the template for all that follow: portable best practices (decode at the boundary, honest
optionals, real fixtures) and acceptance checks (fixtures + decoding tests exist and pass), while
`CLAUDE.md` gains the law and names `Track.swift` as the example to copy. The founder asks the assistant for the next model and
watches it arrive *with its fixtures*. **Ledger:** the view stops being a parser. **Trap:** it still
fetches.

### 3. Networking — *The network hides behind a contract.*
**Beat:** the search endpoint needs a new parameter and the change touches view code.
**Extraction:** `ITunesAPIClient` — URL building, async/await, status codes, typed errors — fronted
by a small protocol (`SearchClient`) and *handed to* whoever needs it, not grabbed as a global.
**Prove it:** tests for the pure logic — URL/query construction, error mapping, decoding via a
stubbed `URLProtocol`; we test *our* logic, not Apple's networking. **Codify it:** `add-endpoint` —
how a new API capability enters the app: extend the protocol, implement in the client, map errors,
test the URL and the decode. The "hand it in, don't grab it" injection rule graduates into
`CLAUDE.md` as a project-wide law the assistant now applies everywhere. **Ledger:** the view stops
being a networker. **Trap:** the screen is still one 70-line `body`.

### 4. View Composition — *A view renders what it is given, and nothing else.*
**Beat:** changing the artwork corner radius breaks the search-field layout. **Extraction:**
decompose the mega-view — `MusicSearchView` owns flow; `TrackRow` and `ArtworkView` render what
they're given. Where `@State` should live; why small view structs are free. **Prove it — honestly:**
pure rendering has no logic to unit test, and the chapter says so; the feedback tool is
**previews**, one per component, with contrived states (longest title, missing artwork). The itch —
"the formatting I *want* to test is still trapped in view code" — is deliberate. **Codify it:**
`extract-subview` — when a view earns extraction (it renders a concept, not a coincidence), what it
receives (values, not sources), and the requirement that every extracted view ships with its
contrived-state previews. **Ledger:** the view stops rendering every pixel. **Trap:** the view still
*thinks* — formatting dates, juggling `isLoading`/`error`/`results` booleans, deciding what "empty"
means.

### 5. View Models — *Raw data never reaches a view.*  *(MVVM enters)*
**Beat:** a three-`Bool` state tangle produces two screenshots — a retry that draws the spinner on
top of the error, and an error drawn over the previous search's results — and none of it can be
tested, nor can the duration formatting still waiting since Chapter 1. **Extraction:**
`MusicSearchViewModel` (`@Observable`) — owns a single `ViewState` enum
(`idle/loading/loaded/empty/failed`), fetches through the injected `SearchClient`, and transforms
`Track` into a display-ready row model: *the view model shapes data for presentation; the view just
renders it.* **Prove it — the part's flagship test moment:** a fake `SearchClient` drives the view
model through every state; assertions run on formatted output in milliseconds, no simulator. The
Ch 1 test the founder couldn't write gets written, verbatim, and passes. **Codify it:**
`add-view-model` — the richest skill yet: the `ViewState` enum shape, init-injected dependencies,
row-model mapping, and the non-negotiable fake-driven state/formatting test suite. From here on,
"make a view model for X" returns the whole pattern, tests included. **Ledger:** the view stops
shaping data and holding screen logic. **Trap:** there's still only one feature — and a request
incoming.

### 6. Duplication and Abstraction — *Duplication is cheaper than the wrong abstraction.*
**Beat:** users want podcasts; the founder's cursor hovers over ⌘C — then hovers over the skills
folder instead. **Extraction:** `Podcast` model, `PodcastsView` + `PodcastsViewModel` +
`PodcastRow`, a `RootView` `TabView`, and feature folders that mean something: `Features/Music/`,
`Features/Podcasts/` (view, view model, rows together — the shape Part II will later cut along). The
judgment chapter: *share* the client, *duplicate* the rows — rule of three vs premature
abstraction. **Prove it:** the feature ships with its state-machine + formatting suite; a feature
isn't done when it renders, it's done when its tests pass. **Codify it:** `add-feature` — the part's
first *composite* skill: folder layout plus calls into `add-model`, `add-endpoint`,
`add-view-model`, `extract-subview`. Podcasts is built largely by *invoking* the standards codified
so far, and the chapter is transparent about the division of labor: the skills produce the
scaffolding and the tests; the founder makes the judgment calls (what to share, what to duplicate).
Skills encode standards — they don't replace taste. **Ledger:** the view stops being the whole app.
**Trap:** the two rows have already drifted (56-point thumbnails with 12 points of spacing in
Music, 64 and 16 in Podcasts), and nothing says which is right.

### 7. Design Tokens — *A value used twice is a token.*
**Beat:** the first design pass. A designer friend wants a brand color and rows that match across
tabs, and nobody can say whether 56 versus 64 was intentional. Asked for a new "Recently Played"
row, the AI picks a *60-point* thumbnail, a third size, because bare numbers are all it has ever
seen here. **Extraction:** tokens named by role (`AppColors.accent`, the app's one custom color;
`AppSpacing`; `AppRadius`) into `DesignSystem/` next to `ArtworkView`, one target-internal folder
deliberately named for what Part II will one day make a package. Both rows take their numbers from
the tokens but stay separate views: *share values, not views.* **The restraint:** system text
styles and semantic colors are already tokens, so there is no `AppFont` wrapper, and a value used
once stays put. **Prove it — honestly:** tokens are looked at, not asserted on; the feedback tool is
a **preview catalog** rendering every token and component (the embryo of Part II's Catalog app).
**Codify it:** `add-design-token` / `add-component` — a value becomes a token when it's reused or
carries a brand decision, components build only from tokens and system styles, every component
registers in the catalog; `CLAUDE.md` bans custom colors and bare layout numbers in feature code.
The AI that invented a size now asks whether it should be a token. **Ledger:** the views stop
defining the app's look. **Trap:** a track detail screen just got approved, and nobody
owns the word "navigate."

### 8. Coordinators — *A screen never decides where to go next.*  *(the C arrives)*
**Beat:** tap a track → detail screen; a settings sheet; marketing wants a deep link to a specific
track "someday." `NavigationLink`s hard-coded in row views start binding screens to each other.
**Extraction:** `AppCoordinator` (`@Observable`) owns the `NavigationStack` path and sheet state per
tab; views stop navigating and start *reporting intent* ("user tapped track") via closures the
coordinator wires; destinations become an enum the coordinator maps to screens. View models present,
views render, the coordinator steers — **MVVM-C is now complete and named.** **Prove it:**
navigation is just logic now — tests assert that intents append the right destination, dismissal
pops it, and a deep-link URL parses to the right route. **Codify it:** `add-route` — new destination
= enum case + coordinator mapping + intent closure + route/deep-link tests; `CLAUDE.md` gains "views
never construct destinations." **Ledger:** the views stop deciding where to go next. **Trap:**
debugging is still `print("here 3")`, and the app has no idea what users do.

### 9. Cross-Cutting Services — *Depend on what you need, not on who provides it.*
**Beat:** the app misbehaves on a stranger's phone: no logs, no crash reports, no analytics.
**Extraction:** four small protocols — `Logger`, `CrashReporter`, `AnalyticsTracker`,
`FeatureFlagProvider` — with typed `AnalyticsEvent`/`FeatureFlag` vocabularies and console
implementations, selected by a `MOCK_SERVICES` build flag so debug builds never ship real analytics.
Services are *injected through initializers*, same as the `SearchClient` — which quietly
concentrates construction at app startup (the app struct + coordinator), a de facto assembly point
Part II will one day formalize. **Prove it:** the spy pattern — a `SpyAnalyticsTracker` records
events; tests assert the view model tracks a search and logs a failure. **Codify it:**
`add-analytics-event` / `add-service` — events are typed (a typo can't invent one), side effects
arrive by injection, every new event ships with a spy test. **Ledger:** the views and view models
stop owning side effects. **Trap:** the `.xcodeproj` just caused its first merge conflict.

### 10. Project Generation — *If it isn't in a text file, it isn't under control.*
**Beat:** a second developer is about to join; the founder cleans house. **Extraction:** the project
file becomes code — XcodeGen and `project.yml` (where `MOCK_SERVICES` visibly lives); folder layout
as the app's table of contents; `Utilities/` for the boring helpers. **Prove it:** the suite built
across Chs 2–9 becomes infrastructure — one scheme runs every test in seconds, wired into CI on
every push. **Codify it:** `update-project` (how targets, schemes, and flags change — through
`project.yml`, never through Xcode's GUI) — and the payoff of the whole device: the skill library
**is** the onboarding. The second developer's assistant reads the same `CLAUDE.md` and skills, and
their first PR arrives in the house style with tests attached, judged by CI before a human ever
looks. Conventions no longer live in the founder's head. Plus the restraint sidebar: *"you may be
itching for repositories, use cases, and modules — hold that thought."* **Ledger:** the last row
retires. **Trap:** none the founder can see. That's the point.

### Epilogue — The Limits of Convention — *A rule the compiler can't see is a rule waiting to break.*
Tour the finished app: views render, view models present, the coordinator steers, services hide
behind contracts, the project file is text, every seam earned its tests the day it was cut, and
every convention lives in a skill the whole team — human and AI — builds with. The ledger is empty;
the suite runs in seconds; a new developer ships in the house style on day one. Then the turn: every
boundary in this app is still a *convention*. A skill is a convention with a helper; tests are a
convention with an alarm; but nothing *stops* tomorrow's tired developer — or a confidently wrong
AI — from calling the client inside a view or importing a feature sideways. The compiler has no
opinion about your folders, your rulebook, or your skills. Measure the baseline scoreboard (clean
build, color-change loop, test time) and hand off: the team is about to grow from two to twenty, and
turning these conventions into *rules the compiler enforces* is the story of **Part II — The
Modular iOS Playbook**.

## End state (Part II's new starting line)

```text
Medley/
├── project.yml
├── CLAUDE.md           # the rulebook, grown one law per chapter
├── .claude/skills/     # add-model, add-endpoint, extract-subview, add-view-model,
│                       # add-feature, add-design-token, add-component, add-route,
│                       # add-analytics-event, add-service, update-project
├── Sources/
│   ├── App/            # @main, RootView (TabView), AppCoordinator
│   ├── Models/         # Track, Podcast
│   ├── Networking/     # SearchClient protocol, ITunesAPIClient
│   ├── Features/
│   │   ├── Music/      # MusicSearchView, MusicSearchViewModel, TrackDetailView, TrackRow
│   │   └── Podcasts/   # PodcastsView, PodcastsViewModel, PodcastRow
│   ├── DesignSystem/   # tokens + shared components (target-internal folder)
│   ├── Services/       # Logger/CrashReporter/AnalyticsTracker/FeatureFlagProvider + console impls
│   └── Utilities/
└── Tests/              # grown chapter by chapter: model fixtures, client logic,
                        # view-model suites (Music + Podcasts), coordinator routes, service spies
```

## Code

End states live in [`code/part-1-architecture/`](../code/part-1-architecture/), one runnable folder
per chapter (`ch01-the-prototype` … `ch10-project-generation`), each the end state of its chapter —
including its tests **and its skills**, so both the suite and the skill library visibly grow folder
by folder. The app target is named `Medley` from the first chapter.

The defining acceptance test of the whole two-part arc: Part I's final folder and the revised
Part II's `ch01` are the same app —

```bash
diff -r code/part-1-architecture/ch10-project-generation code/part-2-modular/ch01-the-monolith
# → empty, after the Part II revision
```

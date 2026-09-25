# Series Roadmap

One company: **Medley**, a media-discovery startup. One app — Medley for iOS, where people
search and save music, podcasts, movies, and audiobooks — followed from weekend prototype to
mature product organization across four books. Each book answers one question, at an
increasing scale:

| Book | Title | Question | Scale |
|---|---|---|---|
| 1 | iOS Architecture, One Skill at a Time | Where should this code live? | 1 → 2 people |
| 2 | The Modular iOS Playbook | Where should this module live? | 2 → 20 people |
| 3 | Developer Experience | How should engineers work? | the engineering org |
| 4 | Product Engineering | How should the company learn? | the whole company |

The arc in four lines: **write better code → build better systems → build a better
engineering organization → build a better product organization.**

> **The product vs the plumbing:** Medley is the product and the company; Apple's free,
> keyless iTunes Search API is merely the data source it happens to be built on — an
> implementation detail readers benefit from (build and run every chapter, no signup) but
> never the star. Existing code still uses the historical `iTunesSearchApp` target name;
> the rename to `Medley` lands with the planned Book 2 revision, not before.

## House style (all four books)

- **Chapter naming:** `[Technical Concept] — [Engineering Law]`. The title is short,
  searchable, industry-standard terminology — it tells you *what you're learning*. The
  subtitle is a durable law — story-independent, usable as a code-review guideline — it
  tells you *why it matters*.
- **Pain first.** Every chapter opens with a concrete, quantified incident from the
  company's story ("a pull request takes 42 minutes", "a missing key crashes the app",
  "nobody uses this feature") — never with a tool. Tools appear only as the resolution,
  quarantined in swappable sidebars so the books outlive vendor churn.
- **Signature payoff per book.** Book 1: every chapter ends with an AI skill. Book 2: every
  chapter ends with a runnable architecture and a scorecard. Book 3: every chapter ends with
  an inner-loop number moving. Book 4: every chapter ends with a product decision made from
  data.
- **Artifact trail:** skills (1) → modules (2) → automations (3) → decision records (4).
- **Every book argues against itself once**, in its closer: the limits of convention (1),
  when to stop modularizing (2), the limits of speed (3), when not to measure (4).

## Book 1 — iOS Architecture, One Skill at a Time

*A solo founder refactors a one-file SwiftUI app into a tested MVVM-C monolith, one Single
Responsibility extraction per chapter; each chapter codifies its convention as a reusable AI
skill. Full outline: [part-1-architecture/README.md](part-1-architecture/README.md).*

1. **The Prototype** — *Structure must earn its place.*
2. **Models** — *Data becomes a type the moment it enters the app.*
3. **Networking** — *The network hides behind a contract.*
4. **View Composition** — *A view renders what it is given, and nothing else.*
5. **View Models** — *Raw data never reaches a view.*
6. **Duplication and Abstraction** — *Duplication is cheaper than the wrong abstraction.*
7. **Design Tokens** — *A value used twice is a token.*
8. **Coordinators** — *A screen never decides where to go next.*
9. **Cross-Cutting Services** — *Depend on what you need, not on who provides it.*
10. **Project Generation** — *If it isn't in a text file, it isn't under control.*

**Epilogue: The Limits of Convention** — *A rule the compiler can't see is a rule waiting to
break.*

## Book 2 — The Modular iOS Playbook

*The team grows to 20 and the monolith is split into SwiftPM modules; boundaries stop being
conventions and become compiler-enforced rules. Chapters live in [part-2-modular/](part-2-modular),
runnable end states in [code/part-2-modular/](code/part-2-modular). To be revised to start from Book 1's end state (MVVM-C
monolith).*

1. **The Monolith** — *A boundary the compiler can't enforce is a suggestion.*
2. **The Design System** — *Extract the leaves of the graph first.*
3. **Domain and Infrastructure** — *Business rules depend on nothing.*
4. **Vertical Slicing** — *A team owns a target, not a folder.*
5. **Dependency Inversion** — *Dependencies point toward stability.*
6. **The Composition Root** — *The object graph is built in exactly one place.*
7. **Feature Lifecycle** — *The test of a boundary is deletion.*
8. **Module Granularity** — *Split modules when people collide, not when diagrams do.*

## Book 3 — Developer Experience

*The inner loop becomes a product and the engineering organization is its customer. Every
chapter opens with developer pain and ends with a measured improvement to the loop.*

1. **Engineering Metrics** — *What isn't measured won't get faster.*
   *(incident: a pull request takes 42 minutes)*
2. **Test Impact Analysis** — *A change pays only for what it touches.*
   *(absorbs test reliability / flaky-test management)*
3. **Build Caching** — *Repeated work should happen once.*
   *(absorbs reproducible environments — deterministic setup is the precondition for cache hits)*
4. **Continuous Delivery** — *Anything that ships more than once must ship itself.*
5. **Platform Engineering** — *Your engineers are users too.*
   *(absorbs onboarding and automated migrations as the platform team's flagship products;
   Book 1's skill library graduates into an org-wide internal product)*

**Epilogue: The Limits of Speed** — *Velocity is wasted on the wrong destination.*

Deferred to a fuller edition: Review Automation (*machines review style; humans review
judgment*). Each absorbed section keeps its law and can be promoted back to a chapter.

## Book 4 — Product Engineering

*The outer loop: the hero is the feedback loop, not any vendor. Every chapter ends with a
product decision made from real data. Built on the four service contracts planted in Book 1
(`Logger`, `CrashReporter`, `AnalyticsTracker`, `FeatureFlagProvider`).*

1. **Product Analytics** — *Every important question needs an answer before it is asked.*
   *(absorbs feedback-loop framing and usage analytics — including the retire-a-feature
   decision, replaying Book 2's deletion proof as a product call)*
2. **A/B Testing** — *Opinions are hypotheses until tested.*
   *(absorbs statistical rigor — peeking, sample size, the experiment that lied)*
3. **Feature Flags** — *Every launch needs an undo.*
   *(staged rollout, canary, kill switch)*
4. **Observability** — *Production must be able to explain itself.*
5. **Metrics and Decision Records** — *A decision without a record is an argument waiting to
   repeat.*
   *(absorbs metric definitions; closes with Goodhart's law — when a measure becomes a
   target, it stops measuring)*

**Epilogue: The Company That Learns** — the four-book arc closes: the ledger, the modules,
the scoreboards, and the decision records shown as one continuous system.

## Deliberate cross-book rhymes

- Book 1 opens with *"structure must earn its place"*; Book 4's Product Analytics echoes it
  as *features must earn their place with data* — the same law, applied first to code,
  finally to product.
- Book 2's "delete a feature safely" proof returns in Book 4 as a data-driven product
  decision.
- Book 1's AI skills → Book 3's platform products → the series-long escalation: *a skill
  suggests, a compiler rejects, a platform migrates you automatically.*
- The scoreboard instrument persists throughout, pointed at code, then systems, then the
  team, then the company; Book 4's currency is decision latency.

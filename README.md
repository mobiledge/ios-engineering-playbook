# The iOS Engineering Playbook

A practical, step-by-step guide to iOS engineering at scale — from a solo prototype to a modular
architecture, a fast developer platform, and a product organization that learns from data.

This is a single book in **four parts**, following one company — **Medley**, a media-discovery
startup — from a solo founder's weekend prototype to a full product organization. The same iOS app
(searching and saving music, podcasts, movies, and audiobooks) is refactored at every step, so you
never re-learn a domain.

It demonstrates how to solve the real scaling challenges of iOS development: slow build times,
frequent merge conflicts, and "spaghetti" coupling.

## How this repo is organized

Plain markdown and runnable code — no site, no build step. Read the chapters here on GitHub.

- `part-N-*/` — one markdown file per chapter, plus a `README.md` with that part's table of contents.
- `code/part-N-*/chNN-*/` — the runnable end state of each chapter, picking up exactly where the
  previous chapter left off. See [`code/README.md`](code/README.md) for the convention.
- `SERIES-ROADMAP.md`, `EDITORIAL-MEMO.md`, `DESIGN-SYSTEM.md` — reference docs.

---

## Series Roadmap

Four parts, one continuous story. Each part was conceived as a standalone book and answers one
question at an increasing scale:

| Part | Title | Question | Scale |
|---|---|---|---|
| **I** | [iOS Architecture, One Skill at a Time](part-1-architecture/README.md) | Where should this *code* live? | 1 → 2 people |
| **II** | [The Modular iOS Playbook](part-2-modular/README.md) | Where should this *module* live? | 2 → 20 people |
| **III** | [Developer Experience](part-3-developer-experience/README.md) | How should engineers *work*? | the engineering org |
| **IV** | [Product Engineering](part-4-product-engineering/README.md) | How should the company *learn*? | the whole company |

The arc in four lines: **write better code → build better systems → build a better engineering
organization → build a better product organization.**

Every chapter title follows one house style — **[Technical Concept] — [Engineering Law]**. The title
says *what you learn*; the italic law says *why it matters* and reads as a standalone code-review
guideline. Only Part II's chapters are written so far (linked below); the rest is the road ahead.

> **The product vs. the plumbing:** Medley is the product and the company; Apple's keyless iTunes
> Search API is merely the data source it's built on. New code (Part I onward) uses the `Medley`
> target name; Part II's existing chapters and code still carry the historical `iTunesSearchApp`
> name, and the rename lands with the Part II revision.

### Part I · [iOS Architecture, One Skill at a Time](part-1-architecture/README.md)

*A solo founder refactors a one-file SwiftUI app into a tested MVVM-C monolith — one
Single-Responsibility extraction per chapter, each codified as a reusable AI skill.*

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

*Epilogue — The Limits of Convention: a rule the compiler can't see is a rule waiting to break.*

### Part II · [The Modular iOS Playbook](part-2-modular/README.md)

*The team grows to 20 and the monolith is split into SwiftPM modules; boundaries stop being
conventions and become compiler-enforced rules. Each chapter has a runnable end state and a
scorecard.*

1. [The Monolith](part-2-modular/01-the-monolith.md) — *A boundary the compiler can't enforce is a suggestion.*
2. [The Design System](part-2-modular/02-extracting-design-system.md) — *Extract the leaves of the graph first.*
3. [Domain and Infrastructure](part-2-modular/03-domain-and-infrastructure.md) — *Business rules depend on nothing.*
4. [Vertical Slicing](part-2-modular/04-vertical-slicing.md) — *A team owns a target, not a folder.*
5. [Dependency Inversion](part-2-modular/05-dependency-inversion.md) — *Dependencies point toward stability.*
6. [The Composition Root](part-2-modular/06-composition-root.md) — *The object graph is built in exactly one place.*
7. [Feature Lifecycle](part-2-modular/07-the-proof.md) — *The test of a boundary is deletion.*
8. [Module Granularity](part-2-modular/08-advanced-granularity.md) — *Split modules when people collide, not when diagrams do.*

### Part III · [Developer Experience](part-3-developer-experience/README.md)

*The inner loop becomes a product and the engineering organization is its customer. Every chapter
opens with developer pain and ends with a measured improvement to the loop.*

1. **Engineering Metrics** — *What isn't measured won't get faster.*
2. **Test Impact Analysis** — *A change pays only for what it touches.*
3. **Build Caching** — *Repeated work should happen once.*
4. **Continuous Delivery** — *Anything that ships more than once must ship itself.*
5. **Platform Engineering** — *Your engineers are users too.*

*Epilogue — The Limits of Speed: velocity is wasted on the wrong destination.*

### Part IV · [Product Engineering](part-4-product-engineering/README.md)

*The outer loop: the hero is the feedback loop, not any vendor. Every chapter ends with a product
decision made from real data.*

1. **Product Analytics** — *Every important question needs an answer before it is asked.*
2. **A/B Testing** — *Opinions are hypotheses until tested.*
3. **Feature Flags** — *Every launch needs an undo.*
4. **Observability** — *Production must be able to explain itself.*
5. **Metrics and Decision Records** — *A decision without a record is an argument waiting to repeat.*

*Epilogue — The Company That Learns: the ledger, the modules, the scoreboards, and the decision
records shown as one continuous system.*

The full plan lives in [`SERIES-ROADMAP.md`](SERIES-ROADMAP.md).

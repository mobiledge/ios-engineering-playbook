# Part II · The Modular iOS Playbook

**Where should this *module* live?** · 2 → 20 people

The team grows to 20 and the monolith is split into SwiftPM modules — boundaries stop being
conventions and become compiler-enforced rules. Each chapter has a runnable end state and a
scorecard.

This is **Part II** of a four-part book that follows one company, Medley, from a solo prototype to a
full product organization. For the whole arc, see the [Series Roadmap](../README.md).

## Who this part is for

This playbook is for **growing teams feeling merge-conflict and build-time pain** — the moment
a second or third developer joins a single-target app and every change starts stepping on
someone else's work, or a clean build starts costing minutes instead of seconds. If that's not
you yet, it probably shouldn't be: a solo developer maintaining a five-screen app should **not**
apply all of this. Every technique in this book has a cost, and the book says so at every step —
the honest answer to "is this worth it yet?" is often "no" until the team or the app grows into
the pain that motivates it.

### Prerequisites

- Comfort with **Swift** and **SwiftUI** basics (views, state, navigation). This book teaches
  module boundaries and dependency direction, not the language or the UI framework.
- No prior experience with Swift Package Manager or XcodeGen is assumed — both are introduced
  as they're used, starting in Chapter 2.

## Chapters in this part

Each chapter title follows the series house style — **[Technical Concept] — [Engineering Law]** —
and ends with a runnable end state and a scorecard.

1. [The Monolith](01-the-monolith.md) — *A boundary the compiler can't enforce is a suggestion.*
2. [The Design System](02-extracting-design-system.md) — *Extract the leaves of the graph first.*
3. [Domain and Infrastructure](03-domain-and-infrastructure.md) — *Business rules depend on nothing.*
4. [Vertical Slicing](04-vertical-slicing.md) — *A team owns a target, not a folder.*
5. [Dependency Inversion](05-dependency-inversion.md) — *Dependencies point toward stability.*
6. [The Composition Root](06-composition-root.md) — *The object graph is built in exactly one place.*
7. [Feature Lifecycle](07-the-proof.md) — *The test of a boundary is deletion.*
8. [Module Granularity](08-advanced-granularity.md) — *Split modules when people collide, not when diagrams do.*

## Code

End states live in [`code/part-2-modular/`](../code/part-2-modular/), one folder per chapter.
These chapters and their code still use the historical `iTunesSearchApp` target name; the rename to
`Medley` lands with the Part II revision. See [`code/README.md`](../code/README.md) for the
per-chapter convention and [`plans/part-2-modular/`](../plans/part-2-modular/) for the continuity
contract and canonical naming glossary.

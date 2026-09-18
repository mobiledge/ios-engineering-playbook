# Editorial Memo — The Modular iOS Playbook

**To:** Rabin (author)
**Re:** Whole-book review, focused on pedagogy
**Date:** June 17, 2026
**Scope reviewed:** All 7 chapters (`part-2-modular/`), the per-chapter runnable code under `code/`, and the chapter READMEs.

---

## Framing

The challenge in this kind of book isn't the code — it's the pedagogy. The code is real and it runs. What determines whether readers *learn* is whether the book builds a stable mental model, proves its claims, and puts the reader's hands on the work. This memo is organized by leverage: the issues at the top will change reader outcomes the most.

A note on what's already working, because it should be protected during revisions:

- **A single carried example.** iTunesSearchApp runs start to finish. Readers never have to re-learn a domain.
- **A genuinely progressive refactor.** Each chapter is a clean end-state backed by a real XcodeGen project — an asset most architecture books lack.
- **Cliffhanger transitions.** "How do we navigate between features without importing them?" (Ch4) and "Who wires it all together?" (Ch5) are textbook motivation. Keep this device.
- **The Chapter 2 principle** — extract code with *many incoming, few outgoing* dependencies first — is the strongest teaching moment in the book.

The structure is sound. The work below is mostly consistency and scaffolding, not resequencing.

---

## 1. Highest leverage: stop the prose and the code from drifting apart

A learner builds a mental model out of names. Every silent rename forces the question "is this a new thing, or the thing from before?" — and that tax compounds across a book. Right now the vocabulary is not stable from chapter to chapter, or between the prose and the repository.

Concrete instances found:

- **Chapter 4 references modules that were never created.** It opens: "we have successfully extracted our horizontal layers: `CoreUtilities`, `DesignSystem`, and `CoreDataLayer`." But Chapter 3 created `Domain` and `Infrastructure` — and the code confirms those names. `CoreUtilities` and `CoreDataLayer` appear from nowhere. A careful reader will assume they missed a chapter.
- **The prose teaches UIKit; the code ships SwiftUI.** The prose talks in `UIViewController`, `navigationController.pushViewController`, and Coordinators (Ch4–6). The sample code is SwiftUI — `MusicSearchView`, `RootView`, a `TabView` (per the Ch4 README). These are different navigation and composition models. A reader holding the book in one hand and the repo in the other has to translate constantly.
- **The interfaces module is named three ways.** Prose says `FeatureInterfaces` and `iTunesSearchInterfaces` (Ch5); the code calls it `AppInterfaces`.
- **The protocols don't match.** Ch5 prose introduces `LibraryDataService` and `MusicSearchRouter`; the code has `LibraryRouter`. Ch6 prose adds an `AppFactory` / `MainCoordinator` that the SwiftUI code structures differently.

None of this is a code bug — it's a *continuity* bug, and it's the single thing most likely to make a reader feel lost even when the ideas are right.

**Recommended fix:** Write a one-page **module glossary** first — one canonical name per concept, and one UI paradigm (I'd choose SwiftUI, since that's what the repo actually is). Then edit every chapter, diagram, and snippet *against* that glossary. This is cheap and removes the highest source of reader confusion.

---

## 2. Show the payoff; don't just assert it

Every chapter promises "faster builds" and "tests in seconds," but the reader never sees proof. For someone weighing this against the boilerplate cost, evidence is the persuader.

**Recommended fix:** Add a recurring **build-time scorecard** ("full app: 3m10s → Library demo app: 8s"), a screenshot of the Catalog/Demo app, or a test runner finishing in 0.2s. Tie each number to that chapter's specific claim. This converts "trust me" into "look."

---

## 3. Put the reader's hands on the repo

There's a runnable project per chapter, but the prose never sends the reader there. The book and the code currently feel like two separate products.

**Recommended fix:** Add a short, consistent **"Try it yourself"** block to each chapter: which scheme to open, what to change, what to observe. Example for Ch2: "Edit a color in `DesignSystem`, build the Catalog scheme, and watch it skip the app target entirely." This is what makes the runnable repo pay off pedagogically.

---

## 4. Give each chapter a repeatable rhythm and checkpoints

Chapters currently run *What is X → Steps → New diagram → Benefits*. Predictable is good, but it's all exposition.

**Recommended fix:** Adopt a recurring loop that mirrors how the work actually feels:

> **Pain (with evidence) → Diagnosis → Refactor → Verify it worked → New trap this introduces.**

You already nail the "new trap" beat (Ch4's feature-to-feature coupling; Ch5's "who wires it?"). Make it explicit and consistent. End each chapter with a one-line **checkpoint** ("you can now build feature X in isolation") so readers can self-assess before moving on.

Also: replace the seven separately-drawn ASCII graphs — which vary in style and naming — with **one canonical dependency diagram that grows by one module per chapter**. A single evolving picture readers can track beats seven inconsistent ones.

---

## 5. Structural calls worth making deliberately

- **Name your audience and prerequisites up front.** The core motivation ("20 developers, daily merge conflicts") only lands for someone on a growing team; a solo dev won't feel the pain. State who the book is for, and either assume or teach SPM / XcodeGen / Tuist explicitly — right now that familiarity is implied.
- **Move "when *not* to do this" earlier, and make it recurring.** Chapter 7's "modularize to solve human problems, not as an academic exercise" is the most mature idea in the book — and it's buried at the very end. Readers need *permission to stop* throughout, or they'll cargo-cult all seven chapters onto a five-screen app. A small recurring "Is this worth it yet?" sidebar would do it.
- **Be honest about the costs.** The book is one-sided pro-modularization. A short, evenhanded treatment of the price — boilerplate, the composition root tending toward a god-object, XcodeGen/Tuist upkeep, graph complexity, onboarding cost — will *increase* trust, not weaken the argument.
- **Resolve "Movies" vs "Movie Detail."** Ch1 lists a "Movie Details" screen; the code adds a `FeatureMovies` list *plus* a detail. Decide whether movies is a browse-list feature or a detail screen, because the cross-feature navigation example in Ch4–5 (search → movie detail) depends on it.

---

## Suggested order of attack

1. **Write the module glossary and reconcile every name + the UIKit/SwiftUI split against it.** (Issue 1 — biggest impact, lowest cost.)
2. **Add build-time evidence and "Try it yourself" hooks to every chapter.** (Issues 2–3 — turns claims into conviction and connects book to repo.)
3. **Apply the recurring chapter rhythm, checkpoints, and the single evolving diagram.** (Issue 4.)
4. **Add the audience/prereqs front matter, the recurring "when not to" sidebar, and a costs section.** (Issue 5.)

Items 1–2 alone will sharply raise how grounded and trustworthy the book feels.

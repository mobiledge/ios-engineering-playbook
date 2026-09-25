# Chapter 2: Extracting the Design System

## Where We Are

[Chapter 1](01-the-monolith.md) left us with **iTunesSearchApp** as a single
application target: one Xcode target holds the models, the networking, the four
cross-cutting services (`Logger`, `CrashReporter`, `AnalyticsTracker`, `FeatureFlagProvider`),
and two features — **Music** and **Podcasts** — both just search-and-list screens against the
public iTunes Search API. Nothing is modularized yet; the compiler enforces no boundaries at
all. That chapter also left us a scoreboard to beat:

| What you do | The monolith (Ch1 baseline) |
| --- | --- |
| Clean build of the whole app | ~3m 10s |
| Change one color and see it on screen | ~40s — the whole app target recompiles |
| Run the Music Search logic tests | compiles the entire app first, ~1m+ |
| Two devs on two features | same target → merge conflicts on shared files |

The startup has just hired its third person. That's who breaks this chapter's baseline.

## Pain: Two Sources of Truth

A designer and a developer are looking at the same build of iTunesSearchApp. They are about to
discover they do not agree on what the app actually looks like — and that neither of them can
prove it.

> **Maya (design):** Quick one — the track cards in search results are using the wrong corner
> radius. They should be 12. They look like 8 in the build.
>
> **Sam (dev):** Let me check. Cards use the `mediumRadius` token… yeah, `mediumRadius` is 8.
>
> **Maya:** Right, but medium is 12 now. We bumped the whole radius scale three weeks ago in the
> design file.
>
> **Sam:** Updated where? The code still says 8. As far as the codebase knows, medium has always
> been 8. So which cards are wrong — just these, or every card in the app?
>
> **Maya:** …all of them should be 12. Are you saying they're all 8?
>
> **Sam:** I'm saying everything using `mediumRadius` is 8, and I can't tell you how many places
> that is without grepping. Could be cards, modals, the bottom sheet. And some of those might
> not even use the token — someone may have hardcoded an 8.
>
> **Maya:** Hardcoded? So even if you change the token, some things won't update?
>
> **Sam:** Maybe. I can't tell you which screens pull from the token and which have a magic
> number baked in without going screen by screen. And every one of those checks means
> rebuilding the whole app just to look — about 40 seconds a shot, today.
>
> **Maya:** This is what I keep hitting. I make a change to the system and I have no idea if it
> landed in the app. I see something off in a build and I can't tell if it's a bug, an old
> value, or a component that was never moved onto the new system. And I can't just open a
> component by itself and look at it — I have to launch the whole app and dig through screens to
> find it.
>
> **Sam:** And from my side, I can't tell if what you're showing me in Figma is the agreed system
> or just your working file. Last time I chased a value, it turned out to be an experiment that
> got reverted.
>
> **Maya:** So neither of us actually knows what's true right now.
>
> **Sam:** Right. You have a source of truth in Figma. I have one in code. There's no place we
> can both look and agree "this is medium radius, this is what it renders as, and these are the
> components that use it."
>
> **Maya:** What I want is to point at a running screen and go "that — that's the card, that's
> its *real* radius, straight from the code." If it doesn't match Figma, we know exactly where
> the gap is.
>
> **Sam:** A live gallery of every primitive and component, rendered from the actual code the
> app ships. Not a screenshot, not a doc that goes stale. You'd open it, see "medium radius = 8,"
> and know it's wrong — and I'd know it's a one-line token change that fixes every component at
> once, because they all pull from the same source.
>
> **Maya:** And I'd catch drift myself, instead of finding it by accident three sprints later.

Neither of them is careless. The friction is structural: there are **two separate sources of
truth with no shared, rendered reference between them.** Every disagreement — *which screens? is
it hardcoded? is that value even final?* — turns into a manual investigation, because no single
artifact is both rendered from the real code *and* inspectable without reading it. And because
every one of those investigations means rebuilding the single `iTunesSearchApp` target just to
look at one color or radius, each check costs Maya and Sam a measured ~40 seconds — the exact
number from our Chapter 1 scoreboard, and the number this chapter is going to knock down.

This is the cost of the company's first brand refresh landing on a two-feature app that just
hired its first designer: with the whole token/component set buried inside one app target, a
color or radius change becomes a daily, ~40-second-per-check tax on both of them, and there is
nowhere for Maya to preview a component without running the entire app around it.

## Diagnosis: Extract What Everything Depends On, and That Depends On Nothing

The first step to unknotting this spaghetti is *not* to extract a whole feature like Music
Search right away. That usually leads to frustration, because features are heavily intertwined
with other parts of the app — networking, models, and shared UI all at once.

Instead, we start from the bottom up by identifying code that has **many incoming dependencies,
but few outgoing dependencies**. In almost every app, the most prominent example of this is the
**Design System** — almost every screen depends on it, while it depends on little more than
Apple's UI frameworks. `Views/Shared` is the textbook case: `MusicSearchView` uses `AppColor`,
`PodcastsView` reuses the same shared controls and colors, and neither of those files — nor
`AppColor` itself — has ever needed to know about `Track`, `Podcast`, or the network layer. That
asymmetry — many things lean on it, it leans on nothing — is exactly what makes it safe to pull
out first, and it's what lets the catalog app Maya and Sam need exist at all: a module you can
render on its own, independent of the app's business logic or network state.

## Refactor: Extracting the Design System

We pulled `Views/Shared` out in this order:

1.  **Create the module.** Add a local Swift package, `Packages/DesignSystem`, alongside the app
    target rather than a second Xcode target — this keeps the boundary lightweight and lets
    Swift Package Manager, not Xcode project settings, own its dependency graph.
2.  **Move the code, one tier at a time.** [`DESIGN-SYSTEM.md`](https://github.com/mobiledge/ios-engineering-playbook/blob/main/DESIGN-SYSTEM.md)
    at the root of this repo lays out the general shape we're following: **Tokens** (the raw and
    semantic values — colors, spacing, radii, type scale), **Styles** (SwiftUI's own style
    protocols applied to tokens), and **Components** (custom views composed from styled pieces).
    Our app's shared UI never needed a custom `ButtonStyle` or `ToggleStyle` — `PrimaryButton`
    and friends were already small, self-contained views — so this extraction populates the
    Tokens and Components tiers and leaves Styles for whichever chapter first needs a custom
    control style. `Views/Shared/AppColor.swift`, `AppFont.swift`, and `Layout.swift` become
    `Packages/DesignSystem/Sources/DesignSystem/Tokens/`; `AppText.swift`, `ArtworkView.swift`,
    `CardView.swift`, `TagView.swift`, and `PrimaryButton.swift` become
    `Packages/DesignSystem/Sources/DesignSystem/Components/`.
3.  **Adjust access control and rename.** Inside the app target these types were implicitly
    `internal`. In a separate module they — and their initializers — must be `public` so
    `iTunesSearchApp` can see them across the module boundary. While we're at it, we give every
    type a `DS` prefix, so `AppColor` becomes `DSColors`, `AppFont` becomes `DSFont`,
    `PrimaryButton` becomes `DSButton`, and so on. We also went one step further than a
    line-for-line move: the identical `HStack` that `TrackRow` and `PodcastRow` each hand-built
    around `ArtworkView` + text got promoted into one shared component, `DSMediaRow`, so both
    rows now render from the same composed piece instead of two copies of the same layout.
4.  **Import the package from the app.** `iTunesSearchApp` adds `DesignSystem` as a local package
    dependency in `project.yml`, and every file that used a shared token or component adds
    `import DesignSystem` at the top.
5.  **Add the Catalog app target.** A second, minimal app target — `Catalog` — is added
    alongside `iTunesSearchApp`. It has its own `Sources` (here, a top-level `Catalog/` folder)
    and depends on nothing but the `DesignSystem` package. Its single screen renders every token
    and every component the package exports — colors, type scale, buttons, tags, cards, section
    headers, media rows — so there is one screen that is the design system, live.

### The new architecture

```text
              ┌─────────────────┐        ┌───────────┐
              │  iTunesSearchApp │        │  Catalog  │
              └────────┬─────────┘        └─────┬─────┘
                       │                         │
                       └───────────┬─────────────┘
                                   ▼
                             DesignSystem
```

The dependency points **downward** from both app targets. `iTunesSearchApp` depends on
`DesignSystem`; so does `Catalog`. Neither `DesignSystem` — nor the compiler — has ever heard of
`iTunesSearchApp`, `Track`, or `ITunesAPIClient`. It is now architecturally impossible for a
design-system file to reach back into app code; the compiler enforces it.

## Verify

**Features unchanged: still Music + Podcasts.** This chapter moves *where UI code lives*, not
*what the app does* — nobody added or removed a feature.

| What you do | Ch1 baseline | After this chapter |
| --- | --- | --- |
| Confirm a component's *real* radius/color | Read code or hunt through app screens | Open `Catalog` — rendered from shipping code |
| Review every component | Click through real app screens | Launch `Catalog`, all in isolation |
| Change a color and see it | ~40s — `iTunesSearchApp` target recompiles | ~5s — only `DesignSystem` + `Catalog` recompile |
| Misuse a domain model in UI code | Compiles fine, breaks later | Won't compile — module boundary enforced |

*Illustrative figures; measure your own in [`code/part-2-modular/ch02-design-system`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch02-design-system). The headline win is the shared, authoritative reference between design and code — the ~40s → ~5s loop is what keeps it honest.*

## Try It Yourself

1. Open `code/part-2-modular/ch02-design-system`, run `xcodegen generate`, then `open iTunesSearchApp.xcodeproj`.
2. Change `DSColors.brand` in `Packages/DesignSystem/Sources/DesignSystem/Tokens/DSColors.swift`
   to a different color.
3. Build and run the **Catalog** scheme. Watch the new brand color show up in seconds — only
   `DesignSystem` and `Catalog` rebuild.
4. Now build the **iTunesSearchApp** scheme. Notice it *also* picks up the new color the next
   time it runs — because it depends on the same package — but that you didn't have to touch or
   even open the main app target to verify the change. That's the loop Maya gets for free.

## Is This Worth It Yet?

One local Swift package is a cheap boundary — a `Package.swift`, a folder move, a `DS` prefix,
and a `project.yml` edit. There's no second team to coordinate with yet, no CI matrix to update,
no versioning to manage. At this size, the **Catalog app alone** tends to justify the whole
chapter the moment a designer joins: it is the first artifact in the project two different job
functions can both point at and agree on. If it were *just* about build times, you could
reasonably wait — 40 seconds is annoying, not disqualifying. It's the shared source of truth
that makes this the first move, not the speed.

## The Next Crack: Nowhere Sane to Put Business Logic

The design system was the safe first win — many screens depend on it, it depends on almost
nothing. But the PM just signed off on the next feature: **"Save to Library."** Users want to
save tracks and podcasts and see them later, offline. That means real business rules for the
first time — don't save the same track twice, keep the list sorted, let someone remove an item —
and persistence to back them.

Try to write a unit test for "don't save duplicates" today and you'll find there's nowhere sane
to put it. The rule would have to live inside a SwiftUI view, next to the `@State` and the
`body`, tangled up with whatever CoreData or URLSession calls happen to be nearby. The only way
to exercise that view is to compile and run the whole app in a simulator — there is no seam to
test the rule on its own. In the next chapter we cut that seam: a **Domain** layer for the rules
that don't care where data comes from, and an **Infrastructure** layer for the networking and
persistence code that does.

## Hands-On: Extract the DesignSystem

The [`code/part-2-modular/ch02-design-system`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch02-design-system)
project contains a real, extracted design system as a local Swift package under
[`Packages/DesignSystem`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch02-design-system/Packages/DesignSystem).
It is the Chapter 1 monolith from [`code/part-2-modular/ch01-the-monolith`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch01-the-monolith)
with the design system pulled out and nothing else — diff the two folders to see exactly what
this chapter changes. Music and Podcasts are both still there, unmodified in behavior.

### A realistic design system, not just colors

A design system is more than a color palette. Ours is built in the layers described in
[`DESIGN-SYSTEM.md`](https://github.com/mobiledge/ios-engineering-playbook/blob/main/DESIGN-SYSTEM.md):

*   **Tokens** — the primitives. `DSColors` is a small semantic palette (brand, surfaces, text,
    status). `DSFont` defines a single font *design*, a fixed type *scale*, and a set of weights,
    then composes them into semantic styles (`largeTitle`, `headline`, `body`, …). `DSSpacing`
    and `DSRadius` give a consistent rhythm.
*   **Components** — built *by composing tokens*. `DSText` pairs a font with a default color.
    `DSButton`, `DSCard`, `DSTag`, and `DSSectionHeader` combine color, type, and radius. The
    highest-level component, `DSMediaRow`, is assembled entirely from `DSArtwork` + `DSText` +
    spacing — so every media list in the app (Music, Podcasts) looks identical for free.

Because everything is composed from a handful of tokens, the entire app can be re-themed by
editing one or two files.

### How the extraction was done

The package is wired into the project via [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```yaml
packages:
  DesignSystem:
    path: Packages/DesignSystem

targets:
  iTunesSearchApp:
    dependencies:
      - package: DesignSystem
```

Three things made this work, exactly as outlined above:

1.  The shared UI files moved out of `Sources/Views/Shared/` and into the package.
2.  Their types became `public` (along with their initializers), since the app now consumes them
    across a module boundary.
3.  Every feature file that uses them now starts with `import DesignSystem`.

The compiler now *enforces* the boundary: it is impossible for a design-system component to
reach back into `Track`, `Podcast`, or `ITunesAPIClient`.

### The payoff: a Catalog app

The project includes a second app target, **`Catalog`**, that imports *only* the design system —
no models, no networking, no database. Run it to review every token and component in isolation:

```bash
cd code/part-2-modular/ch02-design-system
xcodegen generate
open iTunesSearchApp.xcodeproj   # then choose the "Catalog" scheme
```

Because it depends on nothing but `DesignSystem`, it compiles almost instantly — the "faster UI
iteration" benefit, made concrete.

## Checkpoint: One Source of Truth

Maya and Sam now have the thing they were missing: a standalone **Catalog app** that renders
every primitive and component straight from the shipping code. When a value looks wrong, the gap
between design and code is visible in one place — and the fix is a one-line token change that
updates every component at once. Faster iteration follows: a color or radius tweak shows up in
seconds, without compiling `iTunesSearchApp` at all.

---

> **Next:** [Chapter 3: Domain and Infrastructure Layers](03-domain-and-infrastructure.md)

# Chapter 4: Vertical Slicing

## Where We Are

[Chapter 3](03-domain-and-infrastructure.md) left **iTunesSearchApp** as a single
application target sitting on top of three local packages: `Packages/DesignSystem` (Ch.2),
`Packages/Domain`, and `Packages/Infrastructure` (both Ch.3), plus the standalone **Catalog** app.
The features are unchanged — **Music**, **Podcasts**, and, new as of last chapter, **Library** —
but all three still live as views inside one `Sources/Views/` folder, wired together by one
`RootView.swift`. The module graph:

```text
              ┌───────────────────────────────┐
              │         iTunesSearchApp        │
              └──┬──────────────┬──────────────┘
                 │              │
                 ▼              ▼
          ┌─────────────┐  ┌────────┐      ┌───────────┐
          │Infrastructure│  │ Domain │◄─────┤  Catalog  │
          └──────┬──────┘  └───▲────┘      └─────┬─────┘
                 │             │                 │
                 └─────────────┘           DesignSystem ◄──┘
```

Domain and Infrastructure are clean: business rules live in one place, verified in milliseconds,
with the outside world swappable behind a protocol. But that's a *horizontal* cut — it separates
code by technical role (entities vs. protocols vs. concrete adapters), not by which feature it
belongs to. Music, Podcasts, and Library still share one `Sources/Views/` folder and one app
target. Chapter 3 ended by noting exactly who was about to feel that: the team just grew to six
and split into two squads — one owning Music + Podcasts, the other owning the brand-new Library.

## Pain: Two Squads, One Target

> **Sam (Search squad):** I opened a PR to bump the Music search debounce and it's got a merge
> conflict in `RootView.swift`.
>
> **Priya (Library squad):** That's not even your file. What did you touch?
>
> **Sam:** Nothing in it. But Jordan added a fourth tab item to `RootView` yesterday for a
> Library filter toggle, and I'm rebasing a two-line change from three days ago. Same file, same
> ten lines near the top, every time either of us touches a tab.
>
> **Priya:** We hit the same wall from the other side — `project.yml` this time. Alex added
> `Packages/Infrastructure` as a dependency comment last week, I added a build setting for Core
> Data, and now neither diff applies cleanly to the other's branch.
>
> **Sam:** Here's the one that actually costs me time, though. I changed one string in
> `MusicSearchView` — the search placeholder — and building `iTunesSearchApp` to check it took
> **3 minutes 10 seconds.** That's not a Music-only build. That's Podcasts, Library, Core Data,
> networking, all of it, because it's one target.
>
> **Priya:** Meanwhile I can't even run *my own feature* without your build finishing first.
> There's no way to launch "just Library" — it's `iTunesSearchApp` or nothing, so every time I
> want to see my row layout on a phone, I'm sitting through the same 3m10s Sam just measured, for
> a screen I'm not touching.
>
> **Sam:** And Podcasts hasn't changed in two sprints — it's basically in maintenance mode now —
> but it still recompiles every time either of us builds, because it's stuck in the same folder
> as the two features we're actually shipping.
>
> **Priya:** So: two teams, one shared `RootView.swift`, one shared `project.yml`, one shared
> build. We're not stepping on each other's *logic* — Domain and Infrastructure took care of
> that — we're stepping on each other's *files and clock*.

The measured cost: every feature change — Music, Podcasts, or Library — still pays the full Ch1
baseline clean-build tax (**~3m 10s**) because there is exactly one compilation unit for three
teams' worth of code, and two developers on two different features still collide on the same
`RootView.swift` and `project.yml`, the same merge-conflict pattern from the Chapter 1 baseline.
Domain and Infrastructure fixed *what depends on what*; nobody has yet fixed *who owns which
files*.

## Diagnosis: Horizontal Layers vs. Vertical Slices

Domain, Infrastructure, and DesignSystem are **horizontal layers** — each one is a technical role
that cuts *across* every feature. That's exactly the right cut for code with many incoming
dependencies and few outgoing ones, which is why we extracted them first. But no feature lives
entirely inside a horizontal layer; Music, Podcasts, and Library each *use* all three. Team
ownership, by contrast, runs the other way: Sam's squad owns everything Music and Podcasts need
end-to-end; Priya's squad owns everything Library needs end-to-end. That's a **vertical slice** —
one package per feature, cutting from the UI down through whatever domain and infrastructure that
one feature touches — and a package boundary is also a *build* boundary and a *file-ownership*
boundary, which is exactly what two squads sharing one target are missing.

The other half of the fix is the **demo app**: once a feature is its own package, nothing stops
you from building a second, tiny app target whose only dependency is that one package. It compiles
in seconds instead of minutes, because it never touches the features it doesn't need — the fast
inner loop a squad needs to iterate on their own screen.

## Refactor: Extracting the Feature Packages

We did this in the following order — smallest and newest feature first, to prove the pattern
before repeating it twice more:

1. **Extract `Packages/FeatureLibrary`.** Library is the newest feature and the smallest, so it's
   the cheapest place to learn the pattern. `Sources/Views/Library/LibraryView.swift` moves into
   the package and its public entry point is renamed `LibraryScreen` — every feature package's
   entry point follows the `<Feature>Screen` convention from here on. It depends on `Domain`,
   `DesignSystem`, and `Infrastructure`.
2. **Prove it with `DemoApps/FeatureLibraryDemo`.** A second, minimal app target is added whose
   only dependency is `FeatureLibrary`. It boots straight into `LibraryScreen()` — nothing else in
   the app compiles when this scheme builds.
3. **Extract `Packages/FeatureMusicSearch`.** `Sources/Views/Music/` moves into the package. Its
   root view is renamed `MusicSearchView` → `MusicSearchScreen` at this step; `TrackRow` keeps its
   name.
4. **Extract `Packages/FeaturePodcasts`.** `Sources/Views/Podcasts/` moves into the package as
   `PodcastsScreen` + `PodcastRow` — a brand-new package, since Podcasts never had one before.
5. **Shrink the app target.** With all three features gone, `Sources/Views/` disappears entirely.
   What's left is `Sources/App/iTunesSearchApp.swift` (the `@main` entry) and
   `Sources/App/RootView.swift` (the `TabView` that composes the three feature screens) — two
   files, full stop.

Each feature package depends on `Domain`, `DesignSystem`, **and `Infrastructure`** — that last
edge is a **deliberate flaw**. A feature has no business knowing about the concrete networking or
Core Data layer directly; it should only ever see the protocols `Domain` declares. We're taking it
on anyway, because Chapter 5 is where the fix (dependency inversion) actually earns its keep, and
right now it lets each squad move independently without waiting on a composition root that doesn't
exist yet.

One side effect of the move: a Swift package cannot depend on the app executable that hosts it, so
the app target's `Services` facade (`Services.analytics`, `Services.crashReporter`,
`Services.flags`) is no longer reachable from inside a feature package. Each feature now
constructs its own `Infrastructure` types inline — `ConsoleAnalytics()`, `ConsoleCrashReporter()`,
`LocalFeatureFlags()` — the same inline-construction pattern already used for
`ITunesSearchRepository()` and `CoreDataLibraryRepository()`. `Services` still lives in the app
target, thinned down to the one caller left: the app-launch breadcrumb in `iTunesSearchApp.swift`.

### The new architecture

```text
                              ┌─────────────────────┐
                              │    iTunesSearchApp   │
                              └──┬─────┬─────┬───────┘
                                 │     │     │
              ┌──────────────────┘     │     └──────────────────┐
              ▼                        ▼                        ▼
     FeatureMusicSearch          FeaturePodcasts            FeatureLibrary  ◄── FeatureLibraryDemo
              │                        │                        │
              └───────────┬────────────┴────────────┬───────────┘
                           ▼                         ▼
                     Infrastructure ───────────►   Domain
                           │
                           ▼
                     DesignSystem ◄── (all three features)   Catalog ──► DesignSystem
```

`iTunesSearchApp` depends on the three feature packages plus `DesignSystem`, `Domain`, and
`Infrastructure` (to construct the console services at launch). Each feature package depends on
`Domain`, `DesignSystem`, and `Infrastructure` — the Feature→Infrastructure edges are the
deliberate flaw named above. `FeatureLibraryDemo` depends on `FeatureLibrary` alone. `Catalog` is
unchanged, still depending only on `DesignSystem`.

## Verify

**Features unchanged: still Music + Podcasts + Library.** This chapter moves *where* feature code
lives and compiles, not what the app does.

| What you do | Ch1 baseline | After this chapter |
| --- | --- | --- |
| Build/iterate on Library alone | ~3m 10s — the whole app | ~8s — `FeatureLibraryDemo` only |
| Two squads on two different features | Same target → merge conflicts on `RootView.swift`/`project.yml` | Separate packages → no shared files to conflict on |
| Files in the app target | Every feature's views + utilities | 2 — `iTunesSearchApp.swift`, `RootView.swift` |
| Run Library without booting Music/Podcasts | Not possible — one target | `FeatureLibraryDemo` scheme |

*Illustrative figures; measure your own in [`code/part-2-modular/ch04-vertical-slicing`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch04-vertical-slicing). The ~3m10s → ~8s feature loop is the win.*

## Try It Yourself

1. Open `code/part-2-modular/ch04-vertical-slicing`, run `xcodegen generate`.
2. Change the row layout in
   `Packages/FeatureLibrary/Sources/FeatureLibrary/LibraryScreen.swift` — swap the `caption` and
   `subtitle` arguments passed to `DSMediaRow`, or add a `Divider()` between rows.
3. Build only the **FeatureLibraryDemo** scheme and run it. Watch it rebuild in seconds.
4. Now check what else recompiled: open the build log and search for `FeatureMusicSearch` and
   `FeaturePodcasts`. Neither one appears — they never compile for a Library-only change, because
   `FeatureLibraryDemo` doesn't depend on either package.

## Is This Worth It Yet?

Three `Package.swift` files, three folders to keep straight, and a demo app to maintain — that's
real ceremony on top of Chapters 2 and 3's two packages. It pays for itself the moment there are
**two or more squads** who need to stop colliding on the same files and the same build: that's
this chapter, at a team of six split into two squads. A solo developer, or one team still owning
every feature, gains almost nothing from this cut — there's nobody else's merge conflict to avoid,
and "my build is slow" is a build-time problem, not an ownership problem, so a solo dev should
fix the former before reaching for the latter.

## The Next Crack: Every Feature Points at Infrastructure

Two smells are visible the moment you look at the new dependency graph. First, the deliberate flaw
named above: every feature package — including `FeatureLibraryDemo` — links the concrete
`Infrastructure` package directly. Run the `FeatureLibraryDemo` scheme and it pulls in Core Data
*and* the networking stack, even though the Library screen never calls
`ITunesSearchRepository` — the "fast, isolated" demo app isn't as isolated as it looks. Second,
next sprint brings a new feature, **Movies**, and its detail screen is something Library will
need to open — a feature importing another feature's package by name. Both problems have the same
shape: a concrete dependency where a protocol belongs. Chapter 5 covers dependency inversion.

## Hands-On: Extract the Feature Packages

The [`code/part-2-modular/ch04-vertical-slicing`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch04-vertical-slicing)
project is `code/part-2-modular/ch03-domain-infrastructure` plus exactly this chapter's delta — diff the two
folders to see it. Schemes:

- **`iTunesSearchApp`** — the full app (Music, Podcasts, Library tabs).
- **`Catalog`** — the design system in isolation, unchanged from Chapter 2.
- **`FeatureLibraryDemo`** — Library alone, compiling only `FeatureLibrary` and its dependencies.

```bash
cd code/part-2-modular/ch04-vertical-slicing
xcodegen generate
open iTunesSearchApp.xcodeproj    # choose iTunesSearchApp, Catalog, or FeatureLibraryDemo

# The Domain payoff, unchanged from Chapter 3:
swift test --package-path Packages/Domain
```

## Checkpoint: Team Collisions, Relieved

Sam's squad and Priya's squad now own separate Swift packages — `FeatureMusicSearch` +
`FeaturePodcasts` for one, `FeatureLibrary` for the other — with no shared `RootView.swift` or
`project.yml` edits standing between them. The Library squad can build and run their own feature
in seconds via `FeatureLibraryDemo`, without ever touching Music or Podcasts. What's still
unresolved is *how* those packages depend on the outside world, and how a feature will eventually
need to open another feature's screen — the two threads Chapter 5 picks up.

---

> **Next:** [Chapter 5: The Feature That Broke the Graph](05-dependency-inversion.md)

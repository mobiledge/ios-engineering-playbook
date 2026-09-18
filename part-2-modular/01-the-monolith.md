# Chapter 1: The Monolith

Two people, a laptop, and a deadline. That's the whole company. A founder and one developer are trying to ship v1 of a media search app before the money runs out, and the fastest way to get there is to put everything — every screen, every model, every network call — into a single Xcode project and start typing. This chapter is that v1, and it's the starting point of our journey: before we can appreciate the benefits of a modular architecture, we must first understand the problem it solves. To do this, we'll start where almost every iOS application begins: **The Monolith**.

## What is a Monolith?

In the context of iOS development, a monolithic architecture means that all your application code—UI elements, network requests, database models, business logic, and third-party integrations—resides in a single app target. When you open Xcode and click "Create a new Xcode project," you are creating a monolith.

This isn't inherently a bad thing. In fact, for very small projects, prototypes, or indie apps maintained by a single developer — like our two-person startup — a monolithic structure is often the fastest and simplest way to build. There is no team to coordinate, no ownership to divide, and no build-time tax large enough to notice. **At this size, the monolith is the right choice** — the honest answer to "is a module boundary worth it here?" is *no*. Keep that question in mind; every chapter from here on asks it again at a larger size, and the answer won't stay no for long.

## Our Sample Application: iTunesSearchApp

Throughout this playbook, we will be refactoring a fictional media search application called **iTunesSearchApp**. It's the one app our two-person startup shipped: v1 covers exactly two features, Music and Podcasts, and nothing else.

iTunesSearchApp has a couple of core features:
1.  **Music Search:** A searchable list of music tracks fetched from the iTunes API.
2.  **Podcast Search:** A searchable list of podcasts fetched from the iTunes API.

Both features work the same way: type a query, hit the network, and present the results in a list. There is no local database — the app simply shows what the API returns.

### The Anatomy of the iTunesSearchApp Monolith

If we look at the Xcode project structure for our initial monolithic iTunesSearchApp, it might look something like this:

```text
iTunesSearchApp/
├── project.yml                     # XcodeGen spec; the .xcodeproj is generated
└── Sources/
    ├── App/
    │   └── iTunesSearchApp.swift    # SwiftUI @main App entry point
    ├── Models/
    │   ├── Track.swift
    │   └── Podcast.swift
    ├── Networking/
    │   └── iTunesAPIClient.swift
    ├── Views/
    │   ├── RootView.swift           # the TabView that wires the features together
    │   ├── Shared/                  # the design system: tokens + reusable components
    │   │   ├── AppColors.swift      # semantic color palette (brand, surfaces, text, status)
    │   │   ├── Typography.swift     # AppFont — a type scale + semantic text styles
    │   │   ├── Layout.swift         # AppSpacing + AppRadius tokens
    │   │   ├── AppText.swift        # styled-text component built from the tokens
    │   │   ├── ArtworkView.swift
    │   │   ├── CardView.swift
    │   │   ├── TagView.swift
    │   │   └── PrimaryButton.swift
    │   ├── Music/
    │   │   ├── MusicSearchView.swift
    │   │   └── TrackRow.swift
    │   └── Podcasts/
    │       ├── PodcastsView.swift
    │       └── PodcastRow.swift
    └── Utilities/
        ├── DateFormatter+Extensions.swift
        └── Services.swift          # logging, crash reporting, analytics, feature flags — behind plain protocols
```

The app uses the SwiftUI app lifecycle: a single `@main App` struct and a `RootView` `TabView` stand in for the classic UIKit `AppDelegate` + `SceneDelegate` pair. Everything is neatly organized into folders, but from the compiler's perspective, this is all one giant bucket of code. `MusicSearchView` can directly instantiate `iTunesAPIClient`, which can freely reach for shared globals like `Services.logger` and `AppColors`. Nothing in the compiler stops any file from touching any other.

## The Building Blocks: Roles, Not Folders

The file tree above is an *organizational* view — and folders, as we'll see, are only a suggestion the compiler happily ignores. The more useful way to look at iTunesSearchApp is by the **roles** its code plays. Strip away the folders and the app is made of six distinct kinds of thing. Each one does a different job, sits in a different place in the dependency graph, and — this is the part that matters — has a different destiny in the chapters ahead. The whole rest of this book is just giving each of these roles a boundary the compiler enforces.

What the user sees on screen is only one of the six. Here's the full cast:

1.  **App composition** — `iTunesSearchApp.swift` (the `@main` entry point) and `RootView`'s `TabView`. This is the code that *wires the app together*: it knows about every feature and stands them up. It depends on almost everything; almost nothing depends on it. → It becomes the **composition root** in Chapter 6.
2.  **Features** — Music and Podcasts (the views and their rows). This is the actual product — the screens a user touches. Features depend on the design system, the models, and the networking; nothing depends on a feature except the composition that hosts it. → They become isolated **vertical feature slices** in Chapter 4.
3.  **Design System** — everything under `Shared/`: the tokens (`AppColors`, `Typography`, `Layout`) and the components built from them (`CardView`, `TagView`, `PrimaryButton`, …). *Many* things depend on it; it depends on almost nothing. → It's the **first thing we extract**, in Chapter 2.
4.  **Domain** — the models (`Track`, `Podcast`) and the four service *contracts*: the protocols, plus the typed `AnalyticsEvent` and `FeatureFlag` vocabulary. This is the pure description of *what the app is about*, with no mention of UIKit, the network, or any vendor. → It becomes the **`Domain` module** in Chapter 3.
5.  **Infrastructure** — the things that talk to the outside world: `iTunesAPIClient`, the console implementations of the four services, and the real vendor adapters that arrive later. These *implement* the Domain's contracts. → It becomes the **`Infrastructure` module** in Chapter 3, and gets inverted so Domain stops depending on it in Chapter 5.
6.  **Build tooling** — `project.yml` and XcodeGen. This one isn't Swift at all, and it's easy to overlook, but it's the most important block of the lot: it's the thing that actually *defines targets*, which is how every boundary in this book gets made real. → It doesn't get extracted; it grows, one module at a time, through every chapter.

### Why dependency direction is the whole game

Notice what those descriptions kept circling back to: who depends on whom. That arrow is the single most important property of each block, because it tells you *what is safe to pull out first*. The design system has **many incoming, few outgoing** dependencies — lots of code needs it, it needs almost nothing — which makes it the lowest-risk thing to extract. The composition root is the opposite — **few incoming, many outgoing** — which is why it's the *last* thing we settle, in Chapter 6. Hold onto this idea; it's the reasoning behind the order of the entire book.

### The roadmap, on one page

Here's the cast and where each member is headed. Every chapter from here takes one row and turns its boundary from a convention into a rule:

| Building block | What it is | Depends on | Depended on by | Where it's headed |
| --- | --- | --- | --- | --- |
| Design System | Tokens + reusable UI components | (almost nothing) | Features, Composition | **Ch 2** — first module extracted |
| Domain | Models + service contracts | (nothing) | Features, Infrastructure | **Ch 3** — `Domain` module |
| Infrastructure | Networking + service implementations | Domain | Composition | **Ch 3 / Ch 5** — `Infrastructure`, then inverted |
| Features | Music & Podcasts screens | Design System, Domain | Composition | **Ch 4** — vertical feature slices |
| App composition | `@main` + `RootView` wiring | everything | (nothing) | **Ch 6** — composition root |
| Build tooling | `project.yml` / XcodeGen | — | — | grows every chapter |

This table only covers the cast already on stage — two more members join later. In **Chapter 5**, a new feature, Movies, is born already modular, and forces the composition root to stop depending on concrete features at all. In **Chapter 7** — the proof chapter — a new Audiobooks feature ships and Podcasts is retired, on camera, as the demonstration that adding and deleting a feature is now a small, contained change. And once the team outgrows even a single feature module, **Chapter 8** asks the last question this book asks: how far should you split a single feature, and when should you stop.

Keep this table handy. The names in its first column are the vocabulary for the rest of the book — when a later chapter says "move the contracts into `Domain`," this is the `Domain` it means. With the cast established, let's look more closely at the one block that's easiest to get wrong: the cross-cutting services.

## The Cross-Cutting Services

Every app leans on a handful of cross-cutting services that aren't the product but keep it running: **logging** for everyday diagnostics, a **crash reporter** so you find out when things break, an **analytics backend** so you know what people actually do, and a **feature-flag / remote-config service** so you can ship code dark and turn it on later. iTunesSearchApp wants all four.

Three of the four are backed by a vendor you will eventually swap — Crashlytics today, Sentry next year; Amplitude until finance picks PostHog; a homegrown flag service that becomes LaunchDarkly. Logging looks different at first — it's just `print` — but the moment you want to see how the app behaves in users' hands, those logs start shipping to a service too, and it joins the same club. The product code shouldn't care who's behind any of them. So even in the monolith we describe each one as a plain protocol — a **contract** that says what we need, with no mention of who provides it:

```swift
protocol Logger {
    func log(_ message: String)
}
protocol CrashReporter {
    func record(_ error: Error, context: [String: String])
    func breadcrumb(_ message: String)
}
protocol AnalyticsTracker {
    func track(_ event: AnalyticsEvent)
}
protocol FeatureFlagProvider {
    func isEnabled(_ flag: FeatureFlag) -> Bool
}
```

Four contracts, one shape. The events and flags are typed, not stringly-typed, so the whole vocabulary lives in one place and a typo can't invent a new event:

```swift
struct AnalyticsEvent { let name: String; let properties: [String: String] }
enum FeatureFlag: String { case newPodcastUI, offlineMode }
```

There's no vendor SDK in the project yet. Each contract has exactly one **dev/test implementation**: `ConsoleLogger` is real local logging over Apple's unified logging, and the other three are stand-ins for services we don't own that simply echo to the console. The app therefore runs end-to-end with zero vendor SDKs linked:

```swift
struct ConsoleLogger: Logger {
    func log(_ message: String) { /* os_log */ }
}
struct ConsoleAnalytics: AnalyticsTracker {
    func track(_ e: AnalyticsEvent) { print("📊 \(e.name) \(e.properties)") }
}
// …ConsoleCrashReporter and LocalFeatureFlags do the same.
```

### Choosing an implementation by build configuration

Something has to decide *which* implementation the app uses — and because all four follow one shape, it's the same one-line decision four times over. In the monolith that decision is a single global, switched at compile time so development and test builds get the harmless console versions while a real build would get the actual vendors:

```swift
enum Services {
    #if MOCK_SERVICES
    static let logger: Logger = ConsoleLogger()
    static let crashReporter: CrashReporter = ConsoleCrashReporter()
    static let analytics: AnalyticsTracker = ConsoleAnalytics()
    static let flags: FeatureFlagProvider = LocalFeatureFlags([.newPodcastUI: true])
    #else
    // Release → real vendor adapters arrive in a later chapter
    // (RemoteLogger(), CrashlyticsReporter(), AmplitudeAnalytics(), …).
    static let logger: Logger = ConsoleLogger()
    static let crashReporter: CrashReporter = ConsoleCrashReporter()
    static let analytics: AnalyticsTracker = ConsoleAnalytics()
    static let flags: FeatureFlagProvider = LocalFeatureFlags()
    #endif
}
```

This is the whole answer to "where should logs go in production?" — it's not a policy object with levels and routing rules, it's just which `Logger` the line above injects. Console in dev, a remote backend in Release. The same selection that swaps your analytics vendor swaps your log destination.

The `MOCK_SERVICES` flag is set for the Debug configuration in `project.yml`, so it's a deliberate, readable switch rather than Xcode magic:

```yaml
settings:
  configs:
    Debug:   { SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG MOCK_SERVICES }
    Release: { SWIFT_ACTIVE_COMPILATION_CONDITIONS: "" }
```

Feature code then talks only to the seam — `Services.logger.log(…)` in the API client, `Services.analytics.track(…)` in the Music search, `Services.crashReporter.breadcrumb("app_launch")` at startup, `Services.flags.isEnabled(.newPodcastUI)` in Podcasts — and never names a vendor.

This is the right *idea* in the wrong *shape*. The contracts are already independent of their providers, which is exactly what we want. But the protocols, the implementations, and the global that wires them all still live in the same target as the features that call them — so nothing stops a tired developer from skipping the seam and importing a vendor SDK straight into a view. That gap between "good intention" and "compiler-enforced rule" is the whole story of this book: in later chapters these contracts move into `Domain`, the implementations into `Infrastructure`, the build-config choice into a composition root, and finally the whole concern becomes its own SPM package whose vendor SDKs never even link into a Debug or test build.

## The Breaking Point

As iTunesSearchApp becomes more successful, the team grows from 1 developer to 5, and then to 20. New features are added rapidly. This is when the monolith starts to show its cracks.

Here are the typical problems teams face when scaling a monolith:

1.  **Slow Build Times:** Every time you make a change to a single view, Xcode might need to recompile a significant portion of the entire application. Waiting for 3-5 minutes just to see a color change becomes normal.
2.  **Merge Conflicts:** With 20 developers working in the same target, editing the same `iTunesAPIClient.swift` or `AppColors.swift`, Git merge conflicts become a daily, painful occurrence.
3.  **Tight Coupling (The "Spaghetti" Problem):** Because there are no boundaries enforced by the compiler, it's easy for developers to take shortcuts. The `MusicSearchView` might directly reach into the `Podcasts` feature's code, creating hidden dependencies. Folders are only a suggestion — nothing *stops* this. Over time, every part of the app can touch every other part, and the structure you see in the file tree no longer reflects how the code actually connects. When something breaks, there is no longer an obvious place to look.
4.  **Difficult to Test:** Testing the `MusicSearch` means you have to compile the entire app, including the `Podcasts` feature, even though it isn't relevant to the test.
5.  **Scaling Teams:** It becomes difficult to assign ownership. If a bug occurs in the network layer, who owns it? If team A is working on Music and Team B is working on Podcasts, they are constantly stepping on each other's toes.
6.  **Design and Code Drift Apart:** Designers maintain a source of truth in their design tool; developers maintain another in code. With no shared, rendered reference between them, nobody can point at one authoritative thing and agree "this is the real component, this is its real radius and color." Every visual discrepancy becomes a manual investigation — *is that value final? did it ship? is it hardcoded somewhere?* — and drift is usually caught by accident, sprints later, in a random build.

## The Goal of Modularization

Our goal is not to modularize for the sake of modularization. Our goal is to solve the specific problems listed above. Several of these benefits matter, but one stands above the rest.

### The headline win: boundaries the compiler enforces

The single most important reason to modularize is this: **you can use the compiler to enforce boundaries that prevent spaghetti code.**

In a monolith, separation of concerns is a matter of discipline. You *intend* for the network layer and the database layer to stay separate, but nothing stops a tired developer at 5pm from reaching across that line. Folders don't enforce anything. Code review catches some of it, but not reliably, and not forever.

When each concern lives in its own module, the boundary stops being a suggestion and becomes a rule. If `MusicSearch` is not *allowed* to import `Podcasts`, the code simply won't compile. The architecture you drew on the whiteboard is now the architecture you actually have, because the build system refuses to let it drift. This buys you two things that compound every single day:

*   **Separation of concerns is enforced, not hoped for.** A module can only touch what it explicitly depends on. Shortcuts and hidden dependencies become compile errors instead of landmines you discover six months later.
*   **You always know where to look.** When something breaks, the boundaries tell you where the problem can and cannot be. And before you ever open a file, the module graph gives you a true, high-level map of how the app fits together — what depends on what, and where any given piece of logic belongs.

That last point is the quiet superpower. In a healthy modular codebase, you can reason about the whole system without reading all of it, and a new engineer can understand the shape of the app on their first day.

### The other benefits

Everything else is real, but think of it as the bonus that good boundaries make possible:

*   **Improve Build Times** by only compiling the code that has changed.
*   **Reduce Merge Conflicts** by isolating features so teams can work independently.
*   **Enable Isolated Testing** so we can run unit tests for a specific feature in seconds, not minutes.

Faster builds, fewer conflicts, and isolated tests all *follow* from drawing hard lines between parts of the app. Get the boundaries right and the rest tends to come for free.

## The Scoreboard We're Going to Beat

Before we change a single line, let's write down what the monolith actually costs us. Every chapter from here ends with a **scorecard** that takes one of these numbers and knocks it down — turning "modularization helps" into something you can point at.

| What you do | The monolith (our baseline) |
| --- | --- |
| Clean build of the whole app | ~3m 10s |
| Change one color and see it on screen | ~40s — the whole app target recompiles |
| Run the Music Search logic tests | compiles the entire app first, ~1m+ |
| Two devs on two features | same target → merge conflicts on shared files |

*These are illustrative figures for a mid-size app; measure your own in [`code/part-2-modular/ch01-the-monolith`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch01-the-monolith). What matters is the order of magnitude — and how far each number falls as the chapters go.*

## The First Pain We'll Attack

We won't try to boil the ocean. And the next pain doesn't wait for the team to hit 20 — it shows up as soon as the startup hires its third person. A designer joins, the company signs off on a brand refresh, and suddenly every color and radius in the app is up for change at once. With the tokens buried inside the single app target, every tweak to `AppColors` forces a full rebuild of the entire app just to see one new shade on screen — the whole world rebuilds to check one color.

So in the next chapter we take the first, safest step: extract the one thing nearly every screen already depends on — the **design system**. Its standout payoff is *closing the gap between design and code*: once the design system is its own module, we can render it on its own as a live catalog, giving design and engineering the single source of truth they were missing. Faster UI iteration comes along for the ride — and gives us our first number to knock down on the scoreboard.

## Hands-On: Build the Monolith

Theory only goes so far. A working version of the iTunesSearchApp monolith lives in the [`code/part-2-modular/ch01-the-monolith`](https://github.com/mobiledge/ios-engineering-playbook/tree/main/code/part-2-modular/ch01-the-monolith) folder of this repository. It is a single application target containing everything—models, networking, UI, and utilities—mirroring the anatomy above. The app searches the public iTunes Search API for music and podcasts and presents the results in a list.

Each chapter has its own self-contained project folder (`ch01-the-monolith`, `ch02-design-system`, …) representing the code's state at the end of that chapter, so you can open any chapter's code and run it directly.

To run it, you'll need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen        # one time

cd code/part-2-modular/ch01-the-monolith
xcodegen generate            # creates iTunesSearchApp.xcodeproj from project.yml
open iTunesSearchApp.xcodeproj
```

Pick an iOS Simulator and press **Run** (⌘R). You'll get a two-tab app—Music and Podcasts—that fetches live results from the iTunes Search API and lists them.

We use [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from a small `project.yml` rather than committing the `.xcodeproj`. This keeps the project file out of source control, which—conveniently—eliminates one of the biggest sources of merge conflicts in a monolith. It also makes the structural changes in later chapters easy to express as plain text.

### Feel the Coupling

The sample code is deliberately tangled to make later chapters' refactors concrete. Search the sources for `MONOLITH NOTE` to find each pain point:

*   **Feature views instantiate `iTunesAPIClient.shared` directly.** There is no protocol or injection, so the Music and Podcasts features cannot compile or be tested without the networking layer.
*   **`RootView` knows about every feature**, and shared tokens like `AppColors` and `Logger` are global to the whole target.
*   **Features reach for the global `Services` facade directly.** The API client calls `Services.logger.log(…)`, Music's search calls `Services.analytics.track(…)`, and Podcasts reads `Services.flags.isEnabled(.newPodcastUI)`. The four contracts are clean, but the protocols, implementations, and the build-config switch all share the target — so the boundary is a convention, not a rule the compiler enforces.

These are exactly the knots we'll untie. By the end of the playbook, each will be replaced by an explicit, compiler-enforced boundary.

### Exercise: try to delete Podcasts

Here's an exercise that makes the coupling impossible to un-see. Podcasts is, on the surface, the smaller of the two features — its own view, its own row, its own model. It *sounds* like it should be deletable in five minutes. Try it:

1.  Grep the project for every file that mentions `Podcast`, `PodcastsView`, `PodcastRow`, or `.newPodcastUI`.
2.  For each hit, decide whether you'd actually have to touch that file to remove the feature cleanly — not just the `Views/Podcasts/` folder, but `RootView`, the shared `FeatureFlag` enum, anywhere `Services.flags` is switched on Podcasts, and anything else the grep turns up.
3.  Write the number down.

That number is your real coupling score — not an opinion about the architecture, a count you can point at. Keep it. We'll delete Podcasts for real near the end of the book, and it will take minutes.

---

> **Next:** [Chapter 2: Extracting the Design System](02-extracting-design-system.md)

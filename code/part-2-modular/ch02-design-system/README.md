# iTunesSearchApp — Playbook Sample Project

A fully working iOS app that we refactor chapter by chapter. It searches the
public **iTunes Search API** (no API key needed) for **music** and **podcasts**
and presents the results in a list. There is no local database — the app simply
shows what the API returns.

The git history tracks the playbook:

- **Chapter 1 — The Monolith:** everything lives in one application target.
  See [`part-2-modular/01-the-monolith.md`](../../../part-2-modular/01-the-monolith.md).
- **Chapter 2 — Extracting the Design System:** the shared UI is pulled into a
  local Swift package, `Packages/DesignSystem`, and a standalone **Catalog**
  app target is added. See [`part-2-modular/02-extracting-design-system.md`](../../../part-2-modular/02-extracting-design-system.md).

This project is the Chapter 1 monolith with the design system extracted — diff
it against [`../ch01-the-monolith`](../ch01-the-monolith) to see exactly what
this chapter changes. Music and Podcasts are both present and unchanged in
behavior; only where the shared UI code lives has moved.

## Packages and schemes

- **`Packages/DesignSystem`** — a local Swift package (Tokens + Components,
  `DS`-prefixed) with zero dependencies beyond SwiftUI.
- **`iTunesSearchApp`** scheme — the full app (Music + Podcasts), depends on
  `DesignSystem`.
- **`Catalog`** scheme — a second, minimal app target that depends on
  *only* `DesignSystem`. It renders every token and component in isolation, so
  reviewing the design system no longer requires running the whole app.

## Run it

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-2-modular/ch02-design-system
xcodegen generate            # creates iTunesSearchApp.xcodeproj from project.yml
open iTunesSearchApp.xcodeproj
```

Pick a scheme — **iTunesSearchApp** for the full app, or **Catalog** to browse
the design system in isolation — choose a simulator, and press **Run** (⌘R).

## The DesignSystem package

`Packages/DesignSystem` is a layered, reusable design system:

- **Tokens:** `DSColors` (semantic palette), `DSFont` (primitive type scale +
  semantic styles), `DSSpacing` / `DSRadius`.
- **Components (composed from tokens):** `DSText`, `DSButton`, `DSCard`,
  `DSTag`, `DSArtwork`, `DSMediaRow`, `DSSectionHeader`.

The app and the catalog both depend on it; it depends on nothing but SwiftUI.

> The `.xcodeproj` is intentionally **not** committed — it's a generated
> artifact. Re-run `xcodegen generate` any time the source layout changes.

## How the code maps to the chapter's anatomy

The chapter shows the same SwiftUI structure as the code:

| Chapter anatomy | This project | Notes |
|---|---|---|
| `App/iTunesSearchApp.swift`, `Views/RootView.swift` | same | SwiftUI `App` + `TabView` entry point |
| `Models/Track,Podcast` | `Models/` | iTunes API response types |
| `Networking/iTunesAPIClient` | `Networking/` | `async`/`await` URLSession client |
| `Views/Shared/PrimaryButton,AppColor` | `Packages/DesignSystem/` | extracted into a Swift package in Chapter 2 (`DSButton`, `DSColors`, …) |
| `Views/Music/MusicSearchView,TrackRow` | same | search + list of music tracks |
| `Views/Podcasts/PodcastsView,PodcastRow` | same | search + list of podcasts |
| `Utilities/DateFormatter+Extensions,Services` | `Utilities/` | |

## Where the monolith still hurts (on purpose)

This code is deliberately coupled so the later refactors have something real to
fix. Search the sources for `MONOLITH NOTE` to find each spot:

- **Feature views instantiate `iTunesAPIClient.shared` directly** — no protocol,
  no injection. The Music and Podcasts features can't compile or be tested
  without networking.
- **`RootView` knows about every feature** — there's no composition root.
- **Features reach for the global `Services` facade directly** — the four
  cross-cutting service contracts are clean, but their protocols,
  implementations, and the `MOCK_SERVICES` build-config switch all still live
  in the app target, so the boundary is a convention, not a rule the compiler
  enforces.

The design coupling (`AppColor`, shared UI) is the one this chapter removes by
extracting `DesignSystem`. **The trap this leaves open:** business logic —
things like "don't save duplicate library items" — still has nowhere to live
except inside a SwiftUI view, next to networking calls, and the only way to
test it is to compile and run the whole app in a simulator. That's the pain
Chapter 3 attacks by extracting `Domain` and `Infrastructure`.

1. Ch.2 — extract the shared UI (`AppColor` / `PrimaryButton`) into a Design System module.
2. Ch.3 — extract the Domain models and the Networking infrastructure.
3. Ch.4 — slice Music / Podcasts into feature modules.
4. Ch.5 — invert dependencies behind protocols.
5. Ch.6 — assemble everything in a Composition Root.

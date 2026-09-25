# Medley — Part I, Chapter 1: The Prototype

*Structure must earn its place.*

The starting point of the whole book: **Medley**, a media-discovery app built on Apple's keyless
iTunes Search API, as a solo founder's weekend prototype. One screen, one file, one target, no
layers. Read the chapter: [The Prototype](../../../part-1-architecture/01-the-prototype.md).

## What's here

```text
ch01-the-prototype/
├── CLAUDE.md               # the project rulebook — exactly one law so far
├── .claude/skills/         # empty on purpose; Chapter 2 adds the first skill
├── project.yml             # XcodeGen spec: Medley app + MedleyTests
├── Sources/
│   ├── App/MedleyApp.swift # @main — shows ContentView and nothing else
│   └── ContentView.swift   # everything else: all nine ledger jobs in 138 lines
└── Tests/MedleyTests/
    └── PlaceholderTests.swift  # the only honest test the prototype allows
```

`ContentView` searches the live iTunes catalog for songs (`URLSession` + `JSONSerialization`
dictionaries), renders loading / error / empty / results states with built-in SwiftUI views,
and opens a tapped song in Apple Music. It is deliberately one file doing every job —
the responsibility ledger in the chapter maps each line to the job it does.

## Run it

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-1-architecture/ch01-the-prototype
xcodegen generate            # creates Medley.xcodeproj from project.yml
open Medley.xcodeproj
```

Pick an iOS Simulator and press **Run** (⌘R), then search for an artist.

## Test it

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

One test runs, and it only proves the test target links. That is the point of the chapter: nothing
in the prototype can be reached by a unit test yet.

> The `.xcodeproj` is intentionally **not** committed — it's a generated artifact. Re-run
> `xcodegen generate` any time the source layout changes.

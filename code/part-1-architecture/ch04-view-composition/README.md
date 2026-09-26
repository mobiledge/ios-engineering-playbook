# Medley — Part I, Chapter 4: View Composition

*A view renders what it is given, and nothing else.*

Medley after the line-limit fix. The one big view is now three: `MusicSearchView` owns the screen's
state and the search; `TrackRow` draws one result from the `Track` it's given; `ArtworkView` draws a
thumbnail from a `URL?`. Each has previews with contrived states, so a row can be seen without a
network. Read the chapter: [View Composition](../../../part-1-architecture/04-view-composition.md).

## What's here

```text
ch04-view-composition/
├── CLAUDE.md                            # four laws; lists three skills and their examples
├── .claude/skills/
│   ├── add-model/SKILL.md
│   ├── add-endpoint/SKILL.md
│   └── extract-subview/SKILL.md         # concepts, values in, narrow modifiers, previews
├── project.yml
├── Sources/
│   ├── App/MedleyApp.swift              # builds the client, shows MusicSearchView
│   ├── Features/Music/
│   │   ├── MusicSearchView.swift        # was ContentView: state, search, tap-to-open
│   │   └── TrackRow.swift               # one result + five contrived-state previews
│   ├── DesignSystem/ArtworkView.swift   # thumbnail from a URL?, music note when there's none
│   ├── Models/Track.swift
│   └── Networking/                      # unchanged from Chapter 3
└── Tests/MedleyTests/                   # unchanged from Chapter 3: 12 tests
```

## Run it

You need a Mac with Xcode 16.3+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cd code/part-1-architecture/ch04-view-composition
xcodegen generate
open Medley.xcodeproj
```

Open `TrackRow.swift` and show the canvas (⌥⌘↩): five previews render without a network — every
field present, the longest plausible title, only the required fields, empty strings, and the
largest accessibility text size. `ArtworkView.swift` previews loaded, missing, and still-loading
artwork. Then run the app (⌘R) and search.

## Test it

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

The same twelve tests as Chapter 3. This chapter adds none, on purpose: pure rendering has no logic
to unit test, and previews are its feedback loop. The chapter explains why.

> The `.xcodeproj` is intentionally **not** committed — it's a generated artifact. Re-run
> `xcodegen generate` any time the source layout changes.

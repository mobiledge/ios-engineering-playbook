# Medley — Part I, Chapter 5: View Models

*Raw data never reaches a view.*

Medley after the retry bug. The music screen's state and behaviour live in `MusicSearchViewModel`:
one `ViewState` enum instead of three booleans, a search through the injected `SearchClient`, and
tracks turned into `TrackRowModel`s whose every string is already formatted. The views render
state and forward what the user does. The test Chapter 1 couldn't write — "a 247-second song shows
as 4:07" — passes. Read the chapter: [View Models](../../../part-1-architecture/05-view-models.md).

## What's here

```text
ch05-view-models/
├── CLAUDE.md                              # five laws; lists four skills and their examples
├── .claude/skills/
│   ├── add-model/  add-endpoint/  extract-subview/
│   └── add-view-model/SKILL.md            # state enum, display models, previews per state, tests
├── project.yml
├── Sources/
│   ├── App/MedleyApp.swift                # builds the client and the view model, shows the screen
│   ├── Features/Music/
│   │   ├── MusicSearchViewModel.swift     # query + one ViewState; search; errors → messages
│   │   ├── TrackRowModel.swift            # one row, every value preformatted
│   │   ├── MusicSearchView.swift          # switch over state; five previews, one per state
│   │   └── TrackRow.swift                 # draws a TrackRowModel; formats nothing
│   ├── DesignSystem/ArtworkView.swift
│   ├── Models/Track.swift
│   └── Networking/                        # unchanged from Chapter 3
└── Tests/MedleyTests/
    ├── MusicSearchViewModelTests.swift    # every state and transition, through a fake client
    ├── TrackRowModelTests.swift           # every formatted field, including "4:07"
    ├── TrackDecodingTests.swift  ITunesAPIClientTests.swift
    └── Support/FakeSearchClient.swift  Support/StubURLProtocol.swift
```

## Run it

You need a Mac with Xcode 16.3+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cd code/part-1-architecture/ch05-view-models
xcodegen generate
open Medley.xcodeproj
```

Open `MusicSearchView.swift` and show the canvas (⌥⌘↩): five previews — idle, loading, loaded,
empty, failed — none of which needs a network. Then run the app (⌘R), search, turn Wi-Fi off,
search again, turn it back on, and tap **Try Again**: a spinner, and only a spinner.

## Test it

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Twenty-eight tests in four suites, in well under a tenth of a second, with no network.

> The `.xcodeproj` is intentionally **not** committed — it's a generated artifact. Re-run
> `xcodegen generate` any time the source layout changes.

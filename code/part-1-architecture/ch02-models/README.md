# Medley — Part I, Chapter 2: Models

*Data becomes a type the moment it enters the app.*

Medley after its first crash. Search results now decode into a `Track` model at the moment they
arrive, so the view never reads a dictionary again, and the book's first real tests check that
decoding against fixtures saved from Apple's live API. Read the chapter:
[Models](../../../part-1-architecture/02-models.md).

## What's here

```text
ch02-models/
├── CLAUDE.md                       # two laws; lists the first skill
├── .claude/skills/
│   └── add-model/SKILL.md          # model + fixtures + decoding tests, shipped together
├── project.yml                     # XcodeGen spec: Medley app + MedleyTests
├── Sources/
│   ├── App/MedleyApp.swift         # @main — shows ContentView and nothing else
│   ├── Models/
│   │   ├── Track.swift             # a song, with honest optionality
│   │   └── SearchResponse.swift    # the { results: [...] } envelope + the one shared decoder
│   └── ContentView.swift           # every other job: 8 of the 9 ledger rows
└── Tests/MedleyTests/
    ├── TrackDecodingTests.swift    # happy path, minimal, missing artwork, malformed date
    └── Fixtures/                   # real iTunes responses, one edited copy per bad case
```

`ContentView` still builds the URL, calls `URLSession`, checks the status, and formats every value
itself. What changed is one line of decoding: `JSONSerialization` and six dictionary casts became
`SearchResponse.decoder.decode(...)` and a `[Track]`.

## Run it

You need a Mac with Xcode 16.3+ (for Swift Testing) and
[XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-1-architecture/ch02-models
xcodegen generate            # creates Medley.xcodeproj from project.yml
open Medley.xcodeproj
```

Pick an iOS Simulator and press **Run** (⌘R), then search for an artist. Each row now shows the
album under the artist.

## Test it

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Four decoding tests run in a few milliseconds, with no network: the happy path, a minimal result
proving every optional field is optional, the missing-artwork crash as a regression test, and a
malformed date that must fail loudly.

> The `.xcodeproj` is intentionally **not** committed — it's a generated artifact. Re-run
> `xcodegen generate` any time the source layout changes.

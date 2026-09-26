# Medley — Part I, Chapter 3: Networking

*The network hides behind a contract.*

Medley after the storefront fix. The view no longer knows the network exists: it asks a
`SearchClient` for songs and gets `[Track]` or a typed `SearchError` back. `ITunesAPIClient` builds
the request, checks the status, and decodes, and everything it depends on is handed to it by
`MedleyApp`. Read the chapter: [Networking](../../../part-1-architecture/03-networking.md).

## What's here

```text
ch03-networking/
├── CLAUDE.md                          # three laws; lists two skills and their examples
├── .claude/skills/
│   ├── add-model/SKILL.md
│   └── add-endpoint/SKILL.md          # protocol, client, typed errors, stubbed tests
├── project.yml                        # XcodeGen spec: Medley app + MedleyTests
├── Sources/
│   ├── App/MedleyApp.swift            # @main — builds the one ITunesAPIClient, hands it in
│   ├── Models/Track.swift
│   ├── Networking/
│   │   ├── SearchClient.swift         # the contract: searchSongs(matching:)
│   │   ├── ITunesAPIClient.swift      # URL building, status check, decoding
│   │   ├── SearchError.swift          # offline / unreachable / badStatus / unreadableResponse
│   │   └── SearchResponse.swift       # the API's envelope + the one shared decoder
│   └── ContentView.swift              # the screen: 7 of the 9 ledger rows
└── Tests/MedleyTests/
    ├── TrackDecodingTests.swift       # unchanged from Chapter 2
    ├── ITunesAPIClientTests.swift     # the request, one round trip, error mapping
    ├── Support/StubURLProtocol.swift  # answers requests with canned responses
    └── Fixtures/                      # real iTunes responses
```

## Run it

You need a Mac with Xcode 16.3+ (for Swift Testing) and
[XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-1-architecture/ch03-networking
xcodegen generate            # creates Medley.xcodeproj from project.yml
open Medley.xcodeproj
```

Pick an iOS Simulator and press **Run** (⌘R), then search for an artist. To see the storefront
follow the device, set the simulator's region (Settings → General → Language & Region) to the
United Kingdom and search again.

## Test it

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Twelve tests (eighteen cases, counting parameterised ones) run in a few hundredths of a second, and
none touches the network: requests go to `StubURLProtocol`. Turn Wi-Fi off and they still pass.

> The `.xcodeproj` is intentionally **not** committed — it's a generated artifact. Re-run
> `xcodegen generate` any time the source layout changes.

# Medley — project rules

Medley is a media-discovery app for iOS, built in SwiftUI on Apple's keyless iTunes Search API.
Most of it still lives in `Sources/ContentView.swift`; API responses decode into `Sources/Models/`.

These are the project's laws. Follow every one of them. A law is added only when the project
has paid for it — each one records a lesson, not a preference.

## Laws

1. **We ship; structure must earn its place.** Do not introduce a type, file, folder, layer, or
   abstraction until a concrete pain in this project demands it. When a task seems to call for
   new structure, say which pain it solves; if there isn't one yet, don't add it.
2. **Data becomes a type the moment it enters the app.** Decode every API response into a
   `Decodable` model once, where it arrives; nothing past that point reads JSON or a dictionary.
   Model optionality on what the API really sends, and ship every model with fixture-based
   decoding tests. We learned this from a crash: an `as!` on a missing artwork key.

## Skills

Project skills live in `.claude/skills/`. Use the matching skill whenever a task falls under it.
Skills are general practice; the example to copy in this codebase is listed with each one.

- `add-model` — add or change a type decoded from an API response, with its fixtures and tests.
  Example: `Sources/Models/Track.swift`, tested by `Tests/MedleyTests/TrackDecodingTests.swift`;
  decode through `SearchResponse.decoder`.

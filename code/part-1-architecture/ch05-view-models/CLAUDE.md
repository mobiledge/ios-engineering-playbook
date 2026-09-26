# Medley — project rules

Medley is a media-discovery app for iOS, built in SwiftUI on Apple's keyless iTunes Search API.
The music screen lives in `Sources/Features/Music/` (a view model plus the views that render it),
reusable components in `Sources/DesignSystem/`; API responses decode into `Sources/Models/`, and
the network lives in `Sources/Networking/` behind the `SearchClient` protocol.

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
3. **The network hides behind a contract; dependencies are handed in, never grabbed.** Views and
   other callers talk to `SearchClient`, never to `URLSession`, URLs, or JSON. Every type receives
   what it depends on through its initializer — no `.shared`, no singletons, no reading
   `Locale.current` or other globals inside a type; only `MedleyApp` (and previews) construct the
   real ones.
   We learned this from a one-line query change inside a view: it could only be checked by hand,
   and its first attempt failed every search with an HTTP 400 that the app blamed on Apple.
4. **A view renders what it is given, and nothing else.** Split screens into small views that each
   draw one concept from values handed to them — never a client or other source. Put modifiers on
   the narrowest view they're meant for, and give every extracted view `#Preview`s with contrived states
   (longest text, missing data, largest type) that need no network. We learned this from a
   one-character line-limit fix that silently reached every subtitle in the row, and could only be
   seen with a live search.
5. **Raw data never reaches a view.** Every screen has an `@Observable` view model that owns its
   state as one enum (never parallel `isLoading`/`showError` booleans), receives its dependencies
   through `init`, and turns models into display models of preformatted strings. Views render the
   state and forward what the user does; they format nothing and decide nothing. Every state and
   every formatted value is tested through a fake. We learned this from a retry that drew a spinner
   on top of an error, and a duration format nobody could test for four chapters.

## Skills

Project skills live in `.claude/skills/`. Use the matching skill whenever a task falls under it.
Skills are general practice; the example to copy in this codebase is listed with each one.

- `add-model` — add or change a type decoded from an API response, with its fixtures and tests.
  Example: `Sources/Models/Track.swift`, tested by `Tests/MedleyTests/TrackDecodingTests.swift`;
  decode through `SearchResponse.decoder`.
- `add-endpoint` — add or change a call to the API, with its typed errors and tests.
  Example: `Sources/Networking/ITunesAPIClient.swift` behind `SearchClient`, tested by
  `Tests/MedleyTests/ITunesAPIClientTests.swift` through `Tests/MedleyTests/Support/StubURLProtocol.swift`.
- `extract-subview` — split a view, or add UI to a screen, with values in and previews alongside.
  Example: `Sources/Features/Music/TrackRow.swift` (feature view) and
  `Sources/DesignSystem/ArtworkView.swift` (reusable component), each with contrived-state previews.
- `add-view-model` — give a screen its state, formatting, and tests; or add a new screen.
  Example: `Sources/Features/Music/MusicSearchViewModel.swift` and
  `Sources/Features/Music/TrackRowModel.swift`, rendered by `MusicSearchView.swift`, tested by
  `Tests/MedleyTests/MusicSearchViewModelTests.swift` and `Tests/MedleyTests/TrackRowModelTests.swift`
  with `Tests/MedleyTests/Support/FakeSearchClient.swift`.

---
name: add-model
description: Use when adding a type decoded from an iTunes Search API response, or adding or changing a field on an existing one (such as Track). Covers the model, its fixtures, and its decoding tests, which ship together.
---

# add-model

## Convention

Data becomes a type the moment it enters the app.

1. **One `Decodable` struct per API payload**, in `Sources/Models/`, named for the thing itself:
   `Track`, never `TrackModel` or `TrackDTO`. `Decodable`, not `Codable` — the app only reads.
2. **Property names are the JSON keys.** No `CodingKeys` unless a key isn't a legal Swift name.
3. **Optionality mirrors what the API promises.** A property is required only if a result can't
   be shown without it (for `Track`: `trackId`, `trackName`, `artistName`); a response missing one
   fails to decode. Everything Apple doesn't guarantee is optional, and the view copes with `nil`.
   Never force-unwrap a field, and never paper over a required one with a `??` default.
4. **Declare only the fields something uses today.** A new field arrives with its first caller.
5. **Real types, raw units.** URLs are `URL`, dates are `Date`, numbers keep the API's units
   (`trackTimeMillis: Int`). No formatting or display helpers on a model.
6. **Decode once, at the boundary, through `SearchResponse.decoder`.** Nothing past that point
   sees `Data`, JSON, or a dictionary. No `JSONSerialization`, no `as!`, no second decoder.
7. **Every model ships with fixtures and decoding tests, in the same change:**
   - Fixtures are saved real responses (fetch the endpoint, keep one or two results) in
     `Tests/MedleyTests/Fixtures/`, named `<model>_<case>.json`. Edit a copy to make a bad case;
     never hand-write a good one.
   - One Swift Testing `@Test` per case: the happy path; a **minimal** fixture holding only the
     required keys, with every optional expected `nil`; one regression fixture for each field that
     has actually gone missing in production; and a malformed fixture for each field whose format
     the decoder enforces (today: ISO 8601 dates). Decode through the same decoder the app uses.
8. **Adding a field to an existing model follows the same steps:** add the property, check the
   happy-path fixture carries it (real fixtures usually do), assert its value there and its `nil`
   in the minimal test, and only then use it.

## Why

Chapter 2's first crash. The view read artwork with `item["artworkUrl100"] as! String`; the first
search result without artwork took the app down, earned a 1-star review, and cost a hotfix. With
parsing scattered through the view, every read was a separate guess about Apple's JSON. A type
states each guess once, and a fixture test checks it against a real response in milliseconds.

## Exemplar

`Sources/Models/Track.swift` — honest optionality, JSON-named properties, no helpers. Its tests are
`Tests/MedleyTests/TrackDecodingTests.swift`; the envelope and the shared decoder are
`Sources/Models/SearchResponse.swift`.

## Acceptance checks

- [ ] The model is a `Decodable` struct in `Sources/Models/` and declares no field nothing uses.
- [ ] A minimal fixture with only the required keys decodes, and its test expects every optional
      property to be `nil` — including any property added in this change.
- [ ] Every field whose format the decoder enforces (dates) has a malformed fixture and a test
      expecting `DecodingError`.
- [ ] `grep -rnE 'JSONSerialization|as! ' Sources` finds nothing.
- [ ] `xcodebuild test -scheme Medley` passes, including the new tests.

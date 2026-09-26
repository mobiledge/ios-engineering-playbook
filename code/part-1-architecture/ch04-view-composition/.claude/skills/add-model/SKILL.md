---
name: add-model
description: Use when adding a Swift model type decoded from external data (an API response, a file, a push payload), or adding or changing a field on one. Covers the type, its test fixtures, and its decoding tests, which ship together.
---

# add-model

## Best practices

**Where decoding happens**

1. **Decode once, at the boundary** — where the bytes arrive. Everything past that point receives
   typed models, never `Data`, JSON, or `[String: Any]`. Parsing scattered across callers makes
   every read a separate guess with its own idea of what to do when the guess is wrong.
2. **One shared, configured decoder per data source** (date strategy, key strategy). The app and the
   tests decode through the same instance; a test with its own decoder proves nothing about the app.
3. **No `JSONSerialization` and casts, no `as!`, no force-unwrapped decoded values.** A trap in a
   release build is a crash with no message.

**Shape of the type**

4. **A struct, `Decodable` only.** Add `Encodable` when something actually encodes it — an unused
   conformance is an untested promise. Name it for the thing (`Invoice`), not the layer
   (`InvoiceDTO`, `InvoiceModel`).
5. **Property names match the source's keys.** Reach for `CodingKeys` only when a key isn't a legal
   or readable Swift name.
6. **Optionality mirrors what the source promises.** Required only for what the app can't work
   without (identity, the primary label); a payload missing one should fail to decode. Anything the
   source doesn't guarantee is optional, and callers handle `nil`. Never make a field optional just
   to get decoding to pass, and never hide a missing required value behind a `??` default.
7. **Declare only the fields a caller uses today.** A field arrives with its first caller;
   `Decodable` ignores the rest.
8. **Real types, source units.** `URL` not `String`, `Date` not `String`, numbers in the source's
   units (milliseconds stay milliseconds). No formatting or display logic on the model.
9. **A `Date` is an instant.** If the source means a calendar day, note it on the property, and
   format it in the source's time zone, not the user's — or the day (and at New Year, the year)
   shifts.
10. **`Identifiable` through the source's own stable ID** when the model is shown in lists.

**Tests ship with the model, in the same change**

11. **Fixtures are saved real payloads**, trimmed to one or two items and kept in the test target.
    Make each bad case by editing a copy; never hand-write a good one. A hand-written fixture holds
    what you think the source sends; a saved one holds what it does send, including the keys you
    ignore.
12. **One test per case:**
    - happy path — every declared field asserted;
    - minimal — only the required keys, every optional expected `nil`;
    - regression — one fixture for each field that has actually gone missing in production;
    - malformed — one fixture for each field whose format the decoder enforces (dates), expecting
      `DecodingError`.
13. **Assert what the framework actually does**, not what you assume — e.g. which coding path a
    `DecodingError` reports. Let the test correct you.
14. **Adding a field to an existing model** takes the same steps: add the property, check the happy
    fixture carries it, assert its value there and its `nil` in the minimal test, then use it.
15. **Decide what one bad element does to a collection.** Strict (the whole payload fails and the
    error surfaces) is the default. Switch to per-element lossy decoding only when real failures
    justify it, and test that path too.
16. **Fast and offline.** Swift Testing (`@Test`, `#expect`), no network, milliseconds per test.

## Acceptance checks

- [ ] The type is a `Decodable` struct named for the thing, declaring no field nothing uses.
- [ ] Nothing past the boundary decodes; no `JSONSerialization`, `as!`, or force-unwrapped decoded
      value anywhere.
- [ ] Happy, minimal, and per-malformed-field fixtures exist, and any field added in this change is
      asserted in both the happy and the minimal test.
- [ ] Tests decode through the same decoder the app uses and pass without a network.

---
name: add-endpoint
description: Use when a Swift app needs a new call to an HTTP API, or a change to an existing one (a new query parameter, header, path, or error case). Covers the client protocol, the concrete client, typed errors, and the tests, which ship together.
---

# add-endpoint

## Best practices

**The contract**

1. **Callers depend on a protocol, stated in the app's terms.** `func invoices(for customer:)`, not
   `func get(path:query:)`. The protocol mentions no URLs, status codes, or JSON; those are the
   conforming client's business.
2. **Keep the protocol as small as its callers.** Add a method when a caller needs it, not to mirror
   every endpoint the API offers.
3. **One typed error for the whole client**, with cases a caller can act on (offline, unreachable,
   bad status, unreadable response) rather than raw `URLError` or `DecodingError`. Every method
   throws only that type, and says so.

**The client**

4. **Every dependency arrives through `init`:** the `URLSession`, base URL, locale, credentials,
   flags. No singletons, no `.shared`, no reading global state (`Locale.current`, `UserDefaults`,
   environment) inside the type. What is handed in can be swapped in a test; what is grabbed can't.
5. **Build requests in a pure function** (`url(for:)` or `request(for:)`) that sends nothing, so the
   request can be tested without a network or a stub.
6. **Use `URLComponents` and `URLQueryItem`**, never string concatenation. Name every query
   parameter the API needs, even when it has a default — the default is usually someone else's
   storefront, page size, or language.
7. **Derive API values from their real source.** A country code is a locale's *region*, not its
   identifier; a language is its language code. Test the derivation.
8. **Check the status before decoding.** Treat non-2xx as an error, and keep 4xx (our request is
   wrong) distinguishable from 5xx (their service is down) — they need different messages and
   different fixes.
9. **Map every failure exactly once, at the client**: transport errors, bad statuses, and decoding
   failures each become one case of the typed error. Keep the underlying detail (a reason string)
   for logs; callers switch on the case.
10. **Decode through the shared decoder for that API**, never a fresh `JSONDecoder()`.

**Tests ship with the endpoint, in the same change**

11. **No test touches the network.** Route requests through a stub `URLProtocol` installed on an
    ephemeral `URLSession` that the test hands to the client. Suites sharing stub state run
    serialized.
12. **Test your logic, not Apple's:**
    - the request — every query parameter, including each derived value (region, flags);
    - one round trip — a saved real payload through the stub decodes, and the request the stub
      received equals the one the pure builder produces;
    - status mapping — representative 4xx and 5xx statuses become the right error;
    - transport mapping — offline and unreachable codes become the right case (a parameterised
      test is ideal);
    - a 2xx with an undecodable body becomes the unreadable-response case.
13. **Every bug found in a request becomes a named regression test** of the pure builder.

## Acceptance checks

- [ ] Callers reference only the protocol; no call site builds URLs, touches `URLSession`, or
      decodes.
- [ ] The client has no `.shared`, no singleton, and reads no global state; everything it uses is
      an `init` parameter.
- [ ] Every method throws only the client's typed error.
- [ ] Tests cover the request, one round trip, status mapping, transport mapping, and an
      undecodable body — and pass with networking disabled.

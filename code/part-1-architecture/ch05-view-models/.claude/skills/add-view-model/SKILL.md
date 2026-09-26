---
name: add-view-model
description: Use when a SwiftUI screen has state, loading, errors, or formatting to manage, when adding a new screen, or when a view is deciding what to show or how to format data. Covers the view model, its state enum, display models, the view's side, previews per state, and the tests, which ship together.
---

# add-view-model

## Best practices

**The view model**

1. **One view model per screen, `@Observable` and `@MainActor`.** It holds the screen's state and
   behaviour and imports no SwiftUI. Name it for the screen (`InvoiceListViewModel`), not
   `…VM` or `…Manager`.
2. **Every dependency arrives through `init`** — clients, services, clocks. Depend on protocols, so
   tests can hand in fakes. Never construct a real client inside a view model.
3. **One state enum, one case per real screen state** — typically `idle`, `loading`, `loaded`,
   `empty`, `failed` — with the data each state needs as associated values. Never parallel
   `isLoading` / `hasError` / `hasResults` booleans: three `Bool`s make eight combinations for five
   states, and the extra three are bugs ("spinner over the error", "error over stale results").
4. **Expose state read-only** (`private(set)`); expose user input (a query, a toggle) as plain
   settable properties the view can bind to; expose actions as methods (`search()`, `retry()`,
   `select(_:)`).
5. **Each action sets exactly one state per step:** `.loading` before awaiting, then one of the
   outcome states. A new request replaces the old outcome; it never layers on top of it.
6. **Error messages are decided here**, from typed errors, as strings the view shows verbatim.
7. **Accept an initial state in `init`** (defaulting to idle) so previews can start the screen in
   any state without faking a dependency.

**Display models**

8. **Map domain models to display models of preformatted values** (`title`, `subtitle`, `duration:
   "4:07"`, `year: "1997"`) in one initializer. Everything a user reads is decided there, where a
   test can check it; the view formats nothing.
9. **Use the platform's formatters** (`Duration`, `Date.FormatStyle`, `FormatStyle` generally)
   configured explicitly — rounding rule, time zone, padding — rather than hand-rolled arithmetic,
   and don't assume their defaults match your product: check them in a test.
10. **Keep non-drawn data a view needs for an action** (a link, an ID) on the display model, clearly
    marked as not drawn, rather than passing the domain model down to the view.

**The view**

11. **The view renders `state` with one `switch` and forwards intents** — it calls methods, binds
    inputs, and decides nothing. It doesn't format, compute, or branch on anything but the state.
12. **Whoever owns the view model's lifetime creates it** (the app, or a parent screen) and hands it
    to the view, which observes it (`@Bindable`), rather than the view building it from a client.
13. **Previews: one per state case**, each starting the view model in that state. None needs a
    network.

**Tests ship with the view model, in the same change**

14. **Drive every state through a fake dependency** that returns a canned result, records what it
    was asked, and can run a closure *while a request is in flight*, so a test can assert on the
    state mid-request.
15. **Cover every state case and every transition a user can cause:** start, blank input, in-flight,
    success, empty, failure, retry after failure, failure after success, and clearing input.
16. **Test display models as plain values:** every formatted field, the formatter edge cases you
    chose deliberately (rounding, time zones, long values), and pass-through fields.
17. **Tests run on the main actor, with no UI, no network, and no sleeps.**

## Acceptance checks

- [ ] No view that renders this screen holds `@State` for loading, errors, or results, or formats
      a value.
- [ ] The view model has a single state enum, receives all dependencies through `init`, and imports
      no SwiftUI.
- [ ] There is a preview for every state case, and none needs a network.
- [ ] Tests cover every state case, retry and failure-after-success transitions, and every
      formatted field of the display model — and pass with no network.

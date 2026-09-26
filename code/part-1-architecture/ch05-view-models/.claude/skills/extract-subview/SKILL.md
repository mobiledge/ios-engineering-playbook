---
name: extract-subview
description: Use when a SwiftUI view's body has grown large, when a visual change to one part of a screen risks another, or when a new piece of UI is being added to an existing screen. Covers when to extract a subview, what it receives, where state and modifiers go, and the previews it ships with.
---

# extract-subview

## Best practices

**When to extract**

1. **Extract a concept, not a coincidence.** A subview earns its own type when it draws something
   with a name — a row, a thumbnail, a badge, an empty state — not when two stretches of code
   merely look alike.
2. **Extract when you need to see it alone.** If the only way to look at a piece of UI is to run
   the app and navigate to it with the right data, it needs its own type and its own previews.
3. **Small view structs are free.** SwiftUI views are value types that describe UI; splitting a
   `body` into several structs costs nothing at runtime. Line count and readability are the only
   measures that matter.
4. **Name it for what it draws** (`InvoiceRow`, `AvatarView`), and put screen-specific views with
   their feature and reusable ones in a shared components folder.

**What it receives**

5. **Values, not sources.** A subview takes the data it draws (`let invoice: Invoice`,
   `let url: URL?`), never a client, a store, a session, or the environment object that produces
   the data. It renders what it is given, and nothing else.
6. **The narrowest type that works.** A reusable component takes primitives (`URL?`, `String`)
   rather than a feature's model, so it can be used anywhere and previewed with anything.
7. **Actions go out as closures, or stay with the parent.** Tapping, navigating, and opening URLs
   are decisions; a row that draws shouldn't make them.

**State and modifiers**

8. **`@State` lives with the view that owns the state**, not the view that displays it. A child
   gets values (or a `Binding` when it must edit the parent's state).
9. **Put each modifier on the narrowest view it is meant for.** Environment-style modifiers
   (`lineLimit`, `font`, `foregroundStyle`, `tint`) flow into every descendant; on a container they
   silently reach views you didn't intend to change.
10. **Keep behaviour unchanged when extracting.** Move first, then change — in a separate step, so a
    regression can only have one cause.

**Previews ship with the view**

11. **Every extracted view has `#Preview`s with contrived states** — the ones a live run rarely
    shows: the longest plausible text, every optional missing, empty strings, zero values, still
    loading, the largest accessibility text size.
12. **Previews need no network or backend.** Build preview data inline; a preview that needs a live
    service to show anything is a sign the view receives a source instead of values.
13. **Be honest about what previews are.** Pure rendering has no logic to unit test, so previews
    are the feedback loop. Don't dress them up as tests; when there *is* logic worth testing inside
    a view, that's a sign it belongs somewhere testable.

## Acceptance checks

- [ ] The extracted view takes only values (and closures or bindings where needed) — no clients,
      sessions, stores, or `@State` it doesn't own.
- [ ] Reusable components take primitive types, not a feature's models.
- [ ] Every new or extracted view file has `#Preview`s covering its contrived states, and none needs
      the network.
- [ ] The screen looks and behaves the same as before the extraction; any intended change was made
      in a separate step.

# Chapter 4 Plan — View Composition

*A view renders what it is given, and nothing else.*

Read `plans/part-1-architecture/00-conventions.md` first. Prerequisite: `ch03-networking.md`.

## Goal

Retire ledger row 3 (rendering every pixel). Decompose the mega-view into small view structs that
render values handed to them. This is the chapter that **refuses to fake a unit test**.

## Start state

`ch03` end state: models + injected `SearchClient`; one 123-line `ContentView` whose `body` is ~70 lines; skills =
`add-model`, `add-endpoint`.

## Prose tasks — `part-1-architecture/04-view-composition.md`

- **Where we are** — ch03's ledger (rows 1–2 struck) and file tree.
- **The pain** — a friend reports long titles are cut off ("They Are Night Zombies!! They Are
  Neighbors!! …" shows as one truncated line). The fix looks like one character: `.lineLimit(1)` →
  `.lineLimit(2)`. But that modifier sits on the row's `VStack` (line 54 of ch03's `ContentView`),
  so it also reaches the artist, album, and year: every subtitle can now wrap, and rows with long
  album names double in height. Modifiers are shared by accident, and in a 70-line `body` their
  reach is invisible. Worse, there is no way to *see* a row without a live search: the file's only
  preview is the whole screen, built with the real client, starting on the idle state. Cost: a build
  that made the list look broken, found from a friend's screenshot.
- **The extraction** — `ContentView` is renamed `MusicSearchView` and moves to
  `Sources/Features/Music/` (say so explicitly: the name is retired, not lost). It owns flow: the
  `@State`, the search, the tap. `TrackRow` (takes a `Track`) and `ArtworkView` (takes a `URL?`)
  render what they are given. The tap-to-open `Button` stays in `MusicSearchView` (navigation is
  row 7, not the row's business). Cover where `@State` should live (with the thing that owns the
  state, not the thing that displays it) and why small view structs are free. Then make the fix the
  pain wanted, in `TrackRow`'s preview: `.lineLimit(2)` on the title only, `.lineLimit(1)` on the
  subtitle group.
- **Prove it — honestly** — pure rendering has no logic to unit test, and the chapter **says so**.
  The feedback tool is previews: one per component, with contrived states (longest plausible title,
  missing artwork, empty string). Do **not** invent a snapshot-testing dependency. Then name the
  itch deliberately: *the formatting I actually want to test is still trapped in view code.* That
  itch is Ch 5's opening.
- **Codify it** — `extract-subview`, portable in the ch02 format: a view earns extraction when it
  renders a *concept*, not a coincidence; it receives values, not sources; modifiers go on the
  narrowest view they're meant for; every extracted view ships with contrived-state previews. Law 4
  in `CLAUDE.md`, which lists the skill with its example here. Demo: ask the assistant for a
  music-note placeholder when a track has no artwork. Following the skill, it puts the change in
  `ArtworkView` (the concept that owns it), keeps the gray box for "still loading", and adds a
  preview for the `nil` case. It lands in code.
- **The ledger** — row 3 struck through.
- **Is this worth it yet?** — three files where there was one, and previews that are only as good
  as their contrived data. Worth it because a row can now be seen without a network.
- **The trap** — the view still *thinks*: `TrackRow` formats years and durations, and
  `MusicSearchView` juggles three Bools and decides what "empty" means.

## Code tasks — `code/part-1-architecture/ch04-view-composition`

```manifest
+ Sources/Features/Music/MusicSearchView.swift
+ Sources/Features/Music/TrackRow.swift
+ Sources/DesignSystem/ArtworkView.swift
+ .claude/skills/extract-subview/SKILL.md
~ Sources/App/MedleyApp.swift
~ CLAUDE.md
~ README.md
~ project.yml
- Sources/ContentView.swift
```

`project.yml` changes in comments only. Tests are unchanged.

`ContentView.swift` is retired into `MusicSearchView.swift` — call the rename out explicitly in
prose, since the continuity contract forbids silent disappearances. Every new view file carries a
`#Preview` with contrived states. Note that `Sources/DesignSystem/` appears here holding exactly one
generic component; it stays nearly empty until Ch 7 fills it.

## Skill — `extract-subview`

## Acceptance criteria

**cloud**
- [ ] Headings, order, ledger rows 1–3 struck through.
- [ ] "Prove it" explicitly states that rendering has no unit-testable logic and uses previews.
- [ ] Every file under `Sources/Features` and `Sources/DesignSystem` contains a `#Preview`.
- [ ] No file exceeds 150 lines. Continuity equals the manifest, `~` lines included.
- [ ] Every line of the check block below passes (run from the code folder):

```check
! grep -rn 'ContentView' Sources
grep -q 'MusicSearchView(client:' Sources/App/MedleyApp.swift
grep -q 'struct TrackRow: View' Sources/Features/Music/TrackRow.swift
grep -q 'struct ArtworkView: View' Sources/DesignSystem/ArtworkView.swift
for f in $(find Sources/Features Sources/DesignSystem -name '*.swift'); do grep -q '#Preview' "$f" || exit 1; done
find Sources Tests -name '*.swift' -exec wc -l {} + | awk '$2 != "total" && $1 > 150 { bad = 1 } END { exit bad }'
! grep -nE 'SearchClient|URLSession|openURL|@State' Sources/Features/Music/TrackRow.swift Sources/DesignSystem/ArtworkView.swift
! grep -rnw 'Track' Sources/DesignSystem
test "$(grep -cE '^[0-9]+\. \*\*' CLAUDE.md)" -eq 4
grep -q '`extract-subview`' CLAUDE.md
grep -rhE '^[[:space:]]*@Test' Tests | awk 'END { exit !(NR == 12) }'
grep -qiE 'nothing (here )?to unit test|no (unit-testable )?logic to (unit )?test' ../../../part-1-architecture/04-view-composition.md
```

**mac**
- [ ] Builds; previews render; existing tests still pass (test count unchanged from Ch 3).

## Out of scope

- No view model, no `ViewState` enum, no formatting extraction — that is Ch 5's entire payoff.
- No design tokens: bare layout numbers (thumbnail size, corner radius, spacing) **stay** until
  Ch 7.

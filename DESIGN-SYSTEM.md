# Three-Tier SwiftUI Design System

A portable structure for any iOS app. Three levels, one rule: **each level may use the level below it, never reach past it.** No raw value or magic number ever appears above where it's defined.

Replace `Aero` below with your system's name.

---

## Level 1 — Tokens

The indivisible values. Split into two sublayers.

**Raw tokens** — literal values, named by *what they are*. Nothing else references these directly except the semantic layer.

```swift
enum RawColor {
    static let blue500 = Color(red: 0.04, green: 0.52, blue: 1.0)
    static let gray900 = Color(red: 0.11, green: 0.11, blue: 0.12)
}
enum Spacing { static let sm: CGFloat = 8; static let md: CGFloat = 16 }
enum Radius  { static let md: CGFloat = 12 }
```

**Semantic tokens** — express *intent*, point at raw values. Everything in Levels 2 and 3 references only these. Theming (dark mode, a second brand, high-contrast) = remapping this layer in one place; nothing above changes.

```swift
struct AeroTheme {
    let accent: Color
    let textPrimary: Color
    let surface: Color
    static let light = AeroTheme(accent: RawColor.blue500,
                                 textPrimary: RawColor.gray900,
                                 surface: .white)
}
```

Inject the theme via `@Environment` so runtime theming and Xcode previews work, and any subtree can override it:

```swift
extension EnvironmentValues {
    @Entry var aeroTheme: AeroTheme = .light   // iOS 18+ @Entry macro; pre-18, write a manual EnvironmentKey
}
```

---

## Level 2 — Styles

Apply tokens to the controls SwiftUI already ships. Use the framework's own style protocols — your "styles for controls" map almost 1:1:

| Control | Protocol |
|---|---|
| Button | `ButtonStyle` / `PrimitiveButtonStyle` |
| Toggle | `ToggleStyle` |
| Label | `LabelStyle` |
| TextField | `TextFieldStyle` |
| ProgressView | `ProgressViewStyle` |
| Menu | `MenuStyle` |
| List | `ListStyle` |
| GroupBox | `GroupBoxStyle` |

**Text is the exception** — there is no `TextStyle` protocol (`Font.TextStyle` is unrelated; it's Dynamic Type). Text styles are custom `ViewModifier`s.

Register each style as a static extension so it reads idiomatically — `.buttonStyle(.primary)` instead of `.buttonStyle(PrimaryButtonStyle())`:

```swift
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.aeroTheme) private var theme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(theme.accent)            // semantic token, not a raw hex
            .clipShape(.rect(cornerRadius: Radius.md))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { .init() }
}
```

---

## Level 3 — Components

Custom views composed from styled Level-2 pieces and Level-1 tokens — things SwiftUI doesn't ship (cards, banners, list rows with multiple elements). **No raw values or magic numbers inside.** If a component needs one, that's a missing token or a missing style.

```swift
struct AeroCard<Content: View>: View {
    @Environment(\.aeroTheme) private var theme
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) { content }
            .padding(Spacing.md)
            .background(theme.surface)
            .clipShape(.rect(cornerRadius: Radius.md))
    }
}
```

---

## Naming convention

Two orthogonal axes — keep them separate:

- **Brand prefix → types.** `AeroColor`, `AeroButtonStyle`, `AeroCard`. Avoids collisions with SwiftUI's own `Button` and any generic `Card`.
- **Level names → folders / modules.** `Tokens/`, `Styles/`, `Components/`.

```
DesignSystem/
├── Tokens/
│   ├── RawColor.swift, Spacing.swift, Radius.swift   // raw sublayer
│   └── AeroTheme.swift                               // semantic sublayer + Environment
├── Styles/
│   ├── PrimaryButtonStyle.swift
│   └── TitleTextModifier.swift
└── Components/
    └── AeroCard.swift
```

---

## Checklist when adding anything new

1. Is it a value that can't be broken down? → **Token.** Add raw, then expose a semantic name if it carries intent.
2. Is it styling for a control SwiftUI already ships? → **Style.** Use the matching protocol; register dot-syntax.
3. Is it a custom view made of smaller pieces? → **Component.** Build from styles + semantic tokens only.
4. Did you write a hex value or a number above Level 1? → stop; you're missing a token or a style.

import SwiftUI

/// Text rendered with a semantic style — the first place colors and fonts are
/// *composed*. A style maps to both a font (from `DSFont`) and a default color
/// (from `DSColors`), so callers express intent ("this is a headline") instead
/// of picking a size and color by hand.
public struct DSText: View {

    public enum Style {
        case largeTitle, title, headline, body, callout, caption
    }

    private let text: String
    private let style: Style
    private let colorOverride: Color?

    public init(_ text: String, style: Style = .body, color: Color? = nil) {
        self.text = text
        self.style = style
        self.colorOverride = color
    }

    public var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(colorOverride ?? defaultColor)
    }

    private var font: Font {
        switch style {
        case .largeTitle: return DSFont.largeTitle
        case .title:      return DSFont.title
        case .headline:   return DSFont.headline
        case .body:       return DSFont.body
        case .callout:    return DSFont.callout
        case .caption:    return DSFont.caption
        }
    }

    private var defaultColor: Color {
        switch style {
        case .largeTitle, .title, .headline, .body:
            return DSColors.textPrimary
        case .callout:
            return DSColors.textSecondary
        case .caption:
            return DSColors.textTertiary
        }
    }
}

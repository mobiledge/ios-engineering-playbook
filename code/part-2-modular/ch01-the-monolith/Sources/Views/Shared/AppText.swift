import SwiftUI

/// Text rendered with a semantic style — the first place fonts and colors are
/// *composed* into a reusable component. A style maps to both a font (from
/// `AppFont`) and a sensible default color (from `AppColors`), so callers
/// express intent ("this is a headline") instead of picking a size and color by
/// hand. Pass `color:` to override the default when needed.
struct AppText: View {

    enum Style {
        case largeTitle, title, headline, body, callout, caption
    }

    private let text: String
    private let style: Style
    private let colorOverride: Color?

    init(_ text: String, style: Style = .body, color: Color? = nil) {
        self.text = text
        self.style = style
        self.colorOverride = color
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(colorOverride ?? defaultColor)
    }

    private var font: Font {
        switch style {
        case .largeTitle: return AppFont.largeTitle
        case .title:      return AppFont.title
        case .headline:   return AppFont.headline
        case .body:       return AppFont.body
        case .callout:    return AppFont.callout
        case .caption:    return AppFont.caption
        }
    }

    private var defaultColor: Color {
        switch style {
        case .largeTitle, .title, .headline, .body:
            return AppColor.textPrimary
        case .callout:
            return AppColor.textSecondary
        case .caption:
            return AppColor.textTertiary
        }
    }
}

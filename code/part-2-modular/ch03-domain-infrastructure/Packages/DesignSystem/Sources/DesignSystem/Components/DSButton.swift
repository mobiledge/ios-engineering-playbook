import SwiftUI

/// The branded call-to-action button. Composes brand color + typography +
/// radius tokens, and offers a couple of visual variants.
public struct DSButton: View {

    public enum Style {
        case primary    // filled brand
        case secondary  // outlined brand
    }

    private let title: String
    private let systemImage: String?
    private let style: Style
    private let action: () -> Void

    public init(
        _ title: String,
        systemImage: String? = nil,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title).font(DSFont.callout)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.md)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch style {
        case .primary:   return DSColors.onBrand
        case .secondary: return DSColors.brand
        }
    }

    private var background: Color {
        switch style {
        case .primary:   return DSColors.brand
        case .secondary: return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:   return .clear
        case .secondary: return DSColors.brand
        }
    }
}

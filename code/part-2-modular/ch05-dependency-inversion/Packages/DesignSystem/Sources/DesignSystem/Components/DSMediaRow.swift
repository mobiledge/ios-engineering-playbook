import SwiftUI

/// A standard list row for a piece of media: artwork on the left, a title /
/// subtitle / caption stack in the middle, and an optional trailing accessory
/// (e.g. a save button). This is the highest-level component in the library and
/// shows the payoff of composition — it is built entirely from `DSArtwork`,
/// `DSText`, and the spacing tokens, so every media list in the app looks
/// identical for free.
public struct DSMediaRow<Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let caption: String?
    private let artworkURL: URL?
    private let trailing: Trailing

    public init(
        title: String,
        subtitle: String? = nil,
        caption: String? = nil,
        artworkURL: URL?,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.caption = caption
        self.artworkURL = artworkURL
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: DSSpacing.md) {
            DSArtwork(url: artworkURL)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                DSText(title, style: .headline).lineLimit(1)
                if let subtitle {
                    DSText(subtitle, style: .callout).lineLimit(1)
                }
                if let caption {
                    DSText(caption, style: .caption)
                }
            }

            Spacer(minLength: DSSpacing.sm)

            trailing
        }
        .padding(.vertical, DSSpacing.xs)
    }
}

/// Convenience initializer for rows with no trailing accessory.
public extension DSMediaRow where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, caption: String? = nil, artworkURL: URL?) {
        self.init(
            title: title,
            subtitle: subtitle,
            caption: caption,
            artworkURL: artworkURL,
            trailing: { EmptyView() }
        )
    }
}

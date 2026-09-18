import SwiftUI
import Domain
import DesignSystem

/// A minimal fallback detail for media types without their own feature
/// detail screen (Music and Audiobooks don't have one yet). Lives in the
/// composition root because it is glue, not a feature.
struct SavedItemDetailView: View {
    let item: SavedItem

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            DSArtwork(url: item.artworkURL, size: 140)
            DSText(item.title, style: .title)
            if let subtitle = item.subtitle {
                DSText(subtitle, style: .callout)
            }
            DSTag(item.mediaType.rawValue.capitalized)
        }
        .padding(DSSpacing.lg)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

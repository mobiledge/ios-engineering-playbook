import SwiftUI

/// A single row in the podcasts list. Deliberately parallel to `TrackRow` in the
/// Music feature: pure presentation of a `Podcast`, with nothing to save.
struct PodcastRow: View {
    let podcast: Podcast

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ArtworkView(url: podcast.artworkUrl100)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(podcast.collectionName)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                Text(podcast.artistName)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                if let releaseDate = podcast.releaseDate {
                    Text(releaseDate.mediumString)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textTertiary)
                }
            }

            Spacer(minLength: AppSpacing.sm)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

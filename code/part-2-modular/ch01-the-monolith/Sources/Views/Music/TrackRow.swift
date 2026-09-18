import SwiftUI

/// A single row in the music list.
///
/// The row is pure presentation: it takes a `Track` and draws it. There is no
/// persistence and nothing to toggle — the app simply shows what the network
/// returned.
struct TrackRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ArtworkView(url: track.artworkUrl100)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(track.trackName)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                if let releaseDate = track.releaseDate {
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

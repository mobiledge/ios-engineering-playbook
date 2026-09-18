import SwiftUI
import DesignSystem
import Domain

/// Presentational only — it is handed everything it needs (the track,
/// whether it's saved, and a toggle closure). It cannot perform business
/// logic because `MusicSearchUI` has no access to any repository: it never
/// links `MusicSearchLogic`, so there is nothing to call.
struct TrackRow: View {
    let track: Track
    let isSaved: Bool
    let onToggleSave: () -> Void

    var body: some View {
        DSMediaRow(
            title: track.name,
            subtitle: track.artist,
            caption: track.releaseDate?.mediumString,
            artworkURL: track.artworkURL
        ) {
            Button(action: onToggleSave) {
                Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundStyle(DSColors.brand)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
    }
}

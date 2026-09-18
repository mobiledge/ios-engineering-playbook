import SwiftUI
import DesignSystem
import Domain
import Infrastructure

/// A single row in the music list.
///
/// The whole row is a `DSMediaRow` from the design system, plus a
/// save-to-Library affordance. The row talks to the domain's
/// `LibraryUseCase` — which owns the "don't save duplicates" rule — never
/// directly to Core Data.
struct TrackRow: View {
    let track: Track

    private let library = LibraryUseCase(repository: CoreDataLibraryRepository())
    @State private var isSaved = false

    var body: some View {
        DSMediaRow(
            title: track.name,
            subtitle: track.artist,
            caption: track.releaseDate?.mediumString,
            artworkURL: track.artworkURL
        ) {
            Button(action: toggleSave) {
                Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundStyle(DSColors.brand)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            isSaved = library.isSaved(id: track.id, mediaType: .music)
        }
    }

    private func toggleSave() {
        if isSaved {
            library.remove(id: track.id, mediaType: .music)
        } else {
            library.save(
                SavedItem(
                    id: track.id,
                    title: track.name,
                    subtitle: track.artist,
                    artworkURL: track.artworkURL,
                    mediaType: .music,
                    savedAt: Date()
                )
            )
        }
        isSaved.toggle()
    }
}

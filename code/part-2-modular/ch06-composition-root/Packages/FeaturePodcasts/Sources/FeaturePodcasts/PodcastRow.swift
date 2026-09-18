import SwiftUI
import DesignSystem
import Domain

/// A single row in the podcasts list. Deliberately parallel to `TrackRow`,
/// including the save-to-Library affordance: the whole row is one
/// `DSMediaRow`, and the row talks to the domain's `LibraryUseCase` rather
/// than Core Data directly. The concrete `LibraryRepository` is injected from
/// the caller instead of constructed here, since this package can no longer
/// import `Infrastructure`.
struct PodcastRow: View {
    let podcast: Podcast
    let libraryRepository: LibraryRepository

    private var library: LibraryUseCase { LibraryUseCase(repository: libraryRepository) }
    @State private var isSaved = false

    var body: some View {
        DSMediaRow(
            title: podcast.name,
            subtitle: podcast.artist,
            caption: podcast.releaseDate?.mediumString,
            artworkURL: podcast.artworkURL
        ) {
            Button(action: toggleSave) {
                Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundStyle(DSColors.brand)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            isSaved = library.isSaved(id: podcast.id, mediaType: .podcast)
        }
    }

    private func toggleSave() {
        if isSaved {
            library.remove(id: podcast.id, mediaType: .podcast)
        } else {
            library.save(
                SavedItem(
                    id: podcast.id,
                    title: podcast.name,
                    subtitle: podcast.artist,
                    artworkURL: podcast.artworkURL,
                    mediaType: .podcast,
                    savedAt: Date()
                )
            )
        }
        isSaved.toggle()
    }
}

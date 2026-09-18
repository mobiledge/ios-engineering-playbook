import SwiftUI
import DesignSystem
import Domain
import Infrastructure

/// A single row in the podcasts list. Deliberately parallel to `TrackRow`,
/// including the save-to-Library affordance: the whole row is one
/// `DSMediaRow`, and the row talks to the domain's `LibraryUseCase` rather
/// than Core Data directly.
struct PodcastRow: View {
    let podcast: Podcast

    private let library = LibraryUseCase(repository: CoreDataLibraryRepository())
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

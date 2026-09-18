import SwiftUI
import DesignSystem
import Domain

/// A single row in the audiobooks list. Deliberately parallel to `TrackRow`:
/// the whole row is one `DSMediaRow`, with a save-to-Library affordance that
/// talks to the domain's `LibraryUseCase` rather than Core Data directly. The
/// concrete `LibraryRepository` is injected from the caller — this package
/// can't import `Infrastructure`.
struct AudiobookRow: View {
    let audiobook: Audiobook
    let libraryRepository: LibraryRepository

    private var library: LibraryUseCase { LibraryUseCase(repository: libraryRepository) }
    @State private var isSaved = false

    var body: some View {
        DSMediaRow(
            title: audiobook.title,
            subtitle: audiobook.author,
            caption: audiobook.releaseDate?.mediumString,
            artworkURL: audiobook.artworkURL
        ) {
            Button(action: toggleSave) {
                Image(systemName: isSaved ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundStyle(DSColors.brand)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            isSaved = library.isSaved(id: audiobook.id, mediaType: .audiobook)
        }
    }

    private func toggleSave() {
        if isSaved {
            library.remove(id: audiobook.id, mediaType: .audiobook)
        } else {
            library.save(
                SavedItem(
                    id: audiobook.id,
                    title: audiobook.title,
                    subtitle: audiobook.author,
                    artworkURL: audiobook.artworkURL,
                    mediaType: .audiobook,
                    savedAt: Date()
                )
            )
        }
        isSaved.toggle()
    }
}

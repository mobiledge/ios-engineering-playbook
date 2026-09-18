import SwiftUI
import Domain

/// Searches the iTunes catalog for audiobooks and lists the results.
///
/// This is this chapter's proof: built from the same template as every
/// feature package since Chapter 5 — Domain's abstractions injected via the
/// initializer, zero knowledge of the iTunes API or Core Data, no
/// `Infrastructure` import. One dev wired this screen, `AppFactory`'s
/// `makeAudiobooks()`, and a `RootView` tab line in about a day.
public struct AudiobooksScreen: View {
    @State private var term = "Stephen King"
    @State private var audiobooks: [Audiobook] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let search: SearchMediaUseCase
    private let libraryRepository: LibraryRepository

    public init(searchRepository: MediaSearchRepository, libraryRepository: LibraryRepository) {
        self.search = SearchMediaUseCase(repository: searchRepository)
        self.libraryRepository = libraryRepository
    }

    public var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                ForEach(audiobooks) { audiobook in
                    AudiobookRow(audiobook: audiobook, libraryRepository: libraryRepository)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Audiobooks")
            .searchable(text: $term, prompt: "Search audiobooks")
            .onSubmit(of: .search) { Task { await runSearch() } }
            .overlay { if isLoading { ProgressView() } }
            .task { await runSearch() }
        }
    }

    private func runSearch() async {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            audiobooks = try await search.audiobooks(matching: term)
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

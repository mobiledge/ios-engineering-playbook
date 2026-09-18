import SwiftUI
import Domain

/// Searches the iTunes catalog for podcasts and lists the results.
///
/// This mirrors `MusicSearchScreen` exactly: search, fetch, list. No detail
/// screen — just present what the network returned. It goes through the
/// domain's `SearchMediaUseCase`. Unlike Chapter 4, it no longer constructs
/// `ITunesSearchRepository` or `LocalFeatureFlags` itself — this package can
/// no longer import `Infrastructure`. Both are injected via the initializer;
/// the app target builds the concretes ad hoc (Chapter 6 injects it from a
/// composition root). Podcasts is in maintenance mode this chapter — the
/// smallest feature package, and the last of the three squads to get one.
public struct PodcastsScreen: View {
    @State private var term = "The Daily"
    @State private var podcasts: [Podcast] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let search: SearchMediaUseCase
    private let libraryRepository: LibraryRepository
    private let flags: FeatureFlagProvider

    public init(
        searchRepository: MediaSearchRepository,
        libraryRepository: LibraryRepository,
        flags: FeatureFlagProvider
    ) {
        self.search = SearchMediaUseCase(repository: searchRepository)
        self.libraryRepository = libraryRepository
        self.flags = flags
    }

    public var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                ForEach(podcasts) { podcast in
                    PodcastRow(podcast: podcast, libraryRepository: libraryRepository)
                }
            }
            .listStyle(.plain)
            .navigationTitle(flags.isEnabled(.newPodcastUI) ? "Podcasts ✨" : "Podcasts")
            .searchable(text: $term, prompt: "Search podcasts")
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
            podcasts = try await search.podcasts(matching: term)
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

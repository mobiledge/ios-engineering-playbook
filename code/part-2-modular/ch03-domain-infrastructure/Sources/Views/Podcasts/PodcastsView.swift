import SwiftUI
import Domain
import Infrastructure

/// Searches the iTunes catalog for podcasts and lists the results.
///
/// This mirrors `MusicSearchView` exactly: search, fetch, list. No detail
/// screen — just present what the network returned. As of this chapter it
/// no longer talks to `iTunesAPIClient` directly; it goes through the domain's
/// `SearchMediaUseCase`, backed by the concrete `ITunesSearchRepository`
/// constructed inline for now — Chapter 6 injects it from a composition root.
struct PodcastsView: View {
    @State private var term = "The Daily"
    @State private var podcasts: [Podcast] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let search = SearchMediaUseCase(repository: ITunesSearchRepository())

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                ForEach(podcasts) { podcast in
                    PodcastRow(podcast: podcast)
                }
            }
            .listStyle(.plain)
            // MONOLITH NOTE: a remote feature flag toggles new UI. The view asks
            // the global flag provider directly; in Debug builds MOCK_SERVICES
            // turns `newPodcastUI` on so we can see the in-progress design.
            .navigationTitle(Services.flags.isEnabled(.newPodcastUI) ? "Podcasts ✨" : "Podcasts")
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

import SwiftUI

/// Searches the iTunes catalog for podcasts and lists the results.
///
/// This mirrors `MusicSearchView` exactly: search, fetch, list. No detail
/// screen, no persistence — just present what the network returned.
///
/// MONOLITH NOTE: like the Music feature, this view holds a direct reference to
/// the concrete `iTunesAPIClient.shared`. There is no injected dependency and no
/// protocol, so Podcasts cannot be compiled or tested without the networking code.
struct PodcastsView: View {
    @State private var term = "The Daily"
    @State private var podcasts: [Podcast] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let api = iTunesAPIClient.shared

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
            .onSubmit(of: .search) { Task { await search() } }
            .overlay { if isLoading { ProgressView() } }
            .task { await search() }
        }
    }

    private func search() async {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            podcasts = try await api.searchPodcasts(term: term)
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

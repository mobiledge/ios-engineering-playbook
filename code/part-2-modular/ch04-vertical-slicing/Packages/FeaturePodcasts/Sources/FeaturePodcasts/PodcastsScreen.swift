import SwiftUI
import Domain
import Infrastructure

/// Searches the iTunes catalog for podcasts and lists the results.
///
/// This mirrors `MusicSearchScreen` exactly: search, fetch, list. No detail
/// screen — just present what the network returned. It goes through the
/// domain's `SearchMediaUseCase`, backed by the concrete
/// `ITunesSearchRepository` constructed inline for now — Chapter 6 injects it
/// from a composition root.
///
/// Renamed from `PodcastsView` to `PodcastsScreen` at extraction, following
/// the `<Feature>Screen` convention every feature package uses from this
/// chapter on. Podcasts is in maintenance mode this chapter — the smallest
/// feature package, and the last of the three squads to get one.
public struct PodcastsScreen: View {
    @State private var term = "The Daily"
    @State private var podcasts: [Podcast] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let search = SearchMediaUseCase(repository: ITunesSearchRepository())

    // A feature package can't reach the app target's `Services` facade — a
    // Swift package can't depend on the app executable that hosts it. So the
    // remote feature flag lookup that used to go through `Services.flags`
    // constructs its `Infrastructure` type inline instead, exactly like
    // `search` already did.
    private let flags: FeatureFlagProvider = {
        #if MOCK_SERVICES
        return LocalFeatureFlags([.newPodcastUI: true])
        #else
        return LocalFeatureFlags()
        #endif
    }()

    public init() {}

    public var body: some View {
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

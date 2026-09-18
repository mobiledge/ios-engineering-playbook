import SwiftUI
import Domain
import Infrastructure

/// Searches the iTunes catalog for music and lists the results.
///
/// The view no longer knows anything about networking. It talks to a domain
/// `SearchMediaUseCase`, which in turn uses a `MediaSearchRepository`. For now
/// we construct the concrete `ITunesSearchRepository` inline — Chapter 6 will
/// inject it from a single composition root.
struct MusicSearchView: View {
    @State private var term = "Jack Johnson"
    @State private var tracks: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let search = SearchMediaUseCase(repository: ITunesSearchRepository())

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                ForEach(tracks) { track in
                    TrackRow(track: track)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Music")
            .searchable(text: $term, prompt: "Search songs")
            .onSubmit(of: .search) { Task { await runSearch() } }
            .overlay { if isLoading { ProgressView() } }
            .task { await runSearch() }
        }
    }

    private func runSearch() async {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        // MONOLITH NOTE: the view reaches straight for the global telemetry
        // facade — convenient now, but it means this Music feature can't be
        // tested without dragging analytics and crash reporting along too.
        Services.analytics.track(AnalyticsEvent("music_search", ["term": term]))
        do {
            tracks = try await search.music(matching: term)
        } catch {
            Services.crashReporter.record(error, context: ["feature": "music_search"])
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

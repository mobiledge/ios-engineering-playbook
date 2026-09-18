import SwiftUI

/// Searches the iTunes catalog for music and lists the results.
///
/// MONOLITH NOTE: the view holds a direct reference to the concrete
/// `iTunesAPIClient.shared`. There is no injected dependency and no protocol,
/// so this Music feature cannot be compiled or tested without the networking code.
struct MusicSearchView: View {
    @State private var term = "Jack Johnson"
    @State private var tracks: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let api = iTunesAPIClient.shared

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
            .onSubmit(of: .search) { Task { await search() } }
            .overlay { if isLoading { ProgressView() } }
            .task { await search() }
        }
    }

    private func search() async {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        // MONOLITH NOTE: the view reaches straight for the global telemetry
        // facade — convenient now, but it means this Music feature can't be
        // tested without dragging analytics and crash reporting along too.
        Services.analytics.track(AnalyticsEvent("music_search", ["term": term]))
        do {
            tracks = try await api.searchMusic(term: term)
        } catch {
            Services.crashReporter.record(error, context: ["feature": "music_search"])
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

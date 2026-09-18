import SwiftUI
import Domain
import Infrastructure

/// Searches the iTunes catalog for music and lists the results.
///
/// The view still knows nothing about networking: it talks to a domain
/// `SearchMediaUseCase`, which in turn uses a `MediaSearchRepository`. We
/// still construct the concrete `ITunesSearchRepository` inline — Chapter 6
/// will inject it from a single composition root.
///
/// Renamed from `MusicSearchView` to `MusicSearchScreen` at extraction: every
/// feature package's public entry point follows the `<Feature>Screen`
/// convention from this chapter on.
public struct MusicSearchScreen: View {
    @State private var term = "Jack Johnson"
    @State private var tracks: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let search = SearchMediaUseCase(repository: ITunesSearchRepository())

    // A feature package can't reach the app target's `Services` facade — a
    // Swift package can't depend on the app executable that hosts it. So the
    // observability calls that used to go through `Services.analytics` and
    // `Services.crashReporter` now construct their `Infrastructure` types
    // inline, exactly like `search` already did.
    private let analytics: AnalyticsTracker = ConsoleAnalytics()
    private let crashReporter: CrashReporter = ConsoleCrashReporter()

    public init() {}

    public var body: some View {
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
        analytics.track(AnalyticsEvent("music_search", ["term": term]))
        do {
            tracks = try await search.music(matching: term)
        } catch {
            crashReporter.record(error, context: ["feature": "music_search"])
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

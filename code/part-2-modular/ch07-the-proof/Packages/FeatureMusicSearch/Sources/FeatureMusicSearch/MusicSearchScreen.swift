import SwiftUI
import Domain

/// Searches the iTunes catalog for music and lists the results.
///
/// The view still knows nothing about networking: it talks to a domain
/// `SearchMediaUseCase`, which in turn uses a `MediaSearchRepository`. Unlike
/// Chapter 4, it no longer constructs `ITunesSearchRepository` (or
/// `ConsoleAnalytics`/`ConsoleCrashReporter`) itself — a feature package
/// can't import `Infrastructure` anymore. Every one of those is injected via
/// the initializer instead; the app target builds the concretes and passes
/// them in ad hoc (Chapter 6 formalizes that wiring into a composition root).
public struct MusicSearchScreen: View {
    @State private var term = "Jack Johnson"
    @State private var tracks: [Track] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let search: SearchMediaUseCase
    private let libraryRepository: LibraryRepository
    private let analytics: AnalyticsTracker
    private let crashReporter: CrashReporter

    public init(
        searchRepository: MediaSearchRepository,
        libraryRepository: LibraryRepository,
        analytics: AnalyticsTracker,
        crashReporter: CrashReporter
    ) {
        self.search = SearchMediaUseCase(repository: searchRepository)
        self.libraryRepository = libraryRepository
        self.analytics = analytics
        self.crashReporter = crashReporter
    }

    public var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                ForEach(tracks) { track in
                    TrackRow(track: track, libraryRepository: libraryRepository)
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

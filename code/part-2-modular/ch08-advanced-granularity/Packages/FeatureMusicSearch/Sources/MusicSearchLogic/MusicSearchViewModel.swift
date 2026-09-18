import Foundation
import Combine
import Domain
import MusicSearchInterface

/// Pure logic: it conforms to `MusicSearchInterface`'s view-model contract
/// and depends only on injected Domain use cases and service contracts. It
/// imports no SwiftUI and can be unit-tested without compiling a single view
/// — a UI-only PR in `MusicSearchUI` never recompiles, let alone re-runs,
/// this target's tests.
@MainActor
public final class MusicSearchViewModel: MusicSearchViewModeling {
    @Published public var query: String
    @Published public private(set) var tracks: [Track] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let searchUseCase: SearchMediaUseCase
    private let library: LibraryUseCase
    private let analytics: AnalyticsTracker
    private let crashReporter: CrashReporter

    public init(
        query: String = "Jack Johnson",
        searchRepository: MediaSearchRepository,
        libraryRepository: LibraryRepository,
        analytics: AnalyticsTracker,
        crashReporter: CrashReporter
    ) {
        self.query = query
        self.searchUseCase = SearchMediaUseCase(repository: searchRepository)
        self.library = LibraryUseCase(repository: libraryRepository)
        self.analytics = analytics
        self.crashReporter = crashReporter
    }

    public func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        analytics.track(AnalyticsEvent("music_search", ["term": query]))
        do {
            tracks = try await searchUseCase.music(matching: query)
        } catch {
            crashReporter.record(error, context: ["feature": "music_search"])
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }

    public func isSaved(_ track: Track) -> Bool {
        library.isSaved(id: track.id, mediaType: .music)
    }

    public func toggleSave(_ track: Track) {
        if isSaved(track) {
            library.remove(id: track.id, mediaType: .music)
        } else {
            library.save(
                SavedItem(
                    id: track.id,
                    title: track.name,
                    subtitle: track.artist,
                    artworkURL: track.artworkURL,
                    mediaType: .music,
                    savedAt: Date()
                )
            )
        }
        // `isSaved` is computed from the store, so nudge observers to re-read it.
        objectWillChange.send()
    }
}

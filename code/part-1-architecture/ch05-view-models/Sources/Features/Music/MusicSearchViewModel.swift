import Foundation
import Observation

/// The music search screen's state and behaviour, with no SwiftUI in it.
///
/// It owns the query and exactly one `ViewState`, fetches through the `SearchClient`
/// it's handed, and turns tracks into rows ready to draw. `MusicSearchView` renders
/// `state` and forwards what the user does; it decides nothing.
@Observable
@MainActor
final class MusicSearchViewModel {
    /// Everything the screen can show. One value at a time, so "loading *and* failed"
    /// or "failed over old results" can't be represented.
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([TrackRowModel])
        case empty(term: String)
        case failed(message: String)
    }

    var query = "" {
        didSet {
            if query.isEmpty { state = .idle }
        }
    }

    private(set) var state: ViewState

    private let client: any SearchClient

    /// - Parameter state: where the screen starts. Previews pass one; the app uses `.idle`.
    init(client: any SearchClient, state: ViewState = .idle) {
        self.client = client
        self.state = state
    }

    func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }

        print("searching for \(term)")
        state = .loading

        do {
            let tracks = try await client.searchSongs(matching: term)
            print("got \(tracks.count) results")
            state = tracks.isEmpty ? .empty(term: term) : .loaded(tracks.map(TrackRowModel.init(track:)))
        } catch {
            print("search error: \(error)")
            state = .failed(message: error.localizedDescription)
        }
    }
}

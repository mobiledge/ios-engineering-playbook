import SwiftUI

/// The music search screen. Renders its view model's one `state` and forwards what the
/// user does — searching, retrying, tapping a song. Each result is drawn by `TrackRow`.
struct MusicSearchView: View {
    @Bindable var viewModel: MusicSearchViewModel

    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Medley")
                .searchable(text: $viewModel.query, prompt: "Songs, artists, albums")
                .onSubmit(of: .search) {
                    Task { await viewModel.search() }
                }
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Search for a Song", systemImage: "music.note",
                                   description: Text("Try an artist, an album, or a song title."))
        case .loading:
            ProgressView()
        case .loaded(let rows):
            List(rows) { row in
                Button {
                    if let url = row.link {
                        print("opening \(url)")
                        openURL(url)
                    }
                } label: {
                    TrackRow(row: row)
                }
                .tint(.primary)
            }
        case .empty(let term):
            ContentUnavailableView.search(text: term)
        case .failed(let message):
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.search() }
                }
            }
        }
    }
}

// MARK: - Previews: every state, no network

#Preview("Idle") {
    MusicSearchView(viewModel: .preview(.idle))
}

#Preview("Loading") {
    MusicSearchView(viewModel: .preview(.loading))
}

#Preview("Loaded") {
    MusicSearchView(viewModel: .preview(.loaded([.letDown, .nightZombies, .bare])))
}

#Preview("Empty") {
    MusicSearchView(viewModel: .preview(.empty(term: "zzzzqqq")))
}

#Preview("Failed") {
    MusicSearchView(viewModel: .preview(.failed(message: SearchError.offline.localizedDescription)))
}

private extension MusicSearchViewModel {
    /// A view model parked in `state`. Its client is real but never called unless you search.
    static func preview(_ state: ViewState) -> MusicSearchViewModel {
        MusicSearchViewModel(client: MedleyApp.makeSearchClient(), state: state)
    }
}

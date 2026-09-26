import SwiftUI

/// The music search screen: owns the query, the results, and the search itself,
/// and opens a tapped song in Apple Music. Each result is drawn by `TrackRow`.
struct MusicSearchView: View {
    let client: any SearchClient

    @State private var query = ""
    @State private var results: [Track] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasResults = false
    @State private var hasSearched = false

    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List(results) { track in
                Button {
                    if let url = track.trackViewUrl {
                        print("opening \(url)")
                        openURL(url)
                    }
                } label: {
                    TrackRow(track: track)
                }
                .tint(.primary)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
                if showError {
                    ContentUnavailableView {
                        Label("Something Went Wrong", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") {
                            Task { await search() }
                        }
                    }
                } else if !hasSearched {
                    ContentUnavailableView("Search for a Song", systemImage: "music.note",
                                           description: Text("Try an artist, an album, or a song title."))
                } else if !hasResults && !isLoading {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("Medley")
            .searchable(text: $query, prompt: "Songs, artists, albums")
            .onSubmit(of: .search) {
                Task { await search() }
            }
        }
    }

    private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }

        print("searching for \(term)")
        isLoading = true
        hasSearched = true

        do {
            let tracks = try await client.searchSongs(matching: term)
            print("got \(tracks.count) results")

            results = tracks
            hasResults = !tracks.isEmpty
            showError = false
            isLoading = false
        } catch {
            print("search error: \(error)")
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}

/// The whole screen, against the live catalog: it starts idle, and needs a real search
/// to show a row. For rows in every state, see `TrackRow`'s previews.
#Preview {
    MusicSearchView(client: MedleyApp.makeSearchClient())
}

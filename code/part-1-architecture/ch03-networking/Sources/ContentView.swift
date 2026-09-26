import SwiftUI

/// The whole app: search the iTunes catalog for songs and open one in Apple Music.
///
/// It searches through the `SearchClient` it's handed; everything else still lives in this view.
struct ContentView: View {
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
                    HStack(spacing: 12) {
                        AsyncImage(url: track.artworkUrl100) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(.rect(cornerRadius: 6))

                        VStack(alignment: .leading) {
                            Text(track.trackName)
                                .font(.headline)
                            Group {
                                Text(track.artistName)
                                if let album = track.collectionName {
                                    Text(album)
                                }
                                if let released = track.releaseDate {
                                    // Releases are stamped at midnight Pacific. Read the year in UTC,
                                    // or a New Year's Day release shows last year in Hawaii.
                                    Text(released, format: Date.FormatStyle(timeZone: .gmt).year())
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .lineLimit(1)

                        Spacer()

                        if let millis = track.trackTimeMillis {
                            Text("\(millis / 60_000):\(String(format: "%02d", millis / 1000 % 60))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
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

#Preview {
    ContentView(client: MedleyApp.makeSearchClient())
}

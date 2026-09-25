import SwiftUI

/// The whole app: search the iTunes catalog for songs and open one in Apple Music.
///
/// Everything it takes lives in this one view — and at this size, that's the right call.
struct ContentView: View {
    @State private var query = ""
    @State private var results: [[String: Any]] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasResults = false
    @State private var hasSearched = false

    @Environment(\.openURL) private var openURL

    /// Flip to `true` once we're happy showing explicit tracks in search.
    private let allowsExplicitResults = false

    var body: some View {
        NavigationStack {
            List(results.indices, id: \.self) { index in
                let item = results[index]
                Button {
                    if let link = item["trackViewUrl"] as? String, let url = URL(string: link) {
                        print("opening \(link)")
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: item["artworkUrl100"] as! String)) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(.rect(cornerRadius: 6))

                        VStack(alignment: .leading) {
                            Text(item["trackName"] as? String ?? "Untitled")
                                .font(.headline)
                            Group {
                                Text(item["artistName"] as? String ?? "Unknown artist")
                                if let released = item["releaseDate"] as? String {
                                    Text(released.prefix(4))
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .lineLimit(1)

                        Spacer()

                        if let millis = item["trackTimeMillis"] as? Int {
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

        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "explicit", value: allowsExplicitResults ? "Yes" : "No"),
        ]

        do {
            let (data, response) = try await URLSession.shared.data(from: components.url!)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                print("search failed with status \(http.statusCode)")
                errorMessage = "The music catalog is unavailable right now (HTTP \(http.statusCode))."
                showError = true
                isLoading = false
                return
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let items = json?["results"] as? [[String: Any]] ?? []
            print("got \(items.count) results")

            results = items
            hasResults = !items.isEmpty
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
    ContentView()
}

import SwiftUI
import DesignSystem
import Domain

/// Searches the iTunes catalog for movies and lists the results.
///
/// Movies is the first feature *born* as a package — it never lived in the
/// monolith or in an app-target view. Its dependencies are injected as
/// domain protocols from day one: it has no idea the iTunes API or Core Data
/// exist. The app target supplies the concrete implementations inline for
/// now (Chapter 6 gives that wiring a proper home).
///
/// `FeatureMovies` owns its own detail screen (`MovieDetailScreen`) —
/// "MovieDetail" is never a standalone module.
public struct MoviesScreen: View {
    @State private var term = "Star Wars"
    @State private var movies: [Movie] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let search: SearchMediaUseCase
    private let libraryRepository: LibraryRepository

    public init(searchRepository: MediaSearchRepository, libraryRepository: LibraryRepository) {
        self.search = SearchMediaUseCase(repository: searchRepository)
        self.libraryRepository = libraryRepository
    }

    public var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                ForEach(movies) { movie in
                    NavigationLink(value: movie) {
                        MovieRow(movie: movie)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Movies")
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailScreen(movie: movie, libraryRepository: libraryRepository)
            }
            .searchable(text: $term, prompt: "Search movies")
            .onSubmit(of: .search) { Task { await runSearch() } }
            .overlay { if isLoading { ProgressView() } }
            .task { await runSearch() }
        }
    }

    private func runSearch() async {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            movies = try await search.movies(matching: term)
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

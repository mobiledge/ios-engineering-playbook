import SwiftUI
import Domain
import AppInterfaces
import DesignSystem
import FeatureMovies

/// The app's implementation of `LibraryRouter`. Because the app target is
/// allowed to import every module, it can decide that a saved *movie* should
/// open FeatureMovies' `MovieDetailScreen` — while `FeatureLibrary` stays
/// oblivious to `FeatureMovies` entirely.
///
/// This is exactly the wiring the Chapter 5 cliffhanger complains about:
/// there is no composition root to give it a proper home yet, so it lives
/// ad hoc in the app target. Chapter 6 fixes that.
@MainActor
struct AppLibraryRouter: LibraryRouter {
    let libraryRepository: LibraryRepository

    func openSavedItem(_ item: SavedItem) -> AnyView {
        switch item.mediaType {
        case .movie:
            let movie = Movie(
                id: item.id,
                title: item.title,
                artist: item.subtitle ?? "",
                artworkURL: item.artworkURL
            )
            return AnyView(MovieDetailScreen(movie: movie, libraryRepository: libraryRepository))
        case .music, .podcast:
            return AnyView(SavedItemDetailView(item: item))
        }
    }
}

/// A minimal fallback detail for media types without their own feature
/// detail screen (Music and Podcasts don't have one yet).
private struct SavedItemDetailView: View {
    let item: SavedItem

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            DSArtwork(url: item.artworkURL, size: 140)
            DSText(item.title, style: .title)
            if let subtitle = item.subtitle {
                DSText(subtitle, style: .callout)
            }
            DSTag(item.mediaType.rawValue.capitalized)
        }
        .padding(DSSpacing.lg)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

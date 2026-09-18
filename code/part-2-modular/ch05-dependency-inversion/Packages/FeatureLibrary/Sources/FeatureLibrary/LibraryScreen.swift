import SwiftUI
import DesignSystem
import Domain
import AppInterfaces

/// Displays everything the user has saved locally, across Music, Podcasts,
/// and now Movies.
///
/// Renamed from `LibraryView` to `LibraryScreen` at extraction: every feature
/// package's public entry point follows the `<Feature>Screen` convention
/// from this chapter on. Library is injected with a `LibraryRepository`
/// (data) and a `LibraryRouter` (navigation): it can send the user to a
/// saved movie's detail screen without importing `FeatureMovies` — it just
/// asks the router for a destination.
public struct LibraryScreen: View {
    @StateObject private var model: LibraryViewModel
    private let router: LibraryRouter

    public init(libraryRepository: LibraryRepository, router: LibraryRouter) {
        _model = StateObject(wrappedValue: LibraryViewModel(library: LibraryUseCase(repository: libraryRepository)))
        self.router = router
    }

    public var body: some View {
        NavigationStack {
            Group {
                if model.items.isEmpty {
                    ContentUnavailableView(
                        "Your Library is Empty",
                        systemImage: "books.vertical",
                        description: Text("Save songs, podcasts, and movies to see them here.")
                    )
                } else {
                    List {
                        ForEach(model.items) { item in
                            NavigationLink {
                                router.openSavedItem(item)
                            } label: {
                                DSMediaRow(
                                    title: item.title,
                                    subtitle: item.subtitle,
                                    caption: item.mediaType.rawValue.capitalized,
                                    artworkURL: item.artworkURL
                                )
                            }
                        }
                        .onDelete(perform: model.delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                if !model.items.isEmpty { EditButton() }
            }
            .onAppear { model.reload() }
        }
    }
}

/// The view model depends on the domain's `LibraryUseCase` — which owns the
/// dedupe/sort business rules — rather than a repository directly. The
/// concrete Core Data implementation is now injected from the app target
/// instead of constructed here (this package can no longer import
/// `Infrastructure`); Chapter 6 will inject it from a composition root.
final class LibraryViewModel: ObservableObject {
    @Published var items: [SavedItem] = []

    private let library: LibraryUseCase

    init(library: LibraryUseCase) {
        self.library = library
    }

    func reload() {
        items = library.list()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            library.remove(id: item.id, mediaType: item.mediaType)
        }
        reload()
    }
}

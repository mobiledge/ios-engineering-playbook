import SwiftUI
import Domain
import Infrastructure
import AppInterfaces
import FeatureLibrary

/// `FeatureLibraryDemo`'s own composition root — proof that "exactly one
/// place builds the graph" scales down as well as up. It has one screen to
/// build and one dependency to satisfy, so a single static factory method is
/// enough; it doesn't need an `AppFactory`-sized type.
@MainActor
enum DemoCompositionRoot {
    static func makeLibraryScreen() -> some View {
        LibraryScreen(libraryRepository: CoreDataLibraryRepository(), router: PreviewRouter())
    }
}

/// The demo doesn't need real cross-feature navigation, so it stubs the
/// router — try swapping this for a fake that just prints, per this
/// chapter's exercise.
private struct PreviewRouter: LibraryRouter {
    func openSavedItem(_ item: SavedItem) -> AnyView {
        AnyView(Text(item.title).font(.title))
    }
}

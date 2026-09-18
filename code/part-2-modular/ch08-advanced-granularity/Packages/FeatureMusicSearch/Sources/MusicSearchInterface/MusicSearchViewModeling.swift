import Foundation
import Combine
import Domain

/// The contract between `MusicSearchUI` and `MusicSearchLogic`. Both
/// micro-targets depend on this protocol; neither depends on the other.
///
/// `MusicSearchUI` renders whatever conforms to this — the real
/// `MusicSearchViewModel` from `MusicSearchLogic`, or a preview/mock
/// conformer — without ever linking `MusicSearchLogic`. `MusicSearchLogic`
/// implements it without ever linking SwiftUI.
@MainActor
public protocol MusicSearchViewModeling: ObservableObject {
    var query: String { get set }
    var tracks: [Track] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func search() async
    func isSaved(_ track: Track) -> Bool
    func toggleSave(_ track: Track)
}

import SwiftUI
import DesignSystem
import Domain
import MusicSearchInterface

/// Pure UI. It is generic over *any* `MusicSearchViewModeling`, so it can be
/// driven by the real `MusicSearchViewModel` from `MusicSearchLogic`, or by a
/// preview/mock conformer — and it compiles without linking
/// `MusicSearchLogic` at all.
public struct MusicSearchScreen<ViewModel: MusicSearchViewModeling>: View {
    @StateObject private var viewModel: ViewModel

    public init(viewModel: @autoclosure @escaping () -> ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                ForEach(viewModel.tracks) { track in
                    TrackRow(track: track, isSaved: viewModel.isSaved(track)) {
                        viewModel.toggleSave(track)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Music")
            .searchable(text: $viewModel.query, prompt: "Search songs")
            .onSubmit(of: .search) { Task { await viewModel.search() } }
            .overlay { if viewModel.isLoading { ProgressView() } }
            .task { await viewModel.search() }
        }
    }
}

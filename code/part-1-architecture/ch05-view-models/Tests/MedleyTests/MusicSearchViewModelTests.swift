import Foundation
import Testing
@testable import Medley

/// `MusicSearchViewModel`, driven through every `ViewState` by a `FakeSearchClient`.
///
/// No network, no simulator UI, no SwiftUI: the screen's behaviour is plain values now.
@MainActor
struct MusicSearchViewModelTests {
    @Test func startsIdle() {
        let viewModel = MusicSearchViewModel(client: FakeSearchClient())

        #expect(viewModel.state == .idle)
    }

    @Test func aBlankQueryDoesNotSearch() async {
        let client = FakeSearchClient()
        let viewModel = MusicSearchViewModel(client: client)
        viewModel.query = "   "

        await viewModel.search()

        #expect(client.searchedTerms.isEmpty)
        #expect(viewModel.state == .idle)
    }

    @Test func showsOnlyLoadingWhileASearchIsInFlight() async {
        let client = FakeSearchClient(result: .success([.letDown]))
        let viewModel = MusicSearchViewModel(client: client)
        var stateMidSearch: MusicSearchViewModel.ViewState?
        client.whileSearching = { stateMidSearch = viewModel.state }
        viewModel.query = "radiohead"

        await viewModel.search()

        #expect(stateMidSearch == .loading)
    }

    @Test func resultsBecomeLoadedRows() async {
        let client = FakeSearchClient(result: .success([.letDown]))
        let viewModel = MusicSearchViewModel(client: client)
        viewModel.query = "  radiohead "

        await viewModel.search()

        #expect(client.searchedTerms == ["radiohead"])
        #expect(viewModel.state == .loaded([TrackRowModel(track: .letDown)]))
    }

    @Test func noResultsIsEmptyForTheTermSearched() async {
        let viewModel = MusicSearchViewModel(client: FakeSearchClient(result: .success([])))
        viewModel.query = "zzzzqqq"

        await viewModel.search()

        #expect(viewModel.state == .empty(term: "zzzzqqq"))
    }

    @Test func aFailureShowsTheErrorsMessage() async {
        let viewModel = MusicSearchViewModel(client: FakeSearchClient(result: .failure(.offline)))
        viewModel.query = "radiohead"

        await viewModel.search()

        #expect(viewModel.state == .failed(message: SearchError.offline.localizedDescription))
    }

    /// Chapter 1's third exercise: retrying after an error drew the spinner on top of the
    /// error message. Now the retry shows loading, and only loading.
    @Test func retryingAfterAFailureShowsOnlyLoading() async {
        let client = FakeSearchClient(result: .failure(.offline))
        let viewModel = MusicSearchViewModel(client: client)
        viewModel.query = "radiohead"
        await viewModel.search()

        client.result = .success([.letDown])
        var stateMidRetry: MusicSearchViewModel.ViewState?
        client.whileSearching = { stateMidRetry = viewModel.state }
        await viewModel.search()

        #expect(stateMidRetry == .loading)
        #expect(viewModel.state == .loaded([TrackRowModel(track: .letDown)]))
    }

    /// A failure after a successful search replaces the old results; it never draws over them.
    @Test func aFailureReplacesEarlierResults() async {
        let client = FakeSearchClient(result: .success([.letDown]))
        let viewModel = MusicSearchViewModel(client: client)
        viewModel.query = "radiohead"
        await viewModel.search()

        client.result = .failure(.badStatus(503))
        viewModel.query = "radiohead live"
        await viewModel.search()

        #expect(viewModel.state == .failed(message: SearchError.badStatus(503).localizedDescription))
    }

    @Test func clearingTheQueryReturnsToIdle() async {
        let viewModel = MusicSearchViewModel(client: FakeSearchClient(result: .success([.letDown])))
        viewModel.query = "radiohead"
        await viewModel.search()

        viewModel.query = ""

        #expect(viewModel.state == .idle)
    }
}

extension Track {
    /// A real result, as decoded from the Chapter 2 fixture.
    static let letDown = Track(
        trackId: 1_097_861_834, trackName: "Let Down", artistName: "Radiohead",
        collectionName: "OK Computer",
        artworkUrl100: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/07/60/ba/0760ba0f-148c-b18f-d0ff-169ee96f3af5/634904078164.png/100x100bb.jpg"),
        releaseDate: Date(timeIntervalSince1970: 864_198_000), trackTimeMillis: 299_560,
        trackViewUrl: URL(string: "https://music.apple.com/us/album/let-down/1097861387?i=1097861834&uo=4"))
}

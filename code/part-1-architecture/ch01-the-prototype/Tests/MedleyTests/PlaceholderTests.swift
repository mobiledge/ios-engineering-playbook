import XCTest
@testable import Medley

/// The test target exists; the tests don't — yet.
///
/// The test we actually want is "a 247-second song shows as 4:07". It can't be
/// written: that formatting lives inside `ContentView.body`, on a dictionary, in
/// the middle of a `List` row. There is nothing to call and nothing to assert on.
///
/// So this file holds the only honest test available at this size: the app
/// target links into the test bundle and its one view can be created. It proves
/// nothing about behaviour. It stays as a promise — Chapter 2 writes the first
/// real tests, and Chapter 5 writes the one above.
final class PlaceholderTests: XCTestCase {
    func testTheAppLinksIntoTheTestBundle() {
        _ = ContentView()
    }
}

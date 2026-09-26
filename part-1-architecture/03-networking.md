# Chapter 3: Networking

*The network hides behind a contract.*

Medley 1.0.1 fixes the crash, and the reviews settle down. The next message comes from a friend in
London: *"Love it, but half the songs I tap open to 'not available in your country.' Is it
US-only?"*

It is, by accident. The iTunes Search API searches the **US** storefront unless you tell it
otherwise, so a user in the UK gets American results, American catalog gaps, and links into a
store they can't buy from. The fix is one query parameter, `country`. It should be a two-minute
change. It isn't, and working out why is what this chapter is about.

## Where we are

Chapter 2 turned Apple's JSON into a type at the boundary and wrote the book's first tests:

```text
ch02-models/
├── CLAUDE.md                     # two laws; lists add-model
├── .claude/skills/add-model/SKILL.md
├── project.yml
├── Sources/
│   ├── App/MedleyApp.swift
│   ├── Models/
│   │   ├── Track.swift
│   │   └── SearchResponse.swift  # the envelope + shared decoder, in a home it calls temporary
│   └── ContentView.swift         # every other job: 142 lines
└── Tests/MedleyTests/
    ├── TrackDecodingTests.swift  # four tests, six milliseconds
    └── Fixtures/
```

| # | Job the view is doing | Where it lives in Chapter 2 | Retired in |
|---|---|---|---|
| 1 | ~~Parse API responses~~ | ~~six `item["…"]` casts~~ → `Track` + `SearchResponse` | Ch 2 — Models |
| 2 | Talk to the network | `search()`: URL, `URLSession`, status check | Ch 3 — Networking |
| 3 | Render every pixel of the screen | one 70-line `body` | Ch 4 — View Composition |
| 4 | Shape data for display + hold screen state | seven `@State`s, inline formatting | Ch 5 — View Models |
| 5 | Be the whole app | `MedleyApp` → `ContentView`, nothing else | Ch 6 — Duplication and Abstraction |
| 6 | Define the app's look | a thumbnail size, a corner radius, a few modifiers | Ch 7 — Design Tokens |
| 7 | Decide where to go next | `openURL` inside a row's button | Ch 8 — Coordinators |
| 8 | Log, track, report, and flag | five `print`s, one hard-coded `let` | Ch 9 — Cross-Cutting Services |
| 9 | Describe the project itself | this file *is* the map | Ch 10 — Project Generation |

Chapter 2 ended by pointing at `search()`: decoding was tested, but everything around it (the
endpoint, the parameters, the status check) lived inside a SwiftUI view where no test could reach.

## The pain

The founder opens `ContentView.swift`, scrolls past the seven `@State` properties and the 70-line
`body`, finds the query items inside `search()`, and adds one line:

```diff
         components.queryItems = [
             URLQueryItem(name: "term", value: term),
             URLQueryItem(name: "media", value: "music"),
             URLQueryItem(name: "entity", value: "song"),
+            URLQueryItem(name: "country", value: Locale.current.identifier),
             URLQueryItem(name: "limit", value: "50"),
             URLQueryItem(name: "explicit", value: allowsExplicitResults ? "Yes" : "No"),
         ]
```

Build, run, search for "radiohead". The screen says:

> **Something Went Wrong**
> The music catalog is unavailable right now (HTTP 400).

So they check whether Apple is down. They open Apple's system status page, retry, try another
term, and eventually paste the URL into a terminal. The answer is in the URL, not at Apple.
`Locale.current.identifier` is `en_US`: a *language and region*. The API wants a *storefront*, which
is a region code (`US`, `GB`). Given `en_US` it answers **HTTP 400, Bad Request**. And ch01's error
message, written when every non-2xx status looked the same, told the user a lie: a 400 means *our
request* is wrong, not that Apple's catalog is unavailable.

The second attempt, `Locale.current.region?.identifier`, is correct. Proving it's correct is the
expensive part. The URL is built inside a `private` method of a `View`, from a global
(`Locale.current`), and sent through another global (`URLSession.shared`). No test can see it. The
only way to check what a UK user gets is to change the simulator's region in Settings, relaunch,
search by hand, and eyeball the results for British-only releases. Then change the region back and
check the US hasn't broken. Each loop takes about a minute, and the whole afternoon disappears
into a one-line change.

And nothing keeps it working. The next edit to that array (the explicit flag, a different `entity`,
a new page size) is one more hand-edit in a 142-line view file, verified by one more afternoon of
tapping, or more likely not verified at all.

The founder stashes the change. The parameter is right, but it's going into the wrong file.

## The extraction

Look at what `search()` knows. It knows the host name, the path, and five query parameters with the
API's own spellings. It knows `URLSession.shared` exists, what a non-2xx status means, and which
decoder reads Apple's dates. None of that is about *searching for songs on a phone screen*. It's all
about *how Apple's API happens to work*, and it lives in the one file that also decides the thumbnail
corner radius.

**The network hides behind a contract.** The view should be able to say "songs matching this term"
and get songs back, without knowing whether they come from Apple, a cache, or a test. That sentence
is a protocol:

```swift
// Sources/Networking/SearchClient.swift

/// What the app needs from a music catalog, in the app's own terms.
///
/// Callers depend on this, never on a concrete client. It says nothing about URLs,
/// HTTP, or JSON — those are the conforming type's business.
protocol SearchClient {
    /// Songs matching `term`, in the order the catalog ranks them.
    /// - Throws: `SearchError`, and nothing else.
    func searchSongs(matching term: String) async throws -> [Track]
}
```

One method, because the app makes one kind of request. It's stated in the app's vocabulary
(`searchSongs(matching:)`, not `get(path:query:)`), so nothing about HTTP leaks through it.

Behind it goes everything `search()` knew about Apple. The first version is a **pure move**: the
same five parameters, the same behavior, with the storefront fix still stashed. Refactoring and
changing behavior in the same step is how you end up unsure which one broke something.

```swift
// Sources/Networking/ITunesAPIClient.swift
import Foundation

/// `SearchClient` backed by Apple's iTunes Search API.
///
/// Everything it depends on arrives through `init`. It reaches for no globals,
/// so a test can hand it a stubbed session.
struct ITunesAPIClient: SearchClient {
    private let session: URLSession
    private let allowsExplicitResults: Bool

    init(session: URLSession, allowsExplicitResults: Bool) {
        self.session = session
        self.allowsExplicitResults = allowsExplicitResults
    }

    func searchSongs(matching term: String) async throws -> [Track] {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: songSearchURL(for: term))
        } catch {
            throw SearchError(transportError: error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SearchError.badStatus(http.statusCode)
        }

        do {
            return try SearchResponse.decoder.decode(SearchResponse.self, from: data).results
        } catch {
            throw SearchError.unreadableResponse(reason: String(describing: error))
        }
    }

    /// The request URL for a song search. Pure, so tests can check it without sending anything.
    func songSearchURL(for term: String) -> URL {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "explicit", value: allowsExplicitResults ? "Yes" : "No"),
        ]
        return components.url!
    }
}
```

Three choices in it carry the chapter.

**Hand it in, don't grab it.** The client doesn't use `URLSession.shared`. It receives a session in
its initializer. The explicit-results flag, previously a `let` in the view, arrives the same way.
This is the rule the rest of the book leans on: *a type receives what it depends on; it never
reaches out and takes it.* Anything handed in can be swapped: a test hands in a session that never
touches the network. Anything grabbed is fixed. `URLSession.shared` inside the type would mean
every test of this client is a test of Apple's servers and your Wi-Fi. `ITunesAPIClient` is a struct
because it has nothing to mutate: three constants and two functions.

**The request is a pure function.** `songSearchURL(for:)` builds a `URL` and sends nothing. The
request is where the afternoon went, and now it's an ordinary function you can call and inspect.

**Failures get names.** ch01 had two error paths: a status check with a hard-coded message, and
`localizedDescription` for everything else. The client now turns every failure into one type:

```swift
// Sources/Networking/SearchError.swift
import Foundation

/// Everything that can go wrong with a search, in terms the app can act on.
enum SearchError: Error, Equatable {
    /// The device has no connection. Worth "check your connection" and a retry.
    case offline
    /// The request never got an HTTP answer: a timeout, DNS, TLS, or similar.
    case unreachable
    /// The API answered with a non-2xx status. 4xx means our request is wrong; 5xx means theirs is down.
    case badStatus(Int)
    /// The API answered 2xx, but the body didn't decode into our models.
    case unreadableResponse(reason: String)

    /// Classifies a failure from the transport layer (anything `URLSession` throws).
    init(transportError error: any Error) {
        switch (error as? URLError)?.code {
        case .notConnectedToInternet?, .networkConnectionLost?, .dataNotAllowed?:
            self = .offline
        default:
            self = .unreachable
        }
    }
}

extension SearchError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .offline:
            "You're offline. Check your connection and try again."
        case .unreachable:
            "The music catalog couldn't be reached. Try again in a moment."
        case .badStatus(let status) where (400..<500).contains(status):
            "Medley sent a search the catalog couldn't handle (HTTP \(status))."
        case .badStatus(let status):
            "The music catalog is unavailable right now (HTTP \(status))."
        case .unreadableResponse:
            "The music catalog sent results Medley couldn't read."
        }
    }
}
```

Four cases, each one a different thing the app, or a user, can do something about. The 400 that
cost the afternoon now reads as what it is: *our* mistake. The decoding error from Chapter 2 isn't
thrown away; it rides along as `reason` for whoever reads the logs. The `LocalizedError` conformance
means the view's `errorMessage = error.localizedDescription` keeps working without learning anything
new. Whether user-facing wording belongs on an error type at all is a fair question. It's a
presentation decision, and Chapter 5 gives presentation a home. For now the words sit next to the
cases they describe.

`SearchResponse` moves too, from `Models/` to `Networking/`. Its Chapter 2 doc comment admitted
`Models/` was a temporary home. The envelope is a detail of how Apple's API wraps results, and the
client is now its only caller in the app. Chapter 2's decoding tests still decode through its shared
decoder, unchanged, so they still prove the app decodes the way the client does.

Now the view. `ContentView` gets a client and loses everything it knew about Apple:

```diff
 struct ContentView: View {
+    let client: any SearchClient
+
     @State private var query = ""
 …
-    /// Flip to `true` once we're happy showing explicit tracks in search.
-    private let allowsExplicitResults = false
 …
-        var components = URLComponents(string: "https://itunes.apple.com/search")!
-        components.queryItems = [ … ]
-
         do {
-            let (data, response) = try await URLSession.shared.data(from: components.url!)
-            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
-                print("search failed with status \(http.statusCode)")
-                errorMessage = "The music catalog is unavailable right now (HTTP \(http.statusCode))."
-                showError = true
-                isLoading = false
-                return
-            }
-
-            let tracks = try SearchResponse.decoder.decode(SearchResponse.self, from: data).results
+            let tracks = try await client.searchSongs(matching: term)
             print("got \(tracks.count) results")
```

`search()` is now state handling only: set the loading flag, ask the client, record the result or
the error. `ContentView` drops from 142 lines to 123. The type of `client` is `any SearchClient`,
not `ITunesAPIClient`, so the view can't reach past the contract even by accident.

Someone has to build the real client, and the rule says it isn't the view. It's the app:

```swift
// Sources/App/MedleyApp.swift
@main
struct MedleyApp: App {
    private let client = MedleyApp.makeSearchClient()

    var body: some Scene {
        WindowGroup {
            ContentView(client: client)
        }
    }

    /// The one place the real search client is built. Previews use it too.
    static func makeSearchClient() -> any SearchClient {
        ITunesAPIClient(
            session: URLSession(configuration: .default),
            // Flip to `true` once we're happy showing explicit tracks in search.
            allowsExplicitResults: false
        )
    }
}
```

Notice where construction ended up. The view receives its client, the client receives its session
and its flag, and the only code that actually *creates* anything is `MedleyApp`. With one dependency
that's three lines. It's also the first sign of something later chapters will have to deal with:
everything handed in has to be built somewhere, and "somewhere" is filling up at app startup.
Chapter 9 comes back to it.

## Prove it

The afternoon was spent asking one question: *what URL does this send?* Now it's a function call.
The tests cover *our* logic (the parameters we chose, the way we classify failures) and leave
Apple's networking stack alone. And none of them touches the network.

The request is the easy part, because `songSearchURL(for:)` is pure:

```swift
@Test func songSearchURLCarriesEveryQueryParameter() {
    let url = makeClient().songSearchURL(for: "radiohead")

    #expect(url.host() == "itunes.apple.com")
    #expect(url.path() == "/search")
    #expect(queryItems(of: url) == [
        "term": "radiohead", "media": "music", "entity": "song",
        "limit": "50", "explicit": "No",
    ])
}

@Test func explicitResultsFollowTheFlagItWasGiven() {
    let url = makeClient(allowsExplicitResults: true).songSearchURL(for: "radiohead")

    #expect(queryItems(of: url)["explicit"] == "Yes")
}
```

Everything else needs a response, and responses come from `URLSession`. That's where the
handed-in session pays for itself. `URLSession` lets you register a `URLProtocol` subclass that
answers requests itself, and a session configured with one never opens a socket:

```swift
// Tests/MedleyTests/Support/StubURLProtocol.swift
final class StubURLProtocol: URLProtocol {
    enum Stub {
        case response(status: Int, body: Data)
        case failure(URLError)
    }

    /// What the next request receives. `nil` fails the request, so a missing stub can't pass silently.
    static var stub: Stub?
    /// The last request the session actually sent.
    static private(set) var lastRequest: URLRequest?

    /// A session whose every request is answered by `stub`.
    static func makeSession(stub: Stub) -> URLSession {
        self.stub = stub
        lastRequest = nil
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override func startLoading() {
        Self.lastRequest = request
        switch Self.stub {
        case .response(let status, let body)?:
            // …hand back an HTTPURLResponse with `status`, then `body`
        case .failure(let error)?:
            client?.urlProtocol(self, didFailWithError: error)
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
        }
    }
    // canInit, canonicalRequest, stopLoading: the usual one-liners
}
```

The client runs its real code path (`session.data(from:)`, the status check, the decoder), and only
the bytes are fake. One round trip replays Chapter 2's saved Radiohead response and also checks that
the request the stub *received* is the one the pure function *built*:

```swift
@Test func decodesTracksFromTheURLItBuilt() async throws {
    let session = StubURLProtocol.makeSession(stub: .response(status: 200, body: try fixture("track_search_response")))
    let client = makeClient(session: session)

    let tracks = try await client.searchSongs(matching: "radiohead")

    #expect(tracks.map(\.trackName) == ["Let Down", "All I Need"])
    #expect(StubURLProtocol.lastRequest?.url == client.songSearchURL(for: "radiohead"))
}
```

The failure paths are where Swift Testing's parameterised tests earn their place. They're one
function each, with the cases as data:

```swift
@Test(arguments: [400, 404, 500, 503])
func non2xxStatusBecomesBadStatus(status: Int) async {
    let client = makeClient(session: StubURLProtocol.makeSession(stub: .response(status: status, body: Data())))

    await #expect(throws: SearchError.badStatus(status)) {
        try await client.searchSongs(matching: "radiohead")
    }
}

@Test(arguments: [
    (URLError.Code.notConnectedToInternet, SearchError.offline),
    (.networkConnectionLost, .offline),
    (.timedOut, .unreachable),
    (.cannotFindHost, .unreachable),
])
func transportFailuresAreClassified(code: URLError.Code, expected: SearchError) async {
    let client = makeClient(session: StubURLProtocol.makeSession(stub: .failure(URLError(code))))

    await #expect(throws: expected) {
        try await client.searchSongs(matching: "radiohead")
    }
}
```

Two more round out the suite. A 200 whose body is an HTML error page must become
`.unreadableResponse`, not a crash and not an empty list. And the message a user reads has to
blame the right side:

```swift
/// 4xx is our fault and 5xx is theirs, and the message the user reads says so.
@Test func statusMessagesBlameTheRightSide() {
    #expect(SearchError.badStatus(400).localizedDescription.contains("Medley sent a search"))
    #expect(SearchError.badStatus(503).localizedDescription.contains("unavailable right now"))
}
```

`StubURLProtocol` keeps its state in statics, because URL loading creates protocol instances
itself and there's no other way in. That makes the client suite `@Suite(.serialized)`: its tests
run one at a time, while Chapter 2's decoding tests still run in parallel beside them.

```text
✔ Test songSearchURLCarriesEveryQueryParameter() passed after 0.001 seconds.
✔ Test explicitResultsFollowTheFlagItWasGiven() passed after 0.001 seconds.
✔ Test decodesTracksFromTheURLItBuilt() passed after 0.002 seconds.
✔ Test non2xxStatusBecomesBadStatus(status:) with 4 test cases passed after 0.001 seconds.
✔ Test transportFailuresAreClassified(code:expected:) with 4 test cases passed after 0.010 seconds.
✔ Test a200WithAnUndecodableBodyIsUnreadable() passed after 0.003 seconds.
✔ Test statusMessagesBlameTheRightSide() passed after 0.001 seconds.
…plus Chapter 2's four decoding tests
```

The whole suite finishes in under 30 milliseconds, and it passes with Wi-Fi off. The HTTP-error
branch that Chapter 2 said had "never run anywhere except on a user's phone" now runs on every build,
for four statuses.

## Codify it

Two things get written down. The first is a law, because "hand it in, don't grab it" isn't only
about networking. It will govern every dependency from here on: view models in Chapter 5, the
coordinator in Chapter 8, and logging and analytics in Chapter 9:

```diff
+3. **The network hides behind a contract; dependencies are handed in, never grabbed.** Views and
+   other callers talk to `SearchClient`, never to `URLSession`, URLs, or JSON. Every type receives
+   what it depends on through its initializer — no `.shared`, no singletons, no reading
+   `Locale.current` or other globals inside a type; only `MedleyApp` (and previews) construct the
+   real ones. We learned this from a one-line query change inside a view: it could only be checked
+   by hand, and its first attempt failed every search with an HTTP 400 that the app blamed on Apple.
```

The second is the skill for the task that caused the afternoon: *adding or changing a call to an
API*. It follows Chapter 2's shape, portable best practices with no Medley in them:

```markdown
---
name: add-endpoint
description: Use when a Swift app needs a new call to an HTTP API, or a change to an existing one
  (a new query parameter, header, path, or error case). Covers the client protocol, the concrete
  client, typed errors, and the tests, which ship together.
---

# add-endpoint

## Best practices

**The contract**

1. **Callers depend on a protocol, stated in the app's terms.** …
2. **Keep the protocol as small as its callers.** …
3. **One typed error for the whole client**, with cases a caller can act on …

**The client**

4. **Every dependency arrives through `init`:** the `URLSession`, base URL, locale, credentials,
   flags. No singletons, no `.shared`, no reading global state (`Locale.current`, `UserDefaults`,
   environment) inside the type. What is handed in can be swapped in a test; what is grabbed can't.
5. **Build requests in a pure function** … so the request can be tested without a network or a stub.
6. **Use `URLComponents` and `URLQueryItem`** … Name every query parameter the API needs, even when
   it has a default — the default is usually someone else's storefront, page size, or language.
7. **Derive API values from their real source.** A country code is a locale's *region*, not its
   identifier; a language is its language code. Test the derivation.
8. **Check the status before decoding** … keep 4xx (our request is wrong) distinguishable from 5xx
   (their service is down).
…

**Tests ship with the endpoint, in the same change**

11. **No test touches the network.** Route requests through a stub `URLProtocol` …
12. **Test your logic, not Apple's:** the request, one round trip, status mapping, transport
    mapping, an undecodable body.
13. **Every bug found in a request becomes a named regression test** of the pure builder.

## Acceptance checks

- [ ] Callers reference only the protocol; no call site builds URLs, touches `URLSession`, or
      decodes.
- [ ] The client has no `.shared`, no singleton, and reads no global state; everything it uses is
      an `init` parameter.
…
```

Practices 6 and 7 read like general advice, and they are, but each one was paid for this week. `CLAUDE.md`
lists the skill with the files here that show it followed, `ITunesAPIClient.swift` and its tests,
just as Chapter 2 listed `add-model` with `Track.swift`.

Now the stashed change gets a second attempt, and this time the founder asks the assistant:

> **Founder:** Make search use the user's own storefront. UK users are getting US results.
>
> **Assistant:** That changes a request, so I'm following `add-endpoint`, with `ITunesAPIClient`
> as the example `CLAUDE.md` points to.
>
> 1. The storefront depends on the device, so it's a dependency: `ITunesAPIClient.init` gains a
>    `locale: Locale` parameter rather than reading `Locale.current` inside the client.
>    `MedleyApp.makeSearchClient()` hands in `.current`.
> 2. The API wants a region code, so the client derives `country` from `locale.region`, falling back
>    to `US`, and adds it to the query.
> 3. Tests first: `country` joins the every-parameter test, and a regression test pins
>    `en_GB` → `country=GB`, the identifier-vs-region mistake practice 7 warns about. 12 of 12 pass.
>
> `ContentView` didn't need to change.

```diff
 struct ITunesAPIClient: SearchClient {
     private let session: URLSession
+    private let country: String
     private let allowsExplicitResults: Bool

-    init(session: URLSession, allowsExplicitResults: Bool) {
+    init(session: URLSession, locale: Locale, allowsExplicitResults: Bool) {
         self.session = session
+        // The storefront is the locale's *region* ("GB"). The full identifier ("en_GB")
+        // is rejected by the API with HTTP 400.
+        self.country = locale.region?.identifier ?? "US"
         self.allowsExplicitResults = allowsExplicitResults
     }
 …
             URLQueryItem(name: "entity", value: "song"),
+            URLQueryItem(name: "country", value: country),
             URLQueryItem(name: "limit", value: "50"),
```

```swift
/// The bug that opened this chapter: the storefront is the region, not the locale identifier.
@Test func countryIsTheLocaleRegionNotItsIdentifier() {
    let url = makeClient(locale: Locale(identifier: "en_GB")).songSearchURL(for: "radiohead")

    #expect(queryItems(of: url)["country"] == "GB")
}
```

The regression test really does catch the afternoon's mistake. Put `locale.identifier` back in the
client and two tests fail at once: `country → "en_GB"` where `"GB"` was expected, and `"en_US"` in the
every-parameter test. The change that cost an afternoon inside the view took minutes in the client,
and it came with the test that would have saved the afternoon. `ContentView.swift` doesn't appear in
the diff at all.

## The ledger

| # | Job the view is doing | Where it lives today | Retired in |
|---|---|---|---|
| 1 | ~~Parse API responses~~ | ~~six `item["…"]` casts~~ → `Track` + `SearchResponse` | Ch 2 — Models |
| 2 | ~~Talk to the network~~ | ~~`search()`: URL, `URLSession`, status check~~ → `SearchClient` + `ITunesAPIClient` | **Retired in this chapter** |
| 3 | Render every pixel of the screen | one 70-line `body` | Ch 4 — View Composition |
| 4 | Shape data for display + hold screen state | seven `@State`s, inline formatting | Ch 5 — View Models |
| 5 | Be the whole app | `MedleyApp` builds one client and shows `ContentView` | Ch 6 — Duplication and Abstraction |
| 6 | Define the app's look | a thumbnail size, a corner radius, a few modifiers | Ch 7 — Design Tokens |
| 7 | Decide where to go next | `openURL` inside a row's button | Ch 8 — Coordinators |
| 8 | Log, track, report, and flag | four `print`s in the view; the explicit flag, now set at startup | Ch 9 — Cross-Cutting Services |
| 9 | Describe the project itself | this file *is* the map | Ch 10 — Project Generation |

## Is this worth it yet?

Mostly yes. Be honest about which part isn't paying for itself *yet*.

The client and its error type pay off today. There are 94 lines of networking in two files, where
there used to be about twenty lines inside a view. In exchange, the request is a function you can call, every
failure has a name, the user-facing message stops blaming Apple for our 400s, and eight new test
functions (fourteen cases) run the request, a round trip, and every error path in a few
milliseconds without a network. The storefront change proved the trade in the same chapter: an
afternoon in the view, minutes in the client.

The **protocol** is the part to be skeptical about. `SearchClient` has exactly one conformer, and
nothing in this chapter's tests uses the protocol: they test `ITunesAPIClient` directly, through a
stubbed session. Today it's a layer of indirection between the view and the only thing it could
possibly be talking to. Law 1 asks what pain it solves, and the honest answer is: none this chapter,
one soon. The view can't be tested without the network until something *other than* the real client
can stand in for it, and that's exactly what Chapter 5 needs when it moves screen state into a view
model and drives it through every state with a fake client. The protocol costs nine lines, most of
them doc comment, and it stops `ContentView` from depending on how Apple's API works. It goes in
now because the extraction is the cheapest moment to draw the line, not because it has paid for
itself yet.

The other honest cost is ceremony. "Hand it in" means the explicit flag travels from `MedleyApp`
through an initializer instead of being a `let` next to where it's used. At one dependency that's
nothing. Chapter 9 is where it starts to add up.

## The trap this leaves open

`ContentView` no longer knows the network exists, but it still does seven jobs, and one of them
dominates the file: the 70-line `body`. The search field, the result row, the artwork thumbnail,
four different empty and error states, and the navigation title are all one expression. Every
visual change to any part of the screen is an edit to the one `body` that renders all of it, and a
misplaced modifier in one branch can quietly restyle another.

The founder has been putting off the first design request because of exactly that. Row 3,
**rendering**, is next.

## Hands-on

The code for this chapter is in
[`code/part-1-architecture/ch03-networking`](../code/part-1-architecture/ch03-networking/). It's the
end state, including the storefront fix from the skill demo. You need a Mac with Xcode 16.3 or later
and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd code/part-1-architecture/ch03-networking
xcodegen generate
open Medley.xcodeproj
```

Run it and search. Then set the simulator's region to the United Kingdom (Settings → General →
Language & Region), relaunch, and search again: results now come from the GB storefront. To run the
tests, with or without Wi-Fi:

```bash
xcodebuild test -project Medley.xcodeproj -scheme Medley \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

To see exactly what this chapter changed:

```bash
diff -r code/part-1-architecture/ch02-models code/part-1-architecture/ch03-networking
```

### Exercises

1. **Reintroduce the bug.** Change the client to `self.country = locale.identifier` and run the
   tests. Read both failures. Then put `Locale.current.region` *inside* the client instead of the
   `locale` parameter, and ask yourself which test can still check the UK case. (None can. That's
   the law.)
2. **Add a parameter with the skill.** Ask your assistant to cap results at 25 on cellular data.
   Watch where it puts the decision: a well-behaved answer hands the client a dependency that knows
   the connection type, rather than reading it inside the client. Does it write the test before the
   change?
3. **Find what the protocol doesn't buy yet.** Try to write a test that checks `ContentView` shows
   the error screen when the client throws `.offline`. Write down what stops you. Chapter 5 removes
   exactly that obstacle.

---

> **Next:** Chapter 4 — View Composition. *A view renders what it is given, and nothing else.*

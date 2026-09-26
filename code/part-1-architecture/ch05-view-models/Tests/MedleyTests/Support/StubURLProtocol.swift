import Foundation

/// A `URLProtocol` that answers every request with a canned result, so client tests
/// exercise the real `URLSession` code path without touching the network.
///
/// Its state is static (URL loading instantiates protocols itself), so suites that use
/// it must be `.serialized`.
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

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        switch Self.stub {
        case .response(let status, let body)?:
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error)?:
            client?.urlProtocol(self, didFailWithError: error)
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
        }
    }

    override func stopLoading() {}
}

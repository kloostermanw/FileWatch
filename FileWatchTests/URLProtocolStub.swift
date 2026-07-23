//
//  URLProtocolStub.swift
//  FileWatchTests
//
//  Created by Wiebe Kloosterman on 23/07/2026.
//

import Foundation

/// A `URLProtocol` that intercepts every request on a session it is registered with and
/// serves whatever `handler` returns, so network-facing code can be tested without a network.
/// Suites using it must be `.serialized` — `handler` is shared process-wide state.
final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    /// Builds an ephemeral session that routes all traffic through this stub.
    static func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// Convenience for building an `HTTPURLResponse` with a status code.
func httpResponse(_ url: URL, _ status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
}

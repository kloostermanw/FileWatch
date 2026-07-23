//
//  ReleaseChecking.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 21/07/2026.
//

import Foundation

/// Errors surfaced by the update pipeline. Each case maps to a distinct failure so the
/// user-facing message points at the right subsystem — never a synthetic "HTTP -1".
enum UpdateError: LocalizedError, Equatable {
    /// GitHub's unauthenticated rate limit (HTTP 403).
    case rateLimited
    /// The repo has no published releases yet (HTTP 404 on `releases/latest`).
    case noReleasesPublished
    /// Any other non-200 HTTP status, carrying the actual code.
    case badResponse(Int)
    /// URLSession reported neither an error nor a usable response/body.
    case emptyResponse
    /// A download finished without producing a file on disk.
    case downloadProducedNoFile
    /// The response was not an `HTTPURLResponse` (e.g. a non-HTTP scheme).
    case nonHTTPResponse

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "GitHub is rate-limiting update checks. Please try again later."
        case .noReleasesPublished:
            return "No releases have been published yet."
        case let .badResponse(code):
            return "GitHub returned an unexpected response (HTTP \(code))."
        case .emptyResponse:
            return "The server returned an empty response."
        case .downloadProducedNoFile:
            return "The download did not produce a file."
        case .nonHTTPResponse:
            return "The server returned an unexpected (non-HTTP) response."
        }
    }
}

/// Fetches the latest published release. Abstracted so tests can stub it.
protocol ReleaseChecking: Sendable {
    func latestRelease() async throws -> GitHubRelease
}

/// Queries the hardcoded FileWatch repo's latest release, unauthenticated.
struct GitHubReleaseService: ReleaseChecking {
    private let owner = "kloostermanw"
    private let repo = "FileWatch"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func latestRelease() async throws -> GitHubRelease {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.dataCompat(for: request)
        guard let http = response as? HTTPURLResponse else { throw UpdateError.nonHTTPResponse }
        switch http.statusCode {
        case 200: break
        case 403: throw UpdateError.rateLimited
        case 404: throw UpdateError.noReleasesPublished
        default: throw UpdateError.badResponse(http.statusCode)
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}

/// Back-deployable equivalents of the async `URLSession` APIs, which are macOS 12+;
/// FileWatch targets macOS 11.1, so these bridge the completion-handler variants.
extension URLSession {
    func dataCompat(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: UpdateError.emptyResponse)
                }
            }
            task.resume()
        }
    }

    /// Downloads to a temporary file and moves it to a caller-owned stash before the
    /// completion handler returns (the delegate-supplied temp file is deleted after).
    func downloadCompat(from url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let task = downloadTask(with: url) { tempURL, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    // Don't stash an error page (e.g. a 403/404 body) as if it were the .dmg.
                    continuation.resume(throwing: UpdateError.badResponse(http.statusCode))
                    return
                }
                guard let tempURL else {
                    continuation.resume(throwing: UpdateError.downloadProducedNoFile)
                    return
                }
                do {
                    let stash = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                    try FileManager.default.moveItem(at: tempURL, to: stash)
                    continuation.resume(returning: stash)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }
}

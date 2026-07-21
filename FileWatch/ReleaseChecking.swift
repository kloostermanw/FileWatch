//
//  ReleaseChecking.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 21/07/2026.
//

import Foundation

/// Errors surfaced by the update pipeline.
enum UpdateError: LocalizedError {
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case let .badResponse(code):
            return "GitHub returned an unexpected response (HTTP \(code))."
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
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.badResponse((response as? HTTPURLResponse)?.statusCode ?? -1)
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
                    continuation.resume(throwing: UpdateError.badResponse(-1))
                }
            }
            task.resume()
        }
    }

    /// Downloads to a temporary file and moves it to a caller-owned stash before the
    /// completion handler returns (the delegate-supplied temp file is deleted after).
    func downloadCompat(from url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let task = downloadTask(with: url) { tempURL, _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let tempURL else {
                    continuation.resume(throwing: UpdateError.badResponse(-1))
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

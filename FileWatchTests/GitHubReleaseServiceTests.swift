//
//  GitHubReleaseServiceTests.swift
//  FileWatchTests
//
//  Created by Wiebe Kloosterman on 23/07/2026.
//

import Testing
import Foundation
@testable import FileWatch

@Suite(.serialized) struct GitHubReleaseServiceTests {
    private let validBody = Data("""
    {"tag_name": "v1.2.0", "name": "1.2.0", "body": "",
     "html_url": "https://github.com/kloostermanw/FileWatch/releases/tag/v1.2.0",
     "assets": [{"name": "FileWatch.dmg", "browser_download_url": "https://example.com/FileWatch.dmg"}]}
    """.utf8)

    @Test func decodesReleaseOn200() async throws {
        URLProtocolStub.handler = { req in (httpResponse(req.url!, 200), self.validBody) }
        let service = GitHubReleaseService(session: URLProtocolStub.session())
        let release = try await service.latestRelease()
        #expect(release.tagName == "v1.2.0")
    }

    @Test func rateLimitedOn403() async {
        URLProtocolStub.handler = { req in (httpResponse(req.url!, 403), Data()) }
        let service = GitHubReleaseService(session: URLProtocolStub.session())
        await #expect(throws: UpdateError.rateLimited) { try await service.latestRelease() }
    }

    @Test func noReleasesPublishedOn404() async {
        URLProtocolStub.handler = { req in (httpResponse(req.url!, 404), Data()) }
        let service = GitHubReleaseService(session: URLProtocolStub.session())
        await #expect(throws: UpdateError.noReleasesPublished) { try await service.latestRelease() }
    }

    @Test func badResponseOnOtherStatus() async {
        URLProtocolStub.handler = { req in (httpResponse(req.url!, 500), Data()) }
        let service = GitHubReleaseService(session: URLProtocolStub.session())
        await #expect(throws: UpdateError.badResponse(500)) { try await service.latestRelease() }
    }

    @Test func throwsOnMalformedBody() async {
        URLProtocolStub.handler = { req in (httpResponse(req.url!, 200), Data("{}".utf8)) }
        let service = GitHubReleaseService(session: URLProtocolStub.session())
        await #expect(throws: (any Error).self) { try await service.latestRelease() }
    }
}

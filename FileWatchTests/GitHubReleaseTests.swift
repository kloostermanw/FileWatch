//
//  GitHubReleaseTests.swift
//  FileWatchTests
//
//  Created by Wiebe Kloosterman on 21/07/2026.
//

import Testing
import Foundation
@testable import FileWatch

@Suite struct GitHubReleaseTests {
    private func decode(_ json: String) throws -> GitHubRelease {
        try JSONDecoder().decode(GitHubRelease.self, from: Data(json.utf8))
    }

    @Test func decodesTagNotesAndDmgAsset() throws {
        let json = """
        {
          "tag_name": "v1.2.0",
          "name": "Release 1.2.0",
          "body": "Bug fixes.",
          "html_url": "https://github.com/kloostermanw/FileWatch/releases/tag/v1.2.0",
          "assets": [
            {"name": "notes.txt", "browser_download_url": "https://example.com/notes.txt"},
            {"name": "FileWatch.v1.2.0.dmg", "browser_download_url": "https://example.com/FileWatch.dmg"}
          ]
        }
        """
        let release = try decode(json)
        #expect(release.tagName == "v1.2.0")
        #expect(release.name == "Release 1.2.0")
        #expect(release.body == "Bug fixes.")
        #expect(release.version == AppVersion("1.2.0"))
        #expect(release.dmgAsset?.name == "FileWatch.v1.2.0.dmg")
        #expect(release.dmgAsset?.downloadURL == URL(string: "https://example.com/FileWatch.dmg"))
    }

    @Test func dmgAssetNilWhenNoDmgPresent() throws {
        let json = """
        {
          "tag_name": "1.3.0",
          "name": null,
          "body": null,
          "html_url": "https://github.com/kloostermanw/FileWatch/releases/tag/1.3.0",
          "assets": []
        }
        """
        let release = try decode(json)
        #expect(release.dmgAsset == nil)
        #expect(release.name == "1.3.0")
        #expect(release.body == "")
    }
}

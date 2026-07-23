//
//  BroadPathTests.swift
//  FileWatchTests
//
//  Created by Wiebe Kloosterman on 23/07/2026.
//

import Testing
import Foundation
@testable import FileWatch

/// `ViewController.isBroadPath` guards "Add folder to monitor" against folders
/// whose subtree is huge and constantly changing (a notification firehose).
@Suite struct BroadPathTests {
    let home = NSHomeDirectory()

    @Test func flagsRootAndAncestorsOfHome() {
        #expect(ViewController.isBroadPath("/"))
        #expect(ViewController.isBroadPath("/Users"))
        #expect(ViewController.isBroadPath("/Users/"))
    }

    @Test func flagsHomeAndHomeLibrary() {
        #expect(ViewController.isBroadPath(home))
        #expect(ViewController.isBroadPath(home + "/"))
        #expect(ViewController.isBroadPath(home + "/Library"))
    }

    @Test func flagsSystemRoots() {
        for path in ["/System", "/Library", "/Applications", "/Volumes", "/private", "/usr", "/var"] {
            #expect(ViewController.isBroadPath(path), "\(path) should be broad")
        }
    }

    @Test func allowsSpecificProjectFolders() {
        #expect(!ViewController.isBroadPath(home + "/repos/celery-web-app/src/logs"))
        #expect(!ViewController.isBroadPath(home + "/repos/celery-web-app/src/logs/"))
        #expect(!ViewController.isBroadPath("/Users/someone/repos/app/src/storage/logs/"))
    }

    @Test func allowsSubfoldersOfHomeLibrary() {
        // ~/Library itself is broad, but a specific logs folder inside it is fine.
        #expect(!ViewController.isBroadPath(home + "/Library/Logs/MyApp"))
    }
}

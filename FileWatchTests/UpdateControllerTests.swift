//
//  UpdateControllerTests.swift
//  FileWatchTests
//
//  Created by Wiebe Kloosterman on 23/07/2026.
//

import Testing
import Foundation
@testable import FileWatch

/// A checker that blocks inside `latestRelease()` until the test releases it, so two checks
/// can be made to overlap deterministically. Records how many times it was actually called.
private final class GatedChecker: ReleaseChecking, @unchecked Sendable {
    let release: GitHubRelease
    private let lock = NSLock()
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private(set) var callCount = 0

    init(_ release: GitHubRelease) { self.release = release }

    func latestRelease() async throws -> GitHubRelease {
        lock.lock(); callCount += 1; lock.unlock()
        await withCheckedContinuation { continuation in
            lock.lock(); waiters.append(continuation); lock.unlock()
        }
        return release
    }

    func releaseAll() {
        lock.lock(); let pending = waiters; waiters = []; lock.unlock()
        pending.forEach { $0.resume() }
    }
}

@MainActor
private final class CountingPresenter {
    private(set) var count = 0
    func present(_ state: UpdateService.State, _ service: UpdateService) async {
        count += 1
    }
}

private func newerRelease() -> GitHubRelease {
    let json = """
    {"tag_name": "v9.9.9", "name": "v9.9.9", "body": "",
     "html_url": "https://github.com/kloostermanw/FileWatch/releases/tag/v9.9.9",
     "assets": [{"name": "FileWatch.dmg", "browser_download_url": "https://example.com/FileWatch.dmg"}]}
    """
    return try! JSONDecoder().decode(GitHubRelease.self, from: Data(json.utf8))
}

@MainActor
@Suite struct UpdateControllerTests {
    @Test func concurrentChecksCoalesceToOneCheckAndOnePresentation() async {
        let checker = GatedChecker(newerRelease())
        let presenter = CountingPresenter()
        let service = UpdateService(
            checker: checker,
            defaults: UserDefaults(suiteName: "UpdateControllerTests-\(UUID().uuidString)")!,
            currentVersion: AppVersion("1.0.0"),
            throttle: 0,
            now: { Date(timeIntervalSince1970: 0) }
        )
        let controller = UpdateController(service: service, present: presenter.present)

        async let first: Void = controller.check(userInitiated: true)
        async let second: Void = controller.check(userInitiated: true)
        // Let both tasks reach their suspension points before unblocking the network.
        for _ in 0..<10 { await Task.yield() }
        checker.releaseAll()
        _ = await (first, second)

        #expect(checker.callCount == 1)
        #expect(presenter.count == 1)
    }
}

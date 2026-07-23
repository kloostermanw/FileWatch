//
//  UpdateService.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 21/07/2026.
//

import Foundation
import AppKit
import os

/// Checks GitHub for a newer release and downloads its `.dmg`. UI-agnostic: callers
/// read `state` after each `checkForUpdates`/`download` and present accordingly.
@MainActor
final class UpdateService {
    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case available(GitHubRelease)
        case downloading
        case downloaded(URL)
        case failed(title: String, message: String)
    }

    private(set) var state: State = .idle

    private let checker: ReleaseChecking
    private let session: URLSession
    private let defaults: UserDefaults
    private let currentVersion: AppVersion
    private let throttle: TimeInterval
    private let now: () -> Date

    private let lastCheckKey = "UpdateService.lastCheck"
    private let skippedTagKey = "UpdateService.skippedTag"

    private static let logger = Logger(subsystem: "kloosterman.eu.FileWatch", category: "updates")

    init(
        checker: ReleaseChecking = GitHubReleaseService(),
        session: URLSession = .shared,
        defaults: UserDefaults = .standard,
        currentVersion: AppVersion = .current,
        throttle: TimeInterval = 2 * 60 * 60,
        now: @escaping () -> Date = Date.init
    ) {
        self.checker = checker
        self.session = session
        self.defaults = defaults
        self.currentVersion = currentVersion
        self.throttle = throttle
        self.now = now
    }

    func checkForUpdates(userInitiated: Bool) async {
        if !userInitiated {
            switch state {
            case .available, .downloading, .downloaded:
                return
            default:
                break
            }
        }

        if !userInitiated,
           let last = defaults.object(forKey: lastCheckKey) as? Date,
           now().timeIntervalSince(last) < throttle {
            return
        }

        state = .checking
        do {
            let release = try await checker.latestRelease()
            defaults.set(now(), forKey: lastCheckKey)
            guard release.version.isNewer(than: currentVersion) else {
                state = userInitiated ? .upToDate : .idle
                return
            }
            if !userInitiated, defaults.string(forKey: skippedTagKey) == release.tagName {
                state = .idle
                return
            }
            state = .available(release)
        } catch {
            if userInitiated {
                Self.logger.error("Update check failed: \(error.localizedDescription, privacy: .public)")
                state = .failed(title: "Update check failed", message: error.localizedDescription)
            } else {
                Self.logger.error("Background update check failed: \(error.localizedDescription, privacy: .public)")
                state = .idle
            }
        }
    }

    func download(_ release: GitHubRelease) async {
        // Only download the release the user was actually shown as available.
        guard case .available(let available) = state, available == release else {
            state = .failed(title: "Download failed", message: "No update is available to download.")
            return
        }
        guard let asset = release.dmgAsset else {
            state = .failed(title: "Download failed", message: "The latest release has no .dmg download.")
            return
        }
        state = .downloading
        do {
            let stash = try await session.downloadCompat(from: asset.downloadURL)
            let downloads = try FileManager.default.url(
                for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true
            )
            let dest = Self.uniqueDestination(in: downloads, fileName: asset.name)
            try FileManager.default.moveItem(at: stash, to: dest)
            state = .downloaded(dest)
            NSWorkspace.shared.activateFileViewerSelecting([dest])
        } catch {
            Self.logger.error("Download failed: \(error.localizedDescription, privacy: .public)")
            state = .failed(title: "Download failed", message: error.localizedDescription)
        }
    }

    func skip(_ release: GitHubRelease) {
        defaults.set(release.tagName, forKey: skippedTagKey)
        state = .idle
    }

    func dismiss() {
        if case .downloading = state { return }
        state = .idle
    }

    /// Avoids clobbering an existing file by suffixing " (1)", " (2)", etc.
    static func uniqueDestination(in directory: URL, fileName: String) -> URL {
        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        var candidate = directory.appendingPathComponent(fileName)
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = ext.isEmpty ? "\(base) (\(counter))" : "\(base) (\(counter)).\(ext)"
            candidate = directory.appendingPathComponent(name)
            counter += 1
        }
        return candidate
    }
}

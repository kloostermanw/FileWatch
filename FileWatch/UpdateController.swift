//
//  UpdateController.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 21/07/2026.
//

import Foundation

/// Orchestrates `UpdateService` and `UpdateAlertPresenter`: a silent check on launch,
/// a repeating background check, and a user-initiated check from the status-bar menu.
@MainActor
final class UpdateController {
    private let service: UpdateService
    private let interval: TimeInterval
    private var periodicTask: Task<Void, Never>?

    init(service: UpdateService? = nil, interval: TimeInterval = 2 * 60 * 60) {
        self.service = service ?? UpdateService(
            defaults: UserDefaults(suiteName: "FileWatch.kloosterman.eu") ?? .standard
        )
        self.interval = interval
    }

    /// Silent check on launch, then repeats on `interval`. Only prompts when an update
    /// is available; up-to-date and failure stay quiet in the background.
    func start() {
        periodicTask?.cancel()
        periodicTask = Task { [weak self] in
            guard let self else { return }
            await self.backgroundCheck()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.interval * 1_000_000_000))
                await self.backgroundCheck()
            }
        }
    }

    /// Triggered from the menu; always reports the outcome (available, up-to-date, or failed).
    func checkForUpdates() {
        Task { [weak self] in
            guard let self else { return }
            await self.service.checkForUpdates(userInitiated: true)
            await UpdateAlertPresenter.present(self.service.state, service: self.service)
        }
    }

    private func backgroundCheck() async {
        await service.checkForUpdates(userInitiated: false)
        if case .available = service.state {
            await UpdateAlertPresenter.present(service.state, service: service)
        }
    }
}

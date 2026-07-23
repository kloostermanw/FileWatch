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
    typealias Presenter = @MainActor (UpdateService.State, UpdateService) async -> Void

    private let service: UpdateService
    private let interval: TimeInterval
    private let present: Presenter
    private var periodicTask: Task<Void, Never>?
    private var checkTask: Task<Void, Never>?

    init(
        service: UpdateService? = nil,
        interval: TimeInterval = 2 * 60 * 60,
        present: @escaping Presenter = { await UpdateAlertPresenter.present($0, service: $1) }
    ) {
        self.service = service ?? UpdateService(
            defaults: UserDefaults(suiteName: "FileWatch.kloosterman.eu") ?? .standard
        )
        self.interval = interval
        self.present = present
    }

    /// Silent check on launch, then repeats on `interval`. Only prompts when an update
    /// is available; up-to-date and failure stay quiet in the background.
    func start() {
        periodicTask?.cancel()
        periodicTask = Task { [weak self] in
            guard let self else { return }
            await self.check(userInitiated: false)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.interval * 1_000_000_000))
                await self.check(userInitiated: false)
            }
        }
    }

    /// Triggered from the menu; always reports the outcome (available, up-to-date, or failed).
    func checkForUpdates() {
        Task { [weak self] in await self?.check(userInitiated: true) }
    }

    /// Runs a check and presents its outcome. Coalesces concurrent calls: if a check is
    /// already running (background loop vs. a menu click, or rapid menu clicks), the second
    /// caller joins the in-flight check instead of starting a second one — so one result
    /// never produces two alerts.
    func check(userInitiated: Bool) async {
        if let checkTask {
            await checkTask.value
            return
        }
        let task = Task { [weak self] in
            guard let self else { return }
            await self.service.checkForUpdates(userInitiated: userInitiated)
            let isAvailable: Bool
            if case .available = self.service.state { isAvailable = true } else { isAvailable = false }
            // User-initiated checks always report; background checks only prompt on an update.
            if userInitiated || isAvailable {
                await self.present(self.service.state, self.service)
            }
        }
        checkTask = task
        await task.value
        checkTask = nil
    }
}

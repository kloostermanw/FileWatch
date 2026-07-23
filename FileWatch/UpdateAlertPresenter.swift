//
//  UpdateAlertPresenter.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 21/07/2026.
//

import AppKit

/// Presents update-related `NSAlert`s driven by `UpdateService.State` and performs
/// the follow-up action the user chooses.
@MainActor
enum UpdateAlertPresenter {
    static func present(_ state: UpdateService.State, service: UpdateService) async {
        switch state {
        case .available(let release):
            let alert = NSAlert()
            alert.messageText = "Update available"
            let notes = release.body.isEmpty ? "" : "\n\n\(release.body)"
            alert.informativeText =
                "FileWatch \(release.version) is available. You have \(AppVersion.current).\(notes)"
            alert.addButton(withTitle: "Download")
            alert.addButton(withTitle: "Skip This Version")
            alert.addButton(withTitle: "Later")
            switch runModal(alert) {
            case .alertFirstButtonReturn:
                await service.download(release)
                await present(service.state, service: service)
            case .alertSecondButtonReturn:
                service.skip(release)
            default:
                service.dismiss()
            }

        case .upToDate:
            info("You are up to date", "FileWatch \(AppVersion.current) is the latest version.")
            service.dismiss()

        case .failed(let title, let message):
            info(title, message)
            service.dismiss()

        case .downloaded:
            info(
                "Download complete",
                "The installer was revealed in Finder. Open it, then drag FileWatch to your Applications folder."
            )
            service.dismiss()

        case .idle, .checking, .downloading:
            break
        }
    }

    private static func info(_ title: String, _ text: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.addButton(withTitle: "OK")
        _ = runModal(alert)
    }

    /// FileWatch is an `LSUIElement` agent app, so bring it forward before a modal.
    private static func runModal(_ alert: NSAlert) -> NSApplication.ModalResponse {
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal()
    }
}

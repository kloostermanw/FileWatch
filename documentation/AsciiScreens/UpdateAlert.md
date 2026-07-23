# Update alerts

Modal `NSAlert`s shown by the in-app updater. The screenshot shows the
**up-to-date** case, reached from **Menu → Check for Updates…**. The same
presenter renders every other update outcome.

## ASCII — "up to date" (the screenshotted case)

```
            ┌───────────────────────────────────────────┐
            │  ┌────┐                                    │
            │  │ 🔍➕│   You are up to date               │  <- messageText
            │  └────┘                                    │
            │          FileWatch 1.2.6 is the            │  <- informativeText
            │          latest version.                   │
            │                                            │
            │                      ┌───────────────────┐ │
            │                      │        OK         │ │  <- addButton "OK"
            │                      └───────────────────┘ │
            └───────────────────────────────────────────┘
```

The icon is the app icon (`search-plus-solid`); `NSAlert` shows it
automatically. The version string is `AppVersion.current`.

## ASCII — "update available" (same presenter, different state)

```
            ┌───────────────────────────────────────────┐
            │  🔍➕  Update available                     │
            │       FileWatch <new> is available.        │
            │       You have <current>. <release notes>  │
            │                                            │
            │   ┌──────────┐ ┌───────────────┐ ┌───────┐ │
            │   │ Download │ │ Skip This Ver.│ │ Later │ │
            │   └──────────┘ └───────────────┘ └───────┘ │
            └───────────────────────────────────────────┘
             Download -> service.download(release)
             Skip     -> service.skip(release)
             Later    -> service.dismiss()
```

## Source

- **Presenter:** `FileWatch/UpdateAlertPresenter.swift` — enum
  `UpdateAlertPresenter`, `static func present(_:service:)`.
- **Orchestration:** `FileWatch/UpdateController.swift` — class
  `UpdateController` (owned by `AppDelegate` as `updates`).
- **Logic / networking:** `FileWatch/UpdateService.swift` — class
  `UpdateService` with `enum State`.
- **Version comparison:** `FileWatch/AppVersion.swift`.
- **Release model / fetch:** `GitHubRelease.swift`, `ReleaseChecking.swift`.

## State → alert mapping (`UpdateService.State`)

| State | Alert title | Buttons |
|-------|-------------|---------|
| `.available(release)` | "Update available" | Download / Skip This Version / Later |
| `.upToDate` | "You are up to date" | OK  ← *screenshot* |
| `.failed(title, message)` | `title` | OK |
| `.downloaded(url)` | "Download complete" | OK (installer revealed in Finder) |
| `.idle`, `.checking`, `.downloading` | (no alert) | — |

## Who triggers a check, and whether it shows

- **Menu click** → `AppDelegate.checkForUpdates()` →
  `UpdateController.checkForUpdates()` → `check(userInitiated: true)`.
  Always reports the outcome (available, up-to-date, *or* failed).
- **On launch + every 2 hours** → `UpdateController.start()` →
  `check(userInitiated: false)`. Silent unless an update is available
  (up-to-date and failures stay quiet in the background).
- Concurrent checks are **coalesced** in `UpdateController.check`: a
  second caller joins the in-flight check, so one result never produces
  two alerts.

## Behaviour notes

- FileWatch is an `LSUIElement` agent app, so `runModal` first calls
  `NSApp.activate(ignoringOtherApps: true)` to bring the alert forward.
- Choosing **Download** runs `service.download(release)` then re-presents
  the resulting state (e.g. `.downloaded` → "Download complete").
- **Skip This Version** records the version so the background loop won't
  prompt for it again; **Later** just dismisses.

## To change something

- **Wording / buttons of an alert:** edit the matching `case` in
  `UpdateAlertPresenter.present`.
- **Check frequency:** `interval` in `UpdateController.init` (default
  `2 * 60 * 60`).
- **When background checks prompt:** the `userInitiated || isAvailable`
  guard in `UpdateController.check`.

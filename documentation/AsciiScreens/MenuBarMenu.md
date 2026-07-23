# Menu-bar menu

The dropdown shown when the user clicks the FileWatch icon in the macOS
status bar. This is the app's only always-available entry point; every
other screen is opened from here.

## ASCII

```
 (menu-bar)  🔍➕            <- status-bar icon (statusItem.button)
            ┌───────────────────────────┐
            │ Latest message            │  -> showMessage()      -> MessagePopover
            │ Settings                  │  -> showSettings()     -> SettingsPopover
            │ Check for Updates…        │  -> checkForUpdates()  -> UpdateAlert
            │ Stop application          │  -> exit()             -> terminate app
            └───────────────────────────┘
```

## Source

- **File:** `FileWatch/AppDelegate.swift`
- **Class:** `AppDelegate` (`@main`, `NSApplicationDelegate`)
- Built in `applicationDidFinishLaunching(_:)`.

## Elements

| Element | Symbol | Notes |
|---------|--------|-------|
| Status-bar item | `statusItem` (`NSStatusItem`, `variableLength`) | Lives for the app lifetime. |
| Icon | `statusItem.button?.image` | `NSImage("search-plus-solid")` resized to 18×18, `isTemplate = true` so macOS tints it for light/dark. |
| The menu | `statusBarMenu` (`NSMenu`) | Assigned to `statusItem.menu`. |
| "Latest message" | `#selector(showMessage)` | Instantiates storyboard id `messageID` as `MessageViewController` in a transient `NSPopover` (450×300). |
| "Settings" | `#selector(showSettings)` | Instantiates storyboard id `ViewController` as `ViewController` in a transient `NSPopover`. |
| "Check for Updates…" | `#selector(checkForUpdates)` | Delegates to `updates.checkForUpdates()` (`UpdateController`). Ellipsis is a real `…` character. |
| "Stop application" | `#selector(exit)` | `NSApplication.shared.terminate(self)`. |

## Behaviour notes

- The two popovers use `.behavior = .transient` (close when you click
  away). The message popover can switch itself to `.applicationDefined`
  when pinned — see [MessagePopover.md](MessagePopover.md).
- `updates.start()` is also called here: a silent update check on launch
  plus a repeating background check — see [UpdateAlert.md](UpdateAlert.md).
- Directory monitoring is started here too via `DirectoryMonitor.shared`
  (`setPaths()` then `start()`).

## To change something

- **Add/rename/reorder a menu item:** edit the `statusBarMenu.addItem(...)`
  calls and add a matching `@objc func`.
- **Change the icon:** replace the `search-plus-solid` asset or the
  `NSImage(named:)` name.

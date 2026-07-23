# AsciiScreens

ASCII renderings of FileWatch's screens/views, with the names of the UI
elements and the code behind them. Use these when you want to change a
view: find the element in the sketch, then jump to the symbol named next
to it.

FileWatch is an `LSUIElement` menu-bar (agent) app — it has no dock icon
and no main window. Everything the user sees is reached from the status-bar
menu, and every screen is either an `NSPopover` or an `NSAlert`.

## Screens

| Doc | Screen | Entry point |
|-----|--------|-------------|
| [MenuBarMenu.md](MenuBarMenu.md) | The status-bar dropdown menu | Click the menu-bar icon |
| [SettingsPopover.md](SettingsPopover.md) | Watched-directory list + local/remote mapping | Menu → **Settings** |
| [MessagePopover.md](MessagePopover.md) | Latest / historical log message viewer | Menu → **Latest message** |
| [UpdateAlert.md](UpdateAlert.md) | Update-check result alerts | Menu → **Check for Updates…** (or background check) |

## Conventions used in these docs

- **Element → `symbol`** lines name the exact property, action, or
  storyboard identifier in the source, so a rename in the doc should be
  matched by a rename in code.
- Actions are written as they appear in Swift (`@IBAction func delIssue`)
  or as `#selector` targets.
- UserDefaults everywhere uses the suite name `FileWatch.kloosterman.eu`.

## Shared persistence (UserDefaults suite `FileWatch.kloosterman.eu`)

| Key | Type | Written by | Read by |
|-----|------|-----------|---------|
| `directory` | `[[String:String]]` (keys: `directory`, `count`, `enable`, `local`, `remote`) | `ViewController` | `ViewController`, `DirectoryMonitor`, `MessageViewController` |
| `lastMessage` | `[String]` | `DirectoryMonitor.saveLastMessage` | `MessageViewController` |
| `lastFilePath` | `String` | `DirectoryMonitor.saveLastMessage` | `MessageViewController` |
| `messageHistory` | `[[String]]` | `DirectoryMonitor`, `MessageViewController` | `MessageViewController` |

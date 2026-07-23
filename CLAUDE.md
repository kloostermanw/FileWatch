# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Run Commands
- Build: `xcodebuild -project FileWatch.xcodeproj -scheme FileWatch build`
- Run: `xcodebuild -project FileWatch.xcodeproj -scheme FileWatch run`
- Clean: `xcodebuild -project FileWatch.xcodeproj -scheme FileWatch clean`

## Architecture Overview
This is a macOS file monitoring application that watches directories for changes and sends notifications:

- **FileWatch.swift**: Core FSEvent wrapper class providing Swift-friendly interface to macOS FSEvents
- **DirectoryMonitor.swift**: Singleton managing file system monitoring using EonilFSEvents library
- **ViewController.swift**: Main UI controller for directory management (add/remove/configure watched paths)
- **MessageViewController.swift**: UI for displaying file change notifications and history
- **CustomTableCell.swift**: Custom table cell for directory list display
- **Packages/EonilFSEvents/**: Local Swift package vendoring EonilFSEvents 0.1.7 (upstream github.com/eonil/FSEvents was deleted); referenced as a local package, not a remote dependency

## Key Components
- **Data Persistence**: Uses UserDefaults with suite name "FileWatch.kloosterman.eu"
- **Directory Monitoring**: FSEvents-based real-time file system monitoring
- **Notifications**: macOS UserNotifications framework for file change alerts
- **UI Pattern**: Cocoa AppKit with storyboard-based interface

## Documentation — keep it in sync
The `documentation/` folder documents how the app works and how its UI elements
are named. **Whenever you change the application, update the documentation in the
same change** so it never drifts from the code.

- `documentation/AsciiScreens/`: one Markdown file per screen/view, with an ASCII
  rendering and the backing symbol names (classes, `@IBOutlet`s, actions,
  storyboard identifiers, UserDefaults keys). See its `README.md` for the index.
- When you add, rename, remove, or restyle a view or UI element — or change a
  persisted UserDefaults key — update the matching doc (and the README index /
  shared-keys table). Adding a new screen means adding a new `.md` file.

## Code Style Guidelines
- **Imports**: Import specific frameworks only (Foundation, Cocoa, EonilFSEvents)
- **Formatting**: Use 4-space indentation, no trailing whitespace
- **Types**: Use Swift's strong typing system; explicitly declare property types
- **Naming**:
  - Use camelCase for variables/properties
  - Use PascalCase for classes/structs/enums
  - Prefix class properties with `obj` (e.g., `objUserDefaults`)
- **Error Handling**: Use `do/catch` blocks with specific error handling
- **Comments**: Include header comments for all files with creation date and author
- **Extensions**: Use extensions for protocol conformance
- **Memory Management**: Properly handle FSEvent stream lifecycle (start/stop/invalidate)
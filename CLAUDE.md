# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Run Commands
- Build: `xcodebuild -project FileWatch.xcodeproj -scheme FileWatch build`
- Run: `xcodebuild -project FileWatch.xcodeproj -scheme FileWatch run`
- Clean: `xcodebuild -project FileWatch.xcodeproj -scheme FileWatch clean`

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
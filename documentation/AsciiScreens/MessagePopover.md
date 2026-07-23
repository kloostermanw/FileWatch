# Message popover ("Latest message")

Reached from **Menu → Latest message**. Shows the most recent captured log
message and lets the user page back and forth through message history,
pin the popover open, and click file paths to open them in PhpStorm.

## ASCII

```
        ┌──────────────────────────────────────────────────────┐
        │ ┌─────┐                       ┌────────┐ ┌──────────┐ │
        │ │ Pin │                       │ < Prev │ │  Next >  │ │  <- controlsView
        │ └─────┘                       └────────┘ └──────────┘ │
        ├──────────────────────────────────────────────────────┤ ┐
        │ [2026-07-23T08:10:54] application.NOTICE: Failed to  ▲│ │
        │ resize cached image /var/www/.../temp_.png.          ││ │
        │ {"exception":"[object] ... Unable to decode input at ││ │ messageTextView
        │ /var/www/.../InputHandler.php:104)                   ││ │ (inside a scrollView)
        │                                                      ││ │
        │ [stacktrace]                                         ││ │  .php:line spans are
        │ #0 /var/www/.../AbstractDriver.php(56): ...          ││ │  red + clickable links
        │ #1 /var/www/.../ImageManager.php(87): ...            ▼│ │
        │                                                    ◣ │ │  <- resizeHandle
        └──────────────────────────────────────────────────────┘ ┘
```

## Source

- **File:** `FileWatch/MessageViewController.swift`
- **Classes:**
  - `MessageViewController` (`NSViewController`, `NSTextViewDelegate`) —
    the whole view is built programmatically in `loadView()` (no storyboard
    layout), though the scene has storyboard identifier `messageID`.
  - `ResizeHandleView` (`NSView`) — the bottom-right drag handle.

## Elements

| Element | Symbol | Action / behaviour |
|---------|--------|--------------------|
| Top control bar | `controlsView` (`NSView`) | Fixed 40 px strip across the top. |
| "Pin" / "Unpin" | `pinButton` (`NSButton`, toggle) | `@objc togglePin(_:)` — switches popover between `.transient` and `.applicationDefined` (stays open); title/colour toggle. |
| "< Prev" | `prevButton` (`NSButton`) | `@objc showPreviousMessage(_:)` — `currentMessageIndex -= 1`. |
| "Next >" | `nextButton` (`NSButton`) | `@objc showNextMessage(_:)` — `currentMessageIndex += 1`. |
| Scrolling text area | `messageTextView` (`NSTextView`) in an `NSScrollView` | Read-only, selectable; white text on `textBackgroundColor`. |
| Resize handle | `resizeHandle` (`ResizeHandleView`) | Drag to resize popover; min size 300×200. Cursor becomes crosshair on hover. |

## Message data

| Piece | Source |
|-------|--------|
| Current message text | `messageHistory[currentMessageIndex]` (UserDefaults `messageHistory`) |
| Newest message on open | UserDefaults `lastMessage`, appended to history if new |
| File path for mapping lookup | UserDefaults `lastFilePath` |
| local/remote prefixes | matched from the `directory` entries via `find(value:in:)` |

State held on the controller: `messageHistory: [[String]]`,
`currentMessageIndex: Int`, `isPinned: Bool`, `local`/`remote: String`,
`weak var popover: NSPopover?` (set by `AppDelegate.showMessage`).

## Behaviour notes

- **Link rewriting** (`reFormatText(_:)`): spans matching
  `/…/<file>.php(<line>)` (or `:line`) are coloured `systemRed` and turned
  into clickable links. The link's path prefix is rewritten from `remote`
  to `local` so a server path maps to your checkout.
- **Opening a link** (`textView(_:clickedOnLink:at:)`): runs
  `/usr/bin/open -na PhpStorm.app --args --line <line> <path>`. The IDE is
  hard-coded to PhpStorm.
- `[stacktrace]` markers get a preceding newline inserted for readability.
- Navigation buttons enable/disable via `updateNavigationButtons()`:
  Prev off at index 0, Next off at the last message.
- Popover initial size is 450×300 (set in `AppDelegate.showMessage`).

## To change something

- **IDE for links:** change the `PhpStorm.app` / args in
  `textView(_:clickedOnLink:at:)`.
- **What counts as a clickable path:** edit the regex in `reFormatText`.
- **Button labels / layout:** edit `loadView()` (frames + Auto Layout
  constraints are all there).
- **Min resize size:** the `max(300, …)` / `max(200, …)` in `startResize`.

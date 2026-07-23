# Settings popover

Reached from **Menu → Settings**. Lets the user manage the list of watched
directories and edit the `local`/`remote` path mapping used to rewrite
file paths in log messages.

> The whole view is built **programmatically** in `ViewController.loadView()`
> (like `MessageViewController`). The `Main.storyboard` "ViewController" scene
> exists only so `AppDelegate.showSettings` can instantiate it by identifier;
> its storyboard view tree is not used.

## ASCII

```
        MONITORED FOLDERS                       4 folders · 3 active   <- summaryLabel
        ┌──────────────────────────────────────────────────────┐
        │ ☑  📁 celery-web-app                    ( 12 )   🗑    │  } directoryTableView
        │ ☑  📁 celery-web-api                    (  0 )   🗑    │  } (one DirectoryRowView
        │ ☑  📁 celery-control-panel              (  3 )   🗑    │  }  per row)
        │ ☐  📁 celery-web-app-dev1  (dimmed)     (  —  )  🗑    │  }
        │      …/wiebe/repos/celery-web-app-dev1/src/logs/       │
        └──────────────────────────────────────────────────────┘
        ┌──────────────────────────────────────────────────────┐
        │  +  Add folder to monitor…                            │  -> addDirectory
        └──────────────────────────────────────────────────────┘
        ────────────────────────────────────────────────────────
        PATH MAPPING
        Log messages reference paths on the remote server. FileWatch
        rewrites the remote prefix to your local checkout …            <- help text

        Remote path prefix
        ┌──────────────────────────────────────────────────────┐
        │ FROM  /var/www/vhosts/application/src                 │  <- remoteField
        └──────────────────────────────────────────────────────┘
        Local path prefix
        ┌──────────────────────────────────────────────────────┐
        │ TO    /Users/wiebe/repos/celery-web-app/src           │  <- localField
        └──────────────────────────────────────────────────────┘
                                     ┌──────────┐ ┌─────────────┐
                                     │  Cancel  │ │ Save mapping│  -> cancel / saveMapping
                                     └──────────┘ └─────────────┘

Per-row cell (DirectoryRowView):
   ☑            📁          <name>              (count)   🗑
   checkbox   folderIcon  nameLabel/pathLabel   pill      trash
   -> toggleEnabled                                       -> deleteRow
```

## Source

- **Controller:** `FileWatch/ViewController.swift` — class `ViewController`
  (`NSViewController`, `NSTableViewDelegate`, `NSTableViewDataSource`).
- **Row cell:** `DirectoryRowView` (`NSTableCellView`, identifier
  `"DirectoryRowView"`) — in the same file.
- **Support views (same file):** `PillView` (activity badge),
  `HoverTintButton` (hover-reddening trash), `AppearanceForwardingView`
  (root view; forwards light/dark changes), `SettingsPalette` (dynamic
  light/dark chrome colors).
- **Monitoring side-effects:** `FileWatch/DirectoryMonitor.swift`.
- **Opened by:** `AppDelegate.showSettings` (sets `vc.popover`).

## Elements

| Element | Symbol | Backing data / action |
|---------|--------|-----------------------|
| Summary line | `summaryLabel` (`NSTextField`) | `"<n> folders · <m> active"`, set in `refreshList()`. |
| Directory table | `directoryTableView` (`NSTableView`) | Rows from `arrDirectory` (`[[String:String]]`), inside a rounded card (`listCard`) whose height is `listHeight`. |
| Row enable checkbox | `DirectoryRowView.checkbox` | Action `@objc toggleEnabled(_:)` sets `arrDirectory[row]["enable"]` to `"1"`/`"0"`. |
| Row folder glyph | `DirectoryRowView.folderIcon` | SF Symbol `folder.fill`, accent-tinted; dims when the row is disabled. |
| Row name | `DirectoryRowView.nameLabel` | Derived repo name via `displayName(for:)`; bold; dims when disabled. |
| Row path | `DirectoryRowView.pathLabel` | Full path, monospaced, `~`-collapsed, head-truncated so the tail stays visible. |
| Row activity pill | `DirectoryRowView.pill` (`PillView`) | `arrDirectory[row]["count"]`; accent when `> 0`, grey at `0`, `—` when disabled. |
| Row trash button | `DirectoryRowView.trash` (`HoverTintButton`) | Action `@objc deleteRow(_:)`; hidden-ish until row hover, turns red on hover. |
| "Add folder to monitor…" | `@objc addDirectory()` | `NSOpenPanel` (directories only); appends to `arrDirectory` and selects the new row. |
| Help text | (wrapping `NSTextField`) | Explains the remote→local rewrite. |
| "Remote path prefix" field | `remoteField` (`NSTextField`) | Editable `remote` value for the selected row (tag `FROM`). |
| "Local path prefix" field | `localField` (`NSTextField`) | Editable `local` value for the selected row (tag `TO`). |
| "Cancel" | `@objc cancel()` | Closes the popover without saving the mapping edits. |
| "Save mapping" | `@objc saveMapping()` | Writes `remote`/`local` into `arrDirectory[selectedRow]`, persists, closes. Default (accent) button. |
| (selection tracking) | `selectedRow`, `tableViewSelectionDidChange(_:)` → `loadMapping(for:)` | Loads the selected row's `remote`/`local` into the fields. |

## Data model — `arrDirectory` entry

Each row is a dictionary persisted under UserDefaults key `directory`:

```
["directory": "/abs/path/",   // watched folder
 "count":     "0",            // shown in the activity pill (currently always "0")
 "enable":    "1",            // "1" watched, "0" paused
 "local":     "/",            // local path prefix (link rewriting)
 "remote":    "/"]            // remote path prefix (link rewriting)
```

The `local`/`remote` pair is consumed by [MessagePopover.md](MessagePopover.md)
to turn remote server paths in a log line into clickable local paths.

## Behaviour notes

- Add, delete, and checkbox toggle each persist immediately
  (`objUserDefaults?.setValue(arrDirectory, forKey: "directory")`) and call
  `restartMonitoring()` (`DirectoryMonitor` `setPaths()`→`stop()`→`start()`).
  **Cancel**/**Save mapping** only affect the mapping fields.
- `selectedRow` may be `-1` when nothing is selected; `loadMapping` and
  `saveMapping` bounds-check it before indexing `arrDirectory`.
- The activity pill is **display-only** — nothing increments `count` today,
  so it renders `0` for every folder until that is wired up.
- Chrome colors (`SettingsPalette`) resolve per light/dark; `CALayer` fills
  are re-tinted via `resolvedCGColor(_:_:)` on layout and on appearance change.
- The popover is `.transient` — clicking outside closes it.

## To change something

- **Row layout / add an element:** edit `DirectoryRowView` (init builds the
  stack; `configure(dict:showTopDivider:)` fills it).
- **What a control does:** edit the matching `@objc` action in `ViewController`.
- **Derived folder name:** `DirectoryRowView.displayName(for:)`.
- **Make the count real:** increment per-folder `count` in
  `DirectoryMonitor` and refresh the list (out of scope for the visual
  redesign; see the pill note above).
- **Change the persisted shape:** update every reader/writer of the
  `directory` key (see the table in [README.md](README.md)).

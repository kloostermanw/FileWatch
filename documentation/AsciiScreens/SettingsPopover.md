# Settings popover

Reached from **Menu → Settings**. Lets the user manage the list of watched
directories and edit the `local`/`remote` path mapping used to rewrite
file paths in log messages.

## ASCII

```
        ┌──────────────────────────────────────────────────────┐
        │ ☑  …/wiebe/repos/celery-web-app/src/logs/     0   🗑  │  } directoryTableView
        │ ☑  …/repos/celery-web-api/src/storage/logs/   0   🗑  │  } (one CustomTableCell
        │ ☑  …/celery-control-panel/src/storage/logs/   0   🗑  │  }  per row, prototype
        │ ☑  …e/repos/celery-web-app-dev1/src/logs/     0   🗑  │  }  id "userCell")
        ├──────────────────────────────────────────────────────┤
        │              Add directory to monitor                 │  -> AddButton
        ├──────────────────────────────────────────────────────┤
        │ local                                                 │
        │ ┌──────────────────────────────────────────────────┐ │
        │ │ local                                            │ │  <- `local` field
        │ └──────────────────────────────────────────────────┘ │
        │ remote                                                │
        │ ┌──────────────────────────────────────────────────┐ │
        │ │ remote                                  ┌────────┐│ │  <- `remote` field
        │ └─────────────────────────────────────────│  Save  ││ │  -> SaveMapping
        │                                           └────────┘│ │
        └──────────────────────────────────────────────────────┘

Per-row cell (CustomTableCell):
   ☑           <checkbox>          <count>      🗑
   enableCheckBox  DirectoryLabel  countLabel   <trash button>
   -> checkIssue                                -> delIssue
```

## Source

- **Controller:** `FileWatch/ViewController.swift` — class `ViewController`
  (`NSViewController`, `NSTableViewDelegate`, `NSTableViewDataSource`).
- **Row cell:** `FileWatch/CustomTableCell.swift` — class `CustomTableCell`
  (`NSTableCellView`), prototype identifier `userCell`.
- **Layout:** `FileWatch/Base.lproj/Main.storyboard` — scene instantiated
  by identifier `ViewController`.
- **Monitoring side-effects:** `FileWatch/DirectoryMonitor.swift`.

## Elements

| Element | Symbol | Backing data / action |
|---------|--------|-----------------------|
| Directory table | `directoryTableView` (`NSTableView`) | Rows come from `arrDirectory` (`[[String:String]]`). |
| Row checkbox | `enableCheckBox` on `CustomTableCell` | Action `@IBAction func checkIssue(_:)` toggles `arrDirectory[row]["enable"]` between `"1"`/`"0"`. |
| Row path label | `DirectoryLabel` (`NSTextField`) | `arrDirectory[row]["directory"]`; truncates head (`.byTruncatingHead`). |
| Row count | `countLabel` (`NSTextField`) | `arrDirectory[row]["count"]`. |
| Row trash button | (storyboard button, id `EeX-nM-Upx`) | Action `@IBAction func delIssue(_:)` removes the row. |
| "Add directory to monitor" | `@IBAction func AddButton(_:)` | Opens `NSOpenPanel` (directories only), appends a new entry to `arrDirectory`. |
| "local" field | `local` (`NSTextFieldCell`) | Editable mapping value for the selected row. |
| "remote" field | `remote` (`NSTextFieldCell`) | Editable mapping value for the selected row. |
| "Save" button | `@IBAction func SaveMapping(_:)` | Writes `local`/`remote` into `arrDirectory[selectedRow]`. |
| (selection tracking) | `selectedRow`, `tableViewSelectionDidChange(_:)` | Loads the selected row's `local`/`remote` into the fields. |

## Data model — `arrDirectory` entry

Each row is a dictionary persisted under UserDefaults key `directory`:

```
["directory": "/abs/path/",   // watched folder
 "count":     "0",            // shown in the count column
 "enable":    "1",            // "1" watched, "0" paused
 "local":     "/",            // local path prefix (link rewriting)
 "remote":    "/"]            // remote path prefix (link rewriting)
```

The `local`/`remote` pair is consumed by [MessagePopover.md](MessagePopover.md)
to turn remote server paths in a log line into clickable local paths.

## Behaviour notes

- Add, delete, checkbox toggle, and Save each call
  `objUserDefaults?.setValue(arrDirectory, forKey: "directory")` to persist.
- `checkIssue` and `delIssue` also call `reload()`, which restarts
  `DirectoryMonitor` with the new set of enabled paths
  (`setPaths()` → `stop()` → `start()`).
- `selectedRow` may be `-1` when nothing is selected (e.g. right after a
  deletion); `tableViewSelectionDidChange` and `SaveMapping` bounds-check
  it before indexing `arrDirectory` to avoid an index-out-of-range crash.
- The popover is `.transient` — clicking outside closes it.

## To change something

- **Row layout / add a column:** edit the `userCell` prototype in
  `Main.storyboard` and the outlets in `CustomTableCell`, then update
  `tableView(_:viewFor:row:)`.
- **Change what a button does:** edit the matching `@IBAction` in
  `ViewController`.
- **Change the persisted shape:** update every reader/writer of the
  `directory` key (see the table in [README.md](README.md)).

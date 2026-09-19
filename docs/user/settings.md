# Settings reference

Two levels. Library settings travel with the folder
(`<library>/.niman/settings.json`, hand-editable, unknown keys
preserved); app settings (language, theme, layout, debug log) stay on the
device.

## The Settings screen

Settings is split into areas, grouped by what they change: **App**
(appearance, editor, keyboard shortcuts, commands, updates, diagnostics),
the open **Library** (folders, trash and history, sync, transcription,
reminders), and **Maintenance** (re-index, switch or close the library;
in the settings window only re-index, since the rail's library window
switches and closes).
The search at the top looks through the settings themselves, not only
the area names, and takes you to the row it found.

- **Wide windows** (desktop, tablets, phones in landscape): Settings
  opens as a floating window over the note, from the gear at the foot of
  the rail or its key, and closes back to it. The note, its tabs and the
  tree stay where they were. `Esc` or a click outside closes it; from a
  screen an area opened, `Esc` steps back first. Inside are two columns:
  the search and the areas on the left, the selected area on the right,
  so nothing navigates. What an area opens, such as the toolbar
  arrangement or the trash, stays in the window with a way back. A
  search result shows its row on the right and flashes it; the results
  stay, one click from the next. The window is at most 960 × 680 and
  shrinks with a small window.
- **Phones**: the list of areas, each opening a screen of its own.

Every setting reads the same on both: its name, a line saying what it
does, and the control under that. A switch flips in place; anything with
more than two choices shows its current value in a field that opens the
choices.

## Library settings (`LibraryConfig`)

| Key | Default | Meaning |
|-----|---------|---------|
| `trashEnabled` | true | Deletes move to `.trash/`; false = hard delete |
| `trashAutoEmptyDays` | 0 (= never) | Days an item waits in `.trash/` before the library opening deletes it for good (1–3650; anything else reads as never) |
| `historyVersions` | 10 | Kept `.history/` versions per note (0–100, 0 = none) |
| `historyIntervalMinutes` | 5 | Least minutes between two versions kept while editing (1–60) |
| `quickNotePath` | null (= `Quick note.md` at root) | Quick-note target, library-relative |
| `listNoteFolder` | `Lists` | Where new list notes go |
| `templateFolder` | `Templates` | Where note templates live |
| `attachmentsFolder` | `assets` | Where copied-in images and voice clips live, under the library root |
| `editorKind` | `source` | `source` or `wysiwyg` |
| `enabledEditors` | both | Which editors the settings screen offers (never none) |
| `previewEnabled` | true | Whether the preview exists at all |
| `linkType` | `wikilink` | What the link button inserts (`wikilink` or `markdown`) |
| `missingNoteLocation` | `currentFolder` | Where a note created from a dead link lands (`libraryRoot` or `currentFolder`) |
| `treeSort` | `nameAsc` | Tree order (`nameAsc`, `nameDesc`) |
| `pinnedCollapsed` | false | Tree's pinned section rolled up |
| `lineNumbers` | true | Editor row-number column |
| `readableLineLength` | true | Keep a note's text in a centred column |
| `noteColumnWidth` | 700 | That column's text width, px (480–1400, clamped) |
| `typewriter` | false | Keep the line being written in the middle of the editor |
| `editorAutofocus` | false | Raise the keyboard on note open |
| `indentWidth` | 2 | Spaces per indent (2–8, clamped) |
| `editorToolbar` | "" (= shipped) | Arranged toolbar layout |
| `uiTextScale` | 1.0 | Interface text size (0.8–1.8) |
| `noteTextScale` | 1.0 | Note text size, editor + preview (0.8–1.8) |
| `treeWidth` | 340 | Tree pane width, px (200–600) |
| `spellDictionaries` | [] (= locale default) | hunspell dictionaries, selection order |
| `reminderShowTokens` | false | Keep `+`/`@`/`#` markers in reminder notifications |

The three folder keys — `listNoteFolder`, `templateFolder`,
`attachmentsFolder` — are paths under the library root, created the
first time something is written there. Their picker lists the folders
the library actually holds, so a default naming one it has never had
(`assets`, until an image or a voice clip is copied in) starts out
unselected: *New folder* then builds it at the library root, and only
nests it inside a folder you selected yourself.

A missing, unreadable, or malformed file reads as defaults — it never
takes the app down. Writes are atomic (temp file + rename).

## App settings (on device)

Brightness (day / night / system) × palette (system or Catppuccin),
preview layout (`auto` = split at ≥ 600 dp, or `fullScreen`), split
ratio (0.2–0.8, default 0.55), UI language, last opened library, debug
log toggle (default on).

### Sync

**Sync → WebDAV** holds the open library's sync destination: folder
address, user, the password (in the device keychain), what the server
can do, when to sync (automatically, how often to check the server,
Wi-Fi only on phones), and Disconnect. It is per library *and* per device — not in
`settings.json`, so a copied folder never starts syncing into the
original's server. See [sync.md](sync.md).

### Updates

`Automatic updates` (default off) checks GitHub Releases shortly after
launch and then every 6 hours, quietly: a failure (offline, no network)
is a skipped check, never an error dialog. When a newer release is
found, a banner offers the download:

- Android: downloads the `.apk` into the app folder and opens the system installer — confirm there, including the per-app "unknown apps" allowlist.
- Windows: downloads the setup `.exe` and launches the installer.
- Linux: downloads the installed variant (AppImage, `.tar.gz`, Arch
  package) into Downloads; when the variant cannot be detected, the
  release's Linux assets are listed instead.

`Check for updates` runs the same check on demand and downloads
immediately when newer; it works even with automatic updates off.

The last section, **About**, holds two read-only facts about the
installation: the app's own **Version**, and **Changelog**, which opens
the full list of shipped versions, newest first. The same changelog
appears as a dialog on the first launch after an update, listing only
what is new since the version you last saw.

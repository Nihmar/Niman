# Settings reference

Two levels. Library settings travel with the folder
(`<library>/.niman/settings.json`, hand-editable, unknown keys
preserved); app settings (language, theme, layout, debug log) stay on the
device.

## Library settings (`LibraryConfig`)

| Key | Default | Meaning |
|-----|---------|---------|
| `trashEnabled` | true | Deletes move to `.trash/`; false = hard delete |
| `historyVersions` | 10 | Kept `.history/` versions per note (0–100, 0 = none) |
| `historyIntervalMinutes` | 5 | Least minutes between two versions kept while editing (1–60) |
| `quickNotePath` | null (= `Quick note.md` at root) | Quick-note target, library-relative |
| `listNoteFolder` | `Lists` | Where new list notes go |
| `templateFolder` | `Templates` | Where note templates live |
| `attachmentsFolder` | `assets` | Where copied-in images and voice clips live |
| `editorKind` | `source` | `source` or `wysiwyg` |
| `enabledEditors` | both | Which editors the settings screen offers (never none) |
| `previewEnabled` | true | Whether the preview exists at all |
| `linkType` | `wikilink` | What the link button inserts (`wikilink` or `markdown`) |
| `treeSort` | `nameAsc` | Tree order (`nameAsc`, `nameDesc`) |
| `pinnedCollapsed` | false | Tree's pinned section rolled up |
| `lineNumbers` | true | Editor row-number column |
| `editorAutofocus` | false | Raise the keyboard on note open |
| `indentWidth` | 2 | Spaces per indent (2–8, clamped) |
| `editorToolbar` | "" (= shipped) | Arranged toolbar layout |
| `uiTextScale` | 1.0 | Interface text size (0.8–1.8) |
| `noteTextScale` | 1.0 | Note text size, editor + preview (0.8–1.8) |
| `treeWidth` | 340 | Tree pane width, px (200–600) |
| `spellDictionaries` | [] (= locale default) | hunspell dictionaries, selection order |
| `reminderShowTokens` | false | Keep `+`/`@`/`#` markers in reminder notifications |

A missing, unreadable, or malformed file reads as defaults — it never
takes the app down. Writes are atomic (temp file + rename).

## App settings (on device)

Brightness (day / night / system) × palette (system or Catppuccin),
preview layout (`auto` = split at ≥ 600 dp, or `fullScreen`), split
ratio (0.2–0.8, default 0.55), UI language, last opened library, debug
log toggle (default on).

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

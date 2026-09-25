# Settings reference

Three levels. Library settings travel with the folder
(`<library>/.niman/settings.json`, hand-editable, unknown keys
preserved). How a library looks on this screen — the tree's width, the
text size, the editor and its toggles — is per library too, but kept on
the device, so a phone and a desktop each keep their own. App settings
(language, theme, layout, debug log) stay on the device for every
library.

## The Settings screen

Settings is split into areas, grouped by what they change: **App**
(appearance, themes, editor, keyboard shortcuts, commands, updates,
diagnostics),
the open **Library** (folders, journal, trash and history, sync, transcription,
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

These describe the library itself, and travel with it (and with the
sync) in `.niman/settings.json`.

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
| `annotationsFolder` | `Annotations` | Where a note annotating a PDF or a book is made, when the file has none yet (see [organization](organization.md)) |
| `linkType` | `wikilink` | What the link button inserts (`wikilink` or `markdown`) |
| `missingNoteLocation` | `currentFolder` | Where a note created from a dead link lands (`libraryRoot` or `currentFolder`) |
| `indentWidth` | 2 | Spaces per indent (2–8, clamped) |
| `tidyOnClose` | true | Tidy the Markdown of a note closed after an edit (**Settings → Editor → Tidy the Markdown on close**); notes over 4 MB are left as they are |
| `spellDictionaries` | [] (= locale default) | hunspell dictionaries, selection order |
| `reminderShowTokens` | false | Keep `+`/`@`/`#` markers in reminder notifications |
| `journalFolder` | `Journal` | Where the [journal](journal.md)'s entries go (empty = the root) |
| `journalEntryName` | `YYYY/MM/YYYY-MM-DD` | An entry's name: `YYYY` `MM` `M` `DD` `D`, `/` for a folder, `'quoted'` text |
| `journalTemplate` | none (= a heading with the date) | The template an entry is made from, library-relative |
| `journalDayStart` | 0 | The hour a new day begins (0–6): at 4, until four in the morning is still yesterday |

## Library settings kept on this device

Per library, but in the app's own storage rather than the folder: what
suits a desktop's wide window does not suit a phone. The first time a
library is opened by a version with this split, the device takes these
values from `settings.json`; after that, it keeps its own, and they
leave the file at its next write.

| Key | Default | Meaning |
|-----|---------|---------|
| `editorKind` | `source` | `source` or `wysiwyg` |
| `enabledEditors` | both | Which editors the settings screen offers (never none) |
| `treeSort` | `nameAsc` | Tree order (`nameAsc`, `nameDesc`) |
| `pinnedCollapsed` | false | Tree's pinned section rolled up |
| `lineNumbers` | true | Editor row-number column |
| `readableLineLength` | true | Keep a note's text in a centred column |
| `noteColumnWidth` | 700 | That column's text width, px (480–1400, clamped) |
| `typewriter` | false | Keep the line being written in the middle of the editor |
| `editorAutofocus` | false | Raise the keyboard on note open |
| `editorToolbar` | "" (= shipped) | Arranged toolbar layout |
| `uiTextScale` | 1.0 | Interface text size (0.8–1.8) |
| `noteTextScale` | 1.0 | Note text size, editor + preview (0.8–1.8); the list and quote columns, the spacing, the bullets, checkboxes and numbers grow with it |
| `treeWidth` | 340 | Tree pane width, px (200–600) |
| `epubTheme` | none (= the app's) | The theme the EPUB books wear: a theme id, a shipped one or `custom:…` |
| `epubBrightness` | none (= the app's) | The books' brightness: `system`, `day` or `night` |
| `epubFont` | `literata` | The books' face: `literata`, `serif`, `sans` or `mono` |
| `epubTextScale` | 1.0 | The books' text size (0.8–1.8) |

The four folder keys — `listNoteFolder`, `templateFolder`,
`attachmentsFolder`, `annotationsFolder` — are paths under the library
root, created the first time something is written there. Their picker lists the folders
the library actually holds, so a default naming one it has never had
(`assets`, until an image or a voice clip is copied in) starts out
unselected: *New folder* then builds it at the library root, and only
nests it inside a folder you selected yourself.

A missing, unreadable, or malformed file reads as defaults — it never
takes the app down. Writes are atomic (temp file + rename).

## App settings (on device)

Brightness (day / night / system) and the theme the app wears are on
**Themes** (below); UI language, last opened library, debug log toggle
(default on), the keyboard shortcuts and the formatting keys, the
commands pinned in the palette, and — on the desktops — *Close to the
tray* (default on: the window's × hides Niman and leaves it running).

### Themes

The app's colors have their own area: **Settings → Themes**. Brightness —
day, night, or whatever the device says — is its first row, and under it
sit the themes, each with its colors in front of you: the palettes Niman
ships (System, Niman, Catppuccin, Solarized, Gruvbox) and the themes of
your own.

Making one, editing its colors, renaming it, deleting it, exporting it
into a `.json` file and importing one back are all there. The whole story
is in [themes.md](themes.md); the themes do not live in the library — they
are the installation's, so a copied folder does not carry them.

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
the full list of shipped versions, newest first. Each entry's bullets are
Markdown — their bold, code and links read as they would in a note. The
same changelog appears as a dialog on the first launch after an update,
listing only what is new since the version you last saw. Beside them, the **Markdown
cheatsheet**: every construct Niman reads, written and shown (see
[editing](editing.md#markdown-support)); from here its examples are
copied, since no note is open to insert them in.

# Changelog

All notable changes to Niman, newest version first.

This file ships inside the build and feeds the in-app changelog (the
launch dialog after an update and the screen under Settings → About).
Update it in the release commit, before the tag.

## [0.0.7] - 2026-09-18

### Added
- **Count a list**: the editor toolbar's new **Tools** button turns a list into a checklist of totals — a page of `Alessandro - cappuccino, brioche` becomes `- [ ] cappuccino: 2`, ready to tick off at the counter. It shows which list it is about to count and exactly what it would write before writing it, reads each row the way you tell it to, and run again after the list changes it replaces what it wrote rather than adding a second block — keeping the totals you had already ticked. Both editors, same result
- Enter carries a list on in the source editor: the next line starts with the same marker, a numbered list counts on, a task item gives you a fresh empty box, and Enter on an item you have not typed anything into ends the list. The WYSIWYG always did this
- The trash can empty itself: a library can be told how many days a deletion may sit before it goes for good, checked when the library opens. Off in a fresh library, and off whenever the setting cannot be read — it is permission to delete notes permanently
- Settings search: type a word and the matching rows come back with the area they live in
- A note's row menu on desktop can show the file in the file manager, or hand the `.md` to whatever your system opens Markdown with
- An Android testing build that installs beside the normal app — its own application ID, "Niman (Testing)" on the launcher — release-equivalent, with update management switched off

### Changed
- **A note opens as a page, not a tab.** On a phone the tab bar no longer sits under the note: back is the app bar's arrow and it lands on the tab the note was opened from, and the bar carries the note's folder under its title
- **Settings is a home of areas** — Appearance, Editor, Updates, Folders and paths, Sync, Trash and history, Diagnostics and info — each opening its own screen, with the app's own settings separated from the library's and the library named
- The tree's long-press menu opens with the row it acts on — icon, name, and the folder it sits in — instead of being a list of verbs with no subject, and its entries are grouped
- Moving a note asks with the same folder picker the settings use: a real list, a **New folder** button, and a mark on what is selected, instead of a dropdown opening over a dialog
- The new-item button's actions name what they do and where they land, and the trash is a plain list like every other screen, with **Empty** in the app bar — disabled, not missing, when there is nothing to empty
- Todo token chips wear their kind's colour, so projects, contexts and tags are apart at a glance, instead of a colour per name
- Deleting a note into the trash offers **Undo**
- Icons are outline throughout; a filled one now means a state is on
- The switch between the source editor and the WYSIWYG says which one it would take you to, and is not offered in preview, where there is no editor on screen

### Fixed
- **Editing a note in the WYSIWYG no longer rewrites its lists.** A task list with blank lines between its items kept its boxes — they were being written back as plain bullets, and the tick went with them — a spaced-out list kept its spacing, a numbered list kept its numbers and the number it starts at, and a nested list kept its nesting
- A task list with blank lines between its items shows its boxes in the preview too
- Closing the app on Linux ended in a crash on NVIDIA, where a C exit handler unwound into the EGL driver
- Sync on Windows stalled on the third attachment of every run; the attachment is copied in rather than renamed, which is a workaround and marked as one
- The folder settings could create the folder you asked for inside a folder that was not there — `assets/attachments` instead of `attachments`
- Setting the quick note anywhere but the settings screen left every other surface unaware of it
- A library's settings changed somewhere else are re-read instead of going stale
- The find button keeps the keyboard up instead of closing it and reopening it a frame later
- Text that stayed in English whatever language the app was in: the editor's status row, the trash, the tree's row menu, the new-item button's tooltip
- The search mode row fits a phone's width; the new-item button's label cannot run past the screen edge; two settings search results no longer share one identity; the desktop editor header keeps its actions at the right edge

### Other
- `shell.dart` and `note_view.dart` split into focused files, and the settings screen with them
- Background file jobs are counted while in flight, so one that hangs says so in the log instead of leaving a silent gap

## [0.0.6] - 2026-09-16

### Added
- WebDAV sync: point a library at a folder on your server and it keeps in step, by hand or on its own — automatic triggers with backoff, a queue that survives going offline and restarting, per-library credentials in the keychain, and a status panel listing whatever a run could not settle. Servers without ETags or preconditions work in a compatible mode, and one reached through a reverse proxy that mounts it under a path prefix works too. A run that would delete many files asks first, and deletions land in the trash rather than disappearing
- Note history: every note keeps its recent versions in `.history/` inside the library, grouped by day with the lines added and removed against the note as it is now. A version opens as a diff — side by side on a wide screen, stacked on a phone — and restores whole, or in part by picking single changes, with what it replaces kept as a version so a restore is itself undoable
- Conflicts merge instead of asking: when both sides changed a note, edits in different places land together, and only real overlaps open a screen where each one is settled by choosing this device's lines, the server's, or both
- On-device transcription of voice notes: **Transcribe** in a clip's menu runs a Whisper model locally and writes the text into the clip's description, asking first whether it replaces what is written there or goes below it. Models are downloaded and kept per device, never in the library, and nothing leaves the device. Available on Android and on Windows and Linux desktops
- A personal dictionary per library: right-click a word the spell-checker flagged and add it, and it stops being flagged in that library
- Clicking a link to a note that does not exist offers to create it, at the folder you choose in Settings → Editor

### Changed
- **The Android build is 64-bit only.** Devices with a 32-bit-only processor cannot install this version or update to it
- A todo reminder's notification now wears the app's mark instead of a generic alarm clock
- Voice recording can be paused and resumed, and saving a clip no longer stutters the interface
- Opening a library upgrades its database (schema 22). A `.history/` folder appears inside libraries from this version on; it holds the note versions and is never synced

### Fixed
- Inserting a large image no longer freezes the app while the file is read
- Wrong words in several older translations (Icelandic, Belarusian, Bulgarian, Greek, Basque, Lithuanian, Slovak, Albanian, Serbian), and strings that had stayed in English in every language
- The launcher's long-press menu was missing **New voice note**, which the in-app button and `Ctrl+Shift+A` both offered
- Playing a voice note's clip on Windows, where the file's path was put together with mixed separators and the player could not open it

## [0.0.5] - 2026-09-15

### Added
- Android auto-update opens the system package installer for the downloaded APK (FileProvider share, `REQUEST_INSTALL_PACKAGES` declared); the download alone was all 0.0.4 did

## [0.0.4] - 2026-09-15

### Added
- Auto-update from GitHub Releases (off by default): a quiet check shortly after launch and then every 6 hours, a shell banner offering the download, and a manual "Check for updates" row in Settings → Updates that downloads immediately; Windows launches the installer, Linux fetches the installed variant into Downloads, Android saves the APK (the system-installer step is next)

### Fixed
- Release APK without network: the INTERNET permission lived only in the debug manifest, so the update check (and WebDAV sync) failed on release builds

## [0.0.3] - 2026-09-14

### Added
- Home-screen widgets on Android: a todos widget (the open tasks, up to 100 rows, tap a row to toggle it, "+" opens the app with the add field focused) and a notes widget for your pinned notes, both wearing the app's palette
- Voice notes as a chat (`type: audio` notes): vocals on the left, written notes on the right; record or import audio as content-addressed files under the attachments folder, with a description per vocal and rename support
- 34 new UI languages (Dutch, Swedish, Norwegian, Danish, Basque, Catalan, Galician, Polish, Czech, Finnish, Romanian, Hungarian, Croatian, Slovak, Slovenian, Estonian, Latvian, Lithuanian, Bulgarian, Ukrainian, Belarusian, Serbian, Bosnian, Macedonian, Albanian, Greek, Icelandic, Turkish, French, German, Spanish, Portuguese, Chinese, Japanese, Hindi)
- `{{counter:name}}` template counters, kept per library, and `{{cursor}}` to land the caret in a created note

### Changed
- The preview shows a skeleton placeholder while its first parse is in flight, and the editor subtree survives preview switches
- Note rows scroll to the delete action on short screens; notes are picked with the system file picker

### Fixed
- App freeze on empty wikilink forms in the preview

### Other
- New `docs/` tree with user and contributor documentation
- The debug log export includes the device logcat; widget decisions are logged to a durable native file

## [0.0.2] - 2026-09-12

### Added
- The Niman theme, built from the logo palette, as the default on fresh installs
- Frame logging now attributes the frames after a tab switch to that switch (#48)

### Changed
- The preview parses each block inline when it builds, instead of the whole note at once
- The outline finds headings without tokenizing the document
- A big note opens without waiting for its stats, and a tab switch no longer rebuilds the tab bodies

### Fixed
- Preview parse parity, inline math wrapping, and keeping panes alive; the math glue reads its one-character text safely and glues punctuation to the formula
- The pre-search hint is centred and padded

## [0.0.1] - 2026-09-11

### Added
- The first release of Niman: plain `.md` files on disk as the source of truth, with the database as a rebuildable index
- Markdown with tables, task lists, footnotes, strikethrough and code highlighting; math (`$…$` / `$$…$$`, KaTeX); wikilinks and standard links
- Source editor and WYSIWYG editor, switchable; images copied into the library on insert
- Spellcheck on every platform
- Libraries as plain folders with self-contained settings; trash, history, templates, frontmatter, tags
- Full-text search (SQLite FTS5); themes (day/night/system × palettes) and adaptive layout
- Task reminders on Android

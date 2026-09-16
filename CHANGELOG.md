# Changelog

All notable changes to Niman, newest version first.

This file ships inside the build and feeds the in-app changelog (the
launch dialog after an update and the screen under Settings → About).
Update it in the release commit, before the tag.

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

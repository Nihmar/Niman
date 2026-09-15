# Changelog

All notable changes to Niman, newest version first.

This file ships inside the build and feeds the in-app changelog (the
launch dialog after an update and the screen under Settings → About).
Update it in the release commit, before the tag.

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

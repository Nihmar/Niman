# Niman

<img src="assets/branding/app_icon.png" alt="Niman app icon" width="140" align="right">

**Niman Is More (than) A Notebook.**

A multiplatform Markdown note-taking app where your notes are just files.
One note = one `.md` file on disk, organized in folders however you like.
The app's database is only a rebuildable index — your files are always the
source of truth. No lock-in, no proprietary format.

> **Status:** the project is under active development.

## Documentation

Full guides live in [`docs/`](docs/):

- **User:** [getting started](docs/user/getting-started.md),
  [editing](docs/user/editing.md), [organization](docs/user/organization.md),
  [export](docs/user/export.md),
  [journal](docs/user/journal.md), [search](docs/user/search.md),
  [links](docs/user/links.md), [templates](docs/user/templates.md),
  [tasks & reminders](docs/user/tasks.md), [themes](docs/user/themes.md),
  [settings](docs/user/settings.md), [shortcuts](docs/user/shortcuts.md),
  [sync](docs/user/sync.md), [home-screen widgets](docs/user/widgets.md),
  [platform notes](docs/user/platforms.md).
- **Contributor:** [architecture](docs/dev/architecture.md),
  [building](docs/dev/building.md), [conventions](docs/dev/conventions.md),
  [releasing](docs/dev/releasing.md), and the design records under
  [`docs/records/`](docs/records/) — the unified Markdown surface, read/live
  parity and huge notes, the workspace (open notes and tabs), the EPUB
  reader, annotations, the note history, WebDAV sync and transcription.

## What you get today

### Writing

- **Markdown**, as CommonMark/GFM: tables, task lists, footnotes,
  strikethrough, `==highlight==`, callouts (`> [!note]`), fenced code
  blocks with syntax highlighting.
- **Math** with `$…$` and `$$…$$` (KaTeX).
- **One Markdown surface, three modes.** The source editor, the live
  (WYSIWYG) editor and the read view are one widget of Niman's own: the
  note on disk is the same text whichever you write in, and switching
  modes does not move the page.
- **Wikilinks** (`[[note]]`, `[[note|alias]]`, `[[note#heading]]`) and
  standard Markdown links — click to navigate, with a dialog to create a
  missing note. Links reach any file of the library, and can point at a
  page of a PDF or a chapter of a book.
- **Images** copied into the library on insert (no base64 blobs), and
  **voice notes** whose recordings stay plain audio files — a recording
  can be transcribed on the device, with nothing uploaded.
- **Spellcheck** on every platform (system/IME on Android, hunspell on
  desktop) with a per-library personal dictionary.
- Find and replace, word count, heading outline and folding, **typewriter
  mode** on every platform, and **Zen mode** on the desktop.
- The **command palette** and **remappable keyboard shortcuts**.

### Libraries and the workspace

- A **library** is just a folder. Its settings live inside it as
  `.niman/settings.json` — copy the folder to another machine and
  everything travels with it.
- Each library is independent: its own editor preferences, trash policy,
  template folder, journal, tree sort order, and so on.
- Open multiple libraries from a remembered list; switch anytime, and
  **forget** one from its row's menu without touching its files.
- **Tabs and split panes** on the desktop, an open-notes switcher on a
  phone. The notes you had open, and where each was left, come back.
- A **side panel** with the note's outline, tags and history, and the
  **journal** calendar.

### Reading files

- **Pictures, PDFs and EPUB books** open in the note pane on every
  platform, zoomed and paged where they need it.
- A **book or PDF opens where you left it**; that place is kept in the
  library and syncs with it.
- **Annotate** a passage and it becomes a quoted section in a companion
  note, linked back to its place; the file marks where it was annotated.
- Books have a **look of their own** — theme, brightness, font and text
  size — apart from the notes.

### Organization

- **Journal:** one note per day, made the first time you open that day,
  with a folder-, name- and template-pattern you set.
- **Trash:** soft delete to `.trash/`, or hard delete — your choice per
  library — with an optional automatic empty.
- **History:** local `.history/` keeps past versions of each note; browse
  them, compare with the current text and restore from the note's menu.
- **Templates:** `{{placeholders}}` and filters, frontmatter directives,
  counters, includes and `{{ask}}`/`{{choice}}` prompts; the commands are
  coloured in the template folder.
- **Frontmatter:** any YAML key is indexed and searchable. Known fields
  include `title`, `tags`, `date`, `pinned`, `aliases`.
- **Tags:** in frontmatter or inline `#tags` — both searchable.

### Search

Full-text search across titles, body, and tags, powered by SQLite FTS5,
with prefix word search, `key = value` field search and `#tag` search.
Designed to stay fast at scale — the target is 1,000,000 notes.

### Themes

Brightness (day / night / system) and a palette: System (the device's
own colours), Niman, Catppuccin, Solarized or Gruvbox. Build a theme of
your own, edit it colour by colour with the whole app wearing it as you
move, and **export or import** one as a `.json` file to carry it to
another installation.

### Tasks and reminders

- A **Todo tab** over `todo.txt`, with priorities, due dates, projects,
  contexts and tags; the files are coloured as task lists in the editor.
- **Reminders** with `rem:YYYY-MM-DDTHH:MM`: exact alarms on Android that
  fire with the screen off or the app killed, and desktop timers with the
  tray kept open. The app warns about permission and battery settings
  that could block delivery.
- **Home-screen widgets** on Android: the todo list, and a pinned note.

### Sync and the desktop

- **WebDAV sync** per library to Nextcloud, ownCloud, a NAS or any WebDAV
  folder, `http://` over a VPN included: automatic syncing after edits,
  on opening and every few minutes (Wi-Fi only if you like), an offline
  queue that retries by itself, a first sync that deletes nothing, remote
  deletions landing in the trash, and edits from two devices merged line
  by line when they are in different places.
- **Close to tray** with a tray menu, **one Niman per desktop session**,
  **drag and drop** of files and folders onto the window, and *Open file*
  for a Markdown file outside any library.

### Debug log

An exportable debug log (last 5 000 lines in memory, mirrored to disk)
that survives crashes, swipes, and reboots. Useful for diagnosing reminder
delivery and other background behavior.

## What's coming

What is planned and what is in progress is tracked as GitHub issues — see
the [issue tracker](https://github.com/Nihmar/Niman/issues).

## Platforms

- **Android** (minSdk 35), **Linux** (Wayland), **Windows**.
- macOS and iOS are not built yet, but the code is kept portable.

## Release

Releases are built by CI from version tags only.

### Cutting a release

1. Add the version's section to `CHANGELOG.md`, bump `version:` in
   `pubspec.yaml`, and raise the `+N` build number (Android's
   `versionCode`: an update that does not raise it is refused).
2. Commit those together.
3. Tag: `git tag v1.2.0` (must match `vX.Y.Z`, no suffixes).
4. Push: `git push origin v1.2.0`.

The workflow builds all platforms and publishes artifacts on the tag's
GitHub Release page.

### Artifacts

| Platform | Files |
|----------|-------|
| Android | `.apk` |
| Linux | `.tar.gz`, `.AppImage`, `.pkg.tar.zst` (Arch) |
| Windows | Inno Setup installer (`.exe`), portable `.zip` |

### Signing

- **Android:** signed with the release key stored as Actions secrets
  (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Without them a build falls
  back to the debug key, which changes from run to run and makes Android
  refuse to update over the last install — do not ship a release that way.
- **Linux / Windows:** unsigned.

### Building locally

```
./scripts/niman.sh apk beta     # Android testing flavor (the default)
./scripts/niman.sh linux beta   # Linux testing bundle
./scripts/niman.sh apk          # official Android APK
scripts\niman.bat windows beta  # Windows testing build (on a Windows host)
```

Every build has a **beta** (testing) flavor that installs beside the
official app, with its own application ID or support folder. It is the
default for a local build; the official artifacts are built only when
asked. See [building](docs/dev/building.md).

## Architecture

- **Framework:** Flutter + Dart with `very_good_analysis`.
- **State:** Riverpod.
- **Editor and preview:** one Markdown surface of Niman's own
  (`lib/src/markdown/`) in three modes — source, live (WYSIWYG) and read —
  over the `markdown` package's parser, with its own incremental tokenizer,
  `katex_dart` for math and `highlight` for code.
- **Index:** `drift` (SQLite + FTS5), one database per library.
- **Credentials:** `flutter_secure_storage` (the WebDAV password, and
  whatever secrets a feature needs).
- **Testing:** `flutter_test` + `integration_test`.
- **CI:** tag-triggered GitHub Actions.

### Key packages

| Package | Role |
|---------|------|
| [`markdown`](https://pub.dev/packages/markdown) | CommonMark/GFM parser the surface walks |
| [`katex`](https://pub.dev/packages/katex) / [`katex_dart`](https://pub.dev/packages/katex_dart) | Math rendering |
| [`highlight`](https://pub.dev/packages/highlight) | Code syntax highlighting |
| [`drift`](https://pub.dev/packages/drift) | SQLite index + FTS5 search |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | State management |
| [`file_picker`](https://pub.dev/packages/file_picker) | Library/image picker |
| [`pdfrx`](https://pub.dev/packages/pdfrx) | PDF rendering |
| [`home_widget`](https://pub.dev/packages/home_widget) | Android home-screen widgets |
| [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) | Task reminders |
| [`whisper_ggml`](https://pub.dev/packages/whisper_ggml) | On-device speech-to-text for audio notes |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Credentials + secrets |

## Acknowledgments

- [Markor](https://github.com/gsantner/markor) — the offline Markdown editor
  for Android that keeps notes as ordinary files. A reference both for what
  a notes app owes its user (no lock-in, no database between them and their
  text) and for its visual design.
- Obsidian — a behavioral reference. Niman uses its own vocabulary (the
  root folder is the **Library**) and none of its code.

## License

Niman is open source under the MIT license.

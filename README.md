# Copist

<img src="assets/branding/feather.png" alt="Copist app icon" width="140" align="right">

A multiplatform Markdown note-taking app where your notes are just files.
One note = one `.md` file on disk, organized in folders however you like.
The app's database is only a rebuildable index — your files are always the
source of truth. No lock-in, no proprietary format.

> **Naming & status:** *Copist* and its feather icon are placeholders — the
> app will be renamed before release. The project is under active
> development.

## What you get today

### Writing

- Full **Markdown** support: tables, task lists, footnotes, strikethrough,
  fenced code blocks with syntax highlighting.
- **Math** with `$…$` and `$$…$$` (KaTeX).
- **Wikilinks** (`[[note]]`, `[[note|alias]]`, `[[note#heading]]`) and
  standard Markdown links — click to navigate.
- **Images** copied into the library on insert (no base64 blobs).
- **Spellcheck** on every platform (system/IME on Android, hunspell on
  desktop).
- **WYSIWYG editor** alongside the source editor — switch per note or per
  library (powered by `flutter_quill`).
- Word count, heading outline, heading folding.

### Libraries

- A **library** is just a folder. Its settings live inside it as
  `.copist/settings.json` — copy the folder to another machine and
  everything travels with it.
- Each library is independent: its own editor preferences, trash policy,
  template folder, tree sort order, and so on.
- Open multiple libraries from a remembered list; switch anytime.

### Organization

- **Trash:** soft delete to `.trash/`, or hard delete — your choice per
  library.
- **History:** local `.history/` keeps the last N versions of each note.
- **Templates:** with placeholders like `{{title}}`, `{{date:YYYY-MM-DD}}`,
  `{{time}}`, `{{uuid}}`; frontmatter from the template merges into the new
  note.
- **Frontmatter:** any YAML key is indexed and searchable. Known fields
  include `title`, `tags`, `date`, `pinned`, `aliases`.
- **Tags:** in frontmatter or inline `#tags` — both searchable.

### Search

Full-text search across titles, body, and tags, powered by SQLite FTS5.
Designed to stay fast at scale — the target is 1,000,000 notes.

### Themes

Brightness (day / night / system) combined with color palettes (system or
Catppuccin). The layout adapts to screen size: sidebar + editor + preview on
desktop, full-screen toggle on phones, split on tablets. You can override
the layout per library.

### Task reminders (Android)

Mark a task with `rem:` and Copist schedules an exact alarm — it fires even
with the screen off, the app in the background, or the process killed.
The app warns about notification and battery-optimization permissions that
could prevent delivery.

### Debug log

An exportable debug log (last 5 000 lines in memory, mirrored to disk)
that survives crashes, swipes, and reboots. Useful for diagnosing reminder
delivery and other background behavior.

## What's coming

These are tracked as GitHub issues — see the
[issue tracker](https://github.com/Nihmar/Copist/issues) for details.

- **WebDAV sync** ([#9](https://github.com/Nihmar/Copist/issues/9)) —
  whole-library sync to Nextcloud, ownCloud, or any WebDAV server. Includes
  offline queue, conflict detection, and a hunk-level merge UI.
- **Multi-tab editing** ([#23](https://github.com/Nihmar/Copist/issues/23)) —
  open several notes at once.
- **Export** ([#24](https://github.com/Nihmar/Copist/issues/24)) —
  note to `.md` or `.html` (with math rendered), folder/library to zip.
- **Import** ([#25](https://github.com/Nihmar/Copist/issues/25)) —
  Obsidian folders (wikilinks supported) and Notion export zips.
- **Encryption** ([#26](https://github.com/Nihmar/Copist/issues/26)) —
  optional per-file AES-256-GCM, chosen at library creation.
- **Onboarding** ([#27](https://github.com/Nihmar/Copist/issues/27)) —
  a guided first-launch experience.
- **Scale improvements** ([#22](https://github.com/Nihmar/Copist/issues/22)) —
  background indexing and bounded memory for very large libraries.
- **Platform parity** ([#39](https://github.com/Nihmar/Copist/issues/39)) —
  share-in on Android, file association on desktop, single-instance guard.
- **Note history viewer** ([#55](https://github.com/Nihmar/Copist/issues/55)) —
  browse and restore past versions of a note.
- **Performance** ([#45](https://github.com/Nihmar/Copist/issues/45)) —
  tab-switch smoothness and editor performance on large notes.
- **Packaging & release** ([#31](https://github.com/Nihmar/Copist/issues/31)) —
  final branding, signed builds, and the first public release.

**Stretch goals:** Mermaid diagrams, PDF export, LaTeX autocomplete.

## Platforms

- **Android** (minSdk 35), **Linux** (Wayland), **Windows**.
- macOS and iOS are not built yet, but the code is kept portable.

## Release

Releases are built by CI from version tags only.

### Cutting a release

1. Bump `version:` in `pubspec.yaml` and commit.
2. Tag: `git tag v1.2.0` (must match `vX.Y.Z`, no suffixes).
3. Push: `git push origin v1.2.0`.

The workflow builds all platforms and publishes artifacts on the tag's
GitHub Release page.

### Artifacts

| Platform | Files |
|----------|-------|
| Android | `.apk` |
| Linux | `.tar.gz`, `.AppImage`, `.pkg.tar.zst` (Arch) |
| Windows | Inno Setup installer (`.exe`), portable `.zip` |

### Signing

- **Android:** debug-signed until release keys are set up. To sign release
  builds, store your keystore and passwords as Actions secrets — the
  workflow picks them up automatically.
- **Linux / Windows:** unsigned, as planned for v1.

### Building locally

```
./scripts/copist.sh apk          # Android
./scripts/copist.sh linux        # Linux bundle
scripts\copist.bat windows       # Windows (on a Windows host)
```

See the CI workflow and `packaging/` for AppImage, Arch pkg, and Inno Setup
details.

## Architecture

- **Framework:** Flutter + Dart with `very_good_analysis`.
- **State:** Riverpod.
- **Source editor:** `re_editor` with Copist's own incremental Markdown tokenizer.
- **WYSIWYG editor:** `flutter_quill` with a Markdown round-trip codec.
- **Preview:** `flutter_markdown_plus` + `katex_dart` for math +
  `flutter_highlight` for code.
- **Index:** `drift` (SQLite + FTS5), one database per library.
- **Credentials:** `flutter_secure_storage`.
- **Testing:** `flutter_test` + `integration_test`.
- **CI:** tag-triggered GitHub Actions.

### Key packages

| Package | Role |
|---------|------|
| [`re_editor`](https://pub.dev/packages/re_editor) | Source editor widget |
| [`flutter_quill`](https://pub.dev/packages/flutter_quill) | WYSIWYG editor |
| [`flutter_markdown_plus`](https://pub.dev/packages/flutter_markdown_plus) + [`markdown`](https://pub.dev/packages/markdown) | Markdown preview and AST |
| [`katex`](https://pub.dev/packages/katex) / [`katex_dart`](https://pub.dev/packages/katex_dart) | Math rendering |
| [`flutter_highlight`](https://pub.dev/packages/flutter_highlight) | Code syntax highlighting |
| [`drift`](https://pub.dev/packages/drift) | SQLite index + FTS5 search |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | State management |
| [`file_picker`](https://pub.dev/packages/file_picker) | Library/image picker |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Credentials + encryption key |

## Acknowledgments

- [Markor](https://github.com/gsantner/markor) — the offline Markdown editor
  for Android that keeps notes as ordinary files. A reference both for what
  a notes app owes its user (no lock-in, no database between them and their
  text) and for its visual design.
- Obsidian — a behavioral reference. Copist uses its own vocabulary (the
  root folder is the **Library**) and none of its code.

## License

Copist is open source under the MIT license.

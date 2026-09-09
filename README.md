> **Copist is a Vibe-Coded application.** It was developed exclusively with locally
> run AI models — development is done using **Qwen 3.8 27B** (a 27 billion parameter
> model) running locally.

# Copist

<img src="assets/branding/feather.png" alt="Copist app icon" width="140" align="right">

Copist is a multiplatform Markdown note-taking app. Notes are plain files: one note
is one `.md` file on disk, organized in nested folders. The app's SQLite database is
only a **rebuildable index** (search, tags, frontmatter, sync state) — the files on
disk are always the source of truth.

> **Naming & status:** *Copist* (feather icon) is a placeholder name; the app will
> be renamed before release. The project is currently in development — see
> [Milestones](#milestones). Obsidian is a behavioral reference only; the app uses
> its own vocabulary (the root folder is the **Library** — no vaults, canvases, or
> graph views).

## Features (planned)

### Notes & content

- **Frontmatter:** general YAML. Known fields: `title`, `tags`, `date`, `pinned`,
  `aliases`; any other key is indexed and filterable.
- **Tags:** frontmatter `tags:` plus inline `#tags`; both searchable.
- **Links:** `[[wiki]]`, `[[wiki|alias]]`, `[[wiki#heading]]` and standard Markdown
  links; click to navigate. Resolved by unique filename with path fallback.
- **Images:** on insert, the file is copied into the library and linked (no base64
  by default).
- **Math:** `$…$` inline and `$$…$$` display, with whatever coverage KaTeX supports;
  math spans are highlighted in the source pane.
- **Markdown extras:** tables, task lists, footnotes, strikethrough, code blocks
  with syntax highlighting.
- **Editor conveniences:** spellcheck (where available), word count, heading outline
  + folding. LaTeX autocomplete is backlog.
- **Mermaid diagrams:** stretch goal (bundled offline webview renderer).

### Libraries

- A **library** is a folder of Markdown notes, and it describes itself: its
  own settings live inside it as `<library>/.copist/settings.json`, plain
  JSON you can read and fix in any editor. Copy the folder to another
  machine and its trash toggle, history depth, quick note and list folder
  travel with it.
- Copist remembers the libraries you have opened and starts on a list of
  them: name, path, and when each was last opened. Tapping one opens it;
  a long press forgets it, which removes it from the list and touches
  nothing inside the folder.
- **One library open at a time.** Switching from the settings closes the
  current one and opens the next, landing on its tree.
- Each library keeps its own index, in Copist's private storage rather
  than in the folder, so switching does not re-scan and a sync never
  carries a database. Deleting an index file rebuilds it on the next
  open.

### Organization

- **Trash:** `.trash/`, user-toggleable (off = hard delete).
- **History:** last N versions per note in local `.history/` (not synced); also
  serves as the merge base for conflicts.
- **Templates:** configurable folder (default `Templates/`) with placeholders
  `{{title}}`, `{{date:YYYY-MM-DD}}`, `{{time}}`, `{{now}}`, `{{uuid}}`; template
  frontmatter is merged into the new note.
- **Tabs:** multiple notes open at once.

### Search & indexing

- Full-text search (title + body + tags) via SQLite FTS5 — instant at 1M notes.
- The index is rebuildable at any time; files on disk are the source of truth.

### Sync & conflicts

- **WebDAV** sync to one destination at a time (Nextcloud, ownCloud, NAS, or any
  generic WebDAV server), with Basic auth over `http://` and `https://`.
- Whole-library sync; manual button plus automatic (on app focus, on change
  debounced, ~60s poll).
- **Conflicts:** 3-way merge UI, hunk-level (mine/theirs per hunk, or keep whole
  file). Multi-device simultaneous editing is out of scope for v1.

### Security

- At first launch the user chooses a plain or **encrypted library**: AES-256-GCM
  per file, key stored in OS secure storage; exporting yields plain `.md`.
- Credentials stored via `flutter_secure_storage`. Transport uses TLS (Nextcloud
  E2EE is a separate protocol).

### Import / export

- **Export:** note → `.md` / `.html` (with KaTeX); library or folder → `.md`
  bundle (zip). PDF export is a stretch goal.
- **Import:** Obsidian libraries (open the folder — wikilinks are already
  supported) and Notion export zips.

### Themes & layout

- Brightness (day / night / system) × palette (system | Catppuccin; night → Mocha,
  day → Latte). Token-based so more palettes can be added.
- Desktop: sidebar | editor | preview with a draggable split; Android phone:
  full-screen Edit/Preview switch; tablet/wide: split. User override:
  auto / force split / force switch.

## Platforms

- **Now:** Android + Linux + Windows.
- **Later:** macOS, iOS (code is kept portable).
- **Android:** minSdk 35 (Android 15), tablet support, APK for now.
- **Linux:** Wayland required; release as AppImage + Arch `.pkg.tar.zst`
  (PKGBUILD, no AUR).
- **Windows:** built on a Windows host (no cross-build from Linux); SQLite
  comes bundled, since Windows has no system one.

### Task reminders on Android

A `rem:` reminder is an exact alarm held by the system, so it fires with
the screen off, with the app in the background, and with the app's process
dead. Two things can still stop it, and Copist warns about both from the
Todo tab:

- **Notifications off.** The alarm fires and nothing is shown.
- **Battery optimization.** The banner links to the system list. Without
  the exemption, some manufacturer builds (Xiaomi/MIUI and HyperOS,
  Huawei/EMUI, Oppo/OnePlus/Realme ColorOS, Vivo) discard an app's pending
  alarms when it is swiped away from recents, and may sleep it after a
  while. Those ROMs often also need an "autostart" toggle that only the
  user can set. See dontkillmyapp.com for the per-vendor steps.

A *force stop* from Settings cancels an app's alarms on every Android
version; they are rescheduled the next time Copist runs. Reminders survive
a reboot.

### The debug log

Settings has a **Export debug log** action that writes the whole log to a
file you choose. Recording can be turned off there too.

The log is kept two ways: the last 5000 lines in memory, and an
append-only mirror on disk under the app's private storage
(`copist-log.txt`, one rotation, capped at 2 x 512 KB). The mirror is
flushed when the app goes to the background, so it survives a swipe away,
a crash, an OEM kill and a reboot. An export starts with the earlier runs
from disk and ends with the current one, which matters for reminders:
the interesting moment usually happens in a process that no longer exists.

Each line is `<timestamp> <SEVERITY> [<component>] <message>`. For
reminders, look for the `[todo]` lines:

```text
todo reminders: timezone Europe/Rome
todo reminders: 2 pending at startup [208725283, 867842594]
todo reminders: reconcile 2 wanted, notifications allowed, alarms exact, battery unrestricted
todo reminders: armed 867842594 for 2026-09-08T10:30 (in 2h 14m) call plumber
todo reminders reconciled: 2 scheduled (exact)
todo reminders: 2 pending after reconcile [208725283, 867842594]
```

`pending at startup` is the one to read after a kill or a reboot: it is
what the system still holds from the previous run, and the only evidence
of whether the alarms survived. `pending after reconcile` is what the
system actually has, as opposed to what Copist asked for.

## Architecture & stack

- **Framework:** Flutter (stable channel), Dart with `very_good_analysis`.
- **State:** Riverpod.
- **Rendering:** `flutter_markdown_plus` for preview, `katex_dart` (pure-Dart
  KaTeX) for math, `flutter_highlight` for code highlighting.
- **Editor:** `re_editor` (Reqable's large-text editor) with Copist's own
  incremental Markdown tokenizer plugged into its span builder; bidirectional
  scroll sync via line mapping.
- **WebDAV client:** `dart:io` HttpClient — PROPFIND/GET/PUT/MKCOL, ETag/If-Match,
  Basic auth, http + https (zero dependencies).
- **Index:** `drift` (SQLite + FTS5), one database file per library under
  `indexes/`, alongside a small app database holding the settings that
  belong to the installation rather than to a library; files located via
  `path_provider`; credentials via `flutter_secure_storage`.
- **Testing:** `flutter_test`, `integration_test`, and a mock WebDAV server
  (Dart `HttpServer`).
- **No CI:** analyze, test and release builds are run locally.
- **Packaging:** APK/AAB; Linux tar.gz + AppImage + Arch pkg (PKGBUILD).

### Third-party packages

Copist is built on top of these external packages rather than against the raw
Flutter SDK — they carry the core of the app, so they deserve explicit credit:

| Package | Role in Copist |
|---------|----------------|
| [`re_editor`](https://pub.dev/packages/re_editor) | The source-editor widget (caret, selection, IME/composition, handles, scrolling). Highlighting is Copist's own tokenizer via `spanBuilder` |
| [`flutter_markdown_plus`](https://pub.dev/packages/flutter_markdown_plus) + [`markdown`](https://pub.dev/packages/markdown) | Markdown preview: Copist's windowed preview builds on the package's AST → widget pipeline (GFM tables/task lists, footnotes); `markdown` is the AST parser |
| [`katex`](https://pub.dev/packages/katex) / [`katex_dart`](https://pub.dev/packages/katex_dart) | Pure-Dart KaTeX for `$…$` / `$$…$$` math rendering |
| [`flutter_highlight`](https://pub.dev/packages/flutter_highlight) + [`highlight`](https://pub.dev/packages/highlight) | Code-block syntax highlighting in the preview |
| [`drift`](https://pub.dev/packages/drift) (+ `drift_dev`, `sqlite3_flutter_libs`) | The rebuildable SQLite index — notes tree, tags, stems, links, FTS5 search |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | App-wide state management |
| [`file_picker`](https://pub.dev/packages/file_picker) | CHOOSING the library root folder / picking images to insert (never scans storage itself) |
| [`path_provider`](https://pub.dev/packages/path_provider) | OS folders for app data (index, settings, caches) |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | WebDAV credentials + the encryption key (M5/M6) |
| [`crypto`](https://pub.dev/packages/crypto) | sha256 content digests (change detection, sync reconciliation) |

Notable non-default choices: `flutter_smooth_markdown` (0.8.1) is pinned only as
*the reference renderer the M2 cost-model benchmark tests against* — the app's
preview is Copist's own windowed renderer over `flutter_markdown_plus`. `hash` and
`path` come from the Dart team; `meta` is the Flutter SDK's annotation package.

### Sync state machine

> Watch (local file events) + Poll (remote PROPFIND) → **Reconcile** (content hash
> vs ETag/size) → queue: upload / download / delete (tombstones) / conflict.
> `PUT` with `If-Match`; on 412 → re-fetch + 3-way merge UI (base from
> `.history`). Offline: persisted queue, retry with backoff. `.trash` / `.history`
> stay local.

### Performance strategy

- Startup with a cached index (no blocking scan); incremental indexing via file
  watcher; one-time full scan.
- Preview: parse once per change, lazy block rendering, KaTeX output cached per
  math string (LRU).
- Search: FTS5.
- Editor: a single text buffer per note (fine at MB scale).

## Milestones

| # | Milestone | Scope |
|---|-----------|-------|
| M0 | Scaffold | Project, lint, placeholder branding, app shell — **done** |
| M1 | Library core | Open/create library, file watcher, tree UI, CRUD, rename/move, trash toggle — **done** |
| M1.5 | Index integrity | Index diff with stable row ids, change notification, subtree parent fix — **next, blocks M2** |
| M2 | Editor + preview | Highlighting, `flutter_markdown_plus` + `katex_dart`, bidirectional scroll sync, all Markdown extras, word count, heading outline + folding |
| M3 | Links & search | Link resolution + click navigation, FTS5 search (word/tag/title), tag list |
| M4 | Frontmatter & templates | YAML parse/edit, template placeholder engine |
| M5 | Sync | WebDAV client, state machine, manual + automatic, delete propagation, conflict merge UI |
| M6 | Scale & polish | 1M-note performance pass, multi-tab, import/export, themes (brightness × palette), secure storage, onboarding (library + encryption choice) |
| M7 | Packaging & release | APK; Linux tar.gz + AppImage + Arch pkg; Windows zip; open-source repo (license, README) |

**Stretch goals (in order):** Mermaid, PDF export, LaTeX autocomplete, Linux
spellcheck, E2E.

## Scale requirement

Copist must work unbounded: **1,000,000 notes and novel-length files** are a hard
requirement, driving the rebuildable-index, FTS5, and LRU-cache strategies above.

## Acknowledgments

- [Markor](https://github.com/gsantner/markor) — the offline Markdown editor for
  Android that keeps notes as ordinary files and puts a todo.txt view next to
  them. A reference for what a notes app owes its user: no lock-in, no database
  standing between them and their text.
- Obsidian — a behavioral reference only. Copist keeps its own vocabulary (the
  root folder is the **Library**) and none of its code.

## License

Copist is open source under the MIT license.

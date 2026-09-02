> **Copist is a Vibe-Coded application.** It was developed exclusively with locally
> run AI models — development is done using **Qwen 3.8 27B** (a 27 billion parameter
> model) running locally.

# Copist

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

- **Now:** Android + Linux.
- **Later:** Windows, macOS, iOS (code is kept portable).
- **Android:** minSdk 35 (Android 15), tablet support, APK for now.
- **Linux:** Wayland required; release as AppImage + Arch `.pkg.tar.zst`
  (PKGBUILD, no AUR).

## Architecture & stack

- **Framework:** Flutter (stable channel), Dart with `very_good_analysis`.
- **State:** Riverpod.
- **Rendering:** `flutter_markdown` for preview, `katex_flutter` (pure-Dart KaTeX)
  for math, `flutter_highlight` for code highlighting.
- **Editor:** custom lightweight source editor (Markdown + math-span
  highlighting) with bidirectional scroll sync via line mapping.
- **WebDAV client:** `dart:io` HttpClient — PROPFIND/GET/PUT/MKCOL, ETag/If-Match,
  Basic auth, http + https (zero dependencies).
- **Index:** `drift` (SQLite + FTS5); files located via `path_provider`;
  credentials via `flutter_secure_storage`.
- **Testing:** `flutter_test`, `integration_test`, and a mock WebDAV server
  (Dart `HttpServer`).
- **CI:** GitHub Actions (analyze + test; builds added in M7).
- **Packaging:** APK/AAB; Linux tar.gz + AppImage + Arch pkg (PKGBUILD).

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
| M0 | Scaffold | Project, lint, CI, placeholder branding, app shell — **in progress** |
| M1 | Library core | Open/create library, file watcher, tree UI, CRUD, rename/move, trash toggle |
| M2 | Editor + preview | Highlighting, `flutter_markdown` + `katex_flutter`, bidirectional scroll sync, all Markdown extras, word count, heading outline + folding |
| M3 | Links & search | Link resolution + click navigation, FTS5 search (word/tag/title), tag list |
| M4 | Frontmatter & templates | YAML parse/edit, template placeholder engine |
| M5 | Sync | WebDAV client, state machine, manual + automatic, delete propagation, conflict merge UI |
| M6 | Scale & polish | 1M-note performance pass, multi-tab, import/export, themes (brightness × palette), secure storage, onboarding (library + encryption choice) |
| M7 | Packaging & release | APK; Linux tar.gz + AppImage + Arch pkg; CI builds; open-source repo (license, README) |

**Stretch goals (in order):** Mermaid, PDF export, LaTeX autocomplete, Linux
spellcheck, E2E.

## Scale requirement

Copist must work unbounded: **1,000,000 notes and novel-length files** are a hard
requirement, driving the rebuildable-index, FTS5, and LRU-cache strategies above.

## License

Copist is open source under the MIT license.

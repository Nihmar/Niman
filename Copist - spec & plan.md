# Copist - spec & plan

## Naming & terminology

*   App name placeholder: **Copist** (feather icon). Both will be renamed later.  
    (First candidate "Inkwell" was rejected: existing product.)
    
*   Obsidian is a **behavioral reference only**. The app uses its own vocabulary:
    *   Root folder of notes = **"Library"** (no "vault").
        
    *   No Obsidian-peculiar terms: no vault, no canvas, no publish, no daily notes, no graph view, no backlinks (say "references" if needed).
        
    *   Kept (generic or user's own words): note, folder, tag, template, frontmatter, alias, wikilink (`[[…]]` syntax), trash, history, sync, pinned.
        

## Requirements (agreed)

*   **Platforms:** Android + Linux + Windows now; macOS/iOS later (keep code portable).
    
*   **Model:** one note = one `.md` file on disk, nested folders. SQLite is only a _rebuildable index_ (search/tags/frontmatter/sync state), never the source of truth.
    
*   **Scale:** unbound — 1,000,000 notes and novel-length files (hard requirement).
    
*   **Frontmatter:** general YAML. Known fields: `title`, `tags`, `date`, `pinned`, `aliases`; any other key is indexed/filterable.
    
*   **Tags:** frontmatter `tags:` + inline `#tags`; both searchable.
    
*   **Links:** `[[wiki]]`, `[[wiki|alias]]`, `[[wiki#heading]]` + standard MD links; click-to-navigate; resolve by unique filename with path fallback.
    
*   **Images:** on insert, copy file into the library and insert a link (no base64 by default).
    
*   **Trash:** `.trash/`, user toggleable (off = hard delete).
    
*   **History:** last N versions per note in local `.history/` (not synced); doubles as merge base.
    
*   **Templates:** configurable folder (default `Templates/`); placeholders: `{{title}}`, `{{date:YYYY-MM-DD}}`, `{{time}}`, `{{now}}`, `{{uuid}}`; template frontmatter merged into the new note.
    
*   **Math:** `$…$` inline, `$$…$$` display; coverage = whatever KaTeX supports (matrices, aligned/cases, `\text`, `\newcommand`); math spans highlighted in source pane.
    
*   **Layout:** desktop = sidebar | editor | preview (draggable split); Android phone = full-screen Edit/Preview switch, tablet/wide = split; user override (auto / force split / force switch).
    
*   **Tabs:** multiple open notes at once.
    
*   **Markdown extras:** tables, task lists, footnotes, strikethrough, code blocks with syntax highlighting.
    
*   **Editor conveniences:** spellcheck (where available), word count, heading outline + folding. LaTeX autocomplete = backlog.
    
*   **Mermaid:** stretch goal (bundled offline webview renderer).
    
*   **Sync:** WebDAV, one destination at a time (Nextcloud, ownCloud, NAS, generic); Basic auth; `http://` and `https://`; whole library synced; manual button + automatic (app focus, on change debounced, ~60s poll).
    
*   **Conflicts:** 3-way merge UI, hunk-level (mine/theirs per hunk, or keep whole file). Multi-device simultaneous editing out of scope for v1.
    
*   **Android:** **minSdk 35 (Android 15)**; tablet support; APK for now.
    
*   **Linux:** **Wayland required**; release AppImage + Arch `.pkg.tar.zst` (PKGBUILD, no AUR).
    
*   **Security:** first-launch choice: plain or encrypted library (AES-256-GCM per file, key in OS secure storage; export yields plain `.md`). Credentials in `flutter_secure_storage`. Transport: TLS (no standard WebDAV E2E; Nextcloud E2EE is a separate protocol).
    
*   **Search:** full-text (title + body) via FTS5, plus tag lookup from the tag tables (tags are not indexed in FTS); instant at 1M notes.
    
*   **Export:** note → `.md` / `.html` (with KaTeX); library/folder → `.md` bundle (zip). PDF = stretch.
    
*   **Import:** Obsidian library = open the folder (wikilinks already supported); Notion export zip → import.
    
*   **Themes:** brightness (day/night/system) × palette (system | Catppuccin). Night + Catppuccin = dark Catppuccin (Mocha); day + Catppuccin = Latte. Token-based so more palettes can be added.
    
*   **Licensing:** open source (MIT — confirmed).
    

## Development stack

*   Flutter (stable channel), Dart with `very_good_analysis`
    
*   State: Riverpod
    
*   Markdown: `flutter_markdown_plus` (the maintained fork; `flutter_markdown` is discontinued); math: `katex_dart` (pure-Dart KaTeX, verify version at M2); code highlighting: `flutter_highlight`
    
*   Editor: lightweight source editor (MD + math-span highlighting) + bidirectional scroll sync via line mapping; custom widget vs Flutter text editing decided at M2
    
*   WebDAV: `dart:io` HttpClient — PROPFIND/GET/PUT/MKCOL, ETag/If-Match, Basic auth, http+https (zero deps)
    
*   Index: `drift` (SQLite + FTS5); files via `path_provider`; credentials via `flutter_secure_storage`
    
*   Testing: `flutter_test`, `integration_test`, mock WebDAV server (Dart `HttpServer`)
    
*   No CI: analyze, test and release builds run locally
    
*   Packaging: APK/AAB; Linux tar.gz + AppImage + Arch pkg (PKGBUILD)
    

## Sync state machine

Watch (local file events) + Poll (remote PROPFIND) → Reconcile (content hash vs ETag/size) → queue: upload / download / delete (tombstones) / conflict. `PUT` with `If-Match`; on 412 → re-fetch + 3-way merge UI (base from `.history`). Offline: persisted queue, retry with backoff. `.trash`/`.history` stay local.

## Performance strategy

*   Startup with cached index (no blocking scan); incremental indexing via file watcher; one-time full scan.
    
*   Preview: parse once per change, lazy block rendering, KaTeX output cached per math string (LRU).
    
*   Search: FTS5.
    
*   Editor: single text buffer per note (assumed fine at MB scale; measured at M2).
    

## Milestones

*   **M0 Scaffold** — project, lint, placeholder branding, app shell (done)
    
*   **M1 Library core** — open/create library, file watcher, tree UI, CRUD, rename/move, trash toggle (done)
    
*   **M1.5 Index integrity** — index diff with stable row ids, change notification, subtree parent fix (blocks M2)
    
*   **M2 Editor + preview** — highlighting, flutter_markdown_plus + katex_dart, bidirectional scroll sync, all MD extras, word count, heading outline + folding
    
*   **M3 Links & search** — link resolution + click nav, FTS5 search (word/tag/title), tag list
    
*   **M4 Frontmatter & templates** — YAML parse/edit, template placeholder engine
    
*   **M5 Sync** — WebDAV client, state machine, manual + auto, delete propagation, conflict merge UI
    
*   **M6 Scale & polish** — 1M-note perf pass, multi-tab, import/export, themes (brightness × palette), secure storage, onboarding (library + encryption choice)
    
*   **M7 Packaging & release** — APK; Linux tar.gz + AppImage + Arch pkg; Windows zip; open-source repo (license, README)
    
*   **Stretch (ordered):** Mermaid, PDF export, LaTeX autocomplete, Linux spellcheck, E2E

# Shared design

Cross-cutting technical design for Copist, referenced by every milestone file.
Requirements and milestones live in [`Copist - spec & plan.md`](../Copist%20-%20spec%20%26%20plan.md)
— that file is the source of truth for *what*; this file is the source of truth
for *how*.

## Principles

- **Files are the source of truth.** One note = one `.md` file on disk, nested
  folders. SQLite is only a *rebuildable index*; losing it must never lose data.
- **Own vocabulary.** Library (root folder), note, folder, tag, template,
  frontmatter, alias, wikilink, trash, history, sync, pinned. No
  Obsidian-peculiar terms (no vault, canvas, publish, daily notes, graph view,
  backlinks).
- **Portable code.** Android + Linux + Windows now; macOS/iOS later.
- **Scale is a hard requirement:** 1,000,000 notes and novel-length files.

## Module layout

Built incrementally across milestones (skeleton created in M0, filled per
milestone).

```
lib/
  main.dart                 # entrypoint
  src/
    app.dart                # MaterialApp root, theme wiring
    core/
      files.dart            # file IO helpers (atomic temp-file writes, hashing)
      crypto.dart           # AES-256-GCM (M6)
      errors.dart           # error handling
      logging.dart          # logging
      settings/             # local settings persistence (drift)
    library/
      library_state.dart    # open/create library, root path
      file_watcher.dart     # recursive watch + debounced change events
      note_ops.dart         # create / rename / move / delete (trash)
    db/
      database.dart         # drift schema (see below)
      dao.dart              # note/tag/folder DAOs
      indexer.dart          # disk scan → index build + incremental apply
    editor/
      source_editor.dart    # lightweight source editor (single buffer)
      highlighting.dart     # MD + math-span tokenizer → styled display
    preview/
      markdown_view.dart    # flutter_markdown_plus preview
      math.dart             # katex rendering + LRU cache
      scroll_map.dart       # line mapping ↔ bidirectional scroll sync
    links/
      parser.dart           # [[…]] / [[…|alias]] / [[…#heading]] parsing
      resolver.dart         # unique filename, path fallback, aliases
    search/
      search_repo.dart      # FTS5 queries (title + body)
      tag_repo.dart         # tag list + tag→note queries
    frontmatter/
      parser.dart           # general YAML frontmatter parse/validate
      fields.dart           # known fields (title, tags, date, pinned, aliases)
    templates/
      repo.dart             # template folder management (default Templates/)
      engine.dart           # {{title}}, {{date:YYYY-MM-DD}}, {{time}}, {{now}}, {{uuid}}
    export/
      note.dart             # note → .md / .html (KaTeX)
      bundle.dart           # library/folder → .md bundle (zip)
    import/
      obsidian.dart         # open Obsidian library (folder)
      notion.dart           # Notion export zip → notes
    sync/
      webdav.dart           # dart:io HttpClient: PROPFIND/GET/PUT/MKCOL, ETag/If-Match
      machine.dart          # watch+poll → reconcile → queue state machine
      merge.dart            # 3-way hunk-level merge (base from .history)
      config.dart           # destination URL + Basic auth (flutter_secure_storage)
    ui/
      shell.dart            # app shell: sidebar | editor | preview
      tree.dart             # note tree UI
      tabs.dart             # multi-tab (M6)
      theme/                # brightness × palette tokens
      search_screen.dart    # search results
      tags_screen.dart      # tag list
      settings/             # settings screens (library, sync, theme, layout)
      conflict_dialog.dart  # merge UI (mine/theirs per hunk, or whole file)
      onboarding.dart       # first launch: library + encryption choice (M6)
test/
  unit/                     # pure Dart logic
  widget/                   # UI flows
  sync/                     # mock WebDAV server (dart:io HttpServer)
integration_test/           # on-device E2E
```

## Data model (drift: SQLite + FTS5)

All tables are **rebuildable from disk**. The schema is a cache; a full rescan
of the library can reproduce it exactly.

### Notes tree

```
notes
  id          int PK
  path        text UNIQUE   -- library-relative, slash-separated
  parent      int           -- parent notes.id (0 = library root)
  name        text
  is_dir      bool
  size        int unsigned
  modified    datetime
  sha256      text?         -- content hash, files only (sync reconcile)
```

Directory rows are materialized (not derived on the fly) so tree queries are
cheap at 1M scale.

### Frontmatter & tags

```
frontmatter_fields
  id          int PK
  note_id     int           -- notes.id
  key         text
  value       text
  UNIQUE (note_id, key)     -- known: title, tags, date, pinned, aliases;
                             -- any other key is stored too (indexed/filterable)

tags            name UNIQUE   -- normalized (lowercase, no leading #)
note_tags       tag, note_id, is_frontmatter(bool)
```

Frontmatter `tags:` and inline `#tags` both land in `note_tags`; the tag list
UI reads from it. Tag search queries `tags`/`note_tags`, not FTS.

### Search (FTS5)

```sql
CREATE VIRTUAL TABLE notes_fts USING fts5(path UNINDEXED, title, body);
```

Kept in sync by the indexer (same transaction that writes `notes`/
`frontmatter_fields`). Search = FTS5 (title + body) plus tag lookup; tags
are answered from `tags`/`note_tags`, not from FTS.

**Open decision (T-M3-04).** The statement above is a standalone FTS5
table: it keeps its own copy of every note body, so at 1M notes the index
holds a second copy of the library. The alternatives are external content
(`content='notes'`), which needs the body as a column of `notes` and so
puts that same copy in a different table, and contentless
(`content=''`), which stores no text and therefore cannot return the
snippets T-M3-05 requires. Decide before writing the migration; whichever
wins, the row keys must survive a rescan, which is what
[m1_5-correctness.md](m1_5-correctness.md) makes true.

**Body reads.** Populating FTS is the first thing that needs a note's
content since M1 stopped reading files during a scan. Read only the notes
whose `(size, mtime)` or digest changed, and read them on a background
isolate with the walk — reading every body on every scan is what made the
app hang on Android before ([android.md](android.md) issue 3).

### Sync state

```
sync_items
  path        text UNIQUE   -- library-relative
  size        int
  modified    datetime
  sha256      text          -- local content hash
  etag        text?         -- last confirmed remote ETag
  base        text?         -- the .history version (or its digest) current at
                            -- the last successful sync = the 3-way merge base

sync_ops       -- persisted queue (survives app restart / offline)
  id          int PK
  kind        enum(upload, download, delete)   -- delete = tombstone
  path        text
  attempts    int unsigned
  next_retry  datetime
```

### Local settings (not synced, never in the library folder)

```
library_settings   -- keyed by library path: trash toggle, history versions (N),
                     template folder path
app_settings       -- global: theme (brightness × palette), layout mode, ...
```

Credentials (WebDAV URL + Basic auth, encryption key) go to
`flutter_secure_storage`, never into drift.

## Editor & preview

- **Editor:** a lightweight source editor over a single text buffer per
  note. Highlighting (Markdown tokens, math spans `$…$`/`$$…$$`) is a display
  layer over plain text — the edit model never becomes rich text. Whether
  that means a custom widget or Flutter's own text editing with a custom
  controller is decided in T-M2-00, not assumed here.
- **Preview:** `flutter_markdown_plus` render, parsed once per change
  (debounced), lazy block layout. Extras: tables, task lists, footnotes,
  strikethrough, code blocks via `flutter_highlight`.
- **Math:** math spans extracted from source → `katex_dart` (pure-Dart
  KaTeX) → output cached in an LRU keyed by math string. Same spans highlighted
  in the editor pane.
- **Bidirectional scroll sync:** each preview render produces a line-mapping
  table (source line → preview block offset). Scrolling either pane maps
  through the table to set the other's position; the mapping is rebuilt per
  render pass, so it stays cheap.

## Sync architecture (WebDAV)

One destination at a time; Basic auth; `http://` and `https://`; whole library;
zero-dep client on `dart:io` HttpClient.

```
Triggers: local file events (watch) | remote poll (PROPFIND ~60s)
          | app focus | manual button
        ↓
RECONCILE — per item, compare local (sha256, size, mtime) vs remote (ETag, size, mtime):
  • local newer, absent remotely          → upload
  • remote newer, absent locally          → download
  • both changed                          → upload with PUT If-Match(old ETag)
        → 412 → re-fetch remote → 3-way merge (base = .history version at
          last sync) → conflict UI
  • deleted locally, present remotely     → delete (tombstone)
  • equal                                 → skip
        ↓
QUEUE (persisted, drained sequentially):
  upload    MKCOL parents → PUT (If-Match if item exists)
  download  GET → write .tmp → atomic rename
  delete    remote DELETE
  conflict  open merge UI (hunk-level mine/theirs, or keep whole file)
```

- Offline: queue persists, retry with exponential backoff.
- `.trash/` and `.history/` are **never** synced (local-only).
- Transfers stream to/from disk (no full-file in memory) — novel-length files.

### `.history/`

Local-only versioning that doubles as the merge base. `.history/` mirrors the
library tree; for note `<path>` the last N versions (N per library setting,
default 10) are kept as `.history/<path>.v<n>` with a monotonically increasing
`n`. Excluded from indexing, watching, and syncing.

## Theming

- **Brightness:** day | night | system.
- **Palette:** system | Catppuccin (night → Mocha, day → Latte).
- **Token-based:** color roles (background, surface, text, muted, accent, …)
  mapped per palette; adding a palette = adding a mapping.

Layout: desktop = sidebar | editor | preview (draggable split); Android phone =
full-screen Edit/Preview switch; tablet/wide = split; user override:
auto / force split / force switch.

## Testing strategy

| Layer              | Scope                                                        |
| ------------------ | ------------------------------------------------------------ |
| `test/unit/`       | Pure logic: indexer, link resolver, placeholder engine, frontmatter parser, merge, sync state machine (in-memory drift) |
| `test/widget/`     | Tree CRUD, editor/preview, search, settings, conflict dialog |
| `test/sync/`       | Mock WebDAV server (in-process Dart `HttpServer`): PROPFIND/GET/PUT/MKCOL, ETag, 412 paths |
| `integration_test/`| On-device E2E: open library → edit → sync → conflict round trip |
| Local              | `flutter analyze --fatal-infos` + `flutter test` before every commit; there is no CI, by choice |

1M-note validation: a fixture generator (M6) creates a synthetic library and
drives startup, indexing, and search timing assertions.

## Performance strategy

- **Startup:** open with the persisted index — no blocking scan. The file
  watcher applies incremental changes since last run; a full rescan happens
  once at first library open, or on explicit re-index.
- **Tree:** lazy list rendering backed by materialized directory rows.
- **Preview:** parse once per change (debounced), lazy block rendering, KaTeX
  LRU per math string.
- **Search:** FTS5.
- **Editor:** single text buffer per note. "Fine at MB scale" is an
  assumption inherited from the spec and not yet measured — T-M2-00.
- **1M gate (M6):** fixture library + timing assertions in the test suite,
  run locally.

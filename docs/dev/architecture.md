# Architecture

## Principle

**Disk is source of truth.** One note = one `.md` file. SQLite (drift)
is a rebuildable per-library index (FTS5 search, tree rows, frontmatter
fields) — it stores nothing that cannot be reconstructed from disk.

## Layout (`lib/src/<module>/`)

| Module | Contents |
|--------|----------|
| `core/` | Settings (`settings/library_config.dart`), logging, the in-flight isolate gauge (`isolate_gauge.dart`), storage access, theme, language, shortcuts/launch args |
| `library/` | Library open/session state, note file ops, the note write path (`NoteWriter`), watcher, image import |
| `history/` | `.history/` versions: manifest, snapshot policy, disk store (off-isolate), `NoteHistory` service — see [sync.md](sync.md) |
| `diff/` | Myers line diff with its hunk summary, and the three-way merge over them, shared by history rollback and sync conflicts |
| `sync/webdav/` | WebDAV client on `dart:io` (streamed GET/PUT, PROPFIND parsing, typed failures) and the capability probe — see [sync.md](sync.md) |
| `sync/` | Sync state store (`sync_destinations`, `sync_items`, `sync_ops`), secure password store, pure reconcile, the engine (full and quick runs), the trigger scheduler and network monitor, and `LibrarySyncService` for the UI |
| `ui/sync/` | WebDAV settings screen (with the trigger options), status icon and panel (with the queue), first-sync and mass-deletion dialogs, conflict screen (merge by region, or whole copies) |
| `db/` | `AppDatabase` (app settings, migration chain) + `IndexDatabase` (one per library, schema 1, no migrations — delete to rebuild); indexer, scan, tree materialization |
| `markdown/` | The one Markdown surface ([unified-surface.md](unified-surface.md)): `SourceBuffer`, the block scanner and parser (over the `markdown` AST), the styler, the surface controller, and under `render/` the source view (modes `source` and `live`, the WYSIWYG) and the read view (the preview); `edit/` holds selection, caret motion, input, history and find |
| `editor/` | What the surface is driven by: the incremental tokenizer (`highlighting.dart`), the Markdown commands (`md_editing.dart`), toolbar and its layout, context menu, find bar, outline, word count, list tally, typewriter and note column |
| `preview/` | KaTeX math (typesetting, cache, rasterizing), code highlight, image aspect — what the surface draws with |
| `links/` | Wikilink/Markdown-link parse + resolve (single parse rule shared by editor, preview, indexer) |
| `search/` | FTS query builder (user text is never raw FTS), field/tag queries, replace |
| `frontmatter/` | YAML parse, known fields (`title tags date pinned aliases`), field repo |
| `templates/` | Substitution engine (`engine.dart`), directives, includes, `ask`/`choice` prompts, counters |
| `todo/` | todo.txt line model, file store, filters, reminder scheduling backends |
| `spellcheck/` | hunspell (desktop) / system IME (Android) providers, per-library personal dictionary layered in front (right-click *Add to dictionary*) |
| `transcription/` | On-device speech-to-text for audio notes (whisper_ggml): model catalog, downloads, the model directory, transcription settings — see [transcription.md](transcription.md) |
| `ui/` | Shell, tree, settings screens, shared widgets |
| `widget/` | Android home-screen widgets: placement, payload, refresh, theming, background row ops (native Kotlin providers in `android/app/src/main/kotlin/dev/niman/niman/`) |

State: Riverpod. No god classes — one class per file, split at ~300
lines or when responsibilities mix.

## Key flows

- **Open library:** read `.niman/settings.json` once into
  `LibraryConfigRepo` (cached per session) → scan files off the UI
  isolate (`Isolate.run` — every stat is a FUSE round trip on Android) →
  upsert into `IndexDatabase` on main.
- **Edit:** `NoteOps.saveNote` → history snapshot and atomic write
  (temp + rename) in one isolate pass → the note is rescanned into the
  index. Every mode of the surface shares one tokenizer for links.
- **Sync download:** a note lands the same way (snapshot + rename on an
  isolate). An **attachment** has no snapshot, so it lands through
  `swapFileIn` on the calling isolate instead — a stat, a mkdir and a
  rename are async I/O that never block the loop, and an isolate around
  async-only work buys nothing. On Windows that rename hangs on the third
  attachment of every run, so it is given three seconds and then the
  bytes are copied instead: a workaround for
  [#103](https://github.com/Nihmar/Niman/issues/103). See
  [sync.md](sync.md) for what has been ruled out.
- **Isolate jobs:** the scan, probe and write passes above go through
  `IsolateGauge.run` (`core/isolate_gauge.dart`) instead of `Isolate.run`
  directly, which logs each job's start and finish with how many are in
  flight, and warns when one outlives 10 s. A job that hangs otherwise
  logs nothing at all — an exported log then shows a gap and no reason,
  which is what made #103 unreadable until the gauge went in.
- **Search:** `search/query.dart` builds a safe FTS5 MATCH (tokens quoted,
  prefix `*` on last token only); `key = value` and `#tag` take the field
  and tag paths instead.
- **Reminders:** first valid `rem:YYYY-MM-DDTHH:MM` per task schedules an
  exact alarm (Android plugin backend, desktop backend); health/warnings
  surface permission problems.
- **Home-screen widgets (Android):** placed instances are pushed a
  payload whenever the todo snapshot or pinned note moves; rows render
  natively (RemoteViews) and row taps come back as `niman://` intents
  handled off the UI isolate. Placement runs a native config activity
  (library/note pick).

## Planned, not built

- Nothing large at the moment. The one Markdown surface that was planned
  here is built (#247): [unified-surface.md](unified-surface.md) is its
  design and record, and [editor-alternatives.md](editor-alternatives.md) the
  measured record of the packages it replaced.

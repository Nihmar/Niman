# Architecture

## Principle

**Disk is source of truth.** One note = one `.md` file. SQLite (drift)
is a rebuildable per-library index (FTS5 search, tree rows, frontmatter
fields) — it stores nothing that cannot be reconstructed from disk.

## Layout (`lib/src/<module>/`)

| Module | Contents |
|--------|----------|
| `core/` | Settings (`settings/library_config.dart`), logging, storage access, theme, language, shortcuts/launch args |
| `library/` | Library open/session state, note file ops, the note write path (`NoteWriter`), watcher, image import |
| `history/` | `.history/` versions: manifest, snapshot policy, disk store (off-isolate), `NoteHistory` service — see [sync.md](sync.md) |
| `diff/` | Myers line diff with its hunk summary, and the three-way merge over them, shared by history rollback and sync conflicts |
| `sync/webdav/` | WebDAV client on `dart:io` (streamed GET/PUT, PROPFIND parsing, typed failures) and the capability probe — see [sync.md](sync.md) |
| `sync/` | Sync state store (`sync_destinations`, `sync_items`, `sync_ops`), secure password store, pure reconcile, the engine (full and quick runs), the trigger scheduler and network monitor, and `LibrarySyncService` for the UI |
| `ui/sync/` | WebDAV settings screen (with the trigger options), status icon and panel (with the queue), first-sync and mass-deletion dialogs, conflict screen (merge by region, or whole copies) |
| `db/` | `AppDatabase` (app settings, migration chain) + `IndexDatabase` (one per library, schema 1, no migrations — delete to rebuild); indexer, scan, tree materialization |
| `editor/` | Source editor (`re_editor` + own incremental tokenizer `highlighting.dart`), WYSIWYG (`flutter_quill` + Markdown codec), toolbar, find panel, folding, outline, word count |
| `preview/` | Markdown render (`flutter_markdown_plus` + `markdown` AST), KaTeX math, code highlight, scroll sync |
| `links/` | Wikilink/Markdown-link parse + resolve (single parse rule shared by editor, preview, indexer) |
| `search/` | FTS query builder (user text is never raw FTS), field/tag queries, replace |
| `frontmatter/` | YAML parse, known fields (`title tags date pinned aliases`), field repo |
| `templates/` | Substitution engine (`engine.dart`), directives, includes, `ask`/`choice` prompts, counters |
| `todo/` | todo.txt line model, file store, filters, reminder scheduling backends |
| `spellcheck/` | hunspell (desktop) / system IME (Android) providers, per-library personal dictionary layered in front (right-click *Add to dictionary*) |
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
  index. Preview and editor share one tokenizer for links.
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

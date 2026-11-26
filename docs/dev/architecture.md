# Architecture

## Principle

**Disk is source of truth.** One note = one `.md` file. SQLite (drift)
is a rebuildable per-library index (FTS5 search, tree rows, frontmatter
fields) — it stores nothing that cannot be reconstructed from disk.

## Layout (`lib/src/<module>/`)

| Module | Contents |
|--------|----------|
| `core/` | Settings (`settings/library_config.dart`), logging, the in-flight isolate gauge (`isolate_gauge.dart`), storage access, themes and their `.json` transfer, language, shortcuts/launch args, share-in (`share_in.dart`), the first-run state (`welcome.dart`), single instance, the tray, the changelog parser, running a program with a timeout (`process_run.dart`) |
| `update/` | The GitHub-Releases update check, its scheduler and the download of the next build |
| `library/` | Library open/session state, note file ops, the note write path (`NoteWriter`), watcher, image/audio import, Markdown import |
| `import/` | Bringing a Notion export into the library (#25): the zip walk, page ids off the names, links rewritten, assets kept; and, in `html/`, an HTML file converted into a note on its own isolate (#1293: `html_page`, `html_note`, `html_convert_job`, `html_conversion`), or, for a page that is a book, into a folder of notes (#1294: `html/book/`, an AO3 profile and a rule by headings), planned by `book/` — the plan, the destinations and the moving in the EPUB conversion shares — whose UI is `ui/html_convert_flow.dart` and, for a drop, `ui/html_drop_flow.dart` |
| `export/` | What leaves the app: a note's one-page HTML (`note_html.dart`, `html_*`), the PDF through the system browser and its drawn fallback (`export_pdf.dart`, `pdf_webview.dart`), the EPUB books (`epub_book.dart`, `epub_note.dart`) and the folder/library zips (`export_tree*.dart`) |
| `workspace/` | The open notes of one library on one device: panes, tabs and their mementos — see [workspace.md](../records/workspace.md) |
| `journal/` | The journal's day pattern, settings and calendar summaries (see [journal](../user/journal.md)) |
| `reading/` | Where each PDF and each book was left, kept in `.niman/reading.json` |
| `flashcards/` | Decks (#533): the cards read from a note (`Deck.read`), the SM-2 scheduler and the study session, the review states kept in `.niman/review.json`, and the deck catalog Study counts from — see [flashcards.md](../records/flashcards.md); the deck view and the review are `ui/kinds/flashcards/`, Study and its settings `ui/study/` |
| `annotations/` | A file's companion notes, the annotation model and its marks — see [annotations.md](../records/annotations.md) |
| `capture/` | Capturing a web page as a note (#531): the download and its charsets (`fetch/`), a Dart port of Mozilla's Readability.js (`readability/`, held to upstream's test pages), the pictures into the attachments folder, the note — see [web-capture.md](../records/web-capture.md) |
| `epub/` | Reading an EPUB within bounds into its parts (`epub_archive`, `epub_info`, `epub_book`), joined for the reader (`epub_document`) or converted into notes (#1138: `epub_convert_plan` over `import/book/book_plan`, `epub_convert_render`, `epub_convert_job`, `epub_conversion`), its look and its marks — see [epub-reader.md](../records/epub-reader.md) |
| `history/` | `.history/` versions: snapshot policy, the store (content-addressed objects, deltas, an append-only log a note, the upkeep that packs and collects; all off-isolate), `NoteHistory` service — see [sync.md](../records/sync.md) and [history-store.md](../records/history-store.md) |
| `diff/` | Myers line diff with its hunk summary, and the three-way merge over them, shared by history rollback and sync conflicts |
| `sync/webdav/` | WebDAV client on `dart:io` (streamed GET/PUT, PROPFIND parsing, typed failures) and the capability probe — see [sync.md](../records/sync.md) |
| `sync/transfers/` | The bulk transfers of a sync run (download, hash-by-download, upload): a worker isolate per run in production, the run's own client in tests — see [sync.md](../records/sync.md) |
| `sync/` | Sync state store (`sync_destinations`, `sync_items`, `sync_ops`), secure password store, pure reconcile, the engine (full and quick runs), the trigger scheduler and network monitor, and `LibrarySyncService` for the UI |
| `ui/sync/` | WebDAV settings screen (with the trigger options), status icon and panel (with the queue), first-sync and mass-deletion dialogs, conflict screen (merge by region, or whole copies) |
| `db/` | `AppDatabase` (app settings, migration chain) + `IndexDatabase` (one per library, no migration chain: a schema bump drops every table and rescans, so deleting the file rebuilds it too); the indexer facade, the full scan that reconciles one directory at a time with bounded memory (#302), the tree materialization and the content store |
| `markdown/` | The one Markdown surface ([unified-surface.md](../records/unified-surface.md)): `SourceBuffer`, the block scanner and parser (over the `markdown` AST), the styler, the surface controller, and under `render/` the source view (modes `source` and `live`, the WYSIWYG) and the read view (the preview); `edit/` holds selection, caret motion, input, history and find; `from_html/` turns HTML into Markdown (an EPUB's chapters, captured pages) |
| `editor/` | What the surface is driven by: the incremental tokenizer (`highlighting.dart`), the Markdown commands (`md_editing.dart`), toolbar and its layout, context menu, find bar, outline, word count, list tally, typewriter and note column |
| `preview/` | KaTeX math (typesetting, cache, rasterizing), code highlight, image aspect — what the surface draws with |
| `links/` | Wikilink/Markdown-link parse + resolve (single parse rule shared by editor, preview, indexer) |
| `search/` | FTS query builder (user text is never raw FTS), field/tag queries, excerpts and the contains scan read from the notes, replace |
| `frontmatter/` | YAML parse, known fields (`title tags date pinned aliases`), field repo |
| `templates/` | Substitution engine (`engine.dart`), directives, includes, `ask`/`choice` prompts, counters |
| `todo/` | todo.txt line model, file store, filters, reminder scheduling backends; the next copy of a recurring task (`recurring_line.dart`, #1189); the links between tasks and notes (`task_link*.dart`, #1152) and the `todo` fence that draws the tasks it asks for (`todo_block_*.dart`) — see [recurring-tasks.md](../records/recurring-tasks.md) and [todo-note-links.md](../records/todo-note-links.md) |
| `calendar/` | `calendar.txt` beside `todo.txt`: the line parser, the file store and writer, the events of a day and, for a repeating one, its occurrences read from the rule (`calendar_recurrence.dart`, #1190) with `except:`/`until:` — see [calendar-txt.md](../records/calendar-txt.md) and [recurring-events.md](../records/recurring-events.md) |
| `home/` | A library's Home (#535): its tiles and actions, and the `.niman/home.json` layout that syncs key by key — the screens are `ui/home/` |
| `kanban/` | A board read from a note's text (`board_parser.dart`, `KanbanBoard`) and the byte-stable edits of its columns and cards — see [kanban.md](../records/kanban.md); the view is `ui/kinds/` |
| `diagrams/` | The Mermaid engine of Niman's own (#530): a parser per diagram kind behind `mermaid_parser.dart`, a layout, and one drawing (`diagram_renderer.dart`) that targets the Flutter canvas for the screen and live mode or the SVG target for an export |
| `lint/` | The rules of the Markdown corrector behind *Tidy the Markdown* (`lint_rule.dart`): list, fence, paragraph and hard-break fixes, each switchable per library |
| `ocr/` | Text recognition (#532): the Tesseract bindings and where the engine comes from (bundled or downloaded), the languages, the job queue and worker, and the `.ocr.md` note a recognition writes beside its file — see [ocr.md](../records/ocr.md); the screens are `ui/ocr/` |
| `spellcheck/` | hunspell (Linux), the system checker (Windows: `windows_spell_checker.dart`; macOS and iOS: `apple_spell_checker.dart`) and the system IME (Android) providers, per-library personal dictionary layered in front (right-click *Add to dictionary*) |
| `transcription/` | On-device speech-to-text for audio notes (whisper_ggml): model catalog, downloads, the model directory, transcription settings — see [transcription.md](../records/transcription.md) |
| `ui/` | Shell, tree, settings screens, shared widgets; `ui/welcome/` is the first-run deck (#266) and `ui/tour/` the guided tour with its target registry; `ui/kinds/` the views of the note kinds (`type:`) |
| `widget/` | Android home-screen widgets: placement, payload, refresh, theming, background row ops (native Kotlin providers in `android/app/src/main/kotlin/dev/niman/niman/`) |

`packages/` holds two path packages: `niman_apple`, the Swift native code
macOS and iOS share (audio decoding, the PDF export, the clipboard's HTML,
the page reader of web capture, quick actions and background time — see
[apple-platforms.md](../records/apple-platforms.md)), and
`ffmpeg_kit_flutter_new_min`, a copy of the FFmpeg plugin `whisper_ggml`
depends on, put in place of the published one by `dependency_overrides` and
left out of the Apple builds.

State: Riverpod. No god classes — one class per file, split at ~300
lines or when responsibilities mix.

## Key flows

- **Open library:** read `.niman/settings.json` and the device's share
  (`library_device_settings`, `LibraryConfig.deviceKeys`) once into
  `LibraryConfigRepo` (cached per session) → scan files off the UI
  isolate (`Isolate.run` — every stat is a FUSE round trip on Android) →
  upsert into `IndexDatabase` on main. An index that has rows is ready at
  once and reconciled with the disk behind the ready bump; an empty one
  gets its tree first and its notes read behind it — no open waits for a
  full walk, whichever screen it came from (#1073). Behind the ready bump, a sweep off
  the UI isolate removes the `.niman-tmp-*` files a killed write left
  (`core/files.dart`, #379), taking only files older than
  `staleTempMinimumAge` so a write in flight is never touched.
- **Keeping the index current:** the file watcher carries live changes;
  the full walk (`Indexer.fullScan`) is the net under it, run by
  `RescanScheduler` (`library/rescan_scheduler.dart`, #1067): one walk at a
  time (a request during one shares a single follow-up), the next periodic
  one scheduled after the last ended — ten times its duration at least,
  five minutes at least, three times that while the watch is healthy — and
  none while the app is in the background or hidden. A watch that restarts
  (`missedChanges`) and the manual rescan ask for a walk at once. The
  watcher's batches run through `WatchBatchQueue` — one in flight, the ones
  that arrive meanwhile merged into one (#1062). A move the OS paired with
  its destination is those two paths; only a move with no known destination
  reconciles its parent folder, against a listing of that folder's own
  entries (`IndexTree.syncDirLevel`), never its subtree.
- **Folder rename and move:** the app's own rename or move of a folder is
  `Indexer.relocateFolder` (`db/index_move.dart`, #1063): one statement
  rewrites the paths of every row under it, so no note is read and every
  note keeps its id — with its full-text row, tags and link edges. Only the
  notes with a link that reads from their own folder (an edge to a note
  outside the folder, a dead Markdown or `../` link) are read again. A move
  the index cannot carry (a destination that is already indexed, a disk that
  does not show it) goes through `applyEvents` as an external change does.
- **Tree rows:** the tree holds the rows its list can draw, not the rows it
  has scrolled past (#1200, `docs/records/tree-window.md`). `VisibleTree`
  (`ui/visible_tree.dart`) is the list without its rows: the root's child
  count and, for each expanded folder, its rank among its siblings and its
  child count (`NoteDao.childCount`, `rankOf`), from which an index maps to a
  `(folder, position)` and back. `TreePages` (`ui/tree_pages.dart`) keeps the
  pages of rows around the viewport, each a run of 2000 positions of one
  folder: read by keyset from a neighbour held (`childrenPage`, `after:` or
  `before:`) or, with none, by position (`childrenAt`), and let go when the
  list's own layout leaves them (`TreeRowsDelegate` tells the widget what it
  built). `NoteTree` draws them in a `SliverFixedExtentList`: a row whose page
  is not loaded is an empty row of the same height, its page asked for after
  the frame. A text recognition sidecar is nested within its page
  (`TreeListing`), and the row being made is one virtual row under its folder's
  (`ui/tree_listing.dart`). The keyboard's walk, the cursor and the marks hold
  paths, and find a path's index by its rank; a typed name is asked of the
  index run by run (`TreeNameSearch`, `firstChildStartingWith`) when the rows
  in memory do not answer, and a Shift+click range is read a page at a time
  (`TreeRangeReader`). Closing a folder drops its pages and keeps its count.
  A new revision forgets what it moved: a reindex of a note in place or a pin
  names the note's folder (`Indexer.changedFolders`), the session keeps what
  each recent revision moved (`TreeMoves`, `foldersMovedSince`), and the tree
  and the folder grid re-read those folders and the pinned notes alone
  (#1132); any other change, or a new order, forgets everything. While a newer
  read is out the rows on screen are drawn from the pages they had, so a
  change does not blank the tree. In a name order a page walks the
  `notes_tree` index (`(parent, is_dir DESC, name_key, name)`; `name_key` is
  `nameSortKey`: case and accents folded, digit runs by value, #1070) and
  sorts nothing. One read of the model runs at a time with one waiting behind
  it; the pinned notes come from the `notes_pinned` partial index (#1065) and
  are read once per revision.
- **Edit:** `NoteOps.saveNote` → history snapshot and atomic write
  (temp + rename) in one isolate pass → the note is rescanned into the
  index, never beside a write of it: a reindex due while the note's saves
  run waits for them, and a save asked for while one reads the note cancels
  it (`NoteWriter`, #1132). Every mode of the surface shares one tokenizer for links. Every
  atomic write — the joined one and the streaming one alike — ends in
  `publishTempFile` (`core/files.dart`): the temp file is flushed to storage
  before the rename, so a power cut after it cannot bring the note back
  empty (#1058).
- **Sync download:** a note lands the same way (snapshot + rename on an
  isolate). An **attachment** has no snapshot, so it lands through
  `swapFileIn` on the calling isolate instead — a stat, a mkdir and a
  rename are async I/O that never block the loop, and an isolate around
  async-only work buys nothing. On Windows that rename hangs on the third
  attachment of every run, so it is given three seconds and then the
  bytes are copied instead: a workaround for
  [#103](https://github.com/Nihmar/Niman/issues/103). See
  [sync.md](../records/sync.md) for what has been ruled out.
- **Isolate jobs:** the scan, probe and write passes above go through
  `IsolateGauge.run` (`core/isolate_gauge.dart`) instead of `Isolate.run`
  directly, which logs each job's start and finish with how many are in
  flight, and warns when one outlives 10 s. A job that hangs otherwise
  logs nothing at all — an exported log then shows a gap and no reason,
  which is what made #103 unreadable until the gauge went in.
- **Search:** `search/query.dart` builds a safe FTS5 MATCH (tokens quoted,
  prefix `*` on last token only); `key = value` and `#tag` take the field
  and tag paths instead. The FTS table is contentless (`content=''`): it
  holds the word index and no copy of the text, which made the index file
  as large as the notes. A word result's excerpt and the contains scan read
  the note on disk, on an isolate and only up to the first match
  (`search/search_excerpt.dart`).
- **Reminders:** first valid `rem:YYYY-MM-DDTHH:MM` per task schedules an
  exact alarm (Android plugin backend, desktop backend); health/warnings
  surface permission problems.
- **Home-screen widgets (Android):** placed instances are pushed a
  payload whenever the todo snapshot or pinned note moves; rows render
  natively (RemoteViews) and row taps come back as `niman://` intents
  handled off the UI isolate. Placement runs a native config activity
  (library/note pick).
- **Memory:** where the desktop's resident set goes — the three SQLite
  connections and their isolates, the open note buffers, the image and math
  caches, the loaded whisper model — and how to watch it, in
  [memory.md](memory.md) (#511).

## Planned, not built

- Nothing large at the moment. The one Markdown surface that was planned
  here is built (#247): [unified-surface.md](../records/unified-surface.md) is its
  design and record, and [editor-alternatives.md](../records/editor-alternatives.md) the
  measured record of the packages it replaced.

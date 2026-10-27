# Memory usage: where the RAM goes (2026-10-26)

Part of #511 (desktop) and #1144 (Android). This record says what the
running app holds, how much, how that was found, and the fix each holder
asks for — ranked by what it costs a user, not by how easy it is. It stands
beside [performance-audit.md](performance-audit.md) ("Memory": a million
notes cost the open 2 MB) and [huge-notes.md](huge-notes.md) (the 246 MB
note), and does not repeat them.

Nothing here is implemented; each fix has an issue of its own (#1193–#1202).

## How it was measured

Three sources, and each number below says which one it comes from.

1. **The app's own log** (Windows, release and beta, 2026-10-21 to
   2026-10-23). Since #1144 every timed action's line ends with
   `rss <now> MB (peak <max>)`. Read from `niman-log.txt` in the support
   folders of both flavors.
2. **A retention probe under `flutter test`** (JIT, Windows x64, this
   commit). It builds a structure, keeps it, and reads
   `ProcessInfo.currentRss` before and after. It reports the lowest of
   three runs, each after 80 MB of churn to let the collector run. Growth
   is reliable this way and frees are not, so the probe measured only what
   is retained. The probe was a scratch file and is not committed. Issue
   M1 below makes it a test.
3. **Reading the code**, with the arithmetic stated. A Dart string costs
   1 byte per character when every character is ≤ U+00FF and 2 otherwise.
   A pointer slot costs 8 bytes on desktop, and 4 on Android arm64, whose
   pointers are compressed.

What none of these gives is the split of the resident set by owner: Dart
heap, the engine's raster and glyph caches, SQLite, native libraries. That
split needs a heap snapshot over the VM service on a profile build, and
no script in the repository takes one yet (M1).

## What the log says

Windows, a beta build, libraries of 8 to 991 notes:

| Moment | RSS |
|---|---:|
| Library open complete (8 notes), fresh process | 272–276 MB |
| … the first note open after it | 297–302 MB |
| … the rescan after the open | 301–310 MB |
| A 91-note library: open → rescan | 255 → 316 MB |
| Four library switches in a row (289 → 437 → 475 → 484 MB) | +195 MB |
| … then a few notes opened, 20 s later | 451 → 429 MB |
| A 293 k-char note open, after a sync of its library | 511 MB (peak 549) |

Three things follow from this table.

- **The floor is about 270 MB before any note is open.** None of the
  fixes below touches that floor. Without a breakdown it cannot be said
  how much of it is the engine (Impeller or Skia, the GPU process's
  mapped memory, the ICU data) and how much is ours. Attributing it is M1.
- **The climb across library switches comes back down.** It falls by
  about 70 MB within a minute without a new library, so it is garbage the
  collector had not reached yet, not a leak. Each close does release its
  databases: `library_state.dart:1857-1871` closes the sync service, the
  search connection and the index connection. But the peak is what
  Android weighs when it chooses an app to kill. That a close leaves
  ~40 MB for the collector is worth knowing, and M1 says what that 40 MB
  is.
- **A rescan of a 91-note library adds 60 MB to the peak**, against the
  8 MB that 2 000 notes cost on Linux (performance-audit.md). The
  difference is on Windows and unexplained, and M1 attributes it too.

## The findings, ranked

The ranking weighs two things: how much a finding holds, and how many
users ever reach it. Findings 1 and 2 reach every user who has pictures
in their notes. Findings 3 to 6 matter only for the novel-length notes
the app is designed to open. Findings 7 and 8 matter for a library of a
million notes.

### 1. Pictures are decoded at full resolution

- **What it holds.** `EmbedView` draws a note's picture with
  `AspectImage(provider: FileImage(File(path)))`
  (`markdown/render/embed_view.dart:131`, `aspect_image.dart:112`). The
  attachment viewer uses `Image.file` (`ui/attachment_view.dart:203`).
  None of them passes `cacheWidth` or `cacheHeight`, and no `ResizeImage`
  wraps the provider. Each picture is therefore decoded at its file's
  pixel size, whatever size it is drawn at.
- **How much (arithmetic).** RGBA costs 4 bytes per pixel. A 12 MP phone
  photo (4000×3000) decodes to **48 MB**. Drawn 800 logical pixels wide
  at a device pixel ratio of 2, it needs 1600×1200, which is **7.7 MB**.
- **Why it adds up.**
  - Flutter's image cache keeps up to 100 MB of decoded pictures by
    default, and the app never changes that.
  - A picture still on screen, or in a mounted widget, is held whatever
    the cache keeps.
  - The workspace keeps four tabs mounted besides the one showing
    (`ShellWorkspace.keptAlive`, `ui/shell_workspace.dart:42`, a decision
    of #23).
  - A note keeps its read pane mounted behind the editor
    (`ui/note_view.dart:2551`).
  - So five notes with photos keep every one of those photos at full
    resolution.
- **Fix.** Decode at the size the picture is drawn at. The embed knows
  its width from layout, so it can wrap its provider in
  `ResizeImage(provider, width: (drawnWidth × devicePixelRatio).ceil(),
  policy: ResizeImagePolicy.fit)`. When the layout width changes by more
  than a bucket, the embed decodes again. The attachment viewer decodes
  at the viewport's size and decodes again at the zoom it settles on.
  Only that viewer needs pixels beyond the screen. This is not a cap: the
  picture keeps every pixel it can show.

### 2. Nothing answers memory pressure

- **What it holds.** No class in `lib/` overrides
  `didHaveMemoryPressure`. Flutter's binding already empties the image
  cache when Android's `onTrimMemory` arrives (on desktop it never does).
  Nothing of ours is emptied: `ReadParser`'s blocks (finding 5), the
  spelling verdicts (finding 9), the tree's loaded folders (finding 7),
  `diagramCache`, or the math rasters. Nothing of ours is dropped either
  when the app goes to the background (`AppLifecycleState.paused` is
  handled only to save, `note_view.dart:2400`, `shell.dart:2901`).
- **How much.** It is the sum of findings 5, 7 and 9 at the moment the
  system asks. On a phone that is the difference between being kept in
  the background and being killed.
- **Fix.** Add one registry in `core/` for the caches that can be rebuilt
  (`MemoryReclaim.register(() => cache.clear())`). It runs on
  `didHaveMemoryPressure` and on `paused`. Every cache in this record
  that is rebuilt on demand registers with it. Nothing on disk is lost,
  because every one of these caches is rebuilt from the note or from the
  index (the design rule "disk is the source of truth").

### 3. A huge note's blocks cost 98 bytes a line

- **What it holds.** `BlockScanner` keeps a `Block` per block
  (`markdown/block.dart`: 15 final fields, most of them zero or null for
  most blocks: `fenceInfo`, `entering`, `footnote`, `definition`,
  `reach`, `divRole`, `divDepth`, `quoteDepth`, `listOrdinal`). It also
  keeps a `LineState` pointer per line in `_entering`
  (`block_scanner.dart:98`).
- **How much (probe).** On a generated note of 1 M lines (22.9 M
  characters, 1 000 001 blocks), the scanner retained **93–94 MB**: 98 B
  per block, or per line. Measured three times on two runs. The buffer
  over the same text retained 7 MB (7 B a line). The scanner is
  therefore **13 times the buffer** and four times the text itself.
  Scaled to the stress note (2.76 M lines, 2.01 M blocks), that is about
  **270 MB**. The editor, the read pane and the reference cache share one
  scanner after the hand-over (huge-notes.md).
- **Fix.** Store the blocks the way the height map stores heights: in
  chunks of 1 024 typed arrays. The chunks hold `Int32List` start and end
  lines and a `Uint8List` kind with packed depths, and the rare fields
  (fence info, footnote, definition, div role, reach) go to a side map
  keyed by block index. `Block` becomes a view made on read.
  `_entering` becomes a `Uint16List` of ids into an interned table of
  `LineState`s, which are immutable and few. The estimate is ~20 B per
  block, about **55 MB instead of 270** on the stress note. The chunking
  and copy-on-write the scanner already has carry over.

### 4. After an edit, a huge note is joined whole and kept twice

- **What it holds.**
  - `NoteView._unifiedText` (`ui/note_view.dart:847-858`) joins the
    buffer with `buffer.text` whenever the revision has moved. It keeps
    the result in `_unifiedTextCache` until the next revision.
  - The text the note was loaded from stays pinned meanwhile. Every
    unedited `LineChunk` is a view of it (`markdown/line_chunk.dart:23`),
    so it is freed only once every chunk has been written.
  - The tags dock (`ui/dock/tags_dock_pane.dart:85`) asks for
    `note.currentText` on every outline change, which comes after every
    pause in the typing. That is a full join per pause, kept by the
    cache.
  - The same happens in the other callers of `currentText`
    (`note_view.dart:711`, `:1088`, `:2448`; making flashcards; presenting
    slides).
- **How much (arithmetic).** One more copy of the note per edited
  revision: 247 MB on the stress note (Latin-1), 494 MB if a single
  character is past U+00FF. Live at the same time as the pinned original.
- **Fix.**
  - The dock reads the tags from what the scan already keeps:
    `NoteReferenceCache` holds them block by block for a long note, as
    the index does at save time.
  - Every other caller asks the buffer for what it needs (a slice, the
    head, a stream). `_unifiedHead` already does this.
  - `_unifiedTextCache` then holds nothing for a buffer-backed note. The
    joined text exists only inside a call that truly needs the whole
    string, and is dropped when that call returns.

### 5. The read view's parse cache grows for as long as nothing is typed

- **What it holds.** `ReadParser._cache` (`markdown/read_parser.dart:32`)
  is a `Map<int, ReadBlock>`, with one inline AST per block ever drawn. It
  is cleared only when the buffer's revision moves (`:65`).
- **How much.** It grows with the blocks scrolled past since the last
  edit. Reading a huge note end to end in the read view parses every one
  of its 2 M blocks, and the cache keeps every one. No probe measured it.
  A `ReadBlock` is an AST and so larger than a `Block`, which puts the
  total at hundreds of MB.
- **Fix.** Key the cache by the blocks the view has laid out, and drop an
  entry when its block leaves the viewport's extent. `SourceStyler`
  already keeps its parses bounded in this way (`_parses`, 4 096
  entries). Coming back to a block costs one parse again, which is the
  cost of the first time.

### 6. A note opened straight in the read view is scanned twice

- **What it holds.** The read pane reuses the editor's scan only if the
  editor was mounted first (`knownScan`, from `_editorScanOf`, `ui/note_view.dart:2204`).
  Opened in preview, the pane runs `scanInBackground` and builds its own
  blocks. When the source pane mounts later, `SourceStyler.inBackground`
  builds a second set.
- **How much.** A second finding 3: about 270 MB on the stress note, for
  as long as both panes are mounted, which is as long as the tab
  (`note_view.dart:2551`).
- **Fix.** Make the hand-over go both ways. Whichever pane scans first
  owns the `BlockScanner`, and the other one rebinds to it
  (`BlockScanner.rebound`).

### 7. The tree keeps every folder ever opened, and flattens all of them

- **What it holds.** `TreeChildCache._folders`
  (`ui/tree_child_cache.dart:34`) keeps the loaded `List<Note>` of every
  folder ever expanded. Collapsing a folder keeps its list. A folder's
  pages accumulate as the user scrolls (`loadMore`, 2 000 rows a page).
  The flattened `_Rows` list adds a row object per loaded child of every
  expanded folder (`ui/tree.dart:~927`).
- **How much (arithmetic).** A drift `Note` has 13 fields, two of them
  `DateTime`s, and its path is around 40 characters. That comes to about
  500 B. Scrolling through a folder of a million notes keeps **~500 MB**,
  plus 48 MB of rows. Opening the library holds none of it
  (performance-audit.md: 2 MB). This is the use after the open.
- **Fix.** Window the pages: a folder keeps the pages around the viewport
  and re-reads the others with the keyset query it already pages with
  (`after:`). Collapsing a folder drops its pages. The flattened rows go
  as well: the row at an index can be computed from the per-folder
  counts, as `_walkRow` already does for the keyboard
  (`tree.dart:343-400`).

### 8. Syncing the library root reads every row

- **What it holds.** `IndexTree.syncDirSubtree` with an empty path
  (`db/index_tree.dart:581`) calls `NoteDao.allRows()` and builds a
  `Map<String, Note>` of the whole table. It also walks the whole disk
  subtree into a list.
- **How much (arithmetic).** Transient: ~500 MB of rows plus the map at a
  million notes, while the call runs. It is reached when the watcher asks
  for the root to be synced as a subtree.
- **Fix.** Diff a directory at a time, as `fullScan` already does
  (index-reconcile.md: bounded memory). Or give the root the scan itself,
  which is what a root resync is.
- **Corrected while fixing it (2026-10-27, #1201).** The branch is not
  reached. `IndexTree.safeRel` drops the library itself from every event
  batch and every resync, so the watcher never asks for the root as a
  subtree. This finding came from reading the branch, not from following
  its callers. What #1201 did: `syncDirSubtree` hands an empty path to
  `syncDirLevel`, `subtreeRows` no longer reads the library for one, and
  `allRows` is for the tests. Nothing was measured, because there was
  nothing to measure.

### 9. Smaller holders, each growing with use

- **Spelling verdicts.** `EditorSpellCheck._words` and `_suggestions`
  (`spellcheck/editor_spell_check.dart:229`, `:384`) keep one entry per
  distinct word ever checked. They are cleared on a dictionary change
  only. That is the vocabulary of every note opened in the session, so a
  few MB. They also stay when spelling is switched off (`setEnabled`
  clears only the lines, `:292`). On Linux the hunspell engines stay
  loaded while spelling is off. On Windows the engine is the system's.
  - Fix: switching off disposes the engines and the verdicts, and
    switching on loads them again. The verdicts register with finding 2.
- **What the writer remembers.** `NoteWriter._written`
  (`library/note_writer.dart:79`) keeps one `KnownContent` per note saved
  in the session (hash, size, time, sometimes the references). The
  reindex reads it (`:424`) and never removes it. That is 150–300 B a
  note, so small. But it grows with the number of saves and serves no
  purpose once the index has the save.
  - Fix: the reindex takes the entry out (`remove`, not a lookup).
  - **Corrected while fixing it (2026-10-27, #1202).** The entry does
    serve a purpose after the reindex. The next save of the note asks it
    whether the file on disk is this writer's own (`lastWritten`, #1055),
    and removing it would turn the app's own write into somebody else's.
    Only the references are the reindex's alone, and they are the large
    part for a long note. The reindex now takes them and leaves the stamp
    and the digest.
- **The note that is leaving.** `NoteView._load` (`ui/note_view.dart:1416`)
  keeps the old surface until the new note has been read: the buffer,
  the scanner, the undo history, `_unifiedTextCache` and the preview's
  snapshot. Switching between two huge notes in one pane holds both at
  the peak.
  - Fix: once the save has been handed off, release the old surface
    before the read starts.
  - **Found while fixing it (#1202).** `NoteStatsController._revisionOf`
    kept the old surface as well: it remembers which surface its count is
    of, and it now holds that surface weakly. A retaining path taken over
    the VM service (`flutter test --enable-vmservice`, `getRetainingPath`)
    then ends in Flutter itself. `SliverMultiBoxAdaptorElement` keeps a
    stale `_currentBeforeChild` into the unmounted pane until that list
    lays out again. That is the framework's, and short-lived.

## Ruled out

These were suspected, and each one turned out not to hold memory worth
an issue.

- **Todo and calendar.** The probe measured 193 B retained per parsed
  task (200 000 tasks: 36.8 MB), so a list of 10 000 tasks costs about
  2 MB. The controllers open eagerly with the library
  (`ui/shell.dart:2697`), on purpose, because reminders are reconciled
  from them. Gating them behind the library's features is #1109's job,
  not a memory fix. `TodoModelCache` holds pointers to the same entries,
  and it dies with the tab.
- **Isolates copying the note.** `Isolate.run` shares immutable strings
  within the isolate group rather than copying them. So the three
  background scans of a huge note (read view, editor, word count) copy
  only their mutable lists, as the comment at
  `editor/word_count_index.dart:181` says.
- **Undo.** It keeps deltas, not snapshots, and is bounded to 200 steps
  and 16 M code units (`markdown/edit/edit_history.dart:56-60`).
- **Search.** Results are `LIMIT`ed (200), and excerpts are read per
  visible row.
- **SQLite.** There are two connections per open library (index and
  search), each in its own background isolate. Each uses SQLite's default
  ~2 MB page cache and no `mmap`. A closed library closes both. No drift
  `.watch()` keeps a result set alive.
- **Whisper.** The model (78–488 MB) is resident only while the queue
  has work. It is released when the queue drains
  (`transcription/transcription_queue.dart:221`).
- **OCR.** The recognizer is closed after each job. A page's raster
  (~60 MB at 4200 px) is transient, inside the job's isolate.
- **Android.** No `largeHeap` is set. The headless engine that a widget
  tap starts is short-lived. The widget services cache at most 100 rows.
- **Fonts and assets.** 1.3 MB in all.

## The issues

| # | Fix | Platforms | Measured by |
|---|---|---|---|
| M1 (#1193) | A memory probe: a `test/perf/` file that prints retained bytes per structure (scanner, buffer, tree page, task), plus a script that takes a VM-service heap snapshot of a profile beta build at the log's points. It attributes the 270 MB floor, the 40 MB a library close leaves, and Windows' 60 MB rescan | all | itself |
| 1 (#1194) | Decode pictures at their drawn size (`ResizeImage`); the attachment viewer decodes again at its zoom | all | a widget test: a 4000×3000 picture drawn 400 wide decodes to ≤ 800×600 at a ratio of 2 |
| 2 (#1195) | One registry of rebuildable caches, emptied on memory pressure and on `paused` | all (pressure: Android) | a unit test that each registered cache is empty after the signal |
| 3 (#1196) | Typed-array blocks and interned line states in `BlockScanner` | all | the probe: bytes per block, from 98 to ~20 |
| 4 (#1197) | No whole-note join for a buffer-backed note: tags from the scan, callers on slices | all | the probe: retained bytes after an edit plus a pause, on the 1 M-line fixture |
| 5 (#1198) | `ReadParser` keeps only the blocks around the viewport | all | a test: scroll through 100 k blocks, cache size stays near the visible count |
| 6 (#1199) | One scanner per note whichever pane scans first | all | a test: preview-first then source holds one `BlockScanner` |
| 7 (#1200) | Windowed tree pages and no flattened row list | all | `tree_queries_perf_test`: retained bytes after paging through a folder of 1 M |
| 8 (#1201) | A root resync that diffs a directory at a time | all | `index_scale_test`: retained bytes of a root resync at 1 M |
| 9 (#1202) | Spelling switched off releases its engines and verdicts; the writer forgets a save the reindex took; the old note is released before the next loads | all | unit tests per item |

Every fix lands on Android, Linux and Windows together. None of them
changes what a user sees.

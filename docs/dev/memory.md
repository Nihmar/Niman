# Desktop memory: where it goes, and how to watch it

Issue #511: investigate where the desktop app (Linux and Windows) spends its
resident memory, and bring it down.

## Status and method

This is the **code audit** half of the investigation. The absolute numbers
are in [memory-usage.md](../records/memory-usage.md): the resident set the
app's log prints, the floor of about 270 MB attributed by owner with
`tool/memory_report.dart` (#1193), and nine holders ranked with the fix
each asked for. Those fixes shipped in 0.3.2 (#1194–#1202): pictures decoded
at the size they are drawn, the registry of rebuildable caches (see "Giving
memory back"), the block scanner's typed arrays, no whole-note join, the
read view's parse cache bounded, one scanner per note, the tree windowed,
a root resync a directory at a time, and the smaller holders. A fix asks for
a printed before/after, so the figures land with the change that moves them.

What *is* in this file: the owners of desktop memory, read from the code,
with their limits and lifetimes; what is kept for notes and tabs that are
not visible; and how the scale rule (1M notes, novel-length files) holds up.
Every claim carries the file — and, where it helps, the symbol — to check
it in; line numbers are left out, since they move with every change.

## How to measure

Run a **profile** build on the machine to characterise (`flutter run
--profile`), then in DevTools (or the VM service memory view) record:

| State | What to capture |
|---|---|
| Idle, library open, one note | Dart heap, external, RSS |
| A 100k-note library open | after the first full scan, after it is idle |
| Many tabs (20+) open | after each is opened, then after all are closed |
| A novel-length note open (10 MB+) | heap while typing, after the note closes |
| After switching libraries 5× | does RSS return to the idle figure? |
| After an hour of editing | the same, plus whether the heap has a floor it never drops below |

The VM service also breaks the Dart heap down by class
(`getAllocationProfile`), which is where the open note buffers, undo history
and parsed spans show up.

The same engine switches that open the timeline open the memory too
(`FLUTTER_ENGINE_SWITCHES=2`, `FLUTTER_ENGINE_SWITCH_1=vm-service-port=8181`,
`FLUTTER_ENGINE_SWITCH_2=disable-service-auth-codes`, set before the
profile build's executable starts). With them, `tool/memory_report.dart`
prints at the moment it runs what the app's resident set is made of (#1193):

```
dart run --packages=.dart_tool/package_config.json tool/memory_report.dart --label "library open"
```

- **The process, as the VM attributes it** (`getProcessMemoryUsage`): the Dart
  VM with each isolate group's heap, then every mapping the process holds,
  the largest first — the engine's library, the GPU driver, the system's.
  What the VM cannot name is in those mappings and in the difference from
  the resident set the log prints.
- **Each isolate group's heap after a collection**: the UI isolate with the
  `Isolate.run`s it spawned, and each drift connection's isolate. An isolate
  group shares one heap, so it is one figure per group.
- **The classes holding most of each heap**, as `--top` says (15 by default).

A test reads the same heap for one structure: `test/perf/heap_meter.dart`
answers how many bytes an object holds, after a collection, when the run has
the VM service (`flutter test --enable-vmservice`), and falls back to the
resident set — a bound, and a poor one — when it has not.
`test/perf/memory_retention_test.dart` prints what an open note's buffer, a
page of the tree and a list of tasks hold that way. Exact on 2026-10-27:
21 B a line, 697 B a row, 775 B a task, where the resident set had read 7
B a line and 193 B a task.

## Owners

### Dart heap

| Owner | What it holds | Bound / lifetime | Code |
|---|---|---|---|
| Open note text | One `SourceBuffer` per open note (the whole file, in memory) | One per open tab; dropped when the tab closes; the library's workspace is disposed on `close()` | `lib/src/markdown/source_buffer.dart`, `lib/src/workspace/workspace_controller.dart` |
| Undo history | Up to 200 `EditStep`s per note, each holding the removed and inserted text; an edit over a long span keeps only the lines that changed (`line_hunks.dart`) | `EditHistory.limit = 200` steps **and** `EditHistory.defaultBudget` = 16 M code units (32 MB of UTF-16) of text, the oldest dropped first and the newest never (#1050); one per open note, owner's history survives a tab move but not library close | `lib/src/markdown/edit/edit_history.dart`, `edit_step.dart`, `line_hunks.dart` |
| Parsed / highlighted spans | `SourceStyler`'s line store, block list and per-line tokens for every open note; the read view's block heights | Per open note; rebuilt on edit; released with the note | `lib/src/markdown/source_styler.dart`, `lib/src/markdown/render/block_height_map.dart` |
| KaTeX boxes and rasters | Typeset formulas, as boxes (512) and rasterized images (128) | Bounded per `MathCache`/`MathRaster`; one cache per `NoteView` (`_parts.mathCache`, `note_view_parts.dart`), disposed in `NoteView.dispose` | `lib/src/preview/math_cache.dart`, `lib/src/preview/math_raster.dart` |
| Flutter's image cache | Decoded images in the read view and attachments — default **1000 images / 100 MB** | Global to the engine, not per library; released only by age/size eviction | engine (`PaintingBinding.imageCache`) |

The open-note buffers are the largest scaling term: **memory is
proportional to what is open, not to the library**, which is the intended
shape. The thing to confirm by measurement is that closing a tab really
drops its buffer (no `ChangeNotifier` or closure keeps it), and that
`EditHistory`'s steps do not hold a whole novel after a few large
deletions (bounded by text since #1050; the newest step is kept whole, so
one select-all-and-delete of a novel still holds it once).

### The two drift databases and SQLite caches

There are **three connections**, not two:

- `AppDatabase` — app settings, one row; the small one.
- `IndexDatabase` — the library's index (tree rows, stems, tags, links,
  FTS5), on its **own background isolate** (`NativeDatabase.createInBackground`
  in `defaultIndexDatabase`, `library_databases.dart`).
- A second `IndexDatabase` over the **same file** for search, also on its own
  isolate (`defaultSearchDatabase`, `library_databases.dart`).

Each connection carries SQLite's own page cache (a few MiB by default, in
the isolate's native heap) and, for the index, the FTS5 tables. `PRAGMA
auto_vacuum = INCREMENTAL`, `journal_mode = WAL`, `busy_timeout = 5000`
(`indexDatabaseSetup`, `index_database.dart`). The library's two index
connections are `close()`d in `_teardown` (`library_state.dart`); the
`AppDatabase` outlives every library and is closed once, in `dispose`
(same file). So closing a library releases the index
connections and their caches — which matters for "does it return after
switching libraries?".

### Materialized tree rows

Since #1200 the tree holds the pages of rows around the viewport, not the
rows it has scrolled past: `VisibleTree` (`ui/visible_tree.dart`) keeps
only counts, and `TreePages` (`ui/tree_pages.dart`) reads and lets go of the
pages as the list scrolls (see [architecture.md](architecture.md), "Tree
rows", and [tree-window.md](../records/tree-window.md)). At 1M notes the
index holds 1M row objects *on disk*, and the app holds the few pages on
screen: a folder of a million notes held 3.6 MB after a scroll to its end,
against some 700 MB before. `tree_window_memory_test.dart` in `test/perf/`
measures it.

### The PDF engine, the WebView, the EPUB reader

- **Desktop**: exporting a PDF goes through the system browser/Chromium
  (`export_pdf.dart`), a **subprocess** — its memory is not the app's.
- **Android** only: a system WebView (`pdf_webview.dart`) is created for the
  print and destroyed by the bridge. Nothing here holds a WebView open on
  the desktop.
- **EPUB**: read in process (`epub_pane_state.dart`, its own `MathCache`),
  freed with the pane.

### Spell-check dictionaries

hunspell (desktop) loads `.dic`/`.aff` per selected dictionary
(`spellcheck/hunspell_spell_checker.dart`); Windows uses the system checker. A
dictionary is a few MB each and several can be selected
(`LibraryConfig.spellDictionaries`). The loader is per library; confirm the
maps are dropped on library close and not re-read per keystroke.

The editor keeps the answer for each line it has underlined
(`spellcheck/checked_lines.dart`): a bounded least-recently-used memory of
4096 lines and 2 M characters, keyed by the line's text and the ranges it
skips rather than by its index (#1052), so scrolling a large note does not
keep a second copy of it and an Enter above a line does not make it be
checked again. The per-word verdicts (`EditorSpellCheck._words`) are bounded
by the note's vocabulary.

### Whisper models

The transcription model is **kept loaded between clips**
(`SpeechTranscriber`, "the model stays loaded after each call; the queue
calls `release()` when it empties"). A whisper model is tens to hundreds of
MB. This is the largest single item that can sit resident with nothing
visibly running, which is why `TranscriptionQueue` releases it the moment
the queue drains and when it is disposed (`_release`); whether it should
also go after a timeout is not decided.

### Background isolates

`IsolateGauge.run` is `Isolate.run` — a short-lived isolate per read, write
and tidy. Each carries its own heap, and peak memory roughly doubles for the
duration of a job (the note exists in the caller's heap and in the
isolate's). The index and search connections' isolates are long-lived and
idle-cheap after warm-up (`_warmIndex`).

## Giving memory back

Flutter empties its own image cache when the system asks for memory; the
caches the app keeps are its own to empty (#1195). A cache that is **rebuilt
on demand** — from the note on disk, a row of the index, or as a pure
function of its input — implements `Reclaimable` (`core/reclaimable.dart`)
and hands itself to `MemoryReclaim.track(this)` where it is made
(`core/memory_reclaim.dart`). The registry holds its owners by weak
reference, so a cache made per note or per widget state needs no unregister
and is never kept alive by it.

`MemoryReclaimObserver` (`core/memory_reclaim_observer.dart`, installed once
in `main`) calls `MemoryReclaim.reclaimAll()` on:

- `didHaveMemoryPressure` — Android's `onTrimMemory` and iOS's memory
  warning (the Linux and Windows embedders send none);
- `AppLifecycleState.paused` — the app went to the background. On a phone
  this is what Android weighs when it picks a backgrounded process to kill.
  `inactive` and `hidden` do not count: they also come with a dialog or a
  covered window while the user is looking at the app.

Each reclaim logs one `memory` debug line with how many owners it asked and
the resident size before and after (the heap itself is only collected
later).

A `reclaim()` lets go of what is kept and **nothing else**: it notifies
nobody, so the editor does not rescan and the views do not rebuild under
memory pressure, and a result still being computed completes as it would
have. The next ask rebuilds what was let go.

| Owner | What is let go |
|---|---|
| `LruCache` | Every entry — the mentions of `MentionReader`, the previews of `PreviewReader`, the lists of `RevisionCache` |
| `ReadParser` | The blocks read, and the buffer remembered for them |
| `SourceStyler` | The parses kept by block content (the lines on screen keep theirs) |
| `MathCache` | Typeset boxes and remembered failures; renders under way land as usual. A formula view that is rebuilt after that asks for its render again |
| `MathRaster` | The images of formulas with path shapes, disposed as an eviction does |
| `diagramCache` | Every laid-out diagram |
| `EditorSpellCheck` | The per-word verdicts and suggestions; not the per-line answers |

Not here, on purpose: the tree's loaded folders (they are what is on screen;
#1200 windows them), open notes and their undo history (user data), and
anything whose loss shows as a reload.

## Scale rule (1M notes, novel-length files)

Read from the code, the hot paths hold a **window**, not the library or the
whole file:

- FTS5 for search; the tree holds the pages around the viewport (#1200); the index
  full scan is **directory-at-a-time with bounded memory** (#302).
- `filePathsUnder` is an index seek, not a walk (`dao.dart`).
- A novel-length note is read in slices for the scan
  (`background_scan.dart`) and saved through a streamed producer
  (`note_write_stream.dart`), so it is not joined on the UI isolate.

The open questions the measurement should answer: does opening several
novel-length notes hold several whole files (it will — one `SourceBuffer`
each), and is that acceptable (it is the editing model, not a leak); and
does `SourceStyler`'s per-open-note state grow past the note (it should be
proportional to the note's lines).

## Candidate fixes

Each is one issue, with a printed before/after (perf tests print; the
absolute bar goes behind `NIMAN_PERF`). The ones the 0.3.2 round of
[memory-usage.md](../records/memory-usage.md) took are marked done; the rest
stay open.

1. ~~**Release the transcription model when it is not needed** (on queue
   drain, or after a timeout, or when the window goes to the tray).~~ Done on
   the queue's drain and on its disposal (`TranscriptionQueue._release`); a
   timeout and the tray are not built.
2. **Drop the engine image cache on library close** (or lower its cap for
   the read view), so switching libraries does not carry decoded images.
   Measure the image cache's current/limit bytes in DevTools. Still open:
   #1194 decodes a picture at the size it is drawn, so the cache holds far
   less, but nothing empties it on a library close.
3. **Verify closed tabs release their note** — a perf-style integration test
   that opens N notes, closes them, and prints the Dart heap from the VM
   service before and after. Still open: #1202 releases the old note before
   the next one loads in a pane, and `memory_retention_test.dart` prints what
   one open buffer holds, but no test closes a tab and reads the heap.
4. ~~**Bound `EditHistory` by bytes, not only by record count**, so 200 large
   deletions of a novel cannot hold it whole.~~ Done (#1050).
5. **Release the search connection when no search screen is open** if the
   measurement shows its isolate/FTS cache is non-trivial at idle.
6. **A resident-memory regression guard**: an integration test (or a
   `NIMAN_PERF`-gated perf file) that opens/closes a library and several
   notes and asserts the process returns near its starting RSS, printed with
   the number it saw. Partly done (#1193): `test/perf/memory_retention_test.dart`,
   `block_memory_test.dart` and `tree_window_memory_test.dart` print what a
   structure holds and gate their bars behind `NIMAN_PERF`; the library
   open/close round trip is still open.

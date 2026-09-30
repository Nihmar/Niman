# Desktop memory: where it goes, and how to watch it

Issue #511: investigate where the desktop app (Linux and Windows) spends its
resident memory, and bring it down.

## Status and method

This is the **code audit** half of the investigation. The absolute numbers
(resident at idle, with a large library, with many tabs, and after long
editing sessions) were **not captured** in the PR that added this file: the
host it was written on cannot run a desktop profile build (the repo says so
for Windows hosts in `AGENTS.md`). The measurement procedure below is the
one to run on a Linux or Windows desktop; the fixes that follow each ask for
a printed before/after, so the report is completed by the run that makes
them.

What *is* in this file: the owners of desktop memory, read from the code,
with their limits and lifetimes; what is kept for notes and tabs that are
not visible; and how the scale rule (1M notes, novel-length files) holds up.
Every claim carries the file to check it in.

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

The issue's own flags for the frame-side measurement
(`FLUTTER_ENGINE_SWITCHES=2`, `…vm-service-port=8181`,
`…disable-service-auth-codes`) are for the timeline, not memory; for memory
the DevTools Memory view over the same VM service is enough.

## Owners

### Dart heap

| Owner | What it holds | Bound / lifetime | Code |
|---|---|---|---|
| Open note text | One `SourceBuffer` per open note (the whole file, in memory) | One per open tab; dropped when the tab closes; the library's workspace is disposed on `close()` | `lib/src/markdown/source_buffer.dart`, `lib/src/workspace/workspace_controller.dart` |
| Undo history | Up to 200 `EditRecord`s per note, each holding the removed and inserted text | `EditHistory.limit = 200`; one per open note, owner's history survives a tab move but not library close | `lib/src/markdown/edit/edit_history.dart` |
| Parsed / highlighted spans | `SourceStyler`'s line store, block list and per-line tokens for every open note; the read view's block heights | Per open note; rebuilt on edit; released with the note | `lib/src/markdown/source_styler.dart`, `lib/src/markdown/render/block_height_map.dart` |
| KaTeX boxes and rasters | Typeset formulas, as boxes (512) and rasterized images (128) | Bounded per `MathCache`/`MathRaster`; one cache per `NoteView` (`_mathCache`), disposed in `NoteView.dispose` | `lib/src/preview/math_cache.dart`, `lib/src/preview/math_raster.dart` |
| Flutter's image cache | Decoded images in the read view and attachments — default **1000 images / 100 MB** | Global to the engine, not per library; released only by age/size eviction | engine (`PaintingBinding.imageCache`) |

The open-note buffers are the largest scaling term: **memory is
proportional to what is open, not to the library**, which is the intended
shape. The thing to confirm by measurement is that closing a tab really
drops its buffer (no `ChangeNotifier` or closure keeps it), and that
`EditHistory`'s 200 records do not hold a whole novel after a few large
deletions.

### The two drift databases and SQLite caches

There are **three connections**, not two:

- `AppDatabase` — app settings, one row; the small one.
- `IndexDatabase` — the library's index (tree rows, stems, tags, links,
  FTS5), on its **own background isolate** (`NativeDatabase.createInBackground`,
  `library_state.dart:1802`).
- A second `IndexDatabase` over the **same file** for search, also on its own
  isolate (`defaultSearchDatabase`, `library_state.dart:1813`).

Each connection carries SQLite's own page cache (a few MiB by default, in
the isolate's native heap) and, for the index, the FTS5 tables. `PRAGMA
auto_vacuum = INCREMENTAL`, `journal_mode = WAL`, `busy_timeout = 5000`
(`index_database.dart:202`). The library's two index connections are
`close()`d in `_teardown` (`library_state.dart:1527`); the `AppDatabase`
outlives every library and is closed once, in `dispose`
(`library_state.dart:1472`). So closing a library releases the index
connections and their caches — which matters for "does it return after
switching libraries?".

### Materialized tree rows

`NoteDao.tree` runs **one query** returning the rows of the root and of the
expanded folders (`dao.dart:45`); the tree widget materializes only what it
shows. At 1M notes the index holds 1M row objects *on disk*, but the app
holds only the visible/expanded set. Confirm by expanding the whole tree of
a large library that the query's result set is what grows — that is the term
to watch, not the library size itself.

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

### Whisper models

The transcription model is **kept loaded between clips**
(`SpeechTranscriber`, "the model stays loaded after each call; the queue
calls `release()` when it empties"). A whisper model is tens to hundreds of
MB. This is the largest single item that can sit resident with nothing
visibly running — the first thing to check whether it is released when the
transcription queue drains, and whether it should be released after a
timeout rather than held for the session.

### Background isolates

`IsolateGauge.run` is `Isolate.run` — a short-lived isolate per read, write
and tidy. Each carries its own heap, and peak memory roughly doubles for the
duration of a job (the note exists in the caller's heap and in the
isolate's). The index and search connections' isolates are long-lived and
idle-cheap after warm-up (`_warmIndex`).

## Scale rule (1M notes, novel-length files)

Read from the code, the hot paths hold a **window**, not the library or the
whole file:

- FTS5 for search; the tree is materialized per expanded folder; the index
  full scan is **directory-at-a-time with bounded memory** (#302).
- `filePathsUnder` is an index seek, not a walk (`dao.dart:163`).
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
absolute bar goes behind `NIMAN_PERF`):

1. **Release the transcription model when it is not needed** (on queue
   drain, or after a timeout, or when the window goes to the tray). Measure
   RSS with a model loaded and after release.
2. **Drop the engine image cache on library close** (or lower its cap for
   the read view), so switching libraries does not carry decoded images.
   Measure the image cache's current/limit bytes in DevTools.
3. **Verify closed tabs release their note** — a perf-style integration test
   that opens N notes, closes them, and prints the Dart heap from the VM
   service before and after.
4. **Bound `EditHistory` by bytes, not only by record count**, so 200 large
   deletions of a novel cannot hold it whole.
5. **Release the search connection when no search screen is open** if the
   measurement shows its isolate/FTS cache is non-trivial at idle.
6. **A resident-memory regression guard**: an integration test (or a
   `NIMAN_PERF`-gated perf file) that opens/closes a library and several
   notes and asserts the process returns near its starting RSS, printed with
   the number it saw.

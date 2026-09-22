# Huge notes: where the unified surface stands (2026-09-22)

The 0.0.9 stress test opens `Quicknote.md` in the testing build: 246 867 774
characters, 2 757 539 lines, 2 014 477 blocks, a copy of *Geometria 1* many
times over. This file records what was measured on it, what was changed
because of it, and what is still open, so the work can resume from here. The
design it builds on is [`unified-surface.md`](unified-surface.md).

## Where the work is

Phase 4 of the unified surface has started with the step the design called
for first: **one reading of the note for the editor and the preview.**

- Source mode is now coloured by the read view's own engine
  (`lib/src/markdown/source_styler.dart`): the block a line is in comes from
  the `BlockScanner`, and its inline runs from the `BlockParser`'s parse of
  that block. The legacy line tokenizer (`editor/highlighting.dart`) no longer
  colours the unified surface. It still serves the legacy editor, the
  outline, the link parser and the index, until phase 5 removes them.
- Each `StyleRun` knows its markers from its text (`innerStart`/`innerEnd`),
  and a `Token` can be a marker (`Token.marker`). `live` mode already draws a
  marker token invisible and taking no room.
- **Live mode is on hold.** It is not to be worked on until the source mode
  has been tried on the real executables and found sound. The next steps,
  when it resumes, are the reveal policy and the typography listed under
  phase 4 in `unified-surface.md` §10.3.

## What changed, measured on the 246 MB note

| Commit | What | Before | After |
|---|---|---|---|
| `1bc9f5f` | The read view's first scan (blocks and definitions) runs in an isolate from 50 000 lines on; the revision before stays on screen meanwhile | 2.9 s frozen before the preview's first frame | nothing on the UI thread; the scan lands 4.7 s later |
| `3acf0bc` | `StyleRun.innerStart/innerEnd`, `Token.marker` | — | — |
| `52d15ba`, `c418129` | `SourceStyler`, and the source view drawn with it; a long note read in the background and drawn plain until it lands | — | — |
| `1f15406` | `BlockScanner`: a line edited in place has its state replaced in place, and the blocks after a line added or removed are *owed* the shift rather than moved (`_shiftFrom`/`_shift`, paid between one edit and the next) | a character ~20 ms, an Enter ~170 ms (JIT bench) | a character 0.2 ms, an Enter 25 ms |
| `cee783e` | The save of a note past 2 MB waits 2 s, past 16 MB 5 s | a 0.4 s stall after every half-second pause | the stall only after a real pause (a mitigation, see below) |
| `95ffa00` | A format command (bold, list, heading, indent…) is handed the lines its selection touches (`MarkdownSurfaceController.applyLineCommand`); a property test holds every command to its whole-note answer, LF and CRLF. `SourceBuffer.caretOffset`: an offset inside a CRLF is its line's end | seconds for a bold (join, formatted copy, compare) | the touched lines only |

### The interactive test (profile build, `APP_CHANNEL=testing`)

240 characters typed into the quick note at 16 a second, Enter every 40,
then as many Backspaces, while the VM service recorded the timeline and the
main isolate's CPU (commit `cee783e`):

- no frame over 16 ms: `Animator::BeginFrame` p50 1.9 ms, p90 2.9 ms, max
  5.8 ms; raster p50 2.7 ms;
- the UI thread busy about 5 % of the 45 s;
- what remains is an Enter or a Backspace that joins two lines: about 60 ms
  each, spent moving the buffer's line lists and the scanner's lists (below).

Opening the note: read and split in 2.4–2.6 s, the first frame right after,
the background scans landing a few seconds later without blocking.

The test collided with a writer typing in the same window at the same time,
so the note's content changed by lines of test text only (lines 30–35 and the
last one); the version the session started from is `.history/Quicknote.md.v53`.

## What is still open, in the order to take it

Every item is a path that still reads the whole note on the UI thread, or a
cost that grows with it. None is a shortcut to take: each has its proper fix
written next to it.

1. **The save joins the note and copies it.** `_performSave` joins the buffer
   (300–530 ms) and `NoteWriter._writeOffIsolate` sends the string to an
   isolate, which copies it (about 100 ms for 246 MB: strings are copied
   between isolates, not shared — measured). The debounce of `cee783e` only
   moves the stall to a pause. The fix: the history snapshot and the reindex
   read the disk, so nothing on the way needs the joined string. Take a
   snapshot of the line lists (pointer copies, O(lines)), encode them in
   slices of a few milliseconds that yield to the frames, and write the
   chunks with async file I/O to the temp file that is then renamed (or hand
   the bytes over as `TransferableTypedData`). `NoteWriter` gains a save that
   takes bytes; `writeNoteFile` and the history request stay as they are. The
   close guard's save may stay synchronous.
2. **The statistics join the note too.** The word count and the outline wait
   for the pause (`_statsDelay`), then join and copy to an isolate. The
   outline is the headings, which the block index already has; the word count
   can be kept per line and updated by the edits.
3. **An Enter or a line join costs O(lines).** `SourceBuffer.replaceRange`
   moves `_lines` and `_terminators` through `ListBase.replaceRange` (the
   generic element-by-element path), and the scanner moves `_entering` and
   `_blocks`. The fix: chunked storage of the lines, as `PrefixSums` already
   chunks the spans, so an insertion moves one chunk.
4. **A reload from disk compares the whole text** (`text == _currentText` in
   `_reloadIfChanged`): compare the length and a hash first, or the disk's
   bytes against the last saved ones.
5. **"Count list" scans the whole note** when the Tools sheet opens
   (`_hasListToCount` → `tallyTargetsIn`): the list items are in the block
   index.
6. **A kind GUI's edit is whole-text by design** (`_applyKindEdit`). Kind
   notes are small; worth a guard rather than a rewrite.
7. **The read view's definitions are rescanned per revision** when it shows
   a note that is being edited; in the background, but O(note) each time.

## The testing builds

`scripts\niman.bat windows beta` and `scripts\niman.bat apk beta` were built
from `cee783e`; `95ffa00` (the format commands) is not in them yet.

One trap found on the way: running `flutter build windows --profile` while an
APK builds regenerates `GeneratedPluginRegistrant.java` with the dev-only
`integration_test` plugin, and the release APK then fails to compile. Build
them one after the other.

## How it was measured

- CPU: a profile build launched with `FLUTTER_ENGINE_SWITCHES` (VM service on
  port 8181, no auth codes, Dart profiling), sampled with `vm_service`'s
  `getCpuSamples` and aggregated by function.
- Frames: the same connection with `setVMTimelineFlags(['Dart', 'Embedder',
  'GC'])`, then `getVMTimeline` over the window, durations per event name.
- Typing: keys sent to the window with `WScript.Shell.SendKeys` after
  bringing it to the front, and the same number of Backspaces after, so the
  note is left as it was — provided nobody else types in it meanwhile.
- Benches: 2.7 M-line synthetic notes run with
  `dart run --packages=.dart_tool/package_config.json` (JIT) or compiled with
  `dart compile exe` (AOT) for the isolate costs.

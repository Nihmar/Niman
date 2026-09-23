# Huge notes: where the unified surface stands (2026-09-23)

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
  outline and the link parser until phase 5 removes them; the index reads
  a note's tags and links with the unified engine (item 8).
- Each `StyleRun` knows its markers from its text (`innerStart`/`innerEnd`),
  and a `Token` can be a marker (`Token.marker`). `live` mode already draws a
  marker token invisible and taking no room.
- **Live mode is being worked on** (phase 4, the WYSIWYG that replaces
  `flutter_quill`), and its first piece — the marker reveal, per line and per
  word — is in; see the section at the end of this file. The "on hold" this
  used to say is gone, because the reason for it had been overtaken: source
  mode is not *sound* on this note yet (item 3 below), and that is now written
  where it belongs, as phase 3's own open debt in `unified-surface.md`, rather
  than as a hold on the mode that comes after it.

## What changed, measured on the 246 MB note

| Commit | What | Before | After |
|---|---|---|---|
| `1bc9f5f` | The read view's first scan (blocks and definitions) runs in an isolate from 50 000 lines on; the revision before stays on screen meanwhile | 2.9 s frozen before the preview's first frame | nothing on the UI thread; the scan lands 4.7 s later |
| `3acf0bc` | `StyleRun.innerStart/innerEnd`, `Token.marker` | — | — |
| `52d15ba`, `c418129` | `SourceStyler`, and the source view drawn with it; a long note read in the background and drawn plain until it lands | — | — |
| `1f15406` | `BlockScanner`: a line edited in place has its state replaced in place, and the blocks after a line added or removed are *owed* the shift rather than moved (`_shiftFrom`/`_shift`, paid between one edit and the next) | a character ~20 ms, an Enter ~170 ms (JIT bench) | a character 0.2 ms, an Enter 25 ms |
| `cee783e` | The save of a note past 2 MB waits 2 s, past 16 MB 5 s | a 0.4 s stall after every half-second pause | the stall only after a real pause (a mitigation, see below) |
| `95ffa00` | A format command (bold, list, heading, indent…) is handed the lines its selection touches (`MarkdownSurfaceController.applyLineCommand`); a property test holds every command to its whole-note answer, LF and CRLF. `SourceBuffer.caretOffset`: an offset inside a CRLF is its line's end | seconds for a bold (join, formatted copy, compare) | the touched lines only |
| the streaming save | The save hands the note over in slices instead of joining it: `SourceBuffer.sliceText`, the producer the editor feeds, and a writing isolate that takes the bytes as they are made (`note_write_stream.dart`) | 671 ms of one-go work per save (190 ms join + 481 ms isolate copy and encode) | 169 slices, worst 20 ms — the frames keep coming, and no full copy of the note exists |
| the hand-over | The read pane takes the blocks and definitions the editor keeps current (`SourceStyler.scan`, `MarkdownReadView.knownScan`) instead of scanning the snapshot again; the editor's scope now follows footnote citations too | opening the read pane after an edit: the note sent to an isolate on the opening frame, the edit on screen ~4 s later, then a 130–340 ms stall as the scan landed (AOT) | the edit on the opening frame; nothing lands later |
| the chunked buffer | `SourceBuffer` keeps its lines in chunks a snapshot shares, copied per chunk on write (`LineStore`, `PrefixSums.sharing`) | snapshot 250–440 ms, Enter 20 ms in the buffer (AOT, `tool/source_buffer_bench.dart`) | snapshot 54 µs (+ ~15 µs for the first keystroke after it), Enter 0.4–0.8 ms |
| the kept heights | The block scanner records the splices its edits make to the block list, folded into the few stretches they changed (`BlockChanges`); each hand-over carries them, and the read pane replays them over its height map instead of estimating every block again. The map's "measured" flags are a byte list | the read pane's open after an edit: a new height map, 100–200 ms (AOT), every measured height forgotten; one 140 ms regrowth of the flag list on the first block an edit added | 0.1–4 ms, the heights on screen kept. The open is now 63–160 ms, nearly all of it the hand-over itself: copying 2 M blocks and paying the shift an Enter left owed on the blocks after it (open, below) |
| the kept statistics | The word count follows the edits (`WordCount`, per line, chunked like the spans) and the outline is read off the scan the pane already holds (`outlineOfBlocks`), instead of joining the note and walking it twice in an isolate | 2151 ms per statistics refresh (280 ms join on the UI isolate + 772 ms count + 1099 ms outline walk) | 29 ms per refresh, and an edit pays 11–33 ms for the lines it touched |

### The streaming save, measured on the 247 MB note

`dart run tool/save_stream_bench.dart "Quicknote.md"` (246 867 656 chars,
2 757 545 lines), JIT, the real `SourceBuffer`:

| | Old (join, then one isolate) | New (slice, encode, send) |
|---|---|---|
| UI-isolate work per save | 190 ms join + 481 ms isolate copy and encode = **671 ms in one go** | 169 slices, longest 1.5 MB in 4 ms, **worst slice 20 ms** |
| The note copied whole | yes — a string is copied between isolates, never shared | no — only the slice in flight exists |
| Save wall-clock | — | 1149 ms (the writer takes the bytes while the next slice is made) |

The wall-clock got longer (the per-slice `StringBuffer` and the message cost
are real), and that is the point: the same work is no longer one 671 ms
blocking turn of the UI isolate but 169 turns under 20 ms, so the frames
land between them. The slices are 16 384 lines or 4 MB of characters,
whichever comes first, and the loop yields between them
(`note_view.dart`, `kSaveSliceLines`/`kSaveSliceChars`).

Two traps found on the way, both in `note_write_stream.dart`:

- **A message between isolates may carry one port, not two.** A spawn
  message holding two `SendPort`s starts an isolate whose ports then
  deliver nothing at all, with no error anywhere. So the writer is handed
  one port, announces the port it made for itself, and is sent the port its
  result goes to as the first message of the conversation. The rule is
  written at the top of that file.
- **A long-lived spawned isolate does not finish awaited file work under
  `flutter test`.** The same awaits complete in a plain `dart run` isolate;
  under the test harness the writer sat on the first `await` until the test
  timed out. The writer's file work is therefore synchronous, which costs a
  frame nothing — it is the writing isolate.

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

1. ~~**The save joins the note and copies it.**~~ Done: the note is handed
   over in slices and the writer takes the bytes as they are made
   (`note_write_stream.dart`; see the table above). The debounce of
   `cee783e` stays — a save is still disk work worth batching — but what it
   was hiding is gone.
2. ~~**The statistics join the note too.**~~ Done: the word count is kept
   per line and follows the edits (`editor/word_count_index.dart`), and the
   outline is read off the blocks the pane's own scan already produced
   (`editor/outline.dart`, `outlineOfBlocks`). See the table above.
3. **An edit costs O(block), and O(note) when the block is the note — and an
   edit that changes the rest of the note costs the rest of the note.** Two
   different costs were filed here as one, and the second is the one the
   stress note actually has.

   **The measurement, corrected (2026-09-23).** This item used to say that
   `Quicknote.md`'s expensive edits land "inside a 137 k-line `$$…$$` block".
   The bench's own report says otherwise: the note's **longest block is 36
   lines** (a paragraph). What `tool/scanner_edit_bench.dart` edits at 25 %,
   50 %, 75 % and 90 % is the blank line before a `$$` opener or the opener
   itself, and replacing that character *destroys the opener*: every `$$`
   after it now closes where it opened and opens where it closed, all the way
   down. The rescan did not fail to converge — there was nothing to converge
   to, and a fresh scan of the edited note agrees with every one of the
   1 378 772 lines it re-read. So the two costs are:

   | | What it is | Before | Now |
   |---|---|---|---|
   | a | a keystroke inside one huge block (a paragraph with no blank line, a formula or fence that never closes) | the block, per keystroke: 300 000 lines, 80 ms, for the synthetic 300 k-line paragraph | **2 lines** — fixed, below |
   | b | a keystroke that changes what the rest of the note *is*: typing the second `$` of a `$$`, a fence's third backtick, the `---` that opens frontmatter | the rest of the note, at once: 1 378 772 lines, 822 ms at 50 % of `Quicknote.md` | **4 098 lines, 4.5 ms** (AOT); the rest carried on in slices — below |

   **(a) is fixed: the rescan starts at the edit and stops where the scan
   agrees with what was there** (`BlockScanner._rebuild`). Both ends used
   to be the block's: the rebuild began at the first line of the block the
   edit was in, and stopped only at a blank line with a plain state and a kept
   block starting under it — inside a block there is neither, so it ran to
   the block's end. The six attempts recorded in this file's history tried to
   narrow the start and keep the rule for the end; the start was not where the
   cost was.

   * **The start.** The lines before the edit are the same text entered in
     the same states, so the block they are in is the block it was, up to the
     edit. The rebuild takes that block *open* — cut at the edit — and asks of
     the edited line what a fresh scan asks: does it go on with the open
     block, or start one? The blocks are built line by line as the scan goes
     (`_BlockBuilder`), so the open block is always known. The one exception is
     a line before the edit that has a pipe in it: it asks the line under it
     whether it heads a table, so it is not the line it was, and its block is
     rebuilt with the edit.
   * **The end.** A line's kind and exit state read its own text, its entering
     state and at most one line either side, so once two unchanged lines are
     entered in the states they had, every line after them is what it was.
     What the state cannot say is which *block* the line is in, because that
     is a question about the pair; so the scan also looks the old block up
     (`_convergesAt`) and stops only when the fresh scan would make the same
     one — either the old block starts on this line and the open one does not
     take it, or the open block takes it and has the old block's shape
     (`Block.sameShape`), in which case it ends where the old block did. Not on
     a blank run and not on an item whose count would differ, because the
     block after a blank run counts its items from the block before it.

   Held by `block_scanner_test.dart`: *a keystroke inside a block the size of
   the note re-scans a line or two* (a 50 000-line paragraph and formula, a
   character, an Enter and a line join, each under five lines), and
   *line-shaped notes: random edits agree with a fresh scan* — 200 notes of up
   to two hundred lines built from real constructs, twelve edits each, every
   field of every block compared with a fresh scan. The older random test
   compared `Block.toString`, which leaves out the list count, the heading
   level and the fence's language; with those compared it found three bugs of
   its own, all fixed first (`2c3ed44`): a list written `1. 1. 1.` renumbered
   to 1, 1, 2 under a keystroke, a rescan that stopped on the second of two
   blank lines split the run in two, and an item after a quote counted on from
   the quote's list.

   **(b) cannot be made O(change), because the change is O(note); what is
   bounded is how much of it one keystroke pays for.** The scan has to be
   current for the lines on screen and for nothing else at that moment, so
   the rest is carried on between frames — which is what editors that parse
   incrementally do.

   * **A rescan stops at its budget.** Past its own edit it reads at most
     `BlockScanner.budget` lines (4 096 by default: a few milliseconds, far
     more than a screen) and, if it has not converged, leaves a **frontier**
     there. From a frontier on, the recorded states and blocks are what an
     earlier scan made of them — *hints*, kept in place so the list still
     tiles the note (the block the scan stopped inside is cut at the
     frontier).
   * **A hint is still good to converge on.** Every edit lands above every
     frontier (an edit on lines past one starts its rebuild at the
     frontier), so the text around a hint has not changed since it was
     recorded. If the scan reaches a line whose state and block match the
     hint, everything after it is what the hint says — up to the next,
     deeper frontier, if an older budgeted scan left one. A frontier line
     itself is never a convergence point: the block cut there took its shape
     from a line above it. (That guard is not decorative: without it the
     property test below fails at round 658 of 3 000.)
   * **Readers ask for what they need.** `blockAt(line)` scans up to the line
     and on to the end of its block, so every line drawn is coloured exactly
     as a fresh read colours it; `index` finishes the scan; the outline
     (`SourceStyler.headings`) is null while the scan is owed, and the note
     view keeps the outline it has and asks again until it lands.
   * **The rest is carried on a slice at a time** (`MarkdownSourceViewState.
     _carryScanOn`), one budget per slice, each slice its own zero-length
     timer — so a frame or a key waits for one slice at most. Not an
     idle-priority scheduler task, which was tried first: Flutter refuses an
     idle task while any animation runs, and a refused task asks the event
     loop again at once, so a spinner anywhere on screen would have kept a
     core busy spinning for as long as it turned (in the widget test, it was
     an infinite loop).

   Measured on `Quicknote.md`, AOT (`dart compile exe
   tool/scanner_edit_bench.dart`, which now reports the slices too):

   | Edit at | The keystroke | Then | Slices | Worst slice | In all |
   |---|---|---|---|---|---|
   | 10 % | 0.0 ms, 2 lines | — | — | — | — |
   | 25 % | 16.4 ms, 4 098 lines | 2 064 060 lines | 504 | 21.7 ms | 1 933 ms |
   | 50 % | 4.5 ms, 4 098 lines | 1 374 674 lines | 336 | 40.1 ms | 1 455 ms |
   | 75 % | 2.8 ms, 4 098 lines | 685 288 lines | 168 | 22.1 ms | 287 ms |
   | 90 % | 3.2 ms, 4 098 lines | 271 657 lines | 67 | 15.1 ms | 244 ms |

   Two things in that table are owed an honest word. A slice averages about
   4 ms, but the worst ones are 15–40 ms, and they do not follow the slice's
   work — they look like collections on a heap that holds two million
   blocks, which slicing cannot fix. And the carried-on total is about twice
   what the one-shot rescan cost (1.5 s against 0.8 s): the same lines are
   read, but each slice pays for a splice of the block list and its own
   warm-up. Both are paid off the keystroke, on a note of a quarter of a
   gigabyte, for an edit that rewrites what most of it means; the device
   round is where they get their verdict.

   Held by `block_scanner_test.dart` — *a rescan that stops short answers
   every line as a fresh scan would* (a three-line budget, a thousand notes,
   edits landing above, on and past the frontiers, `advance` and `blockAt`
   interleaved and nothing settled between them) and *an edit that changes
   the rest of the note costs its budget* — and, in the view,
   `source_scan_frontier_test.dart`: a `$$` opened over 25 000 lines, the
   lines on screen coloured right at once, the scan carried on, the outline
   back, and a line at the note's end drawn right before any slice has run.

4. ~~**A reload from disk compares the whole text.**~~ Done, and not with a
   hash: the watcher is what asks for the reload, and a watcher reports that
   something happened to a path rather than that the note changed. So the
   file is stamped when it is read or written (`DiskStamp`: size and
   modification time, O(1)) and a reload whose file still matches is not
   read at all — against 208 ms to join the pane's text, 734 ms to normalize
   a fresh read and 44 ms to compare it (measured on the 246 MB note,
   2026-09-22). A file that changed is read, normalized and adopted exactly
   as before; a file that is gone, or that nothing has stamped, is read.
5. ~~**"Count list" scans the whole note.**~~ Done: the sheet lists every
   tool and greys the ones that cannot run, so the question "does this note
   hold a list?" is asked every time it opens — and it was answered by
   reading the note and building a whole `HighlightDocument` for it
   (`tallyTargetsIn`). It is now read off the blocks the pane already
   scanned (`blockList`): 0.004 ms at a million lines against a 235 ms scan
   (`tool`-style bench, `test/perf/list_count_check_test.dart`). The caret's
   own list is still found by tokenizing the note (`_countListSource`), which
   is one tokenize on a tap the writer asked for.

   **Correction (2026-09-23): it was not in effect until `3347d8c`.** The
   shell asked the pane through a `GlobalKey<MarkdownSourceViewState>` that
   sat on the stateless `MarkdownSurface`, so it never had a state to answer
   with, and `SourceStyler.blocks` answered null for any styler whose scan was
   current. Every open of the sheet took the fallback — a full `BlockScanner`
   pass of the note on the UI isolate, or an off-stage read view's stale
   answer, which greyed the tool out on a note that is a list. The benchmark
   measured `blockList` itself, which was right; nothing measured whether the
   shell reached it.
6. ~~**A kind GUI's edit is whole-text by design.**~~ Done, as the guard
   rather than the rewrite: `_applyKindEdit` still hands its whole note back,
   but `MarkdownSurfaceController.applyEdit` no longer cuts the note out to
   diff it — `substring` of a 246 MB note is a copy of the note on the UI
   isolate for a checkbox ticking. The changed range is found line by line
   (`_changedRange`), so an unchanged head and tail are only compared and the
   replacement is the part that actually differs. A handback of what the note
   already says is not an edit at all: no revision bump, no save.
7. ~~**The read view's definitions are rescanned per revision.**~~
   **Corrected (2026-09-23): the reuse saved nothing, and was wrong.** It kept
   the last scope when the lines opening with `[` were unchanged
   (`_definitionsKey`, 21 ms on the 246 MB note), claiming to spare the 618 ms
   definitions scan — but every scan already reads the definitions with the
   blocks (`DocumentScan.of`, in place or in the isolate), so the fresh scope
   was there and the old one was chosen over it. And the key did not see a
   footnote cited mid-sentence, whose order is the footnotes' numbering, so
   the kept scope could be stale. The reuse is gone: the pane draws the
   definitions its scan brings. What does spare the scan now is the editor's
   hand-over (the table above), whose scope is kept current edit by edit.

8. ~~**The first index of a note reads all of it with the legacy
   tokenizer.**~~ Done (2026-09-23). Found on the testing build: with its
   databases deleted, the first index of `Quicknote.md` did not seem to end.
   Measured stage by stage (AOT, the 247 MB note):

   | Stage | Time |
   |---|---|
   | read | 357 ms |
   | UTF-8 decode | 550 ms |
   | sha256 | 1 887 ms |
   | `HighlightDocument.fromText` — every line tokenized, for tags and links | **112 127 ms** |
   | tags and links off those tokens | 373 ms |
   | FTS5 insert of the body (`unicode61`, on the database isolate) | 2 715 ms |

   The tokenizer is the legacy one this design retires, and it is slow on
   exactly this note: every position of a line runs a dozen patterns to find
   the nearest construct, which is quadratic in a line thick with `$…$`
   (32 µs a line, against 5 µs on the 200 KB fixture). And all the index
   keeps of those tokens is the tags and the links.

   So the index reads them with the unified engine, and asks each layer only
   where its answer can be one (`lib/src/markdown/note_references.dart`):
   the block scan says which blocks have inline text at all; the extension
   masker finds the tags and the wikilinks — and sets code spans and inline
   maths aside — in a block that holds a `#` or a `[`; and the Markdown parse
   runs only on a block with a `[` left after the masker, the only place a
   Markdown link can be. **`noteReferencesOf` takes 5.1 s on the note** (the
   block scan is half of it), and the whole read on the index isolate 8.3 s;
   with the FTS insert, a first index of the note is about eleven seconds
   where it was two minutes.

   Not by making the full parse faster: the Markdown package's parse of every
   block is the same order as the tokenizer (378 ms for *Geometria 1*, so
   about 100 s here). The source view is fast because it parses what is on
   screen; the index is fast because it parses the blocks a link can be in.

   What reading with the engine that draws the note changed, on purpose: a
   reference link (`[text][label]` with its definition) is now a link — the
   note draws it as one and the tokenizer never saw it — and a footnote's
   own text is read for links, which the Markdown package takes out of the
   flow. On every fixture note the tags and links are otherwise the ones the
   legacy readers found (`note_references_test.dart`).

   What the comparison caught on the way, and which was nobody's but the
   scanner's: an HTML comment that closes on the line it opens on —
   `<!-- a note -->` — was left open, so the rest of the note up to the next
   `-->` was one HTML block, drawn as raw HTML by the read view and the
   unified source, and its links unread (1 656 lines of the worst-note
   fixture). CommonMark ends a comment, a raw-text tag, a processing
   instruction, a declaration and a CDATA section on the line with its end
   marker, the opening line included; the scanner does too now.

9. ~~**Every save reads the whole note back into the index.**~~ Done
   (2026-09-23), as a wait rather than a speed-up. The device log of the
   `live` round shows a reindex after each save of the stress note — 18, 16,
   34 and 15 s — back to back for as long as the writer typed: the writer
   already folded them to one running and one after it, but on this note one
   is longer than the pause between two saves. A note past 2 MB is now
   reindexed once it has been left alone for 5 s, past 16 MB for 30 s, each
   save starting the wait again (`NoteWriter.quietBeforeReindex`, the save's
   own thresholds). The index is a little behind the note while it is being
   written, and the note is read back once. `NoteWriter.indexed` runs a
   waiting reindex at once, since whoever asks wants the index as the disk has
   it.

## The statistics, measured on the 247 MB note

`dart run tool/stats_bench.dart "Quicknote.md"` (246 867 656 chars,
2 757 545 lines), JIT, the real `SourceBuffer`. One refresh, before and
after:

| | Old (join, copy, walk twice) | New (kept, not recomputed) |
|---|---|---|
| A refresh | 280 ms join on the UI isolate + 772 ms word count + 1099 ms outline walk in the isolate = **2151 ms**, all of it after every pause | **29 ms**: the count is O(1), the headings come off the scan the pane already holds (18 ms), and the frontmatter check reads the note's first 8 KB |
| One edit | the same 2151 ms at the next pause | a character 17–31 ms, an Enter 16–33 ms, a line join 11–21 ms — the lines it touched |
| Building the count | — | 1077 ms once, in the background (`countInBackground`) for a note over 64 KB; a 2 MB one is counted at load |

The 41 452 363 words and 22 260 headings the two ways report are the same
numbers, and that is the property `word_count_index_test` holds: counting
the lines an edit touched answers what counting the whole text answers, for
a character, an Enter, a join, and a line taken off the end.

## Phase 4 has started: the marker reveal

`live` mode hid its markers and showed none of them back, which made it a
preview rather than somewhere to write: the writer could not see the `#` or
the `-` they were editing. The reveal policy is now
`docs/dev/unified-surface.md` §8.6.2's **policy A** — the markers are hidden
everywhere except on the line the caret is in.

It is a *style*, never the text: `_Line.hidden(token, revealed:, run:)` decides
between `_hiddenMarker` and `markdownTokenStyle`, and the marker keeps its
offset, its string and its advance, so the caret, the hit test and the
selection know nothing about it. The line's own size stays the hiding's,
too: a heading is drawn at the heading's size whether its hashes are shown or
not.

Four tests changed with it and one is new: the tests that measured a hidden
marker now put the caret on another line (`the caret is in the heading, so
the hash is drawn` is the new one, and the two `caretRect` comparisons were
narrowed to the horizontal, since a heading above the caret is a different
height in the two modes — 50.0 against 65.0, measured).

**The per-word refinement is in too** (same day). A marker is now tested
against the caret's *run of non-whitespace* (`runAround`, `caret_motion.dart`),
which contains the markers — so `**bold**` reveals both of its pairs while the
caret is inside `bold`, and a plain word reveals no syntax at all. Two
granularities, split by `_isMarker`: a structural mark is the shape of the
*line* and follows the line (a writer in a heading still sees its hashes),
an inline mark is the shape of a *word* and follows the run. Two attempts
before this one got the comparison wrong and hid the pair the caret was
between; the note in `unified-surface.md` says what was wrong and what holds
now.

The lines listen to one value — `CaretSpot(line, runStart, runEnd)` — so a
caret move *inside* a run notifies no line and a move across a run boundary
notifies the two lines involved once. The frame such a move causes costs
**2.6 ms at 2 000 lines and 2.2 ms at 20 000 (×0.8)**, measured by
`test/perf/live_reveal_budget_test.dart` — flat in the note's size, and inside
§9.2's 3 ms ceiling. The row-wise reveal that follows a wrap is still open:
the unit is the line, so a wrapped paragraph shows the syntax of every row it
spans while the caret is in it.

**`live` now draws the WYSIWYG pane** when the unified engine is on
(`note_view.dart`): one widget, two modes, one flag — `source` for the source
pane, `live` for the pane Quill used to draw. Nothing about the note changed
with the mode: its text, caret, commands, save, statistics and memento are the
same question in both, which is why the shell's predicate is "who is drawing
this note" rather than "is this the source pane". The wiring fixed three
hand-off bugs it exposed, all of them data loss on a mode or engine switch;
`unified-surface.md` names them.

**The toolbar's pressed state is published by the surface too**
(`active_formats.dart`): read off the caret line's tokens — the same ones the
colours come from — with the reveal's two granularities and one deliberate
difference (a structural mark follows the line; an inline one lights on
*overlap*, so a bold phrase reads as bold from its middle). The publish defers
out of a build, because the toolbar is not a descendant of the surface and
notifying it mid-build is a `markNeedsBuild` the framework refuses — it did,
in two tests that had nothing to do with toolbars.

**The parity run is on**: the find bar, the spelling and the context menu each
run *every* one of their tests twice, once per unified mode, through a small
`both(...)` helper — the criterion asks for the same tests in both, and a
second test that says the same thing is not that. What is still paired only in
`source`: the tools sheet, folding, the typewriter, Ctrl+click, the semantics.
The row-wise reveal was dropped rather than built, with the reasoning written
down in `unified-surface.md`: with per-word in, hiding a line's structural
marks because the caret wrapped to another row would take away the marker of
the item being written.

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

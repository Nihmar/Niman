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
3. **An Enter or a line join costs O(block), and O(note) when the block is the
   note.** The buffer is not the cost: a character edit moves its two lists in
   under a millisecond, and the state list's own tail move measured a
   millisecond at 2.7 M lines. The scanner is. It re-scans from the first line
   of the *block* the edit landed in — a rebuild that starts mid-block would
   split a paragraph in two — and it stops where the state entering a line
   agrees with what it was and the blocks after it are already right again.

   `dart run tool/scanner_edit_bench.dart "Quicknote.md"` (2 757 545 lines,
   2 014 482 blocks) shows both halves of that:

   | Where the edit lands | Lines re-scanned |
   |---|---|
   | in a one-line paragraph or a blank between blocks (10%) | 3 |
   | a one-character edit that merges a blank line into the line below, inside a 137 k-line `$$…$$` block (50%) | 1 378 781 |
   | inside another `$$…$$` block (75%, 90%) | 689 389, 275 756 |

   The 50% number is the interesting one: the edit *removes a line* (the blank
   line it starts in becomes part of the line after it), so the states after it
   are the states of lines that have moved, and the scan cannot trust them. It
   falls back to the block-boundary rule, and inside a `$$…$$` block there is
   no boundary to stop at until the block closes — 137 k lines later. With the
   line count unchanged the state alone is enough, and the same edit costs one
   line (measured: a 200 000-line math block re-scans 200 000 lines at 3–5 ms
   in the synthetic case, but only because the convergence is cheap there; the
   real note's cost is 78–166 ms for the scan itself).

   **What the fix has to be, and what was tried (2026-09-22).** Not chunked
   line storage, which the numbers above rule out. The scan has to be able to
   start at the edit instead of at the block's first line, and the state a
   block is entered in — kept with the block — is what a rebuild that starts
   there needs.

   That was built, three times, and it is not enough on its own. A narrowed
   rebuild produces the blocks for `[edit, convergence)` and leaves the old
   block's prefix in the list, so the splice has to keep that prefix — and a
   *rebuilt* block directly after a *kept* one is two blocks where the merge
   would have made one:

   * a two-line paragraph edited on its second line rebuilt as
     `Block(paragraph 1..2)` after `Block(paragraph 0..1)` where the fresh
     scan says `Block(paragraph 0..2)`;
   * a lazily continued quote rebuilt from its second line lost the
     `quoteDepth` its first line carries, and split in two;
   * a 9 000-line note of three-line paragraphs counted 4 999 blocks where a
     fresh scan has 5 000.

   Recomputing the states between the block and the edit (so a narrowed
   rebuild of a *quote* would get its depth) and splicing from the block
   before the edit was tried too, and fails the same way. The reason is in
   the count: the narrowed rebuild replaces the containing block's suffix
   with the rebuilt blocks, and the blocks between the rebuild's end and the
   convergence point are dropped with it — the rebuilt range covers less than
   the old block did, so the list stops tiling the document.

   **The whole shape of the fix, then, and how far it got (fifth attempt).**
   Keep the containing block's prefix (`start..from`), rebuild
   `from..convergence`, and *merge the two when the block they make merges* —
   a paragraph's second line, a quote's lazy continuation. That merge is what
   makes the block count come out right, and with it the 9 000-line note of
   three-line paragraphs counts 5 000 blocks against a fresh scan's 5 000, and
   the keystroke costs a handful of lines (that test passed for the first
   time).

   Two things it still got wrong, both in `block_cliff_test`'s
   "an edit at the top, the middle and the end":

   * an edit that starts *at* a block's first line (the blank line at 4) kept
     the block that ended there and rebuilt the same line, so the list had
     `Block(blank 4..5)` twice;
   * an edit *inside* the frontmatter rebuilt `Block(frontmatter 0..5)` where
     a fresh scan says `Block(frontmatter 0..4), Block(blank 4..5)`.

   So the direction is right and the splice's edges are not: a prefix may not
   be kept when the edit starts at the block's own first line, and a block
   whose merge rule is not the paragraph's (frontmatter runs to its closing
   line, not to the next blank) has to be merged the way the scan merges it.

   **Sixth attempt, kept.** Both edges fixed — the prefix is kept only when
   the rebuild really starts inside the block (`narrowed`) and the join uses
   `_mergesInto(prefix.kind, …)`, the scanner's own rule — and the narrowing
   is widened from "the block was entered at the top level" to "every line of
   the block is entered in the block's state" (`_holdsOneState`: every kind
   but a quote and a list item). The join also *checks its work*: the states
   between the block's first line and the edit are recomputed, and the
   narrowing only happens when the state that walk arrives at is the one the
   note recorded for the edit's line (`_entering[from] == probing`). That
   check is what `source_styler_test` demanded — without it a `$$` line came
   out as `codeFence` after some random edits, a state right per line and
   wrong per block.

   With it, **the whole suite is green** (4 758 tests), including
   `block_scanner_test`'s 40-round random-edit property and
   `source_styler_test`'s.

   **The performance gain did not follow, and the measurements above are why
   it was thought to.** `scanner_edit_bench.dart` and the same-line-count
   probe still read 2 068 158 lines for an edit inside the `$$…$$` block at
   25 % of the 246 MB note, and 137 8772 at 50 %. What those numbers are
   measuring is not the walk the fix removes: the scan still has to run to
   the *block's close* before the convergence rule fires, because that rule
   wants a block boundary (`_isBlockBoundary`) and a boundary in the old
   block list (`_hasBoundaryAt`), and inside one long block there is neither
   until it ends. Narrowing the rebuild moved work that was not the cost.

   So item 3 stands as it did: the scan's cost is still the containing block,
   and a note whose block is the note is still O(note) per keystroke. The
   next step is not the rebuild — it is the convergence rule: let a narrowed
   scan stop where the *state* agrees, rather than where the block list has a
   boundary.

   **What is left, stated plainly.** The scan's cost is the containing block,
   and a whole note can be one block, so the path is not gone for a note
   whose head is a `$$…$$` block of a million lines or a paragraph with no
   blank line. The buffer is not the cost and neither is `_entering`; the
   walk from the block's first line is, and the fix is a change to how
   `_rescanFrom` splices and to `Block`/`BlockScanner` together. The
   random-edit property test (`block_scanner_test`, 40 rounds by 12 edits
   against a fresh scan, plus the test that reads through unpaid shifts) is
   the gate: it caught every attempt.

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
6. ~~**A kind GUI's edit is whole-text by design.**~~ Done, as the guard
   rather than the rewrite: `_applyKindEdit` still hands its whole note back,
   but `MarkdownSurfaceController.applyEdit` no longer cuts the note out to
   diff it — `substring` of a 246 MB note is a copy of the note on the UI
   isolate for a checkbox ticking. The changed range is found line by line
   (`_changedRange`), so an unchanged head and tail are only compared and the
   replacement is the part that actually differs. A handback of what the note
   already says is not an edit at all: no revision bump, no save.
7. ~~**The read view's definitions are rescanned per revision.**~~ Done: the
   scope is reused when the lines that can hold a definition are what they
   were, which is what decides whether a scan could find anything different.
   The check folds those lines into one number
   (`MarkdownReadViewState._definitionsKey`), so a definition moved by a
   paragraph added above it is still the same definition — the key is over
   content, not line numbers. 21 ms on the 246 MB note against 618 ms for
   the scan it saves (measured 2026-09-22).

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

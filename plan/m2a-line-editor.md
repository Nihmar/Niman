# M2a — Line-based editor (sub-plan of M2)

**Status:** Done + verified 2026-09-06 (on-device, user, Android): the re_editor
stack opens/typing/highlighting/saves on the real 931K note (evidence
`copist-debug-log-2026-09-06-181029.587.txt`: open 86 ms + one 105 ms first
frame; saves at 931K = join 4–8 ms + write 51–258 ms off-isolate; no slow
frame >200 ms, no errors; speed pass re-verified in
`copist-debug-log-2026-09-06-195842.383.txt`: keystroke sync 0.12–0.40 ms/key
after the segment-aware anchor). The custom widget stack below was replaced by
`re_editor` (`NoteEditor` is a thin `CodeEditor` wrapper: `wordWrap`,
no autofocus, `NonCodeChunkAnalyzer`, stock selection toolbar; `NoteView`
owns the `CodeLineEditingController` and keeps the off-isolate load/save +
500 ms debounce). Highlighting uses the package's per-line `spanBuilder`
wired to this plan's incremental tokenizer (`EditorHighlightSync` +
`HighlightDocument.replaceLines`/lazy `lineAt`: O(visible) per edit, no
whole-file pass — the package's codeTheme engine re-highlights the whole
buffer per change and was measured at 3.3–5.7 s for 931K, so it is off).
Known follow-ups: re_editor's own whole-text `edit()` path is marked "very
very slow" in its source at novel length (typing on this 931K device was
fine, per the evidence above; re-verify on other hardware), and a Markdown
heading fold chunk-analyzer remains M2 work. Rounds of caret/selection/IME fixes (E8a–E8d, rounds 1–7)
are what the switch retires; the file stays as history. Kept from this plan:
`highlighting.dart` (tokenizer, T-M2-02), `folding.dart` + `outline.dart`
(model halves for a future chunk analyzer / outline panel). Deleted: the
caret/selection/IME/gesture/view model stack (`composing_input`,
`line_buffer`, `line_editor`, `row_model`, `virtualized_text_view`,
`hit_test`, `editor_gestures`, `caret_*`, `row_text_metrics`,
`selection_*`, `note_editor_client`, `ime_bridge`, `composing_underline`,
`highlight_sync`, `styled_runs`, `highlight_style`) and their tests. · **Depends on:** M2 (tokenizer T-M2-02, autosave/save
path), M1.5 · **Spec:** *Requirements* (editor)

## Why this is its own plan

The editor is the single largest unknown in M2 and now owns the whole
caret/selection/IME/virtualization/folding surface. It is being split out so
its architecture, milestones and performance budget are tracked on their own
and so the rest of M2 (preview, math, scroll sync, layout, image insert) can
proceed against a stable editor contract instead of a one-line stack
decision. It replaces task **T-M2-01** in
[m2-editor-preview.md](m2-editor-preview.md).

## Decision (inherited, final)

A **custom, line-based widget**, not Flutter's monolithic `EditableText` /
`TextField`. Confirmed by the T-M2-00 on-device verdict: a plain field's
per-frame cost is proportional to **total buffer size** (297K → ~32 ms/frame,
931K → ~100 ms/frame + a 734 ms open frame), which pins real notes at 10–30
fps. A line-based editor re-lays-out only the visible viewport, so a
keystroke is O(visible rows), not O(file). Full evidence:
`reference/opening-files.log.txt` (gitignored; the source notes are
copyrighted).

## Content model

- **One plain-text buffer per note**, modelled as a `List<String>` of logical
  lines (the file's lines). The file is the source of truth (M1 invariant);
  the in-memory line list is the edit model. No rich-text model.
- **Highlighting is presentation**: per visible line, the T-M2-02 tokenizer
  yields tokens; a line is painted as a styled `TextPainter`/`RichText`. The
  edit model never stores styling.
- **Folding** (T-M2-07) is "layout skips these line ranges" — a set of folded
  (startLine, endLine); the view omits those rows. Expressible only line-based.
- **Wrap:** real notes are long-line prose (avg 58–90 chars, max ~2.5 KB/line).
  A logical line maps to **one or more visual rows** via word wrap at the
  column width (monospace). Visual rows are the layout/virtualization unit.
  (Open point: word-wrap vs hard column-wrap; both are O(line). Word-wrap is
  the default for readable prose; column-wrap is the simplest metric. Decide
  at E2.)

## Rendering

- `CustomScrollView` (or a custom `SliverList`-style render object) over
  **visual rows**, not logical lines. Only rows intersecting the viewport are
  laid out and painted. Scroll offset → row index is O(1) once per-line
  row-counts are cached; a row's content is that logical line's wrapped slice.
- Row height is constant (monospace, single font size) → scroll extents and
  row↔offset math are trivial and O(1). Text scaling re-measures the row
  height (a single value) and reflows affected rows.
- **Cost target:** build/paint cost is O(visible rows), independent of file
  size. This is the regression the whole sub-plan exists to guarantee.
  Verified by a headless benchmark (open a 931K buffer, assert steady-state
  frame build cost stays flat as file size grows) and re-confirmed on-device.

## Editing model

- **The model is `ComposingInput`** (decision): the platform is authoritative
  for the IME, and delta lockstep is only defensible with a single owner of the
  buffer, so `ComposingInput` is the editing model. `LineEditor`'s movement ops
  (`moveUp/moveDown/moveHome/moveEnd`, `placeCaretAtLine`) move onto it as
  selection changes (`setSelection`); `LineEditor` becomes a thin movement layer
  or is deleted at E8. The two change signals (a listener list *and* a
  `revision` counter) unify to one — `ComposingInput` extends `ChangeNotifier`,
  which also drops the per-notify `List.of(_listeners)` copy.
- **Caret** = (line, col) within the logical line list; rendered at the pixel
  point of (visual row, col) via the wrap mapping.
- **Selection** = a span over the flat text (or over (line,col) endpoints);
  supports multi-line. Caret + selection drive the text-input client.
- **Input:** the widget is a `TextInput` client (it owns a
  `TextEditingValue`-equivalent over the buffer). Keystrokes and IME
  composition are applied as edits to the line list. This is where Android
  composition/autocorrect and Linux input live — the riskiest surface, so it
  is its own milestone (E4) before selection polish.
- **Undo/redo:** stack of line-list edits (insert/delete/replace ranges),
  bounded depth — scheduled as its own milestone (E-U) before E8d, which
  removes the `TextField` baseline that provided undo for free, so M2a does
  not ship with a lost feature.

## Contract the rest of M2 relies on

So M2's other tasks don't block on editor internals, the editor exposes:

- the flat text buffer (get/set) + a caret line + visible scroll offset;
- "set caret to line N" (for scroll sync + outline jump);
- a change stream (for autosave debounce + preview re-parse).
M2 preview/scroll-sync (T-M2-04/05/06) build against this contract, not the
rendering.

## Milestones (each independently testable)

- [x] **E1** Line buffer model (pure Dart): text↔lines, apply edit
  (insert/delete/replace), caret/offset math, incremental line counts.
  *AC: unit tests — edit ops keep buffer==source; offsets round-trip.*
- [x] **E2** Visual-row model + virtualized read-only view: wrap a logical
  line into rows; render only visible rows of a large buffer; smooth scroll.
  *AC: headless benchmark — open 931K buffer, steady-state frame build cost
  is O(visible), flat vs file size; scroll a long note without jank.*
- [x] **E3** Caret + basic keyboard editing on the model: typing, backspace,
  arrows, home/end. *AC: typed/deleted text updates the buffer; caret moves
  correctly; multi-keystroke sequences keep buffer==composed text.*
- [x] **E4** IME / composition (the hard one): Android composition +
  autocorrect, Linux text input; composition region rendered. *AC: IME works
  on Android + Linux; committing a composition edits the buffer correctly;
  no lost/duplicated input on a long note.*
  - **E4 core (this commit):** `composing_input.dart` — `ComposingInput`
    applies the platform's `TextEditingDelta` stream (insertion / deletion /
    replacement / non-text) to `LineBuffer` (the edit op is O(change); the
    line-start reset is O(lines) — see the performance budget), tracking the
    composing region, selection and caret so the view can render the IME
    underline. Lockstep is enforced, not just asserted: a direct edit
    (`reset`/cut/paste) raises a flag that `apply` checks by re-anchoring to
    `delta.oldText`, so a forgotten IME resync loses the pending edit instead
    of silently corrupting; the debug O(1) `oldText.length == textLength`
    assert is the backstop. The unrecognized-delta branch re-anchors + signals
    a resync instead of dropping silently. Property test: 300 randomized edits
    on a 2000-line note keep the buffer exactly correct (no lost / duplicated
    input). The `DeltaTextInputClient` bridge and the composing-underline
    render are the E8 side (view); the model's correctness is verified here.
- [x] **E5** Selection + clipboard — model half: selection state + copy/cut/
  paste buffer ops on `ComposingInput`. *AC (model half): select across lines;
  copy/paste round-trips; cut updates buffer + caret.* The interactive half
  (tap/drag hit-testing, selection highlight, clipboard UI) is E8b (view).
  - **E5 core (this commit):** selection state + selection buffer ops on
    `ComposingInput`, plus `LineBuffer.substring` (O(range) extraction, the
    copy/cut source — no full-text materialize). Selection is a
    (anchor, focus) pair; the range is `[start, end)`, end exclusive.
    `extendSelectionTo`/`collapseSelection` drive a drag-select; `selectionText`
    (copy), `deleteSelection` (cut → buffer + caret, returns the text) and
    `replaceSelection` (paste/replace → buffer + caret). The last two mutate
    the buffer directly, so they break delta lockstep: the view re-syncs the
    IME with a full `value` update (exactly how Flutter handles a local
    paste/cut). Tap/drag hit-testing, the selection highlight and the
    clipboard UI are the E8 side (view); the model's correctness is here.
- [x] **E6** Folding (with T-M2-07 outline) — model + layout half: `FoldState`
  - fold-aware `RowModel`. *AC (model + layout half): folding a heading hides
  its rows from the layout; scrolling is over the visible rows only.* The
  interactive half (fold markers, outline panel, outline-click → jump) is E8c
  (view).
  - **E6a:** `outline.dart` + `folding.dart` (pure model).
    `outlineOf(tokenizer lines)` derives headings from the tokenizer's
    `headingMarker` token (so a `#` in a code fence / math / frontmatter is
    not a heading — the outline matches the highlighted headings). `FoldState`
    maps a set of folded heading lines to the hidden line ranges: a folded
    heading on line L (level k) hides `[L+1, terminus)` where terminus is the
    next same-or-higher heading (O(h) monotonic-stack scan); the ranges are
    merged, so `isLineVisible(line)` is a binary search and `visibleLines()`
    is the ordered visible set the `RowModel` wraps. The fold anchors, the
    fold markers / outline panel and outline-click → jump are the E8 side
    (view); the layout skipping the rows is E6b (fold-aware `RowModel`).
  - **E6b (this commit):** `RowModel` now wraps a *subset* of the buffer's
    lines — the visible ones. The constructor takes an optional
    `lines` (default: every line); `setLines(lines)` re-wraps to a visible
    set and `sync()` resets to every line. Rows are laid out over the visible
    lines only and `lineAndStartColumn`/`rowOfLine` map through the visible
    set, so the `VirtualizedTextView` renders nothing for a folded range with
    no view change. `rowOfLine` throws for a folded line. The fold markers /
    outline panel and outline-click → jump (the interactive part of the AC)
    are the E8 side (view); the layout skipping the rows is here.
- [x] **E7** Highlighting integration: per visible line, tokenize (T-M2-02)
  and paint styled rows; math spans styled. *AC: tokens/math visually
  distinct; no per-frame re-tokenize of the whole file (only visible rows).*
  - **E7 core (this commit):** the incremental half. `LineBuffer` records the
    last edit (region + replaced text + a count); `HighlightDocument` (with
    `replace` — the O(edited lines) unit of work — and O(1) per-line accessors
    so the view reads only visible lines, never the O(file) `lines` list);
    `Highlighter` keeps it in sync (one buffer edit re-tokenizes only the
    edited lines; the document stays `same` for the view to reuse; accumulated
    edits fall back to a full rebuild; selection-only changes are a no-op);
    `highlight_style`/`styled_runs` map `Token` → `TextStyle` and slice a row's
    tokens to styled `TextSpan`s; `VirtualizedTextView` paints styled runs from
    the document (null = plain text, unchanged). The AC's "visually distinct"
    half lands in E8 (the view reads these runs); the budget (no per-frame
    re-tokenize) is what's verified here. Math spans get the `Math` token kind
    (styled) — no KaTeX engine (M2.5).
- [x] **E-U** Undo/redo (model): the line-list edit stack on `ComposingInput`
  — insert/delete/replace ranges, bounded depth, with `undo`/`redo` ops that
  restore the exact buffer + caret and fire the change stream. *AC: a sequence
  of edits (typing, IME deltas, cut/paste) can be undone and redone to restore
  the exact buffer + caret; the stack is bounded (oldest edits dropped first);
  undo/redo of a direct edit re-syncs the IME (no lost input).* Placed before
  E8d (which removes the `TextField` baseline that provided undo for free) so
  M2a does not ship with a lost feature; the undo/redo buttons + shortcuts are
  the E8a view side.
  - **E-U core (this commit):** a bounded `_UndoEntry` stack on
    `ComposingInput` (default depth 100, oldest dropped first). Every text
    edit is recorded — `apply` (insertion / deletion / replacement; non-text
    moves are not edits) and the direct `deleteSelection`/`replaceSelection`
    (cut/paste) — each with the selection before + after. `undo`/`redo` replay
    the entry (`buffer.replace`, O(change)), restore the exact caret (selection
    before / after the edit), bump the revision (the change stream) and raise
    the IME-resync flag (a direct edit's undo/redo re-syncs the IME — no lost
    input). A new edit clears the redo branch; `reset` (a new load) clears
    both stacks. ACs verified: typed / IME / cut / paste edits undo + redo to
    the exact buffer + caret; the bounded stack drops oldest first; a post-undo
    delta re-anchors on the IME's pre-undo `oldText` (the pending undo is lost,
    the new input is kept).
- [ ] **E8a** Input view: the `DeltaTextInputClient` bridge over
  `ComposingInput` (receive deltas → `apply`; push `value` +
  `commitDirectEdit` after a direct edit), the composing-underline render, and
  tap/drag hit testing. *AC: typing/backspace/arrows on Android + Linux edit
  the buffer through the real IME; the composing underline tracks the region;
  tap places the caret and drag extends the selection.*
  - **E8a core (this commit):** the headless-verifiable half — `ImeBridge`
    (the IME value bridge over `ComposingInput`: computes the `TextEditingValue`
    to push, forwards the delta stream to `apply`), `HitTest` (pixel (x,y) →
    (line, column) over a fold-aware `RowModel`, with the column clamped to the
    row length), `ComposingUnderline` (a composing region = buffer offset range
    → one pixel rectangle per visual row it spans, so a line break simply ends
    the underline at that row) and `EditorGestures` (tap/drag pixel events →
    caret/selection edits on `ComposingInput` via `HitTest`: tap places the
    caret, drag extends the selection, drag-end collapses it). The on-device
    half (the `DeltaTextInputClient`/`TextInputClient` wrapper that links the
    real IME to `ImeBridge`, the paint that draws the underline/selection, and
    the gesture recognizers that feed `EditorGestures`) is pending — wired in
    E8d.
- [ ] **E8b** Selection + clipboard UI: the selection highlight and copy/cut/
  paste wiring over the E5 model ops. *AC: select across lines; copy/paste
  round-trips; cut updates buffer + caret; the IME is re-synced after a direct
  edit (no lost input).*
- [ ] **E8c** Folding + outline view: the fold markers, the outline panel, and
  outline-click → jump. *AC: folding a heading hides its rows; scrolling past
  a fold is correct; the outline lists headings and a click lands the caret on
  the heading.*
  - **Fold state across edits:** `FoldState` is indexed by line number and
    freezes `lineCount`, so it does not survive an edit — an insertion/deletion
    above a fold shifts every line after it, and a stale `visibleLines()` fed
    to `setLines` would trip the range assert (debug) / throw (release). E8c
    owns the folded *set* and remaps it on every edit: apply the edit's line
    delta to the folded line numbers, recompute the outline, and rebuild the
    `FoldState` before `RowModel.setLines` (a fold whose heading line no longer
    resolves is dropped). Folds are transient view state, not buffer state.
  - **E8c core (this commit):** the fold-remap-on-edit half. `FoldState.applyEdit(start, end, inserted, newOutline, newLineCount)` remaps the folded set through a line edit and returns a fresh `FoldState` over the recomputed outline: a fold above the edit is untouched, one at/after it shifts by the net delta, one whose heading line is removed (or no longer a heading in `newOutline`) is dropped, and a one-for-one content edit (a rename) keeps the fold at the same line. The on-device half (fold markers, outline panel, outline-click → jump, and calling `applyEdit` on every edit before `RowModel.setLines`) is E8d.
- [x] **E8d** Wire into `NoteView` + autosave: replace the plain `TextField`
  baseline; debounce + save-on-focus-loss + atomic write (reuse M2 save
  path). *AC: edit a note, close the app, content persisted (byte-identical
  to what was typed); the baseline file is removed.* — done: the `NoteView`
  opens a note in the `NoteEditor` (the `SourceEditor` baseline is removed),
  the owner's debounced save is wired via `onTextChanged`, and the CRLF
  decision is made (LF buffer: strip `\r` on load, write LF on save).
  - **CRLF (round-trip):** the byte-identical AC forces a line-ending decision:
    keep `\r` in the line content (round-trip is free, but the tokenizer and
    painter see a stray character) or strip `\r` on load and restore the
    file's line ending on save (record it per note). Decide before the first
    save.
  - **E8d on-device progress (this branch):** the `NoteEditor` widget carries
    E8a's on-device IME half — the `DeltaTextInputClient` bridge over
    `ComposingInput` via `TextInput.attach`/`show` on focus + a
    `setEditingState` resync after a direct edit — plus the caret +
    composing-underline geometry (`CaretGeometry` + `offsetToRowColumn`), the
    `CaretPainter` (draws the geometry), the overlay on the view (a `Stack` +
    `CustomPaint` + a `scrollOffset` so the caret scrolls with the text), and
    the focus-gated steady caret (a `Focus` widget + the `hasFocus` gate; the
    caret hides while the IME is mid-composition, where the underline takes
    over), and the tap/drag gestures (a `GestureDetector` over the text drives
    `EditorGestures`: tap = caret, long-press = word selection (a persistent
    selection, cleared by a tap; a drag extends it), drag = selection; the
    selection highlight is
    painted by the `CaretPainter` via the new `CaretGeometry.selectionRects`).
    The caret scroll sync (sub-step 5) is done: the editor scrolls to keep the
    caret's row visible (above → top, below → bottom). The NoteView wiring is
    done: the `NoteView` opens a note in the `NoteEditor` (the
    `SourceEditor`/plain-`TextField` baseline is removed), tracks the buffer
    via `onTextChanged` (no `TextEditingController`), and the owner's
    debounced save is wired (the `onTextChanged` → the ~500 ms save; save on
    focus loss + app-hide + dispose are unchanged). CRLF decision (made
    before the first save, per the plan): the buffer uses LF — `\r` is
    stripped on load (the line editor is line-based) and the save writes LF;
    restoring the file's original line ending on save is a deferred
    refinement (record it per note). Deferred: the caret blink (an
    `AnimationController` refinement), the plain-drag persistent selection
    (the *drag* flow's drag-end still collapses per the E8a contract; the
    long-press selection persists after release, cleared by a tap) + the
    vertical-scroll-vs-select disambiguation. The E8d AC "edit, close,
    persisted" now holds (byte-identical to the buffer = LF).
- [ ] **E9** On-device performance verification: re-run the T-M2-00 log
  scenario on the real 931K + 297K notes, and microbenchmark a keystroke
  (apply N single-character deltas to 1K / 10K / 100K-line buffers). *AC: no
  sustained slow frames; scroll inside frame budget; per-keystroke cost
  measured and shown to stay inside budget at 1 MB (the O(lines) reset is the
  expected growth); numbers recorded here.*
  - Microbenchmark done (`test/unit/m2a_keystroke_benchmark_test.dart`: 50
    single-char insertions at end-of-buffer, `ComposingInput.apply` +
    `RowModel.sync` per keystroke = the editor's `_onChange` model half, 10
    warmup; dev machine, 2026-09-05): **1K lines (~0.0 MB): avg 0.07 ms,
    max 0.34 ms · 10K lines (~0.1 MB): avg 0.32 ms, max 0.60 ms · 100K lines
    (~1.1 MB): avg 4.4 ms, max 7.6 ms** — inside the 16 ms frame budget at
    1 MB; the O(lines) growth is the expected one, and at ~1M lines this
    half alone would be ~40 ms, so the in-place `_lineStarts` follow-up is
    warranted before then.
  - Log instrumentation done so the on-device run is analyzable:
    `NoteEditor` logs via `AppLogger(name: 'editor')` — per keystroke
    (`fold X ms, Y ms total, N chars, R rows`), per caret scroll (`row R to
    top/bottom in X ms`), one on init (`editor ready: ... rows in X ms`);
    `NoteView` already logs note load/save (chars + ms). All exportable from
    the settings-screen log buffer (`AppLog.dump()`).
  - On-device round 1 (2026-09-05, user, Android): opened the real
    55K/296K/931K notes in the instrumented build — opening + switching fast
    (load 10/15/37 ms, editor ready 0.01/0.18/0.28 ms), no sustained slow
    frames (one borderline 20–27 ms frame per open = the note's first editor
    frame; the ~111 ms slow frames are app startup). Keystrokes not covered
    (no typing this round). Feedback fixed: long-press word selection
    (missing) + theme-aware caret color (hardcoded black, invisible on the
    dark theme).
  - On-device round 2 (2026-09-05, user, Android, small note + 931K note):
    typing fast on the small note, but (a) the caret looked off by one
    char, (b) the caret was flimsy (1px), (c) the keyboard showed a
    checkmark instead of Enter, (d) the selection behaved like the finger
    was a cursor — after long-pressing 8 chars and tapping elsewhere, the
    next letter overwrote those 8, and (e) the 931K-note session ended in a
    "crash": three ~2.03s vsync stalls around one keystroke + one save, no
    ERROR lines, session dies. Root causes found from the logs + code:
    (a/d) **the gesture path never pushed its new selection to the IME** —
    tap/long-press/drag edited the `ComposingInput` but the platform kept
    the stale selection, so the next keystroke edited that stale selection
    (the 8-char overwrite; the "off by one" caret lands where the IME's
    copy still pointed); (c) the IME was attached with the default
    single-line `TextInputConfiguration` (checkmark = the "done" action);
    (e) the app's own save fires the file watcher, whose batch path
    (`Indexer._reconcile`/`_upsertFile`/`_ensureDirChain`) ran blocking
    `existsSync`/`statSync` on the UI isolate — on Android each stat is a
    FUSE round trip that takes seconds cold, hence the ~2.03s stalls (the
    same ANR rule the M1 plan already enforces for scans); plus the wrap
    width was a fixed 80 columns while the phone viewport shows ~55–60,
    clipping long lines and parking the caret off-screen. All fixed this
    round: gesture changes push to the IME (and only when changed),
    `TextInputType.multiline`, 2px caret, viewport-derived wrap width
    (capped at the `columns` param), and the indexer's event path probes
    disk on a background isolate (`probePaths` via `Isolate.run`, one batch
    per event/chain); a `CrashReporter` (main.dart) now records uncaught
    errors to the log buffer AND persists a `copist-crash-<stamp>.txt`
    (buffer + stack) into the open library, so a crash no longer loses the
    evidence; more `AppLogger` diagnostics everywhere on the hot path
    (per-delta IME lines with the platform's oldText size, gesture pixel→
    offset→selection lines, IME push/focus lines, save start/encode/write
    phases, lifecycle lines).
  - On-device round 3 (2026-09-05, user, Android, 931K note
    "Geometria 1" — kept at the repo root, gitignored): (1) the caret is
    too tall for the characters (it spansned the full 21px row while the
    glyphs are ~14px), (2) the cursor lands in the middle of the
    characters after a tap, (3) long-pressing a word "selects from the end
    of the line to the next line", (4) selecting a word is noticeably slow.
    Forensics from the exported log (the long-press hit the blank line at
    offset 448 between two paragraphs and `selectWordAt` returned the
    "\n\n" run — invisible on screen, which is exactly "end of the line to
    the next"; the ~2s vsync stalls correlate one-to-one with the full-text
    IME pushes — every 931K push blocks the Android main thread ~2s, so a
    drag pushing at pointer-move rate is a freeze storm; and the column
    count re-wrapped 57→80 across the app resume, moving every row under
    the finger — the "caret in the middle of a character"; the row/col
    arithmetic in the log confirms a tap's x maps to its column exactly, so
    the tap mapping itself is fine). Fixes: the caret now spans the font's
    strut box (`measureCaretHeight`, the platform's own caret measure,
    `BoxHeightStyle.strut`), centered in the row; `selectWordAt` on a
    whitespace/line-gap offset takes the nearest word (left first, then
    right) and only falls back to the whitespace run when the buffer has
    no words at all — a "\n\n" selection is impossible; the wrap width is
    re-derived only when a new width holds for two consecutive layouts
    (the initial viewport fit still applies immediately), the re-wrap logs
    old→new + cost and re-syncs the caret scroll; and the gesture path now
    pushes to the IME once per gesture end (tap / long-press start / drag
    end / long-press end), never per pointer move, and never an unchanged
    selection. `enableSuggestions: false` on the attach as the experiment
    for the ~2s push cost (flip back if the trade is not wanted). Gesture
    logs now carry the scroll offset and the resolved row/col. Pending
    (on-device, user-driven): round 4 — with the 931K note: tap, long-press
    a word (it must select the word, not the line gap) + drag, then type
    (the letter must land in the selection), scroll; note whether the
    selection/typing still stalls (the `ime push:`/`slow:` lines say
    where); export the log.
  - Standard selection UI (handles + context toolbar), added after the
    on-device rounds surfaced the gap (the user asked for as much
    "by the book" behavior as possible): the framework's
    `_SelectionHandleOverlay` handles (the platform handle assets,
    draggable through the same pointer→offset mapping the editor gestures
    use) and the `EditableText` context-menu contract (copy/cut/select
    all/paste — the `EditableText.defaultContextMenuBuilder` actions, an
    `AdaptiveTextSelectionToolbar` on iOS) over the virtualized view via
    `NoteSelectionDelegate` (the `TextSelectionDelegate` shim; the
    clipboard/IME glue lives there, not in the widget). The handles follow
    leaders at the selection endpoints (the zero-size leader layers a
    `RenderEditable` paints, realized here as 1×1
    `CompositedTransformTarget`s) and the toolbar anchors from the endpoint
    positions; the IME push path is unchanged (one push per gesture end).
    Verified by `selection_delegate_test` (unit) + `selection_handles_test`
    (widget: handles, toolbar, cut/copy/paste, select all, handle drag);
    on-device verification folds into round 4.

## Performance budget

- **Keystroke, model half** (steady state): the *claim* "O(change),
  independent of file size" is not literally met today. `LineBuffer._resetPositions`
  rebuilds the line-start array (O(lines), one allocation) and `RowModel.sync`
  re-wraps (O(lines), one allocation) on every keystroke — O(lines) total, not
  O(change). At measured sizes (~15K lines) that is a few hundred µs, well
  inside 16 ms; E9 microbench at 1 MB confirms: avg 4.4 ms / max 7.6 ms per
  keystroke at 100K lines (inside budget, O(lines) growth as expected).
  Follow-up if it matters (it will at ~1M lines): update `_lineStarts` in
  place (starts before the edit are unchanged, starts after shift by a
  constant delta) instead of rebuilding.
- **Keystroke, visual half** (steady state, any file size): incremental
  tokenize (~0.5 ms) + visible-row relayout (~1 ms) ≈ **< 2 ms** UI work; well
  inside 16 ms.
- **Open** a 931K buffer: read off-isolate (~26 ms measured) + build line list
  O(chars) + first visible-row layout O(rows). Target first frame < 100 ms
  (no 734 ms open frame).
- **Scroll:** O(visible rows) per frame; no full-buffer layout.
- **Memory:** line list + per-line row counts for ~1M chars is a few MB;
  tokenization cache is bounded to visible/working set.

## Risks / open questions

- **IME composition** (E4) is the make-or-break: Android composing ranges,
  autocorrect spans, and multi-line composition. Mitigation: the input client
  owns a real `TextEditingValue`-equivalent, not a toy; E4 is isolated and
  testable before selection polish. Fallback if composition proves too deep:
  keep a `TextField`-backed input layer for IME only and render lines around
  it — but that reintroduces monolithic layout, so E2's virtualization is the
  thing that must not be compromised.
- **Text scaling / accessibility:** row height is one value; scaling reflows
  visible rows. Announce caret/selection for accessibility later (E5+).
- **Monospace assumption** for O(1) metrics: keep the editor monospace (a
  source editor; math and CJK are styled but metrics stay on the mono grid).
  If proportional is ever required, row height becomes per-row and the O(1)
  scroll math needs a cached row-height array — acceptable, still O(visible).
- **Wrap choice** — decided at E2: **column wrap** (hard wrap at the grid
  width), O(1) row math on the monospace grid. Word wrap is a later visual
  refinement (a presentation change over the same row model, plus per-row
  start columns), not a model rewrite.
- **Row height** — fixed at 21 px (12 px font × 1.75): the integer extent
  keeps `itemExtent * rowCount` exact in double at any buffer size
  (fractional extents trip the sliver's even-multiple assertion).
- **Caret space** — decided at E3: the caret is a full-text offset in the
  same position space as `LineBuffer`; `LineEditor` (the editing session)
  owns the buffer + caret and fires a change stream for autosave/preview.
  Up/down move by *logical* line (column clamped to the target line); the
  wrapped visual-row geometry stays a view concern (E2/E8), so `LineEditor`
  is deliberately independent of `RowModel`.

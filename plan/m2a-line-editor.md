# M2a — Line-based editor (sub-plan of M2)

**Status:** Planned · **Depends on:** M2 (tokenizer T-M2-02, autosave/save
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

- **Caret** = (line, col) within the logical line list; rendered at the pixel
  point of (visual row, col) via the wrap mapping.
- **Selection** = a span over the flat text (or over (line,col) endpoints);
  supports multi-line. Caret + selection drive the text-input client.
- **Input:** the widget is a `TextInput` client (it owns a
  `TextEditingValue`-equivalent over the buffer). Keystrokes and IME
  composition are applied as edits to the line list. This is where Android
  composition/autocorrect and Linux input live — the riskiest surface, so it
  is its own milestone (E4) before selection polish.
- **Undo/redo:** stack of line-list edits (insert/delete/replace ranges).
  Bounded depth. (Can be a later milestone if it threatens E1–E6.)

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
    replacement / non-text) to `LineBuffer` in O(change), tracking the
    composing region, selection and caret so the view can render the IME
    underline. Lockstep is trusted (the platform is authoritative): a debug
    O(1) `oldText.length == textLength` assert, no text compare. Property
    test: 300 randomized edits on a 2000-line note keep the buffer exactly
    correct (no lost / duplicated input). The `DeltaTextInputClient` bridge
    and the composing-underline render are the E8 side (view); the model's
    correctness is verified here.
- [x] **E5** Selection + clipboard: tap/drag select (incl. multi-line),
  copy/cut/paste. *AC: select across lines; copy/paste round-trips; cut
  updates buffer + caret.*
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
- [x] **E6** Folding (with T-M2-07 outline): folded line ranges omitted from
  layout; fold/unfold; outline click → jump. *AC: folding a heading hides its
  rows; scrolling past a fold is correct; outline lands on the heading.*
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
- [ ] **E7** Highlighting integration: per visible line, tokenize (T-M2-02)
  and paint styled rows; math spans styled. *AC: tokens/math visually
  distinct; no per-frame re-tokenize of the whole file (only visible rows).*
- [ ] **E8** Wire into `NoteView` + autosave: replace the plain `TextField`
  baseline; debounce + save-on-focus-loss + atomic write (reuse M2 save
  path). *AC: edit a note, close the app, content persisted (byte-identical
  to what was typed); the baseline file is removed.*
- [ ] **E9** On-device performance verification: re-run the T-M2-00 log
  scenario on the real 931K + 297K notes. *AC: no sustained slow frames;
  keystroke + scroll inside frame budget; numbers recorded here.*

## Performance budget

- **Keystroke** (steady state, any file size): incremental tokenize (~0.5 ms)
  - visible-row relayout (~1 ms) ≈ **< 2 ms** UI work; well inside 16 ms.
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

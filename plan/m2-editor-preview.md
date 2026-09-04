# M2 — Editor + preview

**Status:** Planned · **Depends on:** M1.5 · **Spec:** *Requirements*
(editor, math, layout, images), *Milestones → M2*

## Purpose

Read and write notes: a lightweight source editor with Markdown + math
highlighting, a live `flutter_markdown_plus` + KaTeX preview, bidirectional
scroll sync, all Markdown extras, word count, heading outline + folding,
image insert, and the responsive layout system.

## Current state

M1.5 leaves a correct index and tree. Notes open in a plain `TextField`
baseline editor (autosave, atomic writes, absolute paths, responsive
phone layout) — **rejected on-device** for novel-length files; the
line-based editor it is being replaced by is planned in
[m2a-line-editor.md](m2a-line-editor.md).

## Tasks

The first two tasks decide whether the rest of this milestone's design
holds. Run them before anything else is built on top.

- [x] **T-M2-00** Editor spike: decide whether the editor is a custom
  widget or Flutter's own text editing with a custom
  `TextEditingController` and `buildTextSpan`. The controller route gives
  the design's own rule for free — highlighting as presentation over a
  plain-text model — with caret, selection, IME and accessibility already
  solved. The one requirement that a plain text field cannot serve is
  folding (T-M2-07), so the spike is really about what folding costs
  either way. Include a jank measurement on a novel-length buffer, which
  the spec asserts is fine but nothing has verified. *AC: a decision
  recorded here with the measurement behind it.*

### T-M2-00 decision: editor architecture — **final: custom line-based editor**

> **Status (final, 2026-09-04).** On-device verdict from the plain-`TextField`
> baseline (release APK, Android, real library): the plain editor is
> **rejected** for novel-length files. The custom line-based editor below is
> confirmed and scheduled as sub-plan [m2a-line-editor.md](m2a-line-editor.md).
> Raw evidence (full log + the two source notes, copyrighted — kept in the
> gitignored `reference/` folder): `reference/opening-files.log.txt`.

**On-device measurements** (release APK, per-frame from
`addTimingsCallback`; loads run off the UI isolate via `Isolate.run`):

| Note | Chars | Load | Steady state per frame | Verdict |
| --- | --- | --- | --- | --- |
| `capitolo_04.md` | 25K | 15 ms | one 22 ms build blip | fine |
| novel chapter | 297K | 66 ms | **~32 ms every frame** (build ~23 + raster ~8) | "almost smooth, not 100%" = pinned ~30 fps |
| math notes | 931K | 26 ms | **~100 ms every frame** (build ~78 + raster ~20); 734 ms build on open | "atrocious" = ~10 fps |

Signature: per-frame cost **proportional to total buffer size, not the
visible window** — the monolithic `EditableText` re-lays-out the whole
buffer on every frame (scroll *and* keystroke). Matches the headless spike
below; the headless 44.5 ms whole-buffer layout was the 200 KB case, and
the 931 KB file is ~4.6× that, as observed.

Spike: `test/unit/m2_spike_benchmark_test.dart` (200 KB / 6289-line
fixture, desktop host, best-of-N; run it to refresh the numbers).

Spike: `test/unit/m2_spike_benchmark_test.dart` (200 KB / 6289-line
fixture, desktop host, best-of-N; run it to refresh the numbers).

| Measurement | Value |
| --- | --- |
| Tokenize full buffer (one-time, on open) | 17.4 ms |
| Incremental tokenize per edit | 0.56 ms |
| Per-line layout+paint (the line-based paint unit) | 28 µs/line |
| Visible viewport re-layout (~40 lines) | ~1.1 ms |
| Whole-buffer single-span layout (monolithic field) | 44.5 ms |
| Preview parse (`MarkdownParser` only) | 12.5 ms |
| Preview eager full render (parse+build+layout+paint) | 2129 ms |

Decision: **a custom, line-based widget, not Flutter's monolithic
`EditableText`/`TextField`.**

Measurement-driven rationale:

1. **A monolithic field janks on novel-length.** `RenderEditable` holds the
   whole buffer as one text and re-lays-out the entire thing on every
   keystroke; that whole-buffer layout measures **44.5 ms** — ~2.7 frames at
   60 fps — *per keystroke* on a 200 KB file, which violates the spec's
   "edits without perceptible jank." A line-based editor re-lays-out only
   the changed line(s) plus the visible viewport, so a keystroke costs
   0.56 ms (tokenize) + ~1.1 ms (layout) ≈ **1.7 ms**, inside frame budget.
2. **Folding (T-M2-07) is only expressible line-based.** Collapsing a
   heading range is "layout skips those lines" (design.md); a single
   monolithic text cannot skip lines. A sliver list of line widgets folds by
   omitting the folded lines.
3. **Highlighting stays presentation.** Each line is its own styled
   `TextPainter`/`RichText` built from the tokenizer's tokens — exactly
   "highlighting as presentation over a plain-text model" (design.md), with
   no rich-text edit model.
4. **Accepted cost.** Caret, selection, IME composition, text scaling and
   accessibility are ours to build (the plan's largest unknown). The numbers
   above justify paying that cost: the monolithic alternative is disqualified
   on performance, not on effort.

**Preview cost model (guides T-M2-04/05).** Parsing is cheap (12.5 ms), but
the package's `MarkdownRenderer.render()` is a fully eager `Column` over all
nodes — 2.1 s for 200 KB. The preview must be **windowed**: parse the whole
document, but build+lay out only the visible block range (a sliver) using the
package's per-node builders. Never hand a novel-length document to
`SmoothMarkdown`/`render()` unwindowed.

- [ ] **T-M2-01** Source editor: superseded by sub-plan
  [m2a-line-editor.md](m2a-line-editor.md) (line-based editor, E1–E9),
  confirmed by the T-M2-00 on-device verdict. The plain-`TextField`
  baseline (autosave, atomic writes, save-on-focus-loss) stays in place as
  the fallback and as the save-path donor until the sub-plan's E8 lands.
- [ ] **T-M2-02** Highlighting layer: tokenizer for Markdown tokens (headings,
  bold/italic, code, lists, links) and math spans (`$…$`, `$$…$$`); styled
  display over a plain-text buffer (highlighting is a display concern only).
  *AC: tokens and math spans visually distinct; no rich-text edit model.*
- [ ] **T-M2-03** Verify `katex_dart`: confirm the pinned pure-Dart KaTeX
  version renders the spec coverage — matrices, `aligned`/`cases`, `\text`,
  `\newcommand` — before building on it. *AC: demo fixture renders all four
  cases; version decision recorded.*
- [ ] **T-M2-04** Preview pipeline: `flutter_markdown_plus` render parsed
  once per change (debounced), lazy block layout; tables, task lists,
  footnotes, strikethrough, code blocks via `flutter_highlight`. *AC:
  fixture with every extra renders correctly.* Conformance corpus:
  `test/spec.json` — the CommonMark test suite (652 markdown→html
  examples); run the preview's parsed structure against it as the
  acceptance test.
- [ ] **T-M2-05** Math pipeline: extract math spans → `katex_dart` render →
  LRU cache keyed by math string (design.md); placeholder box while rendering;
  same spans highlighted in the editor. *AC: editing a math expression reuses
  the cache for unchanged spans.*
- [ ] **T-M2-06** Bidirectional scroll sync: line-mapping table per render pass
  (source line → preview block); scrolling either pane moves the other.
  *AC: sync verified in widget test on a long fixture, both directions.*
- [ ] **T-M2-07** Word count + heading outline + folding: live word count;
  outline panel listing headings (click → jump); folding collapses sections in
  the editor. *AC: fold/unfold a section; outline jumps land correctly.*
- [ ] **T-M2-08** Layout modes: desktop = sidebar | editor | preview
  (draggable split); Android phone = full-screen Edit/Preview switch;
  tablet/wide = split; user override (auto / force split / force switch) in
  settings. *AC: all four modes reachable; override persists.*
- [ ] **T-M2-09** Image insert: picker → copy file into the library
  (`assets/` or chosen folder) → insert a link (no base64 by default).
  *AC: image visible in preview from the library-relative link.*
- [ ] **T-M2-10** Tests: unit (scroll-mapping, KaTeX LRU, highlighter) and
  widget (editor/preview render parity, layout modes). *AC: green.*

## Technical design

See [design.md](design.md) → *Editor & preview*. M2 slice:

- **Modules:** `editor/` (source_editor, highlighting), `preview/`
  (markdown_view, math, scroll_map), `ui/shell.dart` (three-pane layout).
- **Autosave:** ~500 ms debounce after last edit + on focus loss; writes via
  `core/files.dart` atomic temp-file rename; file events flow through the M1
  watcher into the index.
- **Scroll map:** rebuilt per render pass; binary search from caret line to
  block; O(blocks), not O(file).
- **KaTeX LRU:** capacity ~512 entries (tunable); key = exact math string;
  render is async — preview stays fluid.
- **Folding:** editor keeps a set of folded heading ranges; layout skips those
  lines; the outline panel drives it.
- **Layout controller:** Riverpod provider `layoutMode`
  (auto/split/switch) + width breakpoints (phone < 600 dp; tablet ≥ 600 dp).

## Exit criteria

- A novel-length fixture (~200 KB, mixed content + math) edits and previews
  without perceptible jank; autosave persists edits.
- Inline `$x^2$` and display `$$…$$` render via KaTeX; editor highlights them.
- Bidirectional scroll sync verified; all layout modes + override work.
- Word count, outline, and folding work on the fixture.
- Unit + widget tests green.

## Risks / open questions

- `flutter_markdown_plus` built-in coverage of footnotes/task-list
  checkboxes may need custom builders/extensions — verify in T-M2-04,
  budget a fallback custom-block pass. The package is the maintained fork
  of `flutter_markdown`, which upstream discontinued; the spec's stack
  list still named the old one.
- Highlight-overlay performance at MB-scale files: if a full re-tokenize per
  frame is too slow, token incrementally (on changed lines only).
- Writing caret, selection and IME from scratch is the largest single
  unknown in the plan (Android composition, autocorrect, text scaling,
  accessibility). T-M2-00 resolved that the cost is owed (the monolithic
  field is disqualified on-device); the risk is now managed inside
  [m2a-line-editor.md](m2a-line-editor.md) (E3–E6, IME-first ordering).
- IME edge cases (multi-line input, auto-correction) on Android — integration
  test in M2's `integration_test/`.

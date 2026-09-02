# M2 — Editor + preview

**Status:** Planned · **Depends on:** M1 · **Spec:** *Requirements* (editor,
math, layout, images), *Milestones → M2*

## Purpose

Read and write notes: a custom lightweight source editor with Markdown + math
highlighting, a live `flutter_markdown` + KaTeX preview, bidirectional scroll
sync, all Markdown extras, word count, heading outline + folding, image
insert, and the responsive layout system.

## Current state

M1 provides tree + CRUD; notes open to a placeholder view with no editing.

## Tasks

- [ ] **T-M2-01** Source editor: custom single-buffer editor widget (caret,
  selection, IME handling) that loads/saves a note's content; debounced
  autosave + save-on-focus-loss, atomic writes. *AC: edit a note, close the
  app, content persisted; IME works on Android + Linux.*
- [ ] **T-M2-02** Highlighting layer: tokenizer for Markdown tokens (headings,
  bold/italic, code, lists, links) and math spans (`$…$`, `$$…$$`); styled
  display over a plain-text buffer (highlighting is a display concern only).
  *AC: tokens and math spans visually distinct; no rich-text edit model.*
- [ ] **T-M2-03** Verify `katex_flutter`: confirm the pinned pure-Dart KaTeX
  version renders the spec coverage — matrices, `aligned`/`cases`, `\text`,
  `\newcommand` — before building on it. *AC: demo fixture renders all four
  cases; version decision recorded.*
- [ ] **T-M2-04** Preview pipeline: `flutter_markdown` render parsed once per
  change (debounced), lazy block layout; tables, task lists, footnotes,
  strikethrough, code blocks via `flutter_highlight`. *AC: fixture with every
  extra renders correctly.*
- [ ] **T-M2-05** Math pipeline: extract math spans → `katex_flutter` render →
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
  widget (editor/preview render parity, layout modes). *AC: green in CI.*

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
- Unit + widget tests green in CI.

## Risks / open questions

- `flutter_markdown` built-in coverage of footnotes/task-list checkboxes may
  need custom builders/extensions — verify in T-M2-04, budget a fallback
  custom-block pass.
- Highlight-overlay performance at MB-scale files: if a full re-tokenize per
  frame is too slow, token incrementally (on changed lines only).
- IME edge cases (multi-line input, auto-correction) on Android — integration
  test in M2's `integration_test/`.

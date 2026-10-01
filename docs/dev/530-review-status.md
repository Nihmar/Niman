# #530 review — status (2026-10-01)

A code review of `feat/530-mermaid-dart-engine` (the Dart-native Mermaid
engine), with the fixes it led to. Interrupted midway; this file says what
is done and what is left. Delete it once the list below is worked off.

Decision kept throughout: **no database**. Nothing of a diagram is stored
in `IndexDatabase`; the in-memory `DiagramCache` is the only cache, and an
export draws its own SVG.

## Where the work is

- The fixes are commits on `feat/530-mermaid-dart-engine`, pushed to
  `origin`. They were made in the worktree `.claude/worktrees/review-530`
  (detached HEAD), because the main checkout holds **uncommitted work on
  sequence diagrams** (`lib/src/diagrams/sequence_*.dart`, plus edits to
  `diagram_result.dart`, `diagram_svg.dart`, `mermaid_parser.dart`) that
  does not compile: `sequence_model.dart:117` uses `break` as an enum
  value, a keyword. That work was left untouched.
- The main checkout's local branch is therefore **behind `origin`**. To
  bring it up: set the sequence work aside (a tagged stash or a WIP
  commit), `git merge --ff-only origin/feat/530-mermaid-dart-engine`, put
  the work back. Expect a small conflict in `mermaid_parser.dart`: the
  review changed its imports and `_firstWord` (front matter / comments are
  now skipped through `mermaid_lines.dart`), the sequence work adds its
  dispatch case there.
- Then remove the worktree: `git worktree remove .claude/worktrees/review-530`.

## Done (one commit each, each with a test that failed before it)

- Comment on `DiagramCache` no longer promises a persisted index cache.
- `block_view.dart`: `_code`'s doc comment back above `_code`.
- A diagram wider than the pane is scaled down to fit (it ran off the
  edge); the full-screen view is drawn on the theme's surface (a light
  theme's dark edges vanished on the black barrier).
- The PDF raster fallback crashed on a diagram ("No Overlay widget
  found", the full-screen button's tooltip): an export (`BlockView.printed`)
  draws no button.
- Read view: a tap on a diagram, or on its parse error, opens the editor
  with the caret on the block or on the error's line
  (`NoteView.onShowSource`, wired in the shell's phone and desktop panes and
  the outside-file screen). The docs already claimed this.
- Live: a mouse press on a diagram no longer places the caret first (which
  hid the diagram and its full-screen button under the pointer); a tap on a
  parse error puts the caret on the error's line.
- Flowchart parser: a bare mention keeps a node's shape and label; a node
  mentioned in a subgraph joins it; `'` is not a quote (`Don't`,
  `l'utente`); `;` ends a statement; `%%` inside quotes is text; no
  direction means top-down; longer links (`--->`, `===>`, `-..->`) and
  `-. text .->` (edge spelling now in `flow_edge_scanner.dart`); nodes may
  be named `Class`, `link`, `click`; no quotes kept around a subgraph title
  or a `|"label"|`; `A:::class` is read.
- Front matter, comments and `%%{init}%%` before the header are read in one
  place (`mermaid_lines.dart`) by the dispatcher and both parsers.
- `DiagramStyle.cacheKey` includes the font family.

## Left to do

### Layout (`flowchart_layout.dart`) — was in progress

1. **LR/RL and every mind map draw transposed nodes**: the layout runs
   top-down and the final transform swaps each rect's width and height
   (`flowchart LR\nA[A very long label here]-->B` gives a 33×175 box). Lay
   out horizontal charts with swapped sizes (nodes and edge-label boxes),
   and build subgraph boxes and titles after orientation. Test: node rect
   proportions in LR.
2. **Nested subgraph boxes coincide** (both get the same rect, titles
   overlap). Record the parent in the parser (`FlowSubgraph.parent`), build
   a box from its nodes **and its children's boxes**, paint parents first;
   drops the O(n³) geometric guessing.
3. **Cycle ranking puts the first node last** (`A-->B-->C-->A`): DFS in
   declaration order, ignore back edges, longest path.
4. **Costs on the UI isolate**: `reindex()` walks every layer after each
   layer sort (3000-node chain: 1.25 s); cycle relaxation is O(V·E);
   barycentres are recomputed inside the sort comparator.
5. Split the file (~470 code lines, 2 classes) — planned:
   `flow_layers.dart` (rank + order), `flow_edge_route.dart` (curves, label
   boxes), `flow_subgraph_boxes.dart`, `flow_orientation.dart`.

### Size rule

- `flow_parser.dart` is still over ~300 code lines with 3 classes: move
  `_Cursor` to its own file.
- `diagram_layout.dart` (4 classes), `flow_model.dart` (4 classes + enums),
  `diagram_style.dart` (2 classes).

### Convert list to mind map (`lib/src/editor/list_to_mindmap.dart`)

- Item text with `()[]{}` changes the node (`- Buy milk (2 litres)` → a
  round node "2 litres"); `%%` cuts it; a leading `::` drops it. Emit
  `nK["…"]` for such labels and let the mind-map parser strip the quotes.
- **Never works on CRLF notes**: lines keep their `\r` and `listItemHead`
  returns null (also `_hasListAtCaret` in `note_view.dart`).
- Ignores fences and front matter: on `- x` inside a ```yaml fence or
  under `tags:` it writes a mermaid fence there. Check the block kind.
- A blank line (loose list) or a continuation line stops the scan; a
  1-space indent gives depth 0 → "only one root". Map depth by the rank of
  distinct indents.
- Copies the whole note on the UI isolate (`_editText`, split/join) in the
  command and on every Tools-sheet open: walk `buffer.lineAt` from the
  caret and edit only the list's range.
- `_hasListAtCaret` reads `selection.anchor`, the conversion
  `selection.start`.
- The palette command is a silent no-op outside a list: show
  `toolMindMapNeedsList`.

### Export

- Dark-mode HTML: the SVG always uses the light palette, so `#333` edges
  sit on `#1b1b1b`. Give `.diagram svg` a white background.
- EPUB read-back loses the diagram: put the source in `data-mermaid` on
  `div.diagram` and restore a mermaid fence in `xhtml_markdown.dart`.
- `svg_target.dart` does not drop C0 control characters (ill-formed XHTML).
- The export style has no font family: set `system-ui, sans-serif`, which
  the box sizes assume.

### Smaller

- Italian `it.dart`: "Sostituisce l'elenco al cursore con una mappa
  mentale" → "Sostituisce con una mappa mentale l'elenco in cui si trova il
  cursore" (same calque in other locales).
- Not yet run: the full suite, `dart fix --apply`, `scripts\niman.bat check`
  and the integration files. Every commit above ran its own tests and
  `flutter analyze --fatal-infos` on the touched directories.

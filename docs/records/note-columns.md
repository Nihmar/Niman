# Note columns (#729)

Two or more columns of blocks on one row — a picture and a table beside
prose, two columns of text — the way an encyclopedia article lays out its
facts beside its text. Written before the code (2026-10-12), as the plan
the work follows. The screens are in
[docs/design/note-columns](../design/note-columns/README.md).

The issue asked first whether this wants a record at all. It does: the
construct touches the scanner, the tree, every surface, every export and
the live engine's row model. Of everything Niman draws, only a table puts
content in columns today, and a table's cells hold inline text, not
blocks.

## The syntax

Pandoc's fenced divs, as Quarto lays them out. They are the only form with
real renderers outside Niman:

```
:::: columns
::: {.column width="40%"}
![[map.png]]

| Height | 2,218 m |
|---|---|
| First climbed | 1823 |
:::

::: column
Prose, a list, a table, a callout…
:::
::::
```

- **Opener.** Three colons or more, then the class: `columns` or
  `{.columns}`, `column` or `{.column …}`. Trailing colons are optional
  (`::: column :::`). Up to three spaces of indent, measured from the
  container's margin, as for a code fence. The attributes are Pandoc's:
  a bare word is a class, and `{…}` holds `.class`, `#id` and `key=value`
  or `key="value"`.
- **Closer.** Three colons or more and nothing else. It closes the
  innermost open div, whatever its length. That is Pandoc's rule. djot
  and commonmark-hs instead want a closer at least as long as its
  opener, so the Insert command writes the outer fence longer (`::::`):
  the two rules then agree on what it writes.
- **Only `columns` and `column` mean anything.** Any other `::: foo` stays
  text, as it is today. There is one exception for matching, under
  [Unknown divs](#unknown-divs).
- **An implicit column.** Content inside `columns` but outside any
  `column` forms a column of its own: each run of such blocks, up to the
  next column's opener, is one column.
- **`width="40%"` is honoured.** Only a percentage counts. `width=40%`
  without quotes is Pandoc's too and reads the same. Anything else
  (`300px`, `40`) is ignored, and that column shares like one with no
  width.
- **Behind `LineRules.appSyntax`**, like the frontmatter, `$$` and
  callouts. With it off — the specifications' examples — a `:::` line is
  text.
- **The fences are never rewritten.** Markdown comes back byte for byte
  (`docs/user/editing.md`), and an export as Markdown copies the text
  (`export_note.dart:71`).

### Where a fence is read

- **An opener cannot interrupt a paragraph.** It needs a blank line or
  the start of a block before it: another fence, a heading, a rule, the
  start of the note or of its container. `Prose` followed by `::: column`
  is one paragraph, as in Pandoc, which asks for the blank line.
- **A closer may end a paragraph.** `text` followed by `:::` closes the
  column, and the paragraph ends on the line before it.
- **An unclosed opener runs to the end of the note**, like a code fence
  (owner's decision 2). Inside a container — a quote, a list item, a
  footnote definition — it runs to the end of that container, again as a
  fence does. While someone types `:::: columns` above the rest of a
  note, everything below becomes one implicit column. One column is as
  wide as the note, so nothing moves until they open the second.
- **Inside code, math, HTML and frontmatter, a `:::` line is content.**
  The state those blocks carry already says so (`LineState.isPlain`).

### Unknown divs

Outside any `columns` div, an unknown `::: foo` is not tracked at all. It
is text, and so is a later bare `:::`. Notes that use `:::` for another
tool are therefore read as they are today, and the scan pays nothing for
them.

Inside an open `columns` div, every opener with attributes is tracked for
matching only. Without that, this Pandoc note:

```
:::: columns
::: column
::: warning
Careful.
:::
More.
:::
::::
```

would close the column at the warning's closer, and `More.` would fall
out of it. A tracked unknown div is drawn as its blocks, with its two
fence lines shown as text where they stand. Niman does not lay it out;
it only counts it.

### Nesting

The scanner reads `columns` wherever it reads blocks: at the top level,
inside callouts, quotes, list items and footnote definitions, and inside
another column (owner's decision 5). **Only the outermost `columns`
level sits side by side.** A `columns` inside a column draws its columns
stacked, one under the other, in source order. Every one of these
contexts gets a test.

## Width and wrapping

One rule, used both by the app and by the exported CSS (owner's
decision 4):

1. **Each column has a share.** A column with a width has its
   percentage. The others split what the widths leave equally. When the
   widths leave nothing, the others share `100 / N` each.
2. **A row holds columns while each gets at least 16 em.** That is
   224 px at the 14 px body size. The gap between columns is 1.5 em
   (21 px), and the same gap separates two rows. A column that does not
   fit starts the next row: the flex-wrap semantics.
3. **On a row, the width after the gaps is split in proportion to the
   shares** of the columns on that row.

Three equal columns in a 700 px note column need 3 × 224 + 2 × 21 =
714 px. They wrap: two on the first row, and the third alone on the
second, as wide as the block. A 40 % / 60 % pair gets 271 and 408 px.

**On a phone the rule stacks the columns by itself.** The text there is
358 px wide, and two columns need 469. Stacking is decided by the width
the block has, never by the device type. A narrow desktop window stacks
too, and so does a wide tablet in a split. On a phone the stacked columns
come in source order; there is no syntax to reorder them (owner's
decision 6).

**No widening on wide windows** (owner's decision 9). The columns live
inside `noteColumnWidth` (700 px by default, `note_column.dart`), like
every other block.

## The scanner: divs as containers without a prefix

Two shapes were possible.

- **Rejected: one block, scanned again.** The whole `columns` block would
  be one scanner block, and its content would be scanned again as a text
  of its own, as `QuoteContent` does for a quote (`quote_content.dart`).
  This is how a quote works, and the issue pointed at it. It fails on two
  counts.
  - **A keystroke would pay for the block.** `LiveQuoteContent` scans a
    quote's content again at every revision, and its comment says why
    that is acceptable: "a quote is a few lines". A columns block is a
    layout container, not a few lines. A 5,000-line one would be scanned
    whole on every keystroke.
  - **Every per-line feature of `live` would need a second path.** The
    styler's tokens, the code colours, tables, formulas, diagrams,
    definitions and callouts each ask `blockOf(line)` for the line's
    block. Inside a re-scanned container they get the container instead,
    which is exactly why quotes carry their own path (`_quotes.of`,
    `_codeColors.ofQuoted`). Columns would need a third.
- **Chosen: flat.** A div is a container with no line prefix, closed by a
  fence line. The blocks inside a column stay ordinary scanner blocks,
  and each records how deep in divs it stands, as a block records its
  list and quote depth. `block.dart` already argues for this shape: "a
  blockquote or a list item records its depth instead of owning nested
  blocks". The consequences:
  - An edit inside a column is the O(change) rescan every edit already
    is.
  - A table, a formula, a diagram or a code block inside a column *is* a
    table, a formula, a diagram or a code block to `live`, with no new
    path.

What changes:

- **`LineState.divs`**: the open divs, outermost first. Each entry is
  `({int colons, DivKind kind, double? width, int items})`. `kind` is
  `columns`, `column` or `other` (a tracked unknown div). `items` is how
  many list items were open when the div opened. Like `listStack`, the
  list compares by value. The state stays a small value, so convergence
  works unchanged: a column's lines converge as any lines do, and an
  edit that opens a div with no closer makes the rest of the note a
  frontier. That frontier is handled as a new code fence's is
  (`docs/records/huge-notes.md` item 3).
- **`ContainerWalk`** walks the divs first. They take no prefix. A div
  ends when the item it was opened in ends, and when its quote or
  footnote definition does. A footnote definition opens at a column's
  margin, because a div adds no margin of its own (owner's decision 7).
- **`LineRules._readLeaf`** reads two more line kinds, only when
  `appSyntax` is on, `open` holds no leaf (`isPlain`), and the
  paragraph check passes:
  - an **opener**, when no paragraph is open and the class is `columns`,
    or `column` with a `columns` open, or anything else with a `columns`
    open;
  - a **closer**, a bare colon run, when a div is open at this item
    depth.
  The test is one character first (`:`), so a note without `:::` pays
  for one comparison per line.
- **`BlockKind.div`**: one block per fence line. `fenceInfo` holds the
  attributes as written. A new `Block.divRole` says what the line does:
  opens `columns`, opens `column`, opens another div, or closes.
  **`Block.divDepth`** is how many divs the block stands in. Both join
  `sameShape`, so a rescan never keeps a block whose role changed.
- **The shared states.** Inside a column, `LineState.paragraphOpen` can
  no longer be the shared constant: the state holds the divs. States are
  interned per divs stack (`paragraphOpen` and `initial` each with these
  divs), so a long column of prose allocates no state per line (#346).

### The tree

`BlockNode` is sealed, so the compiler lists every walk that has to learn
the new nodes. Two are added:

- **`ColumnsNode`**: `line`, `opener` and `closer` (`SourceSpan`s; the
  closer is null when the block runs to the end), and `columns`.
- **`ColumnNode`**: `line`, `width` (`double?`), `implicit`, `opener` and
  `closer`, and `children`.

`BlockTree._build` hangs blocks under the innermost open column, as it
hangs a block under the item its list depth names. Its stack of open
containers becomes one stack of items and divs, so a `columns` opened
inside an item lands in that item's children, and an item opened inside
a column lands in the column. A tracked unknown div adds no node. Its
fence lines become paragraph leaves where they stand, which is what
"stays text" means.

## The read view

Today the read view's sliver places the scanner's top-level blocks from
a height map, and each is drawn by `BlockView` through
`BlockTree.ofBlock` (`markdown_read_view.dart`). The blocks of a column
are top-level scanner blocks, so the read view groups them:

- **The block list is cut into segments.** A run of ordinary blocks is a
  `SliverMarkdownBlocks`, as today. A top-level `columns` block is a
  **`SliverColumns`**: one sliver per column, each a
  `SliverMarkdownBlocks` over that column's blocks with a height map of
  its own, laid side by side. This is the structure `live` draws with
  too (below), so the two place every glyph the same way, which is what
  `read_live_page_test` holds them to. And a 2,000-line columns block
  builds only the blocks the viewport shows.
- **Its height in the note's map is the tallest column's.** The estimate
  is each column's blocks at the column's width, and the largest of them
  per row of columns, summed over the rows. A frame that draws the block
  writes the measured height back, as for any block.
- **Selection is in source order.** Flutter's `SelectionArea` orders its
  selectables by where they are drawn, top to bottom and then left to
  right. That interleaves two columns: a drag from the left column into
  the right would take the left column's lines below the pointer as
  well. The read view's blocks already report to `ReadSelectionScope`
  keyed by their start line (`read_selection.dart`). A
  `SelectionContainer` with a delegate that sorts by that line, and not
  by geometry, makes both the drag and the copy follow the source:
  - all of the left column after the anchor;
  - then the right column up to the pointer.
  The issue's "per-column `SelectionContainer`" is kept where a column is
  a box: inside a callout, a quote or a list item, `BlockView` draws a
  `ColumnsView` (a wrap of boxes, not slivers), and each of its columns
  is a `SelectionContainer`. At the top level the columns are slivers. A
  `SelectionContainer` reads its child's geometry as a `RenderBox`, so
  there the sort is what gives source order.
- **Nested columns** — `columns` inside a callout, a quote or a list
  item — are drawn by `BlockView` as that `ColumnsView`, inside the
  container's box. They are side by side when the width allows; this is
  the outermost `columns` level, so it is not one that stacks.
  `columns` inside a column stack.
- **A footnote definition inside a column** is drawn as nothing where it
  stands, and among the note's footnotes at its end, as everywhere
  (`BlockView.build`, `footnote_list.dart`).

## Live: side by side, and editable

`live` draws **one source line per sliver row**
(`source_view.dart`, the `SliverChildBuilderDelegate` over
`_folds.lineOf(row)`). The caret, a tap, a selection and the IME are
built on that model. Placing two runs of lines beside each other breaks
four of its assumptions:

- **the row model**: a row is a line, and rows are stacked;
- **caret geometry and hit testing**: `_paintedOffsetAt` asks each drawn
  line whether a point's *y* is inside it, and never its *x*;
- **windowing**: one height map, one sliver;
- **the height map**: every row's top is the sum of the rows above it.

What follows keeps everything that does not depend on those four, and
replaces the four.

### What already holds

Most of the engine is built on per-line `GlobalKey`s and source offsets,
not on where a line sits. That is what makes this tractable.

- **The caret** is measured in its line's own paragraph
  (`_measureCaret`, `_caretRectIn`) and drawn by that line
  (`SourceLine`). `caretRect` is shifted by the paragraph's own
  `localToGlobal`. A line drawn in a column at x = 290 has its caret at
  x = 290 with no change.
- **A selection** is a source range, painted by each line as a
  background on the runs it covers (`_selectionIn`). One that starts in
  the left column and ends in the right paints the rest of the left
  column, the fence bands and the start of the right column. Source order
  falls out of the model.
- **Copy** is `buffer.substring(start, end)`: the source, fences
  included.
- **The IME's composing range**, misspellings, find matches and template
  problems are source ranges clipped to each line (`_composingIn`,
  `_misspelledIn`, `_foundIn`). The IME's caret geometry is
  `caretRect` (`_sendGeometry`).
- **Undo** is a stack of source splices (`edit_history.dart`). Typing in
  a column coalesces as anywhere. Insert columns is one step. Deleting a
  selection across columns is one step, and the fences it took go with
  it.
- **Tables, formulas, diagrams and code inside a column** are the blocks
  they are, because the scanner is flat. Their pieces are positioned from
  their own paragraphs (`_piecesOf`, `_tableGrid`).

### Rows: a columns block is one row of the note

`SourceFolds` already maps lines to rows with ranges of lines that are
not rows: "row *r* is the *r*-th line nobody has hidden". It grows a
second kind of range and becomes **`LiveRows`**:

- **folded**: hidden, drawn nowhere, as today;
- **hosted**: the lines of a side-by-side `columns` block after its
  opener, drawn *inside* the opener's row.

`rowOf(line)` for a hosted line answers the host row, as a folded line
answers its heading's. `lineOf(row)` is unchanged. The note's
`BlockHeightMap` stays the one coordinate system for everything that
scrolls: a host row's extent is the whole block's height.

Which blocks are side by side is kept by a reader of the scanner's block
changes (`BlockScanner.takeChanges`). `LiveColumns` keeps the `columns`
blocks: their opener and closer lines, their columns' line ranges and
widths. It updates from the splices, O(change), as the read pane's
heights do. A block whose width puts each column on a row of its own is
not hosted: its lines are ordinary rows. That covers the phone, a narrow
window, and the fallbacks below. **Stacked is the existing engine.** Only
side by side is new.

### Windowing: one sliver per column

The sliver list is cut at host rows. A run of ordinary rows is a
`SliverMarkdownBlocks` over a view of the note's map (rows `[a, b)`,
offsets counted from `a`). A host row is a **`SliverColumns`**:

```
SliverColumns (host row h)             writes its extent to the note's map at h
└─ SliverMainAxisGroup                 the rows of columns, one under the other
   ├─ band: the outer opener           thin, 0.5 em
   ├─ SliverCrossAxisGroup             one row of columns
   │  ├─ column 1: SliverMarkdownBlocks over its lines, its own height map
   │  ├─ gap: SliverConstrainedCrossAxis(1.5 em)
   │  └─ column 2: SliverMarkdownBlocks …
   ├─ SliverCrossAxisGroup             the next row, when the columns wrap
   └─ band: the outer closer
```

Flutter has both groups (`rendering/sliver_group.dart`, in the SDK this
repository builds with). Each child of a `RenderSliverCrossAxisGroup`
gets the same scroll constraints at its own cross extent, and the group
takes the geometry of its tallest child. So:

- each column is windowed by its own `SliverMarkdownBlocks`, and a
  5,000-line block builds the lines the viewport shows and no more;
- the block is as tall as its tallest column, with no code of ours;
- the shares are `crossAxisFlex`, and the gap is a flex-0 child, so the
  width after the gaps is split by share exactly as CSS splits it.

`SliverColumns` itself is a proxy that records the group's scroll extent
in the note's map at the host row, the way `RenderSliverMarkdownBlocks`
records a measured row. **The one thing to check first (phase 5, step
1):** the cross group ignores a child's scroll-offset correction.
`SliverMarkdownBlocks` never asks for one: its comment says positions
come from the map, and the scroll position is not corrected. If that
turns out not to hold, the fallback is a render sliver of our own of the
same shape, about 150 lines modelled on `RenderSliverCrossAxisGroup`.

`RenderSliverMarkdownBlocks` lays out one child even when the whole
sliver is out of the cache range, because `indexAt` falls back to the
last row. With one segment per block that would be one layout per
off-screen segment per frame. A segment wholly outside the cache range
lays out nothing and reports its extent from its map. This is a small
change, and it is held by a count of children laid out.

### The geometry service

Every reader of `_heights` in `source_view.dart` that turns a line into a
*y* goes through one function instead. They are `jumpToLine`,
`topAnchor`, `showAnchor`, `_ensureCaretVisible` / `_rowBounds`,
`_mappedOffsetAt`, `moveCaretVertically`'s scroll fallback, `_page`,
`_codeCopies` and `_reshapeRows`. The function is
`NoteGeometry.lineBox(line)`: the line's top, height and *column* — its
left edge and width.

- **A line of an ordinary row:** the map's offset, at the text's edges.
- **A hosted line:** the host row's offset, plus the top of its row of
  columns, plus its offset in its column's own map, at its column's
  edges.

Two readers need more than the swap.

- **`_codeCopies`** puts a code block's copy button at
  `note.size.width - _rightInset`. Inside a column it is the column's
  right edge.
- **`_ensureCaretVisible`** keeps the caret's row on screen. A host row
  can be taller than the screen, so it keeps the caret's *line*, from
  `lineBox`.

### Hit testing

`_paintedOffsetAt` walks the drawn lines and takes the first whose
paragraph holds the point's *y*. Beside each other, the left column's
line 14 and the right column's line 40 both hold it. The test takes the
column first:

- **A point inside a column** is that column's, and its line is found by
  *y* among that column's lines only.
- **A point in the gap** is the nearer column's.
- **A point on a band** — a fence out of the caret's reach — reveals that
  fence: the caret goes to the end of the fence line. That is how a
  pointer or a finger reaches a column's width.

`_mappedOffsetAt` — for a point no drawn line holds — does the same with
`lineBox` in place of drawn paragraphs. Touch selection
(`SourceTouchSelection`) goes through `offsetAt` and `_caretRectAt`, so
it follows.

### Caret motion

- **Left and Right**, by character and by word, move in source order,
  with one exception: **a fence run out of the caret's reach is not a
  stop.** Right at a column's last character goes to the next column's
  first, in one press, the way Right at a line's end goes to the next
  line. After the last column it goes to the first character after the
  closer; Left mirrors this. This generalizes `_inCell`, which already
  steps the caret over a table's room in the direction it travels. Once
  the caret is *on* a fence line, the line is ordinary text and the
  motions inside it are too.
- **Up and Down** are geometric inside a column, as everywhere: the
  point a row away, asked of the drawn lines (`moveCaretVertically`).
  With the column test above, that point lands in the same column. At a
  column's edge the rule follows the source (owner's decision 8):
  - Down on a column's last row goes to the next column's first row, at
    the same distance from the column's left edge;
  - Up on a column's first row goes to the previous column's last row;
  - past the last column Down leaves the block, to the line after the
    closer; past the first column Up leaves it, to the line before the
    opener;
  - the goal *x* is kept as a distance from the column's edge, so going
    down through three columns keeps the caret in the same place in each.
- **Home and End** are the visual row's ends inside the column, as today.
  **Home at the start of a column's first line steps onto that column's
  opener** and reveals it. That is the keyboard's way to the width:
  Home there did nothing before, so the extension takes nothing away.
- **Ctrl+Home and Ctrl+End** are the note's ends. **Select all** is the
  note, as in a code block.
- **Page Up and Page Down** keep the caret's place on the screen
  (`_page`), so the columns scroll together and the caret stays in its
  column while the column lasts.
- **Shift with any of these** extends the source range.
- **Entering and leaving.** The caret enters the block by any motion
  above. While it is anywhere in the block, the fences show as markers
  (next section). When it leaves, they go back to bands.

### Fence lines

Decided here, for the owner to confirm.

- **Out of the caret's reach**, every fence line is a **band** of 0.5 em
  with nothing drawn in it, in both modes. A column's opener is the
  space above its first block and its closer the space below its last;
  the outer fences are the block's margins. The read view keeps the same
  room, so a flip between the modes moves nothing.
- **With the caret in the block**, markers are drawn in the bands' own
  room, so nothing moves when the caret comes in:
  - each column's opener draws a hairline in `markerDim` (`#4A4F59`),
    with a small chip at the column's top right naming it:
    `column · 40%`;
  - the outer opener draws only a chip at the block's left: `columns`;
  - the closers draw nothing, so the markers do not crowd each other.
- **With the caret on a fence line**, that line shows its source, dimmed
  like any revealed mark: `::: {.column width="40%"}`. It takes a row,
  and only that row moves, as a heading's `#` shows when the caret is on
  it.

The two alternatives were worse:

- **Bands that take no room** — like a definition out of reach — would
  move a column's content down at the moment the caret enters it.
- **Fence lines always as source** would turn a two-column page into
  nine lines of colons.

### IME

The window the platform's input method reads around the caret
(`SourceInput._windowAround`, `windowReach` either side) is clamped to
the caret's column. A keyboard reading the words before the caret should
find the column's words, not `:::` or the end of the column on the left.
The composing range is a source range inside the column, underlined by
its lines, and the candidate window stands at `caretRect`.

### Find, folds, line numbers, overlays

- **Find and replace** work on the source (`source_find.dart`). Showing a
  match goes through `lineBox`. A match inside a fence line — someone
  searching for "width" — puts the caret there and reveals the fence.
- **Folds.** A heading inside a column folds its section inside the
  column: the section ends at the column's closer at the latest. A fold
  whose section spans the block hides the host row whole. The `::::`
  opener gets a fold arrow in both `source` and `live`, which folds the
  block to its opener. Folds today are headings only; `SourceFolds`
  already takes any anchor and end.
- **Line numbers in `live`.** The gutter numbers the outer opener and the
  outer closer, and a bracket between them spans the block. The lines
  inside side-by-side columns are not numbered: there is one gutter and
  several columns. `source` numbers every line, stacked. *Decided here,
  for the owner to confirm.*
- **The table handles and the code copy buttons** are placed from their
  blocks' paragraphs and from `lineBox` (above). The typewriter's line
  colour spans the caret's column, not the note.
- **Semantics** (`note_semantics.dart`) reads the columns in source order.

### Inside callouts, quotes and list items

A `columns` block inside a callout is the outermost `columns` level, so
on a wide enough pane it is side by side in `live` too. A quote is one
scanner block, so its columns are known from its content, scanned again
(`LiveQuoteContent`). The host range is that block's lines, mapped back
to the note. The `SliverColumns` is inset by the container's indent, and
it paints the container's decoration down its whole height: the quote's
bars, the callout's box and bar, the item's indent. `LineShape` draws
those a line at a time today.

**The cap.** A quote's content is scanned again at each revision, and its
comment allows that because "a quote is a few lines". A quote or callout
of more than 2,000 lines draws the columns inside it stacked, which is
the row model with no rescan of the host. The read view is not capped:
it draws a quote whole already.

### Many blocks

With one segment per `columns` block, a note of a thousand blocks is two
thousand slivers. Off screen, each costs a map read per frame. The bar
below holds that. If it fails, the blocks past the first 512 are drawn
stacked, which is the row model with no segment. No cap is set before
the measurement says one is needed.

### Source

`source` is unchanged. It stays line by line and stacked, every line
numbered. The fence lines are coloured as a code fence's are: the colons
`codeFence`, the attributes `codeLanguage` (`SourceStyler._fenceTokens`).
The outer opener gets a fold arrow.

### Performance bars

Following AGENTS.md: each test prints its number and says which bar it
was held to. Every run asserts a backstop; the design's ceiling is
asserted only under `NIMAN_PERF=1`.

| Test | Measures | Backstop (every run) | Ceiling (`NIMAN_PERF`) |
|---|---|---|---|
| `columns_keystroke_test` | a character typed in the middle of a 5,000-line, two-column block in `live`: rescan + build + layout | the rescan reads fewer than 64 lines (a count, so exact); the frame lays out fewer than 200 lines | 8 ms |
| `columns_read_layout_test` | first layout of a 2,000-line, two-column block in the read view, scrolled to its middle | blocks built ≤ what two viewports hold (a count) | 16 ms |
| `columns_scroll_test` | a scroll frame at the end of a note of 500 `columns` blocks | children laid out off screen = 0 | 4 ms |
| `columns_scan_test` | the block scan of the 1 M-line fixture without any `:::`, against the same scan before the change | within 3 % | within 1 % |

## The other surfaces

- **Exports.**
  - **HTML, PDF and EPUB** write
    `<div class="columns"><div class="column" style="flex-grow:40">…</div></div>`
    from `TreeHtml`. The CSS goes in `pageStyle` (`html_page.dart`):

    ```
    .columns { display: flex; flex-wrap: wrap; gap: 1.5em; margin: 0 0 1em; }
    .column { flex: 1 1 0; min-width: min(16em, 100%); }
    .column > :last-child { margin-bottom: 0; }
    ```

    A column's `flex-grow` is its share: its width, or an equal part of
    what the widths leave. With a basis of 0, the width after the gaps
    is split by share. The 16 em minimum makes a column that does not
    fit wrap, because flex lines break on the hypothetical size, which
    is the basis clamped by `min-width`. This is the app's rule (above),
    written once more in CSS.
  - **The issue's `flex-basis: 40%` with `flex: 1 1 16em` was
    considered.** It lets the 40 % column grow past 40 %, because the
    free space is split equally. *Changed here, for the owner to
    confirm.*
  - **Print.** `@media print` adds no `break-inside: avoid` on
    `.columns`: a block taller than a page has to be able to cross one.
    The pictures, tables and callouts inside it keep their own rules. An
    A4 page at 18 mm margins is about 658 px wide at 11 pt, so two
    columns fit side by side.
  - **The raster PDF** (`rasterPdf`, no browser engine) draws through
    `BlockView`, so it gets the read view's `ColumnsView` at the page's
    width.
  - **An EPUB reader without flexbox** stacks the divs as blocks, in
    source order. That is an acceptable degradation.
  - **Markdown export** copies the bytes.
- **Footnotes.** A definition inside a column is collected by the line
  scan (`DocumentScope.scan`, `block_parser.dart`) and drawn at the note's
  end, as anywhere (owner's decision 7). The scanner opens one at a
  column's margin (above).
- **The index.** `blockReferencesOf` (`markdown/note_references.dart`)
  works per scanner block. The blocks inside a column are scanner blocks,
  so their tags, wikilinks and embeds are read with no change. The tree
  walk (`visit`) learns the two nodes, for columns inside a quote or an
  item.
- **Outline.** `outlineOfBlocks` filters the scanner's heading blocks, so
  a heading in a column is an outline entry and a link target
  (`jumpToAnchor`, `headingSlug`). `outlineOfText` walks lines
  (`HighlightDocument.forEachHeading`), and a `:::` line changes none of
  its state. The two agree, and a parity test over a note with headings
  in columns, nested and not, holds them to it.
- **Tidy** (`joinWrappedLines`, `formatMarkdown`):
  - **Never joins a fence line.** Today a `:::` line against paragraph
    text *is* paragraph text and would be joined (`line_join.dart:44`).
    As a `div` block it is a leaf of no paragraph.
  - **Keeps fences verbatim** (`_Unit.opaque`), and puts no blank line
    before or after them: their layout is the writer's.
  - **Descends `ColumnsNode` and `ColumnNode`** in its tree walk.
- **Slides.** `splitSlides` breaks on a top-level thematic break
  (`slide_split.dart:66`). "Top level" adds `divDepth == 0`, so a `---`
  inside columns does not split a slide.
- **Escapes.** The EPUB reader and web capture write their text through
  `escapeMarkdownLineStart` (`text_escape.dart`). A paragraph starting
  with `:::` — Docusaurus admonitions in a captured page, say — gets
  `\:::`. A backslash escapes any ASCII punctuation in CommonMark, and
  `\:::` opens nothing in Niman or Pandoc. `{`, `}` and `.` stay
  unescaped; they are harmless outside a fence line.

## The Insert columns command

The same command on every platform (AGENTS.md: every platform ships every
feature):

| Where | What |
|---|---|
| Toolbar, desktop and phone | **Columns**, `Icons.view_column_outlined`, in the Insert group after **Table** (`ToolbarItem.columns`) |
| Context menu | **Insert › Columns**, after Table (`editor_menu.dart`) |
| Phone | the same toolbar button, and **Columns** in the Insert sheet (`menu_group_sheet.dart`) |
| Command palette | **Insert columns**, no default shortcut, like Insert diagram |

It writes two equal columns at the caret's block, through `insertBlock`,
with a blank line before when the line above is text, as a table is
inserted:

```
:::: columns
::: column
Left column
:::

::: column
Right column
:::
::::
```

`Left column` is selected, so typing replaces it. The outer fence is
four colons, so djot and commonmark-hs close it where Pandoc does.

## How it degrades elsewhere

| Where the note is opened | What it shows |
|---|---|
| Pandoc (HTML, LaTeX, docx) | Divs with the classes. Real columns where the writer lays them out. |
| Quarto (HTML, revealjs, PDF) | Real columns: this is Quarto's own syntax. `width="40%"` honoured. |
| djot | Divs, closed where Pandoc closes them because the outer fence is longer. |
| GitHub, CommonMark, GitLab | The `:::` lines as paragraph text, the blocks in reading order. |
| Obsidian | The same: `:::` lines as text, the blocks in order. |
| An EPUB reader without flexbox | The columns stacked, in source order. |

Nowhere is content lost or reordered: the worst case is the colons as
text.

## Rejected alternatives

| Alternative | Why not |
|---|---|
| **HTML and CSS** (`<div style="display:flex">` in the note) | An HTML block is drawn as code in both modes (`leaf_view.dart`, `docs/user/editing.md`). Rendering it would mean an HTML engine, and Markdown inside an HTML block is not Markdown to CommonMark unless blank lines are placed just so. |
| **Tables holding blocks** | A GFM cell holds inline text, one line. Lists, pictures and callouts would need `<br>` hacks or a table syntax of our own, and the table editor's model (`markdown/table/`) would have to learn blocks. |
| **Transclusion** (a row of embedded notes) | The content would live in other files: the note no longer reads as one text, and a column cannot be edited where it is shown. |
| **Callouts as layout** (the Modular CSS Layout's `> [!multi-column]`) | Every line gets a `>` prefix, two levels deep, and it renders as nested quotes everywhere but Obsidian with a CSS snippet. Owner's decision 10: one syntax. |
| **Obsidian Multi-Column** (`--- start-multi-column: ID`) | A plugin's syntax. Its `---` lines read as rules or setext underlines everywhere else, and its settings block is noise. |
| **Layout in the frontmatter** | It lays out the whole note, not a row of it, and a picture beside one paragraph is the common case. |
| **A terse separator** (`::: columns` with `::: \|` between columns) | No renderer anywhere knows it, and a `\|` line looks like a table to GFM. |
| **The narrower first step** (read view and exports only, `live` showing the source) | The issue named it. The owner chose the complete solution (decision 8): the source of a two-column page, shown stacked while editing, is the page changing under the writer, which `read-live-parity.md` exists to prevent. |

## Phases

One PR, on one branch, a commit per step:

1. **The engine.**
   - `LineState.divs`, the two line kinds, `BlockKind.div`, `divRole`
     and `divDepth`.
   - `ColumnsNode` and `ColumnNode` in the tree.
   - The tests:
     - every nesting context;
     - unclosed openers;
     - `:::` inside code, math, HTML and frontmatter;
     - unknown divs inside and outside;
     - convergence after edits on fences, held to a full scan;
     - Pandoc's own examples as an oracle for the nesting.
2. **The read view.**
   - Segments and `SliverColumns`.
   - `ColumnsView` inside containers.
   - Source-order selection.
   - The estimate.
   - `columns_read_layout_test`.
3. **The exports.**
   - `TreeHtml`, `pageStyle`, print and the raster path.
   - A golden HTML page.
4. **Index, outline, tidy, escapes, slides.** Each with its test, the
   outline parity among them.
5. **`source`, then `live` side by side, then the command.**
   - The `SliverCrossAxisGroup` spike first.
   - Then `LiveRows`, `LiveColumns`, `NoteGeometry`, hit testing,
     motion, the fence bands, IME, folds, overlays.
   - Then the Insert command on every surface.
   - `read_live_page_test` extended to columns.
   - The keystroke and scroll bars.
   - The user guide (`docs/user/editing.md`, a "Columns" section) and
     `docs/user/platforms.md`. Nothing is left out on any platform; a
     phone stacks by the width rule.

## Risks

- **The scanner's correctness and convergence.** `:::` inside code, math,
  HTML and frontmatter must stay content. An edit that opens or closes a
  div must converge where a full scan agrees. The scanner's existing
  oracle tests compare a rescan with a full scan after every edit
  (`block_scanner` tests); they gain fence edits.
- **Performance.** A new field in `LineState` touches the hottest path.
  The scan bar above and the shared states hold it.
- **The live rework.** The row model is the engine's spine. Every
  `_heights` reader moves to `lineBox`, and hit testing learns columns.
  `read_live_page_test` and the existing caret tests are the net. The
  stacked case is the old engine, so a phone exercises none of the new
  geometry. The desktop tests have to.
- **`SliverCrossAxisGroup`.** A framework class we have not used. The
  spike comes first, and the fallback is named above.
- **Escaping imported text.** A captured page whose paragraph starts with
  `:::` would otherwise open columns in the note it lands in.
- **Pandoc and djot closers.** Niman reads Pandoc's rule: a bare closer
  closes the innermost div. A note written for djot, with an inner
  closer longer than its opener, closes the same divs. A note relying on
  djot's length matching to close an *outer* div with a long closer would
  not. Insert writes fences that read the same under both.

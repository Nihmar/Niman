# Read and live: one page (2026-09-23)

The read view and `live` are meant to be the same page, one of them
editable. A glyph that moves when the pane flips is the page changing under
the reader. This file records where the two stand, what was done to bring
them together, the decisions taken on what is left, and where opening the
246 MB stress note stands.

The alignments are held by `test/widget/read_live_page_test.dart`: each one
compares where a construct's first glyph lands in both modes — across and
down — and where a code block's box and a rule stand, so they cannot drift
apart again unnoticed.

## Where the constructs stand

The first glyph of each construct, read view minus `live`, no line numbers,
no column: the table's row measured with the platform font (Segoe UI) in a
520 px pane, the rest as `read_live_page_test` holds them.

| construct | dx | dy |
|---|---|---|
| headings, paragraphs, lists, task lists, quotes, rules | **0.0** | **0.0** |
| fenced and indented code, its box, its colours | **0.0** | **0.0** |
| display formulas | **0.0** | **0.0** |
| HTML blocks | **0.0** | **0.0** |
| a quote's content: headings, lists, code | **0.0** | **0.0** |
| tables: every cell, the rows, the grid | **0.0** | **0.0** |
| definitions and the footnotes the note ends with | **0.0** | **0.0** |

Every construct is aligned to the pixel, across and down, however far down
the note it is — out of the caret's reach. Where the caret is, `live` shows
the source: a definition, a fence, the marks of the word the caret is in —
in a table's cell too, whose row stays on the grid.

## Done

| commit | what |
|---|---|
| `4143509` | The read view's bullets and checkboxes are painted by `live`'s own function (`item_marks.dart`), centred in the marker column on the item's first row; its numbers take `live`'s colour. |
| `09ec542` | A tight list's items touch, a blank line is one spacing (not three), and the spacing between blocks is 1 em. |
| `3c38d5c` | The text starts and wraps at the same place in both modes, with or without a note column (`noteTextInsets`). The read view kept the line numbers' room without drawing them, until 2026-09-24: an empty gutter down a page that is only read. It keeps none now, and with the numbers on the text moves by their width at a flip. |
| `72a392b` | A heading's hidden hashes no longer leave their space before the title in `live`; every line's text stands where a paragraph's first glyph would, half an ambient letter spacing in. |
| `c02ce9c` | A quote's bar is inside its indent in the read view, as in `live`. |
| `259bb3a` | **Bug:** `live` hid a code block's code — its content lines were tokens of the fence, and the fence is a marker. The content is now `TokenKind.codeBlock` and drawn. |
| `3d49b98` | Footnotes are drawn as prose (formulas typeset, emphasis stressed); the way back is the arrow alone, where a button's minimum height stood a blank row between footnotes. |
| `a51e52f` | **Bug:** a footnote or link definition with a formula or a wikilink in it was drawn, in pieces, in the note's body. |
| `6da307a` | Decision 1: a blank line is one of `live`'s rows in the read view, a block leaves no spacing of its own, and a rule is a row with the rule across its middle. |
| `be23473` | **Bug:** a line less than four spaces in, after an indented code block, was scanned as code and drawn in a box, in both modes. |
| `e55f6f8` | **Bug:** a row of `live` whose text is all hidden — a rule, a quote's empty line — was laid out as nothing: the rule stood at the top of its row and a quote's bar broke off at every empty line. |
| `a05639e` | Decision 2: a code block is `live`'s box in both modes, in monospace, the fences' rows its top and bottom padding. |
| `b7a4e47` | An indented code block's four columns are hidden in `live`, as the read view takes them off. |
| `063ab5a` | `live` colours code by its fence's language, the block highlighted whole or in the read view's own pieces (`LiveCodeColors`); the read view no longer paints the highlight theme's background band behind each row. |
| `518fa07` | **Bug:** a block measured at no height kept its estimate — a typeset formula's lines past its first stood a row of nothing apiece in `live`, and a definition left its rows empty in the read view. |
| `43e13c8` | A display formula has `live`'s half a spacing above and below it in the read view. |
| `cd97871` | `live` reads a quote's content again as blocks, as the read view does (`LiveQuoteContent`): a heading inside a quote at its size, a list's next lines under its item's text, a code block in its box. |
| `df4f5b9` | An HTML block is drawn in a code block's box in both modes, a row per line. |
| `65919a1` | `live` hides a block of nothing but definitions while the caret is not in it, and ends the note with the read view's footnotes (`footnoteSliver`, shared); a tap on a footnote puts the caret in its definition. A link definition has no footnote to tap: it is reached with the caret, or in `source`. |
| `78af1366` | The read view's table is as wide as its columns, where it spread what they left of the pane evenly across them. |
| `061458e` | `live` draws a table as the read view's grid over its own source: the pipes and the spaces round each cell drawn as room that puts the next cell on its column (`LiveTables`), a cell's padding round each row, the delimiter row taking no room, the grid painted behind (`LiveTableGridPainter`). The caret's row is drawn as written. It is what #261's editing builds on. |

## Decisions (2026-09-23)

### 1. A blank line is 1.5 em, in both modes — done (`6da307a`)

To align vertically the two modes need the same rows. In `live` a blank line
is a text row, 1.5 em; the read view gave it 1 em. **Decided: 1.5 em in
both** — the read view draws a blank line as one of `live`'s rows, and a
block leaves no spacing of its own under it: the space between two
paragraphs is the blank line the note has between them, as tall as `live`
draws it. The 1 em spacing of `09ec542` goes with it.

Headings went with it: neither mode leaves a spacing under a heading now,
and none above it. Room above a heading is **not added**: the Markdown
linter (#72) will ask for a blank line before a heading, and that blank
line is the room, the same in both modes.

### 2. A code block is a box, in both modes — done (`a05639e`)

The read view draws a filled box with an inner padding; `live` drew the code
as plain rows, its fences hidden. **Decided: the box in both.** In `live` a
background and an inset behind the block's rows, the fence rows becoming the
box's top and bottom padding; in the read view the same geometry, so the
code's rows land on `live`'s. `live` now sets the code in monospace, as the
read view does, so a line of code wraps at the same place in both.

### Still to align after these

Nothing, out of the caret's reach. What is left is by design: the caret's
line shows its structural marks in `live`, and the word the caret is in its
inline ones. A table is the exception, as in Obsidian: its row stays on the
grid under the caret — only the word's marks show, widening the cell while
they do — the delimiter row never shows, and the caret moves from cell to
cell, never onto the room between them (`LiveTables.cellColumn`).

### Found on the way: a layout loop on one note — fixed

`read_view_geometry_test` sweeps the fixtures and, when it is on the
machine, `Geometria 1.md` (one person's note, not in the repository). It
threw *RenderViewport exceeded its maximum number of layout cycles* on that
note since `3d49b98` (footnotes drawn as prose).

The diagnosis written here before was wrong: the note alone scrolls to its
end cleanly. The loop was the **hand-over from one text to the next**: the
test pumps the fixtures one after another into the same read view, and the
geometry note arrived while the pane stood 138 000 px down the 200 KB
fixture. The footnote `SliverList` kept the previous text's children, laid
out at that text's end; inserting the new footnotes above them — taller,
with formulas — asked the viewport for a scroll correction on every pass,
and each correction moved the blocks the pane measured, so no pass agreed.
The app hands the read pane a new buffer at every flip from the editor, so
the same shape was reachable there.

The footnote sliver is now keyed by the text it was read from, so a new
text starts it afresh. `markdown_read_view_test.dart` holds it with a
synthetic pair of notes, in CI; the geometry note's sweep is clean again,
which also let its gate see a check it had never run on that note: a
formula wider than the pane was counted as neither broken nor shrunk,
because the gate read the size the view was *asked* for, not the one it
painted. It reads the painters now.

## Opening the 246 MB note

### Where it stood

The device log (beta) showed about 5 s with the window frozen after the text
had arrived. A CPU profile of a profile build found three passes over the
whole note on the UI isolate:

1. **A bug in the word count.** `buildWords` counted the note in an isolate,
   dropped the answer and counted it again on the UI isolate. Fixed in
   `2f2519b`.
2. **Normalizing the line endings** (two `replaceAll` over the text) and
   **splitting it into 2.76 M lines** (`SourceBuffer.fromText`).
3. **Copying the buffer** to the word count's isolate: sending an object
   graph copies it, on the isolate that sends it.

`138d3ad` reads, normalizes, splits and counts the note in one isolate
(`loadNote`) and hands the result over with `Isolate.exit`, which does not
copy it: the longest frame went from 8 326 ms to 413 ms (profile build),
the load 4.3 s off the UI isolate.

### What was done after

| commit | what | before | after |
|---|---|---|---|
| `b47e8d3` | Prefix sums keep their values in `Float64List`s, filled from a function (`PrefixSums.generate`): the height map and the buffer's index were a boxed double per row | height map over 2.76 M rows 218 ms (JIT); a million rows 72 ms | 31 ms; a million rows 10 ms |
| `6b0dd63` | A note's lines are **views** of the text it was read from — the string and where each line starts (`LineChunk`) — until a chunk is written to; `lineLengthAt` answers a length without cutting the line out, and `live`'s height map reads lengths | `fromText` 802 ms (JIT), 2.76 M strings for the garbage collector | 198 ms, ~2 700 chunks |
| `954afde` | The load no longer counts the words: the note is shown when it is read, and the surface counts it in the background | ~1 s of the open (1.0–1.3 s JIT) | 0: the count lands after the note |

The numbers are from `test/perf/huge_note_open_test.dart` and from runs on
the real note under `flutter test` (JIT); the app's AOT is faster. What the
first frame of `live` still spends on the note is the height map over its
rows (85 ms cold, JIT) and the colours' hand-over to their isolate (23 ms —
a `String` is not copied between the isolates of one group, measured: 250 MB
in 0 ms, so only the view's bound and index arrays are). The decode stays
(~700 ms, off the UI isolate): the text has to be a `String` to be drawn.

## Formulas with paths on the desktop (2026-09-24)

KaTeX draws a stretched delimiter, a root sign, a brace or an enclosure's
strokes as a path, and Impeller on the Linux desktop fills a path without
antialiasing when its surface has no multisampling. Measured on the engine
(an integration probe under `-d linux`): a matrix's parentheses had only
black and white pixels on their edges, while the glyphs beside them, which
come from the font's atlas, were smooth.

`preview/math_raster.dart` draws such a formula — and only such a one —
at four times the screen's resolution, halves the image twice (a box
filter over sixteen samples a pixel) and keeps it, one image per formula,
size, colour and screen, the 128 last drawn. The image is drawn with no
filtering: it has the screen's resolution already, so each pixel takes one
of its pixels, and a formula on a fraction of a pixel lands at most half a
pixel off rather than blurred. All three places a formula is painted go
through it (`paintMath`): a display formula, an inline one in the read
view's text, an inline one in `live`.

**Open doubt:** it is on for Linux and Windows. Linux is measured; Windows
is assumed, from the same renderer family, and not verified — if Windows
turns out to smooth paths itself, `MathRaster.enabled` should drop it,
since the image costs a little sharpness a smooth renderer does not need
to pay. Android's Vulkan surface is multisampled and is left out.

## Tables edited as tables (#261, 2026-09-24)

`markdown/table/` reads a table's lines into cells, alignments and how it
was written (`MarkdownTable`) and writes them back; `TableEdits` are the
menu's edits on it, each a table and the cell the caret goes to. In `live`
`LiveTableCommands` runs one over the caret's table and writes the table's
lines back in one replacement — one undo step — and builds the menu's
table part; `LiveTableHandles` are the two `+`, drawn in an overlay so they
take no room and the page stays the read view's.

Decisions taken without the writer, to revisit if they read wrong:

- **The submenus open beside the menu** on the desktop, as the mouse comes
  onto their row (2026-09-24): the menu is drawn on the overlay itself
  (`ContextMenuFlyout`), not as a selection toolbar, so a flyout has a place
  to stand. It used to open in the menu's place, a back row on top. On a
  phone Row and Column open a sheet.
- **Padded** means the writer padded: a cell with more than one space
  either side of its text, or a delimiter cell of more than three dashes.
  Not whether the pipes line up — a padded table one cell of which has
  grown since is re-padded whole, and a table of one-letter cells lines
  up by chance. A padded table is rewritten with each column as wide as
  its widest cell, three at least (a delimiter cell's minimum); an
  unpadded one keeps a space round each cell or none (`|a|b|`) as its
  rows had it, the delimiter row's own way apart, and each column's own
  dashes until its alignment changes. A padded right- or centre-aligned
  column pads on that side.
- **Tab** in a table goes to the next cell, Shift+Tab to the one before,
  the cell's text selected so typing replaces it; Tab past the last cell
  adds a row. Outside a table, and in `source`, Tab indents as before.
- **Sorting** compares two numbers as numbers (a decimal comma read as a
  point), anything else as text ignoring case; it is stable, and the
  header is never sorted.
- **The caret** goes to the new row's or column's cell after an add, with
  the moved cell after a move, to the nearest cell after a delete, and
  stays after a sort or an alignment.
- **Alignment is drawn**: the read view sets a cell's text by its
  column's alignment, and `live` gives the room before it (`LiveTables`);
  `read_live_page_test` holds the two to the pixel. It was not drawn at
  all before, which the menu's Align would have made plain.
- **Not done**: a size picker for an inserted table (#262 has two
  columns and one row; the `+` and Tab add the rest).


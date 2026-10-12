# Note columns — the screens, and the decisions

These are the mockups #729 was agreed against (2026-10-12), before any
code: seven desktop screens and three phone screens, in `html/`. They show
two or more columns of blocks on one row, written as Pandoc's fenced divs.
They are drawn to look like Niman, in the Night palette of
`lib/src/ui/theme/niman.dart`. Where a mockup and the app disagree, the
app is what ships. The engine design behind them is the record
[note-columns.md](../../records/note-columns.md).

| Screen | Desktop | Phone |
|---|---|---|
| The read view: a picture and a facts table in a 40 % column beside prose and a callout; then the note full width; then three columns wrapping two and one; stacked in source order on a phone | [Desktop-1-Read](html/Desktop-1-Read.html) | [Phone-1-Read](html/Phone-1-Read.html) |
| `live` with the caret in a column, editing side by side: a selection inside the column, the fences as thin markers; stacked on a phone, with Columns on the keyboard's toolbar | [Desktop-2-LiveCaret](html/Desktop-2-LiveCaret.html) | [Phone-2-Live](html/Phone-2-Live.html) |
| `live` with the caret on a fence line: its source shown dimmed, so the width can be edited | [Desktop-3-LiveFence](html/Desktop-3-LiveFence.html) | — |
| A selection from the left column into the right, in source order, and what Copy puts on the clipboard | [Desktop-4-SelectionAcross](html/Desktop-4-SelectionAcross.html) | — |
| `source`: stacked, every line numbered, the fences coloured, a fold arrow on the `::::` opener, the Insert columns template just written | [Desktop-5-Source](html/Desktop-5-Source.html) | — |
| Exported: the HTML page and an A4 PDF page | [Desktop-6-Export](html/Desktop-6-Export.html) | — |
| The Insert columns command: the palette, the toolbar button, the context menu's Insert › Columns | [Desktop-7-Insert](html/Desktop-7-Insert.html) | in [Phone-2-Live](html/Phone-2-Live.html) |
| Columns inside a callout, stacked | — | [Phone-3-Nested](html/Phone-3-Nested.html) |

## Decided with them

- **Pandoc's and Quarto's fenced divs**: `:::: columns`, then
  `::: {.column width="40%"}` or `::: column`, and `:::` closers. They
  are the only syntax with real renderers elsewhere. An opener is three
  colons or more and a class; trailing colons are optional. A closer
  closes the innermost div, as in Pandoc. Insert writes the outer fence
  longer, so djot and commonmark-hs close it in the same place. Only
  `columns` and `column` are read, and any other `::: foo` stays text.
  Content inside `columns` but outside any `column` is a column of its
  own. The syntax is gated behind `LineRules.appSyntax`. Fences are never
  rewritten: Markdown comes back byte for byte.
- **An unclosed opener runs to the end of the note**, like a code fence.
  This is the behaviour a writer already knows from fences.
- **An opener needs a blank line, or a block start, before it; a closer
  may end a paragraph.** Pandoc asks for the blank line, and a `:::` line
  inside prose should stay prose.
- **Any number of columns.** `width="%"` is honoured and the rest share
  equally. Each column is at least 16 em wide; columns that do not fit
  wrap, by the flex-wrap rule, in the app and in the exported CSS alike.
  A phone stacks them. The rule reads the width the block has, never the
  device type, so one rule covers a phone, a narrow window and a wide
  tablet.
- **Nesting, completely.** Columns are read wherever blocks are: at the
  top level, inside callouts, quotes, list items and columns. Only the
  outermost `columns` level sits side by side; deeper levels stack. Every
  context is tested.
- **Source order on a phone**, with no syntax to reorder the columns.
  Reordering would need a second syntax, and no other renderer has one.
- **A footnote definition inside a column goes to the note's end**, as
  everywhere.
- **`live` is the complete solution: side by side and editable.** It
  ships in one PR, with a commit per step. The source of a two-column page
  shown stacked while it is edited is the page changing under the writer,
  which `docs/records/read-live-parity.md` exists to prevent. The record
  designs the engine: one sliver per column, the caret and hit testing per
  column, motion in source order, IME, undo, find, folds and the height
  map. `source` stays line by line, stacked.
- **No widening past the note column.** The columns live inside
  `noteColumnWidth`, as every other block does.
- **One syntax, no alias.** There is no Obsidian `> [!multi-column]`
  form: two ways to write one thing would be two things to keep in step.

### Decided while drawing them, for the owner to confirm

- **Fence lines are 0.5 em bands, in both modes.** A column's opener is
  the room above its first block, and the outer fences are the block's
  margins. The bands take the same room in both modes, so a flip moves
  nothing.
  - With the caret in the block, each column's opener draws a hairline
    and a chip naming the column (`column · 40%`). The outer opener draws
    a chip at the left (`columns`), and the closers draw nothing.
  - With the caret on a fence line, that line shows its source, as any
    revealed mark does.
  - A fence is reached by a click or a tap on its band, by Home at the
    start of a column's first line, by a find match in it, or in
    `source`. Arrows do not stop on hidden fences: Right at a column's
    last character goes to the next column's first.
- **Line numbers in `live`.** The gutter numbers the outer opener and the
  outer closer, and a bracket between them spans the block. The lines of
  side-by-side columns are not numbered there, because there is one
  gutter and several columns. `source` numbers every line.
- **The export's CSS shares by `flex-grow` over a zero basis**, with
  `min-width: min(16em, 100%)`. It replaces the issue's
  `flex-basis: 40%` with `flex: 1 1 16em`, which lets a 40 % column grow
  past 40 %. With the new form a column gets exactly its share of the
  width after the gaps, and still wraps at 16 em.
- **Stacked columns are separated by the gap alone** (1.5 em), which is
  the flex-wrap rule's own row gap. A rule drawn between them would have
  no CSS counterpart in the export.
- **Insert columns** is a toolbar button (*Columns*,
  `view_column_outlined`, after Table), a context-menu entry
  (Insert › Columns), a palette command (*Insert columns*, no shortcut),
  and an entry in the phone's Insert sheet.

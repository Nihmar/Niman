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
| fenced code, its box | **0.0** | **0.0** |
| indented code | its four spaces: `live` shows them | **0.0** |
| table | −0.7 | `live` draws tables as source (#261) |

Everything but tables and indented code is aligned to the pixel, across and
down, however far down the note it is.

## Done

| commit | what |
|---|---|
| `4143509` | The read view's bullets and checkboxes are painted by `live`'s own function (`item_marks.dart`), centred in the marker column on the item's first row; its numbers take `live`'s colour. |
| `09ec542` | A tight list's items touch, a blank line is one spacing (not three), and the spacing between blocks is 1 em. |
| `3c38d5c` | The text starts and wraps at the same place in both modes, with or without line numbers and a note column (`noteTextInsets`): the read view keeps the numbers' room without drawing them. |
| `72a392b` | A heading's hidden hashes no longer leave their space before the title in `live`; every line's text stands where a paragraph's first glyph would, half an ambient letter spacing in. |
| `c02ce9c` | A quote's bar is inside its indent in the read view, as in `live`. |
| `259bb3a` | **Bug:** `live` hid a code block's code — its content lines were tokens of the fence, and the fence is a marker. The content is now `TokenKind.codeBlock` and drawn. |
| `3d49b98` | Footnotes are drawn as prose (formulas typeset, emphasis stressed); the way back is the arrow alone, where a button's minimum height stood a blank row between footnotes. |
| `a51e52f` | **Bug:** a footnote or link definition with a formula or a wikilink in it was drawn, in pieces, in the note's body. |
| `6da307a` | Decision 1: a blank line is one of `live`'s rows in the read view, a block leaves no spacing of its own, and a rule is a row with the rule across its middle. |
| `be23473` | **Bug:** a line less than four spaces in, after an indented code block, was scanned as code and drawn in a box, in both modes. |
| `e55f6f8` | **Bug:** a row of `live` whose text is all hidden — a rule, a quote's empty line — was laid out as nothing: the rule stood at the top of its row and a quote's bar broke off at every empty line. |
| `a05639e` | Decision 2: a code block is `live`'s box in both modes, in monospace, the fences' rows its top and bottom padding. |

## Decisions (2026-09-23)

### 1. A blank line is 1.5 em, in both modes — done (`6da307a`)

To align vertically the two modes need the same rows. In `live` a blank line
is a text row, 1.5 em; the read view gave it 1 em. **Decided: 1.5 em in
both** — the read view draws a blank line as one of `live`'s rows, and a
block leaves no spacing of its own under it: the space between two
paragraphs is the blank line the note has between them, as tall as `live`
draws it. The 1 em spacing of `09ec542` goes with it.

Headings went with it: neither mode leaves a spacing under a heading now,
and none above it. Still a proposal, to confirm: some room above a heading,
the same in both modes.

### 2. A code block is a box, in both modes — done (`a05639e`)

The read view draws a filled box with an inner padding; `live` drew the code
as plain rows, its fences hidden. **Decided: the box in both.** In `live` a
background and an inset behind the block's rows, the fence rows becoming the
box's top and bottom padding; in the read view the same geometry, so the
code's rows land on `live`'s. `live` now sets the code in monospace, as the
read view does, so a line of code wraps at the same place in both.

### Still to align after these

- Tables: `live` has to draw them as tables first (#261).
- Display formulas: their margins in the two modes.
- A list inside a quote: its continuation lines in `live` stay on the
  quote's column rather than the item's — the scanner sees one quote block.
  A code block inside a quote is the same case: `live` draws its lines as
  the quote's, with no box.
- Indented code: the read view takes its four spaces off, `live` shows them
  — they are the line's own text, not a prefix it hides.
- The colours of code: the read view highlights by the fence's language,
  `live` draws code in one muted colour.
- An HTML block: a box with a padding all round in the read view, source in
  `live`.
- Footnote and link definitions: `live` draws them as their source, the read
  view as nothing — the blank lines around them are still rows, so the read
  view leaves a few empty rows where the definitions stand.

### Found on the way: a layout loop on one note

`read_view_geometry_test` sweeps the fixtures and, when it is on the
machine, `Geometria 1.md` (one person's note, not in the repository). On
that note, the jump to the very end has thrown *RenderViewport exceeded its
maximum number of layout cycles* since `3d49b98` (footnotes drawn as prose),
before this round's changes: bisected. The fixtures in the repository are
clean, and CI does not have the note.

What the trace shows: the blocks sliver is laid out once, the footnotes'
`SliverList` asks for no scroll correction, and the viewport goes round
again nineteen times without laying either out — a position adjusted by
less than a double can tell at 266 800 px, so no sliver's constraints
change. Not fixed yet; the next step is to log the position's
`applyContentDimensions` in that frame.

## Opening the 246 MB note

### Where it stands

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
copy it. Measured again on the profile build:

| | before | after |
|---|---|---|
| load, off the UI isolate | — | 4.3 s, the window responsive |
| longest frame | 8 326 ms | 413 ms |
| first frame after the load | — | 11 ms |

The load's phases, measured on the real note (JIT, so slower than the
app's AOT):

| phase | ms |
|---|---|
| read from disk | 70–210 |
| UTF-8 decode | 640–780 |
| line-ending normalization | ~100 |
| split into lines | ~950 |
| word count | ~1 100 |

### What can still be done

1. **The 413 ms frame** is the height map, built for all 2.76 M rows during
   the first build. It can be made in the loading isolate, or built a chunk
   at a time: the frame goes.
2. **About −1 s**: show the note before its word count is done; the count
   lands a moment later.
3. **The decode and the split** would need a different buffer: lines as
   offsets into one string rather than 2.76 M strings of their own. A larger
   piece of work, which would also cut the memory and the garbage collector's
   time — the native time the profile still shows. Worth an issue of its own.

The recommendation is 1 and 2 now, and 3 as an issue.

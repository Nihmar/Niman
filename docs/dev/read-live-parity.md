# Read and live: one page (2026-09-23)

The read view and `live` are meant to be the same page, one of them
editable. A glyph that moves when the pane flips is the page changing under
the reader. This file records where the two stand, what was done to bring
them together, the decisions still open, and where opening the 246 MB stress
note stands.

The alignments are held by `test/widget/read_live_page_test.dart`: each one
compares where a construct's first glyph lands in both modes, so they cannot
drift apart again unnoticed.

## Where the constructs stand

Measured with the platform font (Segoe UI), a 520 px pane, no line numbers,
no column: the first glyph of each construct, read view minus `live`.

| construct | dx | dy |
|---|---|---|
| headings, paragraphs, lists, task lists, quotes | **0.0** | owed — see below |
| fenced code | +8.4 | owed |
| table | −0.7 | `live` draws tables as source (#261) |

Horizontally everything but code and tables is aligned to the pixel.
Vertically the two differ by the rows each mode gives a blank line and the
space around headings, which is a decision rather than a fix (below).

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

## Decisions open

### 1. How tall a blank line is

To align vertically the two modes need the same rows. In `live` a blank line
is a text row, 1.5 em; the read view gives it 1 em, as asked on 2026-09-23.

- **A.** Blank rows in `live` are 1 em too: the spacing chosen stays, and the
  one visible effect is a shorter caret on an empty line.
- **B.** 1.5 em in both, as `live` is today.

Headings go with it: the read view left 1 em under a heading, `live` leaves
nothing. The proposal is the same room above a heading in both modes.

### 2. What a code block looks like

The read view draws a filled box with an inner padding; `live` draws the
code as plain rows, its fences hidden. The proposal is the box in both: in
`live` a background and an inset behind the block's rows, the fence rows
becoming the box's top and bottom padding.

### Still to align after these

- Tables: `live` has to draw them as tables first (#261).
- Display formulas: their margins in the two modes.
- A list inside a quote: its continuation lines in `live` stay on the
  quote's column rather than the item's — the scanner sees one quote block.

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

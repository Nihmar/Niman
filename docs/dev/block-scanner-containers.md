# Block scanner: containers as CommonMark reads them (work in progress)

Branch `fix/block-scanner-containers`, based on `f2efd5bc` (which itself sits
on `main` at `72d15445`). The goal: `lib/src/markdown/block_scanner.dart`
decides list items and quotes line by line as CommonMark does, proved by a
differential test against `package:markdown`.

## Method

`test/unit/block_scanner_commonmark_test.dart`, skipped unless asked for,
like the `NIMAN_PERF` perf tests:
`NIMAN_SCANNER_DIFF=1 flutter test test/unit/block_scanner_commonmark_test.dart`.
A report for now (it prints, never fails); once the causes below are fixed
it should assert no differences. It:

- generates 40 000 small documents (seed via `--dart-define=SEED=n`) from
  realistic lines: blank, text, `- `, `* `, `1. `, `2) `, `> `, `> - `,
  `# `, a fence, `---`, at indents 0/2/3/4/6; a first line of `---` is
  skipped (Niman front matter, not CommonMark);
- every content line carries a unique word (`w17`), found again in the
  reference's tree: leaf kind (text / code / heading), list items around it,
  quotes around it;
- **a quote is one block to the scanner** — the read view strips the `>`
  and scans the inside again with a new `BlockScanner`
  (`BlockView._quoteContent`) — so inside a quote only the quote count and
  the items *outside* the quote are compared;
- each differing document is shrunk (drop lines while it still differs)
  and the minimal repros are printed, shortest first.

`package:markdown` is not 100 % CommonMark (laziness especially): check a
doubtful repro against the spec before fixing the scanner for it.

## State

| Step | Documents differing / 40 000 | Minimal repros |
|---|---|---|
| before `f2efd5bc` | 24 600 (old mapping) | 1 113 |
| `f2efd5bc` (merged from the background task) | 20 453 | 1 106 |
| `ae23fb49` — an item goes on with paragraph text only | 15 897 | 724 |
| causes 1-4 (`66598421`) | 1 896 | 1 164 |
| cause 5 + indented code from the content column (`de0922be`) | 1 425 | 932 |
| quote absorbs one indented continuation (`d4b6c333`) | 942 | 614 |
| quotes, lazy items and rules from the item's column (`327ada12`) | 368 | 194 |
| item and fence close on the line that ends them (`01963d99`) | 309 | 138 |

`ae23fb49`: `_mergesInto(listItem)` took any non-blank line without a
marker, so `# Heading`, `> quote`, a fence or `---` under a list became the
item's words. It now takes `_kindOf(end) == paragraph` only. Unit suite
green, widget suite green (drop_open_test is the known Windows flake, passes
alone). Test: `block_scanner_test.dart`, "an item goes on with paragraph
text only".

The last step: a quote takes **one** indented (four spaces or more)
continuation of its paragraph; a second is not a lazy continuation any more
and opens an indented code block that ends the quote (`LineState.
quoteIndented`, `_quoteClosesToCode`). It also resolved the ordered-marker
regression the causes 1-4 introduced: a marker at or above the innermost
item's own marker column is a sibling or an ancestor, and breaks the
paragraph; the same rule now guards the rescan's convergence — see the open
item below.

## Causes resolved

1. **Indented code where a paragraph cannot be interrupted** — `openParagraph`
   is now set for *all* text (not only inside lists), and a second shared
   constant `LineState.paragraphOpen` carries the common prose line without a
   state apiece (#346).
2. **ATX heading indented 1-3 spaces** — `_headingLevel` takes the content
   column and counts the available indent from it.
3. **An ordered list not starting at 1, or an empty item, cannot interrupt a
   paragraph** — `_markerInterrupts` centralises the rule for `_kindOf` and
   the builder. A marker at or above the innermost item's own marker column
   is a sibling or an ancestor and always interrupts.
4. **Setext heading inside an item** — `_mergesInto(listItem)` accepts
   `_underlineLevel > 0` as it does for a `paragraph`.
5. **A line less indented than an item's content column closes the item and
   anything open in it** — a line that opens a new block (marker, heading,
   rule, quote) ends the item and the fence with it; plain text does not.
   Indented code inside an item is measured from the content column.
6. **Quote inside a deep item** and **a quote's one indented continuation** —
   `_quoteDepth` counts from the item's content column, and a quote takes one
   indented continuation of its paragraph; a second opens code and ends the
   quote (`LineState.quoteIndented`).
7. **Empty item followed by a blank line** — covered by the container rules
   above.

## Still open

- **The incremental rescan keeps a stale hint across a blank line** once
  `openParagraph` can turn a hint paragraph into an item. The fresh scan is
  correct; `blockAt` on a stopped-short rescan can still answer the old
  block. `block_scanner_test.dart`, "a rescan that stops short answers every
  line as a fresh scan would" is skipped with this reason, to be fixed with
  `openParagraph`-aware convergence (an `_isBlockBoundary`/`_convergesAt`
  check on the block the boundary line opens).
- **About 309 of 40 000 documents still differ** (138 minimal). All of them
  want containers measured as CommonMark does, from the line's own indent
  rather than from column 0, and the two pieces of that are one refactor:

  1. **Inside a quote, measure past the `>`.** A line `> - w` has its item
     *after* the marker: `_listMarker`, `_indentOf` and the item's content
     column all start at the wrong place today, so `> - w` / `    > w` (a
     quote in the item, two levels) and `> - w` / `  > w` (the item's text,
     one level) are not told apart. The fix is to pass the offset past the
     quotes (`_afterQuotes`) into the marker/indent readers — not only into
     `_listAfter`, which was tried and regressed the whole harness.
  2. **Indented code inside an item is measured from the item's marker,
     not its content column.** `  2) w` / `      ---` / `    w` has a setext
     heading in the item and then `    w` at four spaces from the margin,
     inside the item: code in the item, not a line outside it.

  Both need the indent reading changed in one place and threaded through
  `_contentColumn`, `_opensIndentedCode` and `_listAfter` together; a partial
  change moves the count by thousands, as measured. The remaining classes
  (26 text, 23 code, 25 quoted/heading, then a long tail) are these two.

Full list of minimal repros: rerun the harness (≈40 s) — sort order is
shortest first.

## Downstream to check before merging

`BlockParser.contentText` strips the indent only for `listItem` blocks and
quotes. A paragraph, heading or fence *inside* a deep item (4+ spaces in,
`listDepth >= 1`) is handed to `package:markdown` with its indent, which
reads 4+ spaces as indented code. The scanner now produces such blocks more
often (`f2efd5bc` and the fixes above): check the read view renders
`- A\n  - B\n\n    para of B` as a paragraph, and strip the item's content
column for every block in a list, not only items.

Also restore, once the scanner reads them, the tests the #530 work had to
avoid: `test/unit/list_to_mindmap_test.dart` (nested paragraph after a
sublist, fence in a nested item) and an export test for a Mermaid fence
four spaces into a list item (`test/unit/note_html_test.dart`).

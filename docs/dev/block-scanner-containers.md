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

## Review (2026-10-05): what blocks the merge

A review of the branch at `2786f53b` found the method sound and the
numbers real, and five things that keep it off `main`, each measured:

1. **A unit test is red.** `word_count_index_test.dart`, "a scan of a note
   reads the same headings the text does": cause 2 makes the scanner read
   `   # x` as a heading, and the text outline (`outlineOfText`, the
   tokenizer's `forEachHeading`) does not.
2. **`headingLevelOf` changed its contract.** It now skips up to three
   spaces but still returns only the `#` count, and its callers take that
   count as an offset from the line start: `source_styler.dart` marks the
   spaces as the heading marker on `  ## x`, and `outlineOfBlocks` cuts the
   heading's text at the wrong place.
3. **The rescan test was skipped on a wrong diagnosis.** The smallest
   failing case is `- item` / `  ---`, with the second line then replaced
   by an empty one: the rescan answers `paragraph`, a fresh scan
   `listItem`. Cause 4 lets a setext underline head an item's text, and the
   builder follows it, but the three rescan helpers do not: `_reopened`
   turns any cut heading back into a `paragraph`, `_headed` drops the
   item's ordinal, and `_convergesAt` takes a setext heading only from an
   open `paragraph`. `openParagraph` has nothing to do with it.
4. **A list scans twice as slowly.** `test/perf/list_count_check_test.dart`,
   100 000 lines: 86 ms before the branch, 188 ms on it (two runs each).
   `_listAfter` classifies the line again (`_kindOf(line)`) that its caller
   has just classified.
5. **Decisions read more than the state.** `_listAfter` and
   `_fenceClosesItem` read `_text(line - 1)`, and `_listAfter` asks
   `_kindOf(line)` — the state the line *entered* in — even when its caller
   passed another (`_exitOfFrom(line, LineState.initial)`). The rescan
   relies on "same state + same text = same blocks"; a decision that reads
   anything else breaks it. The marker-interrupts rule is written twice
   (`_kindOf`, `_listAfter`), and `_kindOutsideFence` is a partial copy of
   `_kindOf` that does not know fences.

Also: `block_scanner.dart` went from 1 354 lines to 1 763, and
`task_cascade_test.dart` records a user-visible change (`> - [ ] b` /
`  - [ ] child` no longer ticks the child with `b`) that belongs in the
changelog.

## Plan

Each phase is gated: the unit suite, the harness count (it must not rise),
and, from phase 1 on, the rescan test unskipped.

1. **The blockers, on the current code** — independent of the rewrite.
   - *Rescan:* `_reopened`, `_headed` and `_convergesAt` learn that a
     setext heading can be an item's first paragraph, and keep its ordinal.
     Unskip "a rescan that stops short"; search again for the smallest
     failing edit sequence in case another class hides behind this one.
   - *Indented ATX headings:* one rule in the three readers (the scanner,
     `HighlightDocument.forEachHeading`, the styler). `headingLevelOf`
     answers where the `#`s start as well as how many; `source_styler` and
     `outlineOfBlocks` read from there. Gate: `word_count_index_test`.
   - *State and speed together:* the line's kind is decided once and handed
     to `_listAfter`; whether the line before was blank lives in
     `LineState` instead of being read back; the interrupt rule is one
     function. Gate: the 100 000-line list back near 86 ms.
2. **Split the file, no behaviour change.** The pure line readers (marker,
   heading, fence, HTML, quote, rule, setext) to `line_syntax.dart`; the
   scan and the rescan stay; the builder to its own file. Gate: harness at
   exactly the count it had, suite unchanged.
3. **The indentation model** (`docs/dev/block-scanner-indent-model.md`),
   with one change to its design: not `quoteDepth` and `listStack` side by
   side plus quote columns — that cannot hold an item in a quote in an item
   — but **one ordered stack of containers** (quote or item), each column
   kept *relative to its parent's content*. One walk consumes the open
   containers, then opens new ones, as CommonMark's algorithm does;
   `listStack`, `quoteDepth` and `listIndent` become getters derived from
   the stack, so their readers do not change. Gates: the fifteen pinned
   cases, the harness falling at every step (a step that raises it is
   reverted whole), the rescan test, the perf file.
4. **The harness becomes a gate.** A short run (≈2 000 documents) in the
   default suite that fails, with an explicit list of `package:markdown`
   quirks it tolerates; the 40 000 stay behind `NIMAN_SCANNER_DIFF`. New
   forms: tabs, `+`, `10.`, `===`, `$$`, HTML, tables. And an incremental
   variant — edit sequences against a fresh scan, shrunk the same way — which
   is what found item 3 above in seconds.
5. **Downstream and merge.** `BlockParser.contentText` strips the item's
   content column from every block in a list (below) — `- a` / `` /
   `     # deep` is a heading block to the scanner and indented code to the
   parse, which styles ` d` as inline code; restore the tests the
   #530 work avoided, which live on that branch — so #530 lands first and
   this branch is rebased on `main` after it; the changelog notes the task
   cascade change.

## Still open

- **The remaining repros need the indentation model**, not another fix to
  the current one: see `docs/dev/block-scanner-indent-model.md` for the
  evidence, the model, the fifteen pinning cases and the method. Both
  incremental attempts to move the indent reading regressed the harness by
  thousands, so it is a rewrite of `_contentColumn`/`_indentOf`/`_listMarker`
  together, not a patch.
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

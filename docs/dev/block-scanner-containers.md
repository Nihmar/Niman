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
| *the harness reads quotes as the app does (`c3d56535`), same scanner* | *1 684* | *212* |
| a block in an item read past the item's column (`2ab50765`) | 285 | 224 |
| the container walk (phase 3) | 0 | 0 |
| *GFM, wider forms, tabs (phase 4), same seeds* | *0 (seeds 1-4); 1 (seed 5)* | *0; 1* |

The rows in italics and below are the second harness — the scanner read
through the app's own quote pipeline, words compared by their full path
of items and quotes — and do not compare with the rows above it.

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
5. **Structure.** The marker-interrupts rule is written twice (`_kindOf`,
   `_listAfter`), and `_kindOutsideFence` is a partial copy of `_kindOf`
   that does not know fences. `_listAfter` asks `_kindOf(line)` — the
   state the line *entered* in — even when its caller passed another
   (`_exitOfFrom(line, LineState.initial)`).

   The review also took `_listAfter` and `_fenceClosesItem` reading
   `_text(line - 1)` for a break of the rescan's "same state + same text =
   same blocks". It is not one: the rescan is built for one line of
   lookback (`settledFrom` never converges on the line after the edit), and
   "the rescan reads one line back, and keeps what that line decides"
   (`block_scanner_test.dart`) now pins it. Two lines back would break it.

Also: `block_scanner.dart` went from 1 354 lines to 1 763, and
`task_cascade_test.dart` records a user-visible change (`> - [ ] b` /
`  - [ ] child` no longer ticks the child with `b`) that belongs in the
changelog.

## Plan

Each phase is gated: the unit suite, the harness count (it must not rise),
and, from phase 1 on, the rescan test unskipped.

1. **The blockers, on the current code** — done.
   - *Rescan* (`79dcb128`): a cut setext heading is read again from its
     first line, so an item that loses its underline is an item again;
     convergence takes a setext heading from an open item. "A rescan that
     stops short" runs again, and a search of 240 000 random edit sequences
     (items, nested items, quotes in items, fences, tables, HTML) found no
     other class.
   - *Indented ATX headings* (`96bdbbc1`): `BlockScanner.headingMarkerOf`
     answers where the `#`s start and how many; the styler and the block
     outline read from there, and the tokenizer takes up to three spaces.
     `word_count_index_test` is green.
   - *Speed* (`c2dc98c9`): the line on the scan is classified once, the
     rule expression runs only on a line that could be a rule, and a run
     of lines in one construct shares one state. The 100 000-line list:
     188 → 132 ms, against 86 before the rework. The rest is the lazy run
     the fixture is made of (an item, then 60 000 lines without a blank):
     it used to close the item on its first lazy line and go on as plain
     prose, and now keeps the item open, as CommonMark does. Per 100 000
     lines, before the rework → now: prose 54 → 45 ms, items 145 → 164,
     nested items 199 → 232, a lazy run 24 → 64.
   - *One interrupt rule* (`485f03dd`): one function, read by both places;
     two of its five conditions were dead. Harness unchanged at 309 / 138
     through all of phase 1.
2. **Split the file, no behaviour change** — done (`841c2a09`…`3c4f5273`,
   five commits, each at 309 / 138 with the scanner's tests green; the
   100 000-line list scans in the time it did). `block_scanner.dart` was
   1 837 lines; it is now six files under `lib/src/markdown/`:

   | File | What it holds |
   |---|---|
   | `block_scanner.dart` | the index: rescan, frontiers, convergence |
   | `line_rules.dart` (`LineRules`) | what a line is, the state it leaves, the items it stays in |
   | `block_rules.dart` (`BlockRules`) | the block a line starts, whether it goes on with the open one, setext, ordinals |
   | `line_containers.dart` (`LineContainers`) | a line against the open items and quotes — **what phase 3 rewrites** |
   | `line_syntax.dart` (`LineSyntax`), `html_block_syntax.dart` | what a line says on its own text |
   | `block_builder.dart` (`BlockBuilder`) | blocks built line by line; `Block.cutAt`/`cutFrom`/`headed` |

   The names this document and `block-scanner-indent-model.md` use are
   the ones they had before the split: `_contentColumn`, `_markerReach`,
   `_quoteItems`, `_quoteDepthAfter`, `_isIndented` are now
   `LineContainers.*`; `_listMarker`, `_indentOf`, `_headingLevel`,
   `_fenceOpen`, `_quoteDepth` are `LineSyntax.*`; `_kindOf`, `_exitOf`,
   `_listAfter`, `_fenceClosesItem` are `LineRules.*`; `_blockStarting`,
   `_mergesInto`, `_underlineLevel`, `_ordinalOf` are `BlockRules.*`.
3. **The indentation model** — done, by another design than either this
   plan or `block-scanner-indent-model.md` had. Three steps:

   - **The harness first** (`c3d56535`). It compared, for a word in a
     quote, every quote around it with the depth of the scanner's quote
     block; but a quote is one block by design, its inside scanned again
     by the read view and `live`, so `> a` / `> > b` counted as a fault.
     It now reads the scanner's side through that same pipeline —
     `BlockParser.contentText`, then a scan of the content, down to the
     blocks that are not quotes — and compares each word's leaf and full
     path of items and quotes (`LQL`) with `package:markdown`'s. The
     fifteen shapes moved into it, their answers computed by the
     reference: the two nested-quote ones passed at once (they were the
     harness's). Measured on the old scanner: 1 684 / 212.
   - **Phase 5's strip, brought forward** (`2ab50765`): a block in a list
     item is read past the item's indentation, quotes included. Most of
     the 1 684 were this — a quote four spaces into an item kept its `>`
     and its inside was read as code — and the harness could not tell
     the scanner's faults from these while they stood: 285 / 224 after it.
   - **The rewrite**: not CommonMark's container stack but the reading of
     the parser the read view draws with. `package:markdown` does not keep
     a stack: a list gathers each item's lines — a line at least the
     item's indent in, with that taken off, or a line short of it
     *lazily*, **as it stands** — and parses them again on their own; a
     quote does the same with its `>` off. So each container measures the
     line where its parent left it, and a lazy line is handed on
     undedented, which is what the six failed attempts kept colliding
     with: `  1. w` / `      - w` / `    * w` is three levels because
     `    * w` is lazy for the first item and reaches the second.

     `ContainerWalk` walks a line through the open items, outermost
     first, with each item's indent *relative* to its parent
     (`OpenItem.indent`) and the cumulative column a reader strips
     (`OpenItem.content`); it ends a list at a rule, a marker, a block
     that may interrupt or text after a blank line, and decides whether
     the open quote takes the line (by its `>`, or lazily by the quote's
     last line: `LineState.quoteLast`). What is left is read by
     `LineRules` in the innermost item's coordinates, as at a margin —
     no rule measures from the note's margin any more, and
     `LineContainers` is gone. Each line is read once (`LineRead`), and
     a block goes on only in the container it is in (`LineRead.carried`:
     a fence in an item ends with its list).

     And `BlockParser.itemPrefixLength` strips per line what the walk
     does — an item's indent off a line that reaches it, nothing off a
     lazy one — not a fixed column; `SourceStyler`'s parse cache keys on
     the items' indents, since the parsed text now depends on them.

   **Result: 0 of 40 000 documents differ**, on four seeds (1-4, 160 000
   documents); the fifteen shapes all pass, the rescan test is green.
   Scans got faster, from reading each line once: per 100 000 lines,
   before the branch → now, prose 54 → 21 ms, items 145 → 107, nested
   items 199 → 107, a lazy run 24 → 25; the list fixture 86 → 85.
4. **The harness becomes a gate** — done. The reference now parses with
   `ExtensionSet.gitHubFlavored`, the read view's set, and each block is
   read the way the view draws it: its `contentText` parsed by the
   package (`60a907b6`). New forms: `+`, `10.`, empty items, a container
   right after a marker (`- > q`, `- - a`, a fence), `* * *`, `===`,
   tables, HTML, `>W`, and tab indents (one document in four). What they
   found, fixed:

   - *GFM's blocks* (`22ec68f9`): `* * *` is a rule; HTML opens up to
     three spaces in; a line over a delimiter row is a table's head,
     tried before anything but a fence, ending a paragraph and denying
     an underline whether or not its cells fit; what follows a marker is
     read in the item it opens; a setext underline in an item keeps the
     block an item, headed.
   - *A block parsed in its container's coordinates* (`cce4bbfb`): the
     view hands the parser each block alone, and an item's continuation
     lines lost the column the parser, seeing the marker, took off again.
     The spaces they now keep are hidden in `live`.
   - *Tabs* (`53a34ae1`): four columns to the parser's patterns, an
     item's indent taken off with the parser's `dedent` — a tab whole once
     the indent is reached in it, its leftover columns counting toward
     the next item's.
   - *A table's head in its container* (`c31a652e`): the delimiter row
     has to stay in the head's items, which the line under it decides.
     The rescan starts a line back, two over a delimiter row, none over a
     blank line; a headed item converges only with its number.

   The gate: 2 000 documents, seed 1, in the default suite; 40 000 behind
   `NIMAN_SCANNER_DIFF=1`. Two of the package's quirks are left out of
   the comparison, counted: a lone `-` under a paragraph (its task-list
   syntax takes an empty item and drops the text before it, ≈3 800 per
   40 000) and `===` in a quote (no setext heading where a quote ends
   lazily, ≈1 700). Seeds 1-4: 0 / 40 000 each; seed 5: 1 (below).

   The incremental variant is `block_scanner_rescan_test.dart`: random
   edit sequences over the hard lines, each step against a fresh scan,
   the shortest case kept per kind — 4 000 sequences always, 240 000
   behind the same variable: none differ. It found the headed item's
   ordinal and the table head two lines up.

   Two fixes outside the scanner followed from its blocks: the formatter
   keeps a list's inner blocks in the list's unit, and the lint keeps
   the blank line after an item that holds one of its own (`00490154`).
5. **Downstream and merge** — done. The strip is done (above). #530
   landed (#542) and the branch is rebased on `main`; the tests the #530
   work left out are back (`cbb49c7f`: a fence in a nested item, a
   diagram four spaces into an item), both read right on `main` already
   since `f2efd5bc`. The task cascade change (`> - [ ] b` / `  - [ ] child`
   no longer ticks the child with `b`: the child is no item of the quote)
   is for the changelog of the release that ships it, which is written in
   the release commit.

## Still open

The harness compares the scanner with `package:markdown`, not with the
CommonMark spec's examples: it passes what it generates, the package's
quirks included. Known differences:

- **A table head nested in containers** whose delimiter row the walk
  reads otherwise — one document in 40 000 (seed 5):
  `+ w` / `  >w` / `      1. w` / `|---|---|` / `  |---|---|`.
- **A list mixing tabs and spaces** where a tab straddles an item's
  indent: the parser splits the tab into spaces, but `contentText` has
  to be a substring of the note, so the block keeps the whole tab.
- **A fence on a marker line** (`- ```js`): the scanner reads it, but
  the view renders the code as a block of its own after the item's, and
  its closing fence as code text.
- **The package's quirks**, left out of the harness and followed by the
  view: the lone `-` under a paragraph, `===` in a lazily ending quote.
- **GFM's footnote definitions and alerts** are not among the forms.
- **A quote that opens deeper than it goes on** (`> > a` / `>` / `> b`):
  the block keeps its first line's depth, so its content strips two
  levels where it has one.
- **The spec's own examples** have not been run against the scanner;
  they would reach forms the generator does not write.

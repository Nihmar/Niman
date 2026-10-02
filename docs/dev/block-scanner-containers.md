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

`ae23fb49`: `_mergesInto(listItem)` took any non-blank line without a
marker, so `# Heading`, `> quote`, a fence or `---` under a list became the
item's words. It now takes `_kindOf(end) == paragraph` only. Unit suite
green, widget suite green (drop_open_test is the known Windows flake, passes
alone). Test: `block_scanner_test.dart`, "an item goes on with paragraph
text only".

## Causes still open (minimal repros, `·` = space)

1. **Indented code where a paragraph cannot be interrupted is not the
   case**: `····w` at the start of a note, after a heading, a rule or a
   fence is code in CommonMark; `_opensIndentedCode` wants line > 0 and a
   blank line before. Needs an "open paragraph" flag in `LineState` for
   *all* text (today `openParagraph` exists only inside lists) — mind the
   shared `LineState.initial` memory optimisation (#346): a second shared
   constant for "plain, paragraph open".
2. **ATX heading indented 1–3 spaces** (`··#·w`) is read as text:
   `_headingLevel` wants column 0. Inside items, count from the item's
   content column, as `_fenceOpen` now does.
3. **An ordered list not starting at 1, or an empty item, cannot interrupt
   a paragraph**: `w\n2)·w` is one paragraph. Same "open paragraph" flag.
4. **Setext heading inside an item**: `-·w\n··---` is an `h2` in the item;
   the scanner gives the item text. The item's block is `listItem`, which
   cannot be a heading today — decide how a setext underline under an
   item's first paragraph is modelled.
5. **A line less indented than an item's content column closes the item
   and anything open in it** (fence, indented code): `*·w\n····```\n-·w`
   — the fence ends at `- w`. Today a fence runs to its own close.
6. **Quote inside a deep item** (`····>` under `··-·`): `_quoteDepth`
   allows 3 spaces from the margin only; count from the item's content
   column.
7. **Empty item followed by a blank line ends the item** (`-\n\n···>·w`):
   niche.

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

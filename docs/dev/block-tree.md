# One block tree: the scanner's structure, package:markdown for inlines only (work in progress)

Follows [block-scanner-containers.md](block-scanner-containers.md), whose
phases 1-4 made the scanner read containers as `package:markdown` does
(0 of 40 000 generated documents differ). That work cost what it cost
because the structure is decided **twice**: the scanner decides it to
find blocks, and `package:markdown` decides it again inside every block
it is handed — so the scanner had to agree with the package line by
line, quirks included, or the two readings drew different notes.

The aim: the scanner's reading is the only one. Every surface — read
view, live, export, index — takes its blocks from it, and the package
parses only the inline text of a leaf (a paragraph's, a heading's, a
cell's), with `md.InlineParser`.

## Where the package decides structure today

Measured on `e7df1296`:

1. **`BlockParser.parseText`** (`block_parser.dart:85`) runs
   `md.Document.parseLines` with every GFM block syntax on each scanner
   block: a heading's level comes from its `h1`…`h6`, an item's task box
   from the checkbox list syntax, a link reference or footnote definition
   from the package swallowing it (no runs, nothing drawn), setext from
   the package's underline. The block's text is handed over in its
   container's coordinates (`contentText`) so that this second reading
   agrees with the first; the runs are found back in the source by
   searching for each text node (`_Walk._text`, `_sourceFormOf`), and
   marked `approximate` when the search fails.
2. **A quote is read two ways.** The read view scans its inside again
   (`BlockView._quoteContent`, up to eight deep); live hands the whole
   quote to the package (`SourceStyler._parsedOf`).
3. **A table cell** gets a scanner and a parse of its own
   (`block_view.dart:569`).
4. **Export** (`NoteHtml._parsed`, `note_html.dart:118`) parses the
   whole note with the package, independently of the scanner, and
   `imageTargets` parses it again.

Outline, links, frontmatter and spell check read a third structure, the
legacy tokenizer (`editor/highlighting.dart`). It is out of this plan's
scope, noted in "Later".

## The model

**Top level stays flat.** `BlockIndex` keeps the scanner's blocks as
they are: incremental, virtualised by line, one block per visible unit.
What is new is what a block *is* below that:

- **Its path**: the containers around it — the items (from the state
  entering it) and the quotes. A surface that draws one block needs its
  path, not its siblings; the export, which needs siblings (where a list
  opens and closes, tight or loose), groups consecutive blocks by path.
- **Its subtree.** A container block — a quote, an item's own block —
  is read again in its own coordinates: the quote's marks off, or the
  item's marker blanked and its indent off, and the result scanned
  (`BlockScanner` over the content), recursively. That is what the read
  view does for quotes already; doing it for items too is what makes
  `- - a`, `- > q`, `- # h` and `- ```js` (the marker-line fence the
  containers plan could not draw) ordinary children instead of something
  the package has to work out. A plain item — marker and paragraph text,
  the common case — skips the scan.
- **Leaves**: paragraph, heading, fenced / indented code, math, HTML,
  table, rule, frontmatter, blank — and the two definitions the package
  swallows today, link reference and footnote, which become blocks of
  their own.

**A leaf's inline text has an exact source map.** For each line of the
leaf the scanner knows where its content starts (containers off,
heading marks off, an item's marker and task box off, a paragraph's
leading spaces off) and where it ends (closing `#`s, a setext underline
left out). The inline text is those segments joined by `\n`, and a
position in it maps back by segment: no searching, no `approximate`.

**Inlines**: `md.InlineParser(text, document).parse()` over the masked
leaf text (`ExtensionMasker`, as now), with the document seeded with the
note's link references and footnotes (`DocumentScope`, as now) and the
app's inline syntaxes. The walk from nodes to `StyleRun`s keeps its
offsets by construction instead of by search.

## Plan

Each phase is gated by the unit suite, the CommonMark harness at 0, the
rescan test, and `test/perf/list_count_check_test.dart`.

1. **The tree, beside the current path.** `BlockPath` and a builder that
   gives any scanner block its path and subtree, leaves with their
   segments; link reference and footnote definitions read by the
   scanner. Nothing draws from it yet. The harness compares it with the
   package's tree directly — leaf kind and container path of every word —
   instead of going through `contentText` and a parse.
2. **HTML from the tree.** A writer from the tree (containers, tight /
   loose lists, leaves through `md.InlineParser` and the package's
   renderer) — the oracle this plan has been missing: for a generated
   document it is compared **byte for byte** with
   `md.markdownToHtml` of the whole note, which tests the structure, the
   leaf texts and their segments at once. Quirks the containers plan
   excluded stay excluded, counted.
3. **The read view on the tree.** `BlockParser.parseText` builds a
   `ParsedBlock` from a leaf's inline text and its segments; `BlockView`
   draws containers from the path and subtree (quotes, items, callouts,
   tables by cell) and leaves from their runs. `_sourceFormOf`, the
   search and `approximate` go.
4. **Live on the tree.** `SourceStyler` takes a quote's runs from its
   subtree, like the read view; `LiveQuoteContent` becomes the subtree.
5. **Export on the tree.** `NoteHtml` renders with phase 2's writer plus
   its own rewrites (callouts, math, wikilinks, heading ids,
   `imageTargets` from the tree); compared with the current export on the
   export tests' fixtures.
6. **The package for inlines only.** No `parseLines` left in `lib/`.
   The harness keeps the package as its oracle for structure for as long
   as the app reads as the package does.

## Decisions

- **Whose semantics.** While the plan runs, the package's (the harness
  keeps it at 0): nothing a user sees changes. Once the package parses
  no structure, matching it is a choice, not a constraint — moving to
  CommonMark proper (the quirks: a lone `-` under a paragraph, setext in
  a lazily ending quote) can be decided then, with the spec's examples
  run against the scanner.
- **Speed.** A plain item does not scan again; a quote and a container
  item do, once per revision of the block, cached as the parse is now.
  Measured against the list fixture and the 100 000-line benches at
  each phase.

## Later

- Outline, links, frontmatter and spell check from the tree instead of
  the legacy tokenizer.
- The spec's examples against the scanner (see Decisions).

## State

Phase 1 in progress.

# One block tree and our own inline parser, to cmark-gfm (work in progress)

**Revised 2026-10-06.** The plan first kept `package:markdown` for the
inlines and compared the tree's HTML with the package's, byte for byte.
The aim is GitHub Flavored Markdown as `cmark-gfm` reads it, not the
package — whose quirks that comparison would have had us copy and then
throw away. So the oracle is the specifications' own examples, and the
package goes entirely: the inlines get a parser of our own too. The
history below the plan keeps the first version's reasoning where it
still holds.

Follows [block-scanner-containers.md](block-scanner-containers.md), whose
phases 1-4 made the scanner read containers as `package:markdown` does
(0 of 40 000 generated documents differ). That work cost what it cost
because the structure is decided **twice**: the scanner decides it to
find blocks, and `package:markdown` decides it again inside every block
it is handed — so the scanner had to agree with the package line by
line, quirks included, or the two readings drew different notes.

The aim: the scanner's reading is the only one. Every surface — read
view, live, export, index — takes its blocks from it, and a leaf's
inline text (a paragraph's, a heading's, a cell's) is read by our own
inline parser. Both follow `cmark-gfm`.

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

**Inlines**: our own parser over a leaf's inline text, `cmark-gfm`'s
algorithm (the spec's appendix: the delimiter stack for emphasis, the
bracket stack for links and images), each node carrying its offsets in
the leaf's text — and through the segments, in the note. The app's own
constructs (wikilinks and embeds, tags, inline math, `==highlight==`,
`<u>`/`<sup>`/`<sub>`) are syntaxes of the same parser, where today they
are masked before the package sees the text and put back after.

## The oracle

The specifications' examples — already in the repository since the
package was measured against them (2026-09-21, `test/fixtures/spec/`,
sources and licence in its README; loader `tool/spec_suite.dart`,
cmark's normalizer ported in `tool/html_normalize.dart` and proved on a
375-case corpus):

- `gfm-0.29-gfm.json` — the published GFM spec, 677 examples:
  CommonMark 0.29 and GFM's tables, task lists, strikethrough, extended
  autolinks and tag filter. **The reference.**
- `cmark-gfm-extensions.txt` — `cmark-gfm`'s extension tests, 30
  examples, footnotes among them (no spec covers them); added
  2026-10-06.
- `commonmark-0.31.2.json` — 652 examples: a second count, for where
  CommonMark moved on since 0.29.

**The bar**: the package, whole-document, passes 645 / 652 CommonMark and
662 / 677 GFM (`markdown_conformance_test.dart`, 22 triaged in
`nonconforming.txt`). Our parser does at least as well before anything
draws with it. The gate works as that test's does, both ways — every
example outside an allowlist passes, every one inside still fails — and
results are counted by the spec's sections, so block failures and inline
ones read apart.

The random harness against `package:markdown` stays as the structure's
regression net until the read view stops drawing with the package
(phase 5); where the package and the spec part — its quirks, already
counted apart — the spec wins.

## Plan

Each phase is gated by the unit suite, the random harness, the rescan
test, `test/perf/list_count_check_test.dart` and, from phase 2, the spec
counts (they may only go up).

1. **The tree, beside the current path** — done. A builder that gives a
   text its tree, each leaf's lines mapped to the note; footnote and link
   reference definitions read by the scanner. Nothing draws from it yet.
2. **Our inline parser, the spec harness and the HTML writer** —
   together, with no stop at the package's inlines (reordered
   2026-10-06: measuring a parser we would throw away was no step). The
   HTML entity table generated from WHATWG's `entities.json`
   (`tool/`); the parser, `cmark-gfm`'s algorithm, every node with its
   offsets in the leaf's text: escapes, entities, code spans, emphasis
   and strong (the delimiter stack), links and images (the bracket
   stack, reference definitions from the tree), autolinks, raw HTML,
   breaks; then GFM's strikethrough, extended autolinks, footnote
   references and tag filter. The spec files read as examples; each
   leaf's inline text from the tree; a writer in `cmark-gfm`'s form
   (containers, tight and loose lists, task items, tables, footnotes).
   Measured by section, inline sections first — and for speed: the
   pathological inputs linear, the bench against the package's inline
   parser at least even (Decisions, "Speed").
3. **The blocks to the spec.** Every block section at its examples:
   where the scanner follows the package and the spec says otherwise
   (a lone `-` under a paragraph, setext in a lazily ending quote,
   definitions inside containers, the tab limits), the scanner follows
   the spec.
4. **The app's extensions in the parser.** Math, wikilinks and embeds,
   tags, highlight, `<u>`/`<sup>`/`<sub>`, template placeholders, as
   syntaxes in the masking order (Decisions); each tested on its own,
   and the spec counts unchanged with them on.
5. **The read view on the tree.** `ParsedBlock` from a leaf's inlines
   and its segments; `BlockView` draws containers from the tree (quotes,
   items, callouts, tables by cell) and leaves from their runs.
   `ExtensionMasker`, `_sourceFormOf`, the search and `approximate` go.
6. **Live on the tree.** `SourceStyler` takes its runs from the tree,
   quotes included; `LiveQuoteContent` becomes the subtree.
7. **Export on the tree.** `NoteHtml` renders with the writer plus its
   own rewrites (callouts, math, wikilinks, heading ids, picture
   targets); checked against the export tests.
8. **`package:markdown` removed** from `pubspec.yaml`: nothing in `lib/`
   imports it; the random harness, its last user, retires with it.

## Decisions

- **Whose semantics: `cmark-gfm`'s** (GFM spec 0.29 and its extension
  tests). CommonMark 0.31.2's changes since are counted and decided case
  by case.
- **The app's extensions are additions to it**, each documented, each
  tested on its own, never a change to what GFM reads where they are
  absent:
  - *inline*: `$…$` math (`math_rule.dart`'s predicate), `$$…$$` within
    a line, `[[wikilinks]]` and `![[embeds]]` (`links/parser.dart`'s
    rule), `#tags`, `==highlight==`, `<u>`, `<sup>`, `<sub>`, and the
    templates' `{{…}}` placeholders;
  - *block*: `$$` display math, frontmatter, callouts (`> [!type]`, `-`
    or `+` to fold, a title), and `mermaid` fences drawn as diagrams.

  Their precedence is today's masking order, as syntaxes of the parser:
  a code span hides everything in it, then display math, inline math,
  wikilinks and embeds, tags — so the emphasis algorithm never reads a
  `_` inside a formula (`extension_masker.dart`'s measure: 7 530 `_`
  runs in one note, 17 of them emphasis). A spec example holds none of
  them, except the `$` and `#` a spec example may write as text: those
  are where an extension could change GFM's reading, and are checked
  against it one by one.
- **Until phase 5, nothing a user sees changes**: the views keep drawing
  with the package; the tree and the writer are measured beside them.
- **Speed is a requirement, as much as conformance** (asked for,
  2026-10-06). The app holds 1M-note libraries and novel-length notes,
  and every keystroke in live reparses what it touches. So:
  - *Linear time, always.* The inline parser keeps `cmark`'s guarantees
    — the openers' lower bounds in the emphasis search, the 999-character
    label, the bracket stack's deactivation, a code span's closing run
    found once — and a test runs `cmark`'s pathological inputs (deep
    nesting of brackets and emphasis, long backtick and delimiter runs,
    many unclosed links) at growing sizes and fails on anything worse
    than linear.
  - *At least as fast as what it replaces.* A bench in `tool/` parses
    the same leaves with ours and with `package:markdown`'s inline
    parser — the 10 KB, 1 MB and worst-note fixtures, and a
    math-heavy note (`_` runs inside formulas are the masker's own
    measure) — and a `test/perf` file holds ours to it, the absolute bar
    behind `NIMAN_PERF` as AGENTS.md has it. Masking goes away with the
    package, which is time saved, not spent.
  - *No work per character that does not have to be.* ASCII on fast
    paths (no regular expression per character), text runs taken in one
    `substring`, nothing allocated for a character that is plain text.
  - *Only what is seen.* As now: the scanner is incremental, and a leaf
    is parsed when it is drawn, cached until its text changes.
  - *The blocks too.* A plain item does not scan again; a quote and a
    container item do, once per revision of the block, cached as the
    parse is now. Measured against the list fixture and the 100 000-line
    benches at each phase.

## Later

- Outline, links, frontmatter and spell check from the tree instead of
  the legacy tokenizer.

## State

Phase 1 in progress.

- **The builder** (`BlockTree.of`, nodes in `block_node.dart`): the
  scanner's blocks, a quote's content and an item's content scanned
  again, each later block of a list hung under the item its depth names
  (an item its marker line opens inside — `- - a` — included). Each
  leaf's lines map to the note by `(line, start, end)`, composed through
  every level of content. Two things the flat blocks do not say, which
  the builder had to:
  - *A tab's columns left over.* An item's indent may end inside a tab;
    the parser hands the rest on, counting toward an inner item's indent
    only. A scan of a container's content now takes them per line
    (`BlockScanner(leftOver:)`, `ContainerWalk.of`): `- - w` / `\t---`
    is the inner item's heading.
  - *A construct a marker line opened* (`- > x` / `  > y`, a fence after
    a marker): its later lines are blocks of their own to the scanner,
    entered with the construct still open; the builder joins them to the
    node the marker line's content made — a quote's content is scanned
    again whole.
- **The harness** (`READER=tree`): 0 of 40 000 documents differ on seeds
  1-4, and on seed 5 the one table the read view's pipeline misses too.
  The gate holds both readings at 0 over 2 000 documents.

- **Footnote definitions** (`71e640e4`): a container in the scanner, as
  the package reads one (the table below). `LineState.footnote` holds it
  around every other container, and whether its last line was blank;
  `FootnoteSyntax` reads its opening and its end with the package's own
  block patterns; `Block.footnote` marks its blocks. Opened at the note's
  margin only: inside an item or a quote the package leaves a definition
  where it stands, a footnote's `li` in the middle of the note, which no
  one wants drawn. The tree has a `FootnoteNode`. The read view and live
  draw a definition's blocks with the footnotes, as before; its blank
  lines stay the note's spacing.
- **The harness** cites the footnote first in the reference's document
  (an uncited one is dropped) and reads a footnote's `li` as `F`. New
  forms `[^f]: W`, `[^f]:`. Left out, counted: the package throwing (a
  cited footnote ending with a list, ~400 per 40 000) and a definition
  inside a container (~700). Seeds 1-6: 0 differing documents for the
  tree; the read view's pipeline has one on seed 4 (`- - w` / `\t* w` /
  `\t\t---`, its tab limit, not a footnote).

- **Link reference definitions**: read where no paragraph is open, by
  `LinkDefinitionSyntax` — the package's `LinkParser` algorithm (its
  file is not exported), asking for the lines after the first one at a
  time, walked in their container, up to a line that would end a
  paragraph. `LineState.definition` counts the lines the definition has
  left; after it no paragraph is open, which is what the scanner read
  wrong (`[r]: /u` / tab `code` is code, `[r]: /u` / `2) x` a list,
  `[r]:` / `/u` one definition). `Block.definition` marks its block; the
  tree's leaf carries it. Whether a line opens one depends on the lines
  after it, the next one's next included (a table's head ends the
  paragraph): `Block.reach` records how many, and an edit within reach
  reads the block again from its start; the look back is bounded by the
  farthest reach the scan has made. Harness forms `[r]: /u`, `[r]:`,
  `/u "t"`: the tree went from 474 differing documents to 0 (seeds 1-6);
  the rescan test, with definitions among its pieces, finds no
  divergence (it found the next-line reach). The list fixture scans in
  the time it did (113-122 ms against 108-115, the same host).

### Phase 2 (in progress): our inline parser

- **The parser** (`lib/src/markdown/inline/`): `cmark`'s algorithm —
  the delimiter stack (`DelimiterStack`, the rule of 3 and the openers'
  lower bounds), the bracket stack (`Bracket`: inline, full, collapsed
  and shortcut references, deactivation of outer links), code spans,
  escapes, HTML5 character references (`html5_entities.dart`, generated
  from WHATWG's `entities.json` by `tool/gen_html5_entities.dart`),
  autolinks, raw HTML by the 0.29 rules, hard and soft breaks; GFM's
  strikethrough (one or two tildes, runs of equal length), footnote
  references (`![^1]` a `!` and the reference, as `cmark-gfm`) and
  extended autolinks (`www.`, `http(s)://`, `ftp://`, addresses, with
  `mailto:` and `xmpp:` written). Every node carries its offsets in the
  leaf's text; text nodes are joined only where they are their source as
  written, so the offsets stay one to one.
- **The writer** (`lib/src/markdown/html/`): the tree in `cmark-gfm`'s
  HTML — tight and loose lists, task items, tables with alignment,
  footnotes numbered by citation with their links back, the tag filter.
  Link reference definitions are read with `cmark`'s rules
  (`LinkReferences`) from every paragraph's start.
- **The measure** (`dart run tool/tree_spec.dart`), against the
  package's 645 / 652 and 662 / 677: **596 / 652** CommonMark 0.31.2,
  **625 / 677** GFM 0.29, **30 / 30** `cmark-gfm`'s extensions. Every
  inline section passes but for failures that are the blocks' — an
  autolink or a tag-like line alone on its line is read by the scanner
  as an HTML block (the package's type-7 rule), and the tab, setext,
  code, HTML block and list cases — and three examples where CommonMark
  0.31 moved on from GFM 0.29 (symbols as punctuation, two comment
  rules). The gate (`tree_conformance_test.dart`, both ways like the
  package's) holds them in `tree_nonconforming.txt`, buckets `blocks`
  (phase 3) and `version`.

- **Speed.** `inline_pathological_test.dart` runs `cmark`'s pathological
  inputs at two sizes four times apart: all eighteen linear. Making them
  so found five faults — text nodes joined two at a time (quadratic in a
  run of delimiters), the code span's closing run searched again for
  each opener (now `cmark`'s cache of runs), outer link brackets
  deactivated one by one (now a count of links made), the 999-character
  label limit not applied to a link text, and a run of `)` after a URL
  counted again for each — and a sixth that was a crash: freezing,
  autolinking and writing the inline tree recursed, and 20 000 levels of
  nested emphasis overflowed the stack; all three walk with a stack of
  their own now. `tool/inline_bench.dart`, same leaves, best of five:

  | note | leaves | ours | package inline | app today |
  |---|---:|---:|---:|---:|
  | Geometria 1 (945 KB, a user's, by path) | 3 345 | 28 ms | 366 ms | 380 ms |
  | fixture-200kb.md | 2 065 | 5 ms | 52 ms | 67 ms |
  | fixture-1mb.md | 11 103 | 17 ms | 257 ms | 323 ms |
  | worst-note.md | 1 420 | 50 ms | 609 ms | 573 ms |

  ("app today": masked, then the package's whole parse of the block.)
  `test/perf/inline_parser_perf_test.dart` holds ours to no slower than
  the package on every run, the absolute bars behind `NIMAN_PERF`.

Left in phase 2: nothing the plan names; the blocks are phase 3.

### Phase 3 (done): the blocks to the spec

GFM **677 / 677** (the package: 662), CommonMark 0.31.2 **649 / 652**
(the package: 645; the three left are where 0.31 moved on from GFM
0.29, decided for GFM), `cmark-gfm`'s extensions **30 / 30**. What it
took:

- HTML blocks: kind 7 is one whole tag as the spec writes it
  (`InlineScanners.tag`, the inline parser's own rule) — an autolink
  alone on its line was one — and interrupts no paragraph; kind 6's name
  ends where the spec says.
- GFM's extensions only where `cmark-gfm` turns them on: extended
  autolinks and the tag filter for its extension tests and the spec's
  "(extension)" sections; `TreeHtml(extensions:)`, on in the app.
- The app's block syntax (frontmatter, `$$`) off for the specs' examples:
  `appSyntax`, through scanner, tree and writer; on in the app.
- The writer: a note's last line break opens no line; a list is loose
  when a blank line ends a block of an item before another, a sublist's
  included.
- The tree: indented code runs over its blank lines; an empty item's
  marker line is no blank line between its blocks.
- Lazy lines underline nothing, in a quote or an item: the tree hands
  each line's laziness to the scan of a container's content, as it hands
  a tab's columns. The package heads a lazy `===` in an item, and a lazy
  `    ---` under a quote, which cmark adds to the paragraph: there the
  spec wins, and the random harness leaves them out, counted. The tree
  reads 0 of 40 000 documents otherwise on seeds 1-5.

- A tab a container's prefix ends inside of keeps its columns past it:
  an item's indent is counted in columns (`LineSyntax.itemContent`),
  the prefixes say what they leave over (`BlockParser.linePrefix`), the
  leaves keep it (`LeafNode.leftOver`), and the writer counts code's four
  columns from where the content starts, tabs to their stops.

### Phase 4 (done): the app's syntax in our parser

`InlineParser(appSyntax:)`, on in the app, off for the specs' examples:

- **Math, wikilinks and embeds, tags**: `ExtensionMasker.extensionAt`,
  the masker's own rules in its order, asked where a `$`, `[[`, `![[` or
  `#` stands; each an atomic node (`MathNode`, `WikiLinkNode`,
  `TagNode`). Reading left to right gives the masker's priority for
  free — a code span, an autolink or raw HTML read first holds what
  looks like math — and more: math inside an HTML attribute is no math
  now. `math_rule.dart` reads a span from a position
  (`inlineMathAt`), and a `$` or `$$` that found no closing one to the
  end is not scanned for again: `$1 $2 $3…` was quadratic.
- **`==highlight==`**: a delimiter run of exactly two, matched with a run
  of the same length, as `~` is — so it nests with emphasis, which the
  package's regular expression did not.
- **`<u>`, `<sup>`, `<sub>`**: raw HTML paired among siblings on one
  line, as the app has always read them (`StyleTags`), the inside parsed.
- The templates' `{{…}}` placeholders are no syntax of a note's inlines:
  the template checker reads them.

Tested by `inline_app_syntax_test.dart`; the pathological inputs grow by
seven of the app's, all linear. The bench, ours with the app's syntax:
Geometria 1 17.5 ms against the app's 382 (masked, the package's parse),
fixture-1mb 18.5 against 323, the worst note 20.6 against 578 — faster
than without it, the formulas being single nodes the emphasis algorithm
never walks.

Next: phase 5 — the read view on the tree.

### An open question: `$` as a currency sign

`20$ + 0,10$/Kg` is read as a formula (` + 0,10`): the app's rule
(`math_rule.dart`) opens on any `$`, a space after it included, because
the notes write `$ x $`. `\$` keeps it text, but `live` shows the
backslash (the parse it colours from loses the escape; our parser keeps
it, and phase 5 hides it as it hides any mark). Measured on Geometria 1,
13 004 formulas: 156 open with a space after the `$` (Pandoc's and
Obsidian's rule would lose them), none opens right after a digit, none
closes right before a letter or a digit. So "a `$` right after a digit
does not open" reads prices as text and loses no formula there — to be
decided.

### Footnote and link reference definitions: what is known

Read from `package:markdown` 7.3.1's sources, then confirmed by running
`Document.parseLines` (GFM) on examples, a footnote cited after it:

| Input | The package |
|---|---|
| `p` / `[^1]: a` | the definition interrupts the paragraph |
| `[^1]: a` / `    b` | `a\nb`, one paragraph in the footnote |
| `[^1]: a` / `b` | `a\nb`: a line that opens no block goes on lazily |
| `[^1]: a` / blank / `    b` | two paragraphs in the footnote |
| `[^1]: a` / blank / `        code` | code in the footnote |
| `[^1]: a` / blank / `b` | `b` is a paragraph after it |
| `[^1]: a` / blank / tab `b` | code after it: four *literal* spaces only |
| `[^1]: a` / `     b` (five) | `a\n b`: four come off, the fifth stays |
| `[^1]: a` / `# h`, `- i`, `> q`, a fence, `***`, `---`, `<div>` | each ends it |
| `[^1]: a` / `\| x \| y \|` / `\|---\|---\|` | the table goes **into** the footnote (lazy head) |
| `[^1]:` / `    a`, `[^1]:a`, `   [^1]: a` | definitions |
| `    [^1]: a` | code |
| `[^a b]: a` | no footnote: a link reference with label `^a b` |
| `- [^1]: a`, `> [^1]: a` | the definition stays **in place** inside the item or quote, no section |
| a definition never cited | dropped from the output |
| `[^1]: a` / `[^2]: b`, both cited | only `2` is drawn, `[^1]` stays text — a quirk |
| `[^1]: a` / blank / `    - x` | **throws** (`_appendBackref` expects elements) |

Link reference definitions: `p` / `[x]: /u` is one paragraph (it cannot
interrupt one); `[x]: /u` / `text` is a definition, then a paragraph;
the multi-line forms hold (title or URL on the next line, a label over
two lines); a definition invalid partway (`[x]: /u "t`) leaves the whole
paragraph as text; in an item or a quote it is taken out and leaves the
container empty; four spaces in, it is code.

The throw is a bug of the app's too: the export parses the whole note
with the package, so a cited footnote that ends with a list cannot be
exported.

The source reading, for the record:

- **GFM adds** `FencedCodeBlockSyntax`, `TableSyntax`, the two checkbox
  list syntaxes and `FootnoteDefSyntax` (`extension_set.dart`), tried
  **before** the standard syntaxes (`block_parser.dart:80-83`).
- **A footnote definition** opens on `footnotePattern`:
  `^[ ]{0,3}\[\^([^\] \r\n\x00\t]+)\]:[ \t]*` — up to three spaces, a
  label without spaces or tabs. It does not override `canEndBlock`
  (default `true`), so it **interrupts a paragraph**.
- **It is a container.** `FootnoteDefSyntax.parseChildLines` takes the
  rest of its first line, then: a blank line (and remembers it); a line
  starting with four literal spaces, those four taken off (a tab is not
  four spaces here); after a blank line, any other line ends it;
  otherwise a line on which any block syntax's pattern matches ends it,
  and any other line is taken as it stands (lazily). The lines are parsed
  again as blocks (`BlockParser(lines, document).parseLines()`), so a
  footnote holds paragraphs, lists, code.
- **Where it goes**: `Document.parseLines` ends with `_filterFootnotes`,
  which takes the definitions out of the top-level nodes, keeps those
  whose label is referenced, sorts them by first reference and appends
  them as `section.footnotes > ol > li`. Only top-level nodes are
  filtered — whether a definition inside a list or a quote stays in place
  is to be checked.
- **A link reference definition** (`LinkReferenceDefinitionSyntax`,
  pattern `^[ ]{0,3}\[`) has `canEndBlock` false: it **cannot interrupt
  a paragraph**. Its multi-line forms and what happens when it is invalid
  partway are to be checked.

To do, in order: confirm the above by running examples (the harness's
reference side has to place a footnote's words — `li` inside the
section must not count as an item); the scanner's container (a field of
its own in `LineState`, or `OpenItem` with an indent of four and a flag
— every user of `listStack` / `listDepth` decides which); the consumers
that find definitions by line today (`DocumentScope`, `footnote_list`,
`source_styler`, `note_html`).

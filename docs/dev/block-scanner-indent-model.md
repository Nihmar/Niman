# Block scanner: the indentation model (design for the remaining repros)

`docs/dev/block-scanner-containers.md` records the container rework up to
309 of 40 000 documents differing (138 minimal) on
`fix/block-scanner-containers`. Everything left needs one change the
incremental fixes could not make: **a single, per-line notion of how far
the line is indented past the containers it is already in**. This
document is the plan for that change, with the evidence it is built on.

Do not start from the current code's `_contentColumn`/`_indentOf`/`
_listMarker`; start from the model below and rewrite those three to
follow it.

## Evidence

Every minimal repro left wants containers measured where their content
actually begins, and the two things that are measured today both start
at the wrong place. The reference (`package:markdown`, the parser the
read view uses) for the shapes that matter:

### A quote's content is measured past the `>`, and a `>` past it nests

| Input (`·` = space) | Reference | Scanner now |
|---|---|---|
| `>·-·w` then `····>·w` | `blockquote ul li blockquote p` (quote 2) | one quote, depth 1 |
| `>·-·w` then `··>·w` | `blockquote ul li` (quote 1, the item's text) | one quote, depth 1 |
| `>·w` then `····>·w` | `blockquote p` (one, the `>` is text) | one quote, depth 1 |
| `>·w` then `>·>·w` | `blockquote p blockquote p` (quote 2) | one quote, depth 1 |
| `··>·w` then `····w` | `blockquote p` (the last line in the quote) | quote then code |

The first two are the same two lines with different indent, and the
reference tells them apart **only** by where the second `>` stands
relative to the item's content column (4):
- `    > w` — the `>` at 4 is *inside* the item, so it opens a quote in
  the item: two levels.
- `  > w` — the `>` at 2 is *short of* the item's content column, so it
  is the item's text in the one open quote: one level.

### A quote block is the quote, not the items in it

| Input | Reference | Scanner now |
|---|---|---|
| `>·-·w` | `blockquote ul li` (the quote is at list −1) | quote at list 0 |
| `*·w` / `··>·w` / `>·w` | `ul li blockquote p blockquote p` | `li, quote0, quote−1` |
| `>·-·w` (alone) | `blockquote ul li` | `quote0` |

The scanner counts the item written after the `>` as the quote's own
list depth. It is not: the quote sits in the items *outside* it, and the
items *inside* it are read when the quote's own lines are scanned again
the way `BlockView._quoteContent` already does.

### Indented code inside a quote is measured from the quote's content

| Input | Reference | Scanner now |
|---|---|---|
| `>·w` / `····w` / `····w` | `blockquote p pre code` | quote, quote, code |
| `··>·w` / `····w` | `blockquote p` | quote, code |

Four spaces past the quote's content column is code; four spaces past
the margin is not, when the quote is indented. The first row shows the
boundary: a quote takes **one** indented paragraph continuation, and the
second indented line opens code that ends the quote.

### An item's contents are measured from the item's marker

| Input | Reference | Scanner now |
|---|---|---|
| `··1.·w` / `······---` / `····w` | `ol li h2 pre code` (code in the item) | heading, code at −1 |
| `··2)·w` / `······---` / `····w` | `ol li h2 pre code` | heading, code at −1 |
| `··1.·w` / `······-·w` / `····*·w` | `ol li ul li ul li` (three levels) | `li0 li1 li0` |
| `··1.·w` / `······``` ` / `····w` | `ol li pre code` | item, fence, text |

`  1. w` has its marker at 2 and its content at 5. `    w` at 4 is less
indented than the content column but still **inside the item** — one
space past the marker — and is code there (four spaces from the
*marker's own line start*, i.e. the container's content, not the
margin). `    * w` at 4 likewise opens a **list level** inside the item,
and the reference has it three deep, not at zero.

### Fences and items close together

| Input | Reference | Scanner now |
|---|---|---|
| `1.·w` / `···``` ` / ```` ``` ```` / `w` | `ol li pre code pre code` | item, fence, paragraph in item |
| `*·w` / `··``` ` / `*·w` / `··*·w` | `ul li pre code li ul li` | item, fence, item0, item1 |

The line that closes an item's fence leaves the item with it, and is
then read as if no fence were open (the `w` after the close is code in
the reference — a quirk of `package:markdown`, but the parser is the
target). The earlier fix got the second row's depths right but not the
first row's kinds.

## The model

One value per line, computed once, before any container decision:

```
effectiveIndent(line) = the column of the line's first content character,
                        after consuming the indent of every open container
                        (each open item's content column, each open quote's
                        content column)
```

Concretely, start at column 0 and walk the line:
- skip up to three spaces, then a `>` and one space → that is a quote
  level; the column now past it is the new base;
- if both an item is open and the column reaches the item's content
  column, consume it (the base becomes the item's content column).

What is left when neither applies is `effectiveIndent`: how far the
line is indented past everything it is already in. **Every** decision
reads that value, not `_indentOf` from the margin:

| Decision | Reads |
|---|---|
| a marker may interrupt a paragraph | the marker at `effectiveIndent`, at most `effectiveIndent + 3` |
| an ATX heading | `#` within three of `effectiveIndent` |
| a thematic break | `---` within three of `effectiveIndent` |
| an indented code block | four or more past `effectiveIndent` |
| a fence opens | three at most past `effectiveIndent` |
| an item opens | a marker at `effectiveIndent`, content at marker + width + padding |
| an item continues | the line at or past the item's content column |
| a quote opens | a `>` at `effectiveIndent` |

`listDepth` and `quoteDepth` then fall out of the walk itself: they are
**how many containers were consumed**, not two counts kept apart. A
block that is a quote reports the depth of the items it was consumed
*into before* the `>` — depth of the walk minus the quotes it opened —
which is what `_quoteOuterItems` started to do.

### Where it touches

Three functions compute the model; the rest read it:

- `_afterQuotes(text)` → fold into the walk (`_consumeContainers`).
- `_indentOf(text)` → replace by `_effectiveIndent(text, state)`.
- `_contentColumn(text, state)` → the base the walk started each
  decision from; keep for the *item* comparisons only.
- `_listMarker(text, reach)` → take the walk's start offset, markers
  then compared to the item columns the walk produced.

`LineState` keeps `quoteDepth` and `listStack` as today, plus:
- `quoteContentColumn` — where the innermost quote's content starts
  (what `_isQuoteIndented` and the "one continuation" rule need);
- `quoteMarkerColumn` — where its `>` stands (what decides nested vs
  same level);
- `quoteIndented` — as today.

Both columns are per-container, not derived on the fly from the line,
because a lazy line carries no `>` of its own and must keep what the
open quote had.

## Test cases to pin, one at a time

Write these as unit cases in `test/unit/block_scanner_test.dart` before
the rewrite, so each step of it is checked against a known answer. They
are the minimal repros from the harness, with the reference's answer.

Measured against the scanner on `fix/block-scanner-containers`
(`01963d99`): 7 are **red** and 8 pass. The 8 passing are regression
cases the rewrite must not break; the 7 red are what it is for.

| # | Input (`·` = space) | Line | Want | Today |
|---|---|---|---|---|
| 1 | `>·-·w` / `····>·w` | 1 | quote L−1 Q2 | quote L−1 Q1 (red) |
| 2 | `>·-·w` / `··>·w` | 1 | quote L−1 Q1 | pass |
| 3 | `>·w` / `····>·w` | 1 | quote L−1 Q1 | pass |
| 4 | `>·w` / `>·>·w` | 1 | quote L−1 Q2 | quote L−1 Q1 (red) |
| 5 | `··>·w` / `····w` | 1 | quote L−1 Q1 | pass |
| 6 | `>·-·w` | 0 | quote L−1 Q1 | pass |
| 7 | `*·w` / `··>·w` / `>·w` | 2 | quote L−1 Q1 | pass |
| 8 | `>·w` / `····w` / `····w` | 2 | code L−1 Q0 | pass |
| 9 | `>·w` / `····w` | 1 | quote L−1 Q1 | pass |
| 10 | `··1.·w` / `······---` / `····w` | 2 | code L0 Q0 | code L−1 (red) |
| 11 | `··2)·w` / `······---` / `····w` | 2 | code L0 Q0 | code L−1 (red) |
| 12 | `··1.·w` / `······-·w` / `····*·w` | 2 | item L2 Q0 | item L0 (red) |
| 13 | `··1.·w` / `······``` ` / `····w` | 2 | code L0 Q0 | code L−1 (red) |
| 14 | `1.·w` / `···``` ` / ```` ``` ```` / `w` | 3 | code L−1 Q0 | paragraph L0 (red) |
| 15 | `*·w` / `··``` ` / `*·w` / `··*·w` | 3 | item L1 Q0 | pass |

The red classes, in the harness's own counts: 1 and 4 are the
`quoted → quoted Q1` (nested quote) class, 10/11/13/14 the
`quoted → code L−1` and `code → code L−1` classes, 12 the
`text → text L0` deep-item class.

## Method

1. Write cases 1-15 as unit tests (red against the current scanner).
2. Introduce `_consumeContainers` and `_effectiveIndent`, and rewrite
   `_listMarker`/`_contentColumn`/`_isIndented`/`_isRule`/`_headingLevel`
   call sites to read them **together** — the two failed attempts in
   this session moved the harness by thousands when only some call
   sites were changed.
3. Keep the unit suite and, at each step, run
   `NIMAN_SCANNER_DIFF=1 flutter test
   test/unit/block_scanner_commonmark_test.dart`; the minimal count must
   fall at every step. A step that raises it is reverted whole.
4. Keep `block_scanner_test.dart`'s "a rescan that stops short" green at
   every step: phase 1 of the plan in `docs/dev/block-scanner-containers.md`
   unskips it before the rewrite starts.
5. Only then touch the downstream `BlockParser.contentText` indent
   strip `docs/dev/block-scanner-containers.md` lists.

## What the last two attempts proved (do not repeat)

- Passing an offset past the quotes into `_listAfter` alone: 309 →
  6 393. The marker/indent readers must all move together.
- Adding `quoteColumn`/`quoteIndent` as state and threading them: 309 →
  4 343, with `quoted → code` and `code → quoted` swapping places. The
  columns alone are not enough; the **walk** is, because it makes the
  indent one value instead of two half-measured ones.
- Measuring the indent past the quotes (`_indentAfterQuotes`) and making
  the marker columns relative to it: 309 → 6 346. The stack's item
  columns are absolute and a relative marker does not compare to them —
  the walk has to carry **how many quotes were consumed** and compare
  items only at the same quote level.
- Making indented code in an item measure from the item's marker alone
  (not its content column): 309 → 352, 59 new minimal repros. A marker
  four in is a sublist, not code in the item; the rule needs the walk's
  effective indent to tell them apart.

Each partial change fixes the shape it aimed at and moves others by the
hundreds, which is what makes this a rewrite: the four numbers above are
the same lesson four times.

A fifth attempt, this session, went further: it made `_listMarker`
measure past the quotes, `_contentColumn` read the content position past
them, `_quoteDepthAfter` sum a nested `>` past an item's content,
`_quoteOuterItems` give a quote block the items outside it, and added a
`quoteIndent` for the indented-code boundary. It **passed fourteen of
the fifteen cases** (all but the quote-at-the-margin one) and still sat
at 4 476 of 40 000 differing / 577 minimal, against 309/138 before it —
145 of the new repros are `quoted → code` shapes like `1. w` /
`   ``` ` / `  > w`, where an item and a quote interleave.

The reason is the one the four numbers already carry: `_listMarker`
returned absolute columns, `_contentColumn` compared a position past the
quotes, and every other reader sat between the two. A rewrite that
measures once, in the walk, removes the gap; patching the three readers
keeps it and moves the errors around. The fifteen cases are a good
checkpoint for that rewrite — they are green in the fifth attempt — but
the harness count is the gate, and it did not fall.

A sixth attempt made the marker and item columns **relative** to the
quote prefix (so both halves measure from the same point) and gave a
quote block the items before its `>`: 309 → 4 229 / 413, two of the
fifteen cases red again. Same signature.

### Why patching cannot work (six attempts, six times)

| Attempt | Harness (diff / minimal) |
|---|---|
| starting point | 309 / 138 |
| offset past quotes in `_listAfter` only | 6 393 / — |
| `quoteColumn`/`quoteIndent` as state | 4 343 / — |
| indent past quotes, marker columns relative | 6 346 / 197 |
| indented code from the item's marker | 352 / 175 |
| five readers moved together (14/15 cases) | 4 476 / 577 |
| marker and item columns relative + `_quoteOuterItems` | 4 229 / 413 |

Every attempt is a different subset of {`_listMarker`, `_contentColumn`,
`_indentOf`/`_indentPastQuotes`, `_quoteDepthAfter`, `_quoteOuterItems`,
`quoteIndent`} moved to measure past the quotes, and every one leaves the
same defect: an item's column is measured on the line that opened it,
a line's position is measured on the line being read, and the two are
compared as if they were one space. The walk has to produce **both** in
the same coordinates — the item's column when it opened is itself the
result of a walk over its own line — and no patch to the readers gives
that, because the item columns are already in the stack from earlier
lines.

So the rewrite is: replace `_contentColumn`, `_indentOf`/`_afterQuotes`
and `_listMarker` with one `_consume(text, state)` that walks the line
and returns the content position, the depth and the markers **in the
line's own coordinates**, and make the stack hold each item's column
**as that walk produced it** (so opening and reading use one function).
The fifteen cases and the harness are the gate.

The fifteen cases are in `block_scanner_test.dart`'s "the indentation
model" group: eight run, seven are `skip: pending` with this document's
name. The rewrite unskips them.

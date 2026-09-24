# WYSIWYG surface: alternatives measured

> **Superseded (#247).** `flutter_quill`, `re_editor` and the old preview are
> gone: every mode is now Niman's own surface
> ([unified-surface.md](unified-surface.md)). This page is kept as the record
> of what was measured before that decision; the files it links under
> `editor/wysiwyg/` and the M2 benchmark it names no longer exist (they are in
> the git history).

The WYSIWYG surface is `flutter_quill` behind Niman's own Markdown codec
(`editor/wysiwyg/`). A Delta document is not Markdown, so the codec pays
for the round trip: ~530 lines across
[markdown_document_codec.dart](../../lib/src/editor/wysiwyg/markdown_document_codec.dart)
and [markdown_blocks.dart](../../lib/src/editor/wysiwyg/markdown_blocks.dart),
plus the opaque embeds that keep tables, math, wikilinks, footnotes and
frontmatter read-only.

That cost makes replacements look attractive, so they get proposed. This
records what was measured, on 2026-09-18, so the next proposal starts
from numbers instead of from the README of the week. **Verdict: none of
the six replaces `flutter_quill` today.**

## The bench

Everything measured here used
[m2_spike_benchmark_test.dart](../../test/unit/m2_spike_benchmark_test.dart)'s
fixture — `test/fixtures/markdown/fixture-200kb.md`, 206 241 chars,
6289 lines — and the same shape of test: first frame after pumping the
widget, then the best of five mid-document single-character edits.

The spike branches (`spike/smooth-markdown-editor`,
`spike/live-markdown-editor`) were deleted after this was written; their
benches cannot live on `main` because the dependencies are gone. To redo
one: add the package, copy the fixture-loading and `_firstFrame` helpers
from the M2 benchmark, and print rather than assert.

Numbers are debug-mode, inside the test harness, on one Windows machine.
They are inflated in absolute terms; only the ratios between rows carry.

## Baseline: what the app already does

From T-M2-00, re-run on the same machine and day:

| | |
|---|---|
| Tokenize 200 KB from cold | 23.95 ms |
| **Incremental edit, mid-buffer** | **0.507 ms** |
| Line layout + paint | 44.7 µs/line (only visible lines are paid for) |
| Whole buffer as a single span | 52.0 ms |

The 0.507 ms is the number every candidate has to be read against. It is
`O(change)`, not `O(document)`, because
[highlighting.dart](../../lib/src/editor/highlighting.dart) re-tokenizes
only what moved.

## Measured, and rejected

### flutter_smooth_markdown 0.10.0

Already a declared dependency — but dead: nothing in `lib/` imports it,
only the M2 benchmark does. Its 0.10.0 added
`flutter_smooth_markdown_editor`, which keeps Markdown source as the
document of record (no Delta, no codec).

| | |
|---|---|
| `SmoothMarkdown` eager preview, 200 KB | 2769.2 ms (0.8.1 measured 2781.5 ms) |
| Editor, formatted, 20 KB | 37.3 ms |
| Editor, formatted, 200 KB | 110.6 ms |
| Editor, source, 200 KB | 125.3 ms |
| Keystroke, 200 KB | 72.2 ms |

Two findings. The **preview widget is still eager** and has not improved
in two releases, which confirms the M2 rejection that
[wysiwyg_editor.dart](../../lib/src/editor/wysiwyg/wysiwyg_editor.dart)
refers to. The **editor is not** — its formatted mode builds block
segments through a `ListView.separated`, so ten times the document costs
three times the open, not ten.

Rejected anyway, on correctness: formatted mode throws `RangeError` out
of `_sourceRangeForDocumentBlock` at both 20 KB and 200 KB — `indexOf`
called with a start past the end of the source (20669 of `0..20624`).
That is the block-to-source mapping the "source of record" promise rides
on. Source mode alone is clean. The 72 ms keystroke would rule it out
independently.

### live_markdown_editor 0.11.0

Source-preserving by design, Raw/Live/Read modes, its own editable engine
(no Material in `lib/`), two dependencies, MIT, 160/160 pub points
against this exact toolchain.

| | |
|---|---|
| Live, 20 KB | 355.3 ms |
| Live, 200 KB | 1329.1 ms |
| Raw, 200 KB | 405.0 ms |
| Read, 200 KB | 862.0 ms |
| **Source survives byte for byte** | **yes** (206 241 = 206 241 chars) |

It is the only candidate that got the contract right: every mode renders,
nothing throws, and the text leaves the controller identical character
for character — where flutter_smooth_markdown broke on exactly that.

Rejected on the keystroke, which costs the whole document:

| 2 KB | 20 KB | 200 KB |
|---|---|---|
| 6.2 ms | 33.1 ms | 422.4 ms |

Clean `O(n)`, about 2 ms per KB: the parse runs over everything on every
edit. Under ~5 KB it is comfortable; 20 KB — an ordinary note — already
lags. Against 0.507 ms this is a different complexity class, not a
constant factor to tune.

Worth revisiting if it ever parses incrementally. It was 26 days old and
had 3 likes when measured, so it needs a track record regardless.

## Rejected on inspection, without a bench

### markdown_editor_live 0.6.0

A `TextEditingController` over a `TextField`, one file of substance,
6 likes. It hides syntax markers with `fontSize: 0.0` and **compensates
the caret nowhere**: the markers stay in the text at their offsets, so
arrows walk invisible characters, backspace eats one `*` of a `**` pair
(leaving text that re-parses as italic mid-correction), and selection
over a marker paints a zero-width rect. Its only offset mapping serves a
different hack — `​\n` "virtual newlines" it *injects into the
controller's own text* to make room for image widgets, which for an app
whose file is the truth is a way to write zero-width spaces into a note.
Rebuild is ~13 regexes over the whole document per keystroke, with an
`O(n)` offset map called per match. No hooks for the toolbar, find or
spell underlines; no links, blockquotes, task lists or tables.

### appflowy_editor 6.2.0

The best *model* of the six — a tree of nodes with children, which maps
onto Markdown block structure far better than a flat Delta, plus
registrable `NodeParser`s that could make tables and math editable
instead of opaque. Rejected on everything around it:

- pub.dev reports `INCOMPLETE PACKAGE ANALYSIS`, 60/160, platform support
  0/20 and static analysis 0/50 against Flutter 3.47.4 / Dart 3.13.3 —
  this app's toolchain. Last release was 9 months old; `main` targets
  Flutter 3.38. Adopting it means pinning a git ref, with 117 open issues
  behind it.
- Dual MPL-2.0 / AGPL-3.0 against this app's MIT. MPL is the workable
  branch, but the choice would have to be deliberate and recorded.
- 21 direct dependencies, including `pdf`, `http`, `file_picker`,
  `universal_html` and `provider` — in an app on Riverpod with an
  encrypted sync story.

### super_editor

Last stable release 0.2.7, two years old; only `0.3.0-dev.*` since, and
the maintainers direct users to depend on the GitHub repo. Same git-pin
liability as appflowy_editor, without a published release to fall back
on.

## Still open

**`fleather` 1.28.0** is the one candidate not yet measured. It is the
Zefyr successor on the Parchment model — still Quill Delta underneath,
which is the point: the existing codec would *port* rather than be
rewritten, and `parchment`'s `codecs` library already ships a
`ParchmentMarkdownCodec` to compare against. MIT/BSD-3, 193 likes,
13.3k weekly downloads, 160/160 points, and a dependency list an order of
magnitude lighter than appflowy_editor's.

**`flutter_quill` itself was never put on this bench.** So what is
established is that these candidates are slower than the *source* editor,
not that they are slower than *what the app ships*. The 200 KB cap in
[wysiwyg_editor.dart](../../lib/src/editor/wysiwyg/wysiwyg_editor.dart)
exists because Quill is not cheap either. Measuring the incumbent — mount
`WysiwygEditor` on this fixture, reusing the setup in
[wysiwyg_editor_test.dart](../../test/widget/wysiwyg_editor_test.dart) —
is what would turn "worse" into "a regression" or "a wash", and it is the
first thing the next evaluation should do.

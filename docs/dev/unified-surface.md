# Unified Markdown surface — research and design

**Status:** research dossier and design proposal. No code yet.
**Branch:** `feat/unified-markdown-surface` (cut from remote `main` @ `16691f7`).
**Date:** 2026-09-20.
**Scope:** replace the source editor, the WYSIWYG editor and the preview with
one widget, written from scratch in pure Flutter/Dart, uniform in
functionality, performance and visual rendering, supporting CommonMark, GitHub
Flavored Markdown, wikilinks, inline math and block math, and fast on
`Geometria 1.md` (934 769 bytes, 10 331 lines, **13 845 math spans** —
841 display blocks and 13 004 inline — measured, §5.4).

---

## The verdict in six sentences

1. **The design that satisfies all the constraints is one widget with three
   *modes* (`source`, `live`, `read`) over one pipeline**, where the note's
   Markdown text is the only document, the parse tree is derived and
   disposable, and the three modes differ only in which characters are
   rendered, whether there is a caret, and whether prose is monospaced
   ([§8](#8-the-proposal-one-surface-three-modes)). This is the only model that satisfies the repo's "disk is source
   of truth" rule without a lossy serialization codec.
2. **The performance answer is not a new trick — it is the app's own existing
   tricks, generalized**: an O(change) line-state tokenizer whose keystroke
   chain is already flat at 0.30 / 0.28 / 0.37 ms across 200 KB / 500 KB /
   934 KB, a block/inline parse
   split that already measures 14 ms vs 378 ms on the 934 KB note, and a
   frozen-extent height map that already renders only the visible blocks. The
   rewrite's job is to make *all three modes* run on them, which is what
   removes the WYSIWYG's 200 KB cap (below which, measured, it does not even
   open any of this repo's fixtures), the preview's 137–182 ms wait for first
   content, and its per-block math cost on the geometry note.
3. **The hardest engineering problem is not the renderer, it is the editable
   text surface**: a custom `TextInputClient` that reports *visual* text while
   the document is *source* text, with a per-block offset map, an Android IME
   that has to be verified on a real device, and no silent data loss. This is
   where the schedule risk lives, and it should be spiked before the plan is
   committed to.
4. **The parser is measured, not written (D2) — and the measurement is in.**
   The pure-Dart `markdown` package scores **645/652 on CommonMark 0.31.2 and
   662/677 on GFM** ([§4.9](#49-the-markdown-package-measured)), with 22
   examples triaged: 8 to fix, 14 pinned because they are serializer details or
   spec quirks that never reach the user. `highlight` stays as the code
   *grammar* engine with its rendering path removed. That takes 23–42 days out
   of the estimate — from ~140–245 to ~121–210 — and two new requirements (the
   export seam, and removing the split preview) take 5–9 of it back.
5. **The rewrite also deletes real duplication**: today the same find bar,
   list tally, context menu, formatting commands, active-format computation
   and link handling are implemented once per surface, with slightly different
   behaviour. One widget collapses each of those rows to one implementation —
   and the cross-engine scroll sync the split preview needed is deleted
   outright rather than kept in step (D4).
6. **It is a 6–10 month project for one engineer, and it can be stopped at any
   phase boundary.** `read` mode alone (Phase 2) fixes the preview's wait for
   first content, the math cost and the size cap, and is worth shipping on its
   own.

## How to read this document

| If you want… | Read |
|---|---|
| what was asked and what it costs | [§1](#1-the-mandate) |
| what exists today, with its own measured numbers | [§2](#2-where-we-are-today) |
| every behaviour that must not regress | [§3](#3-the-feature-contract-what-must-not-regress) |
| the syntax that must be supported, exactly | [§4](#4-the-specification-commonmark-and-gfm) |
| how bad the real documents actually are | [§5](#5-the-corpus-reality) |
| what Flutter/Dart gives you to build on | [§6](#6-the-primitives-available) |
| what the best editors in the world do | [§7](#7-prior-art-what-to-steal) |
| **the proposal** | [**§8**](#8-the-proposal-one-surface-three-modes) |
| the numbers the implementation must hit | [§9](#9-the-performance-budget) |
| the plan, the effort, the levers | [§10](#10-effort-and-phasing) |
| what can go wrong, and the questions to answer | [§11](#11-risks-alternatives-and-open-questions) |
| inventory, sources, glossary, repro scripts | [§12](#12-appendix) |
| the incumbent's numbers in full, with the harness | [§13](#13-annex-the-incumbent-baseline-measured-in-full) |

Statements are labelled by provenance throughout: **measured** (a command was
run, the command is given), **read** (from the repo, a spec or a source, with a
link), or **proposed** (the author's design judgement). §12.5 explains the
method.

## Table of contents

  - [The verdict in six sentences](#the-verdict-in-six-sentences)
  - [How to read this document](#how-to-read-this-document)
- [1. The mandate](#1-the-mandate)
  - [1.1 What was asked](#11-what-was-asked)
  - [1.2 What that decomposes into](#12-what-that-decomposes-into)
  - [1.3 The repo's own rules that constrain the answer](#13-the-repos-own-rules-that-constrain-the-answer)
  - [1.4 What keeping the two pure-Dart engines changes](#14-what-keeping-the-two-pure-dart-engines-changes)
  - [1.5 The decisions, and what each one changes](#15-the-decisions-and-what-each-one-changes)
- [2. Where we are today](#2-where-we-are-today)
  - [2.1 The three surfaces, and the code that exists for them](#21-the-three-surfaces-and-the-code-that-exists-for-them)
  - [2.2 What the code already measured (and what it says to keep)](#22-what-the-code-already-measured-and-what-it-says-to-keep)
  - [2.3 The existing assets worth porting, not discarding](#23-the-existing-assets-worth-porting-not-discarding)
- [3. The feature contract: what must not regress](#3-the-feature-contract-what-must-not-regress)
  - [3.1 The drop-in contract: what the one widget must answer](#31-the-drop-in-contract-what-the-one-widget-must-answer)
  - [3.2 The overlap: what the rewrite actually deletes](#32-the-overlap-what-the-rewrite-actually-deletes)
- [4. The specification: CommonMark and GFM](#4-the-specification-commonmark-and-gfm)
  - [4.1 Versions and where they live](#41-versions-and-where-they-live)
  - [4.2 Block-level element inventory](#42-block-level-element-inventory)
  - [4.3 Inline-level element inventory](#43-inline-level-element-inventory)
  - [4.4 The emphasis algorithm in executable detail](#44-the-emphasis-algorithm-in-executable-detail)
  - [4.5 Spec test suite](#45-spec-test-suite)
  - [4.6 Extension zone — what CommonMark/GFM deliberately do not cover](#46-extension-zone--what-commonmarkgfm-deliberately-do-not-cover)
  - [4.7 Round-trip fidelity requirements](#47-round-trip-fidelity-requirements)
  - [4.8 Recommended conformance strategy](#48-recommended-conformance-strategy)
  - [Appendix A — Quick reference constants for the Dart implementation](#appendix-a--quick-reference-constants-for-the-dart-implementation)
  - [Appendix B — Sources](#appendix-b--sources)
  - [4.9 The `markdown` package measured](#49-the-markdown-package-measured)
- [5. The corpus reality](#5-the-corpus-reality)
  - [5.1 Global stats](#51-global-stats)
  - [5.2 Block-level census](#52-block-level-census)
  - [5.3 Inline-level census](#53-inline-level-census)
  - [5.4 Math deep-dive](#54-math-deep-dive)
  - [5.5 Structural worst cases](#55-structural-worst-cases)
  - [5.6 Scroll/layout sizing model](#56-scrolllayout-sizing-model)
  - [5.7 A synthetic "worst note" spec and fixture](#57-a-synthetic-worst-note-spec-and-fixture)
  - [5.8 Summary of the numbers that should drive the design](#58-summary-of-the-numbers-that-should-drive-the-design)
- [6. The primitives available](#6-the-primitives-available)
  - [6.0 Executive summary of the cost model](#60-executive-summary-of-the-cost-model)
  - [6.1 Text layout & painting cost model](#61-text-layout--painting-cost-model)
  - [6.2 Building a custom render/viewport](#62-building-a-custom-renderviewport)
  - [6.3 Editable text from scratch](#63-editable-text-from-scratch)
  - [6.4 Making text look native-quality without HTML](#64-making-text-look-native-quality-without-html)
  - [6.5 Math rendering without a package](#65-math-rendering-without-a-package)
  - [6.6 Syntax highlighting without a package](#66-syntax-highlighting-without-a-package)
  - [6.7 Isolates and parsing off the UI thread](#67-isolates-and-parsing-off-the-ui-thread)
  - [6.8 A concrete performance budget](#68-a-concrete-performance-budget)
  - [6.9 Traps and known Flutter pitfalls](#69-traps-and-known-flutter-pitfalls)
  - [6.10 Suggested module layout for the new widget](#610-suggested-module-layout-for-the-new-widget)
  - [6.11 Source index (for follow-up reading)](#611-source-index-for-follow-up-reading)
- [7. Prior art: what to steal](#7-prior-art-what-to-steal)
  - [7.1 The three candidate architectures](#71-the-three-candidate-architectures)
  - [7.2 CodeMirror 6, mechanism by mechanism](#72-codemirror-6-mechanism-by-mechanism)
  - [7.3 Incremental parsing: Lezer, tree-sitter, and the *minimum* for Markdown](#73-incremental-parsing-lezer-tree-sitter-and-the-minimum-for-markdown)
  - [7.4 ProseMirror and Lexical: the position-mapping idea](#74-prosemirror-and-lexical-the-position-mapping-idea)
  - [7.5 Live preview in the wild](#75-live-preview-in-the-wild)
  - [7.6 Virtualized document rendering in other ecosystems](#76-virtualized-document-rendering-in-other-ecosystems)
  - [7.7 Math rendering: KaTeX and MathJax](#77-math-rendering-katex-and-mathjax)
  - [7.8 Syntax highlighting prior art](#78-syntax-highlighting-prior-art)
  - [7.9 What Niman already does that must be carried over](#79-what-niman-already-does-that-must-be-carried-over)
  - [7.10 Ideas worth stealing](#710-ideas-worth-stealing)
- [8. The proposal: one surface, three modes](#8-the-proposal-one-surface-three-modes)
  - [8.1 The shape of the answer](#81-the-shape-of-the-answer)
  - [8.2 The document model: the source text *is* the document](#82-the-document-model-the-source-text-is-the-document)
  - [8.3 One typography, one block metric set](#83-one-typography-one-block-metric-set)
  - [8.4 Layout: only the blocks the viewport shows](#84-layout-only-the-blocks-the-viewport-shows)
  - [8.5 The parser: incremental, two-phase, line-oriented](#85-the-parser-incremental-two-phase-line-oriented)
  - [8.6 Inline rendering: change styles, not characters](#86-inline-rendering-change-styles-not-characters)
  - [8.7 Editing mechanics](#87-editing-mechanics)
  - [8.8 The two specialised renderers](#88-the-two-specialised-renderers)
  - [8.9 What replaces what](#89-what-replaces-what)
  - [8.10 How each requirement is met, concretely](#810-how-each-requirement-is-met-concretely)
  - [8.11 A sketch of the public API](#811-a-sketch-of-the-public-api)
- [9. The performance budget](#9-the-performance-budget)
  - [9.1 How to read a number in this project](#91-how-to-read-a-number-in-this-project)
  - [9.2 The budget, by operation](#92-the-budget-by-operation)
  - [9.3 The legacy baseline to beat (measured)](#93-the-legacy-baseline-to-beat-measured)
  - [9.4 The benchmark harness the implementation must ship with](#94-the-benchmark-harness-the-implementation-must-ship-with)
  - [9.5 Memory budget](#95-memory-budget)
  - [9.6 Regression gates](#96-regression-gates)
- [10. Effort and phasing](#10-effort-and-phasing)
  - [10.1 The rule that shapes the plan](#101-the-rule-that-shapes-the-plan)
  - [10.2 What the decisions do to the effort](#102-what-the-decisions-do-to-the-effort)
  - [10.3 The stages](#103-the-stages)
  - [10.4 What to spike first, before committing to the plan](#104-what-to-spike-first-before-committing-to-the-plan)
  - [10.5 How this lands in the repo's workflow](#105-how-this-lands-in-the-repos-workflow)
- [11. Risks, alternatives and open questions](#11-risks-alternatives-and-open-questions)
  - [11.1 The risks, ranked by what they would cost](#111-the-risks-ranked-by-what-they-would-cost)
  - [11.2 Alternatives considered, and why they lose](#112-alternatives-considered-and-why-they-lose)
  - [11.3 The open questions, and what was answered](#113-the-open-questions-and-what-was-answered)
  - [11.4 What would make this project fail, in one sentence each](#114-what-would-make-this-project-fail-in-one-sentence-each)
- [12. Appendix](#12-appendix)
  - [12.1 Source inventory of the surfaces being replaced](#121-source-inventory-of-the-surfaces-being-replaced)
  - [12.2 The dependency ledger](#122-the-dependency-ledger)
  - [12.3 Canonical references](#123-canonical-references)
  - [12.4 Glossary](#124-glossary)
  - [12.5 How this document was produced, and how to reproduce it](#125-how-this-document-was-produced-and-how-to-reproduce-it)
  - [12.6 First-day checklist](#126-first-day-checklist)
- [13. Annex: the incumbent baseline, measured in full](#13-annex-the-incumbent-baseline-measured-in-full)
  - [13.1 Environment and method](#131-environment-and-method)
  - [13.2 Results](#132-results)
  - [13.3 Complexity analysis (from the numbers)](#133-complexity-analysis-from-the-numbers)
  - [13.4 Headline table the new implementation must beat](#134-headline-table-the-new-implementation-must-beat)
  - [13.5 Reproducibility](#135-reproducibility)
  - [13.6 Caveats — why these numbers are not device reality](#136-caveats--why-these-numbers-are-not-device-reality)


---

# 1. The mandate

## 1.1 What was asked

Replace the three components that today act as **source editor**, **WYSIWYG
editor** and **preview** with **one widget** that is uniform in
**functionality, performance and visual rendering**. It must keep supporting
everything the app supports today — **CommonMark**, **GitHub Flavored
Markdown**, **wikilinks**, **inline math** and **block math**. No existing
package may be adopted: the implementation is to be written from scratch and
kept as **pure Flutter/Dart as possible**. It must stay fast on adversarial
real documents, with `Geometria 1.md` (934 769 bytes, 10 331 lines,
13 845 math spans — 841 display blocks and 13 004 inline) as the named worst
case. Everything learned and thought
through goes into one Markdown file. The work happens on an ad-hoc branch cut
from remote `main`.

## 1.2 What that decomposes into

| # | Requirement | How it is read here | Where it is answered |
|---|---|---|---|
| R1 | One widget, not three | A single `MarkdownSurface` widget with a mode (`source` / `live` / `read`), one controller, one set of callbacks, one theme, one viewport machinery. The three modes are *policies* over one pipeline, not three engines. | [§8](#8-the-proposal-one-surface-three-modes) |
| R2 | Uniform functionality | Every behaviour that exists today — formatting, find/replace, folding, outline, word count, list tally, context menu, tools, spellcheck, clipboard, links, images, embeds, typewriter, Zen, column, line numbers, per-tab state, undo — works in every mode, from the same code path. | [§3](#3-the-feature-contract-what-must-not-regress), [§8.9](#89-what-replaces-what) |
| R3 | Uniform performance | One windowing/layout/paint engine for all three modes. No mode may have a size cap the others do not (the WYSIWYG's 200 KB cap today), and no mode may have a different complexity class. | [§8.4](#84-layout-only-the-blocks-the-viewport-shows), [§9](#9-the-performance-budget) |
| R4 | Uniform visual rendering | One typography and block-metrics model shared by all modes, so the same note reads the same in source, live and read. No more three different stylesheets. | [§8.3](#83-one-typography-one-block-metric-set) |
| R5 | Full syntax support | CommonMark + GFM + wikilinks + `$…$` + `$$…$$` + YAML frontmatter, plus footnotes, tags and the app's link/embed rules. | [§4](#4-the-specification-commonmark-and-gfm), [§5](#5-the-corpus-reality) |
| R6 | No UI packages | No package may own the surface: own renderer, own editor, own viewport, own math typesetter. `flutter_quill`, `re_editor`, `flutter_markdown_plus`, `flutter_highlight`, `katex`, `katex_dart` and the already-dead `flutter_smooth_markdown` all go. **The two pure-Dart engines stay** (D2): `markdown` as the CommonMark/GFM parser and `highlight` as the code lexer. | [§1.4](#14-what-keeping-the-two-pure-dart-engines-changes), [§4.8](#48-recommended-conformance-strategy), [§10.2](#102-what-the-decisions-do-to-the-effort) |
| R7 | Pure Flutter/Dart | Only `dart:ui` (`TextPainter`, `Paragraph`, `Canvas`), `package:flutter/widgets|rendering|material`, `dart:isolate`, `dart:typed_data` and fonts shipped as assets. No plugin, no native code, no FFI, no web view. | [§6](#6-the-primitives-available) |
| R8 | Fast on `Geometria 1.md` | Concrete, asserted budget: cold open, first frame, per-keystroke, scroll frame, jump, math render, memory. | [§9](#9-the-performance-budget), [§5](#5-the-corpus-reality) |

## 1.3 The repo's own rules that constrain the answer

From `AGENTS.md` and `docs/dev/conventions.md`, all of which the proposal must
satisfy rather than argue with:

- **Disk is source of truth.** One note = one `.md`. Nothing may be stored
  that cannot be rebuilt from the file. This is the single most important
  constraint on the document model: a Delta-like or tree-like in-memory
  document that is *serialized* on save is out; the source text must be the
  document.
- **No O(n) full scans on hot paths.** Target: 1 M notes and novel-length
  files.
- **No disk I/O on the UI isolate.**
- **No god classes**: one class per file, split at ~300 lines.
- **Every platform ships every feature** — Android, Linux, Windows in the same
  round. A surface that is fast on desktop and unusable on a phone is not
  acceptable.
- **The keep-its-place interface rule**: a control that shows only in some
  states keeps its place.
- **English everywhere**, docs updated in the same PR, one logical change per
  commit.

## 1.4 What keeping the two pure-Dart engines changes

Measured on this checkout with `flutter pub deps --json`: the seven
surface packages (`flutter_quill`, `re_editor`, `flutter_markdown_plus`,
`katex`, `katex_dart`, `flutter_highlight`, `flutter_smooth_markdown`) pull in
a dependency closure of **122 packages**. Of the 235 packages in the graph,
**55 (23 %) are reachable only through the surface stack** — including
`quill_native_bridge_*` (native code compiled into every one of the seven
platforms), `sqflite` (a second SQLite, on top of the `sqlite3` the index
already bundles), `flutter_svg`, `vector_graphics*`, `cached_network_image`,
`flutter_cache_manager`, `provider`, `flutter_colorpicker`, `html`, `csslib`,
`isolate_manager`, `isolate_contactor`, `rxdart`, `diff_match_patch`,
`flutter_math_fork`, `file_selector_*` and `flutter_keyboard_visibility_*`.

Building the surface from scratch removes those 55 packages and the seven
direct dependencies, plus ~10 500 lines of Niman code that exists to bridge
those packages' models to Markdown (`wysiwyg/markdown_document_codec.dart`,
`wysiwyg/quill_*`, `preview/block_parse.dart`'s glue, the three separate find
controllers, three separate toolbars' dispatch).

**Decided (D2, 2026-09-20): `markdown` and `highlight` stay.** Neither pulls
native code, so neither compromises R7, and keeping them removes the single
largest work item in this document. What changes is not *whether* the surface
is written from scratch — it still is — but where the parser comes from:

- **`markdown` 7.3.1 becomes the CommonMark/GFM engine**, and Phase 1 stops
  being "write a conformant parser" and becomes **measure and close the gap**:
  run the spec suite against it, enumerate and pin every failure, and fix only
  what the app actually needs ([§4.8](#48-recommended-conformance-strategy)).
  That is days, not weeks — and it is the biggest single lever in this
  document ([§10.2](#102-what-the-decisions-do-to-the-effort)).
- **What it does not remove.** The package has no incremental API, so the
  line-state block scanner and the lazy per-block inline phase
  ([§8.5](#85-the-parser-incremental-two-phase-line-oriented)) are still
  Niman's — the package is called *per block*, on already-bounded input, never
  over the document. The single-token-source invariant for links
  ([§2.3](#23-the-existing-assets-worth-porting-not-discarding)) is still
  Niman's, and the extensions the package does not know (wikilinks, math
  delimiters, frontmatter) are still Niman's.
- **`highlight` stays as the code *grammar* engine, not as the renderer.**
  Its measured hazards are unchanged and must be contained
  ([§8.8.2](#882-code-a-line-state-lexer-not-a-whole-block-regex), K13):
  never call `Result.toHtml()` (super-quadratic: 100 KB → 6 869 ms), never lex
  more than the visible or changed lines, and guard the input, because Dart
  has no regex timeout and the `cpp` grammar is O(n²) on adversarial input.
  The line-state driver and the line cache are Niman's either way; the
  package supplies the language rules.

## 1.5 The decisions, and what each one changes

Recorded 2026-09-20, from the user's answers. Everything below is settled
unless it says otherwise, and the rest of this document assumes it.

| # | Decision | Answer | What it changes here |
|---|---|---|---|
| D1 | One widget with three modes, or three widgets over one engine? | **One widget, three modes** (`source` / `live` / `read`) | [§8](#8-the-proposal-one-surface-three-modes) stands as designed. The chrome (toolbar, find, context menu, tools) is one implementation, which is what R2 rides on. |
| D2 | Does "no packages" include the pure-Dart `markdown` and `highlight`? | **They may stay.** `markdown` is the parser, `highlight` the code lexer | Phase 1 becomes *measure and close the gap* instead of *write a parser*: **−23 to −42 days** (the parser workstreams), the largest single lever here. **Measured on 2026-09-21: 645/652 CommonMark and 662/677 GFM**, with 22 examples triaged (8 to fix, 14 pinned) — see [§4.9](#49-the-markdown-package-measured) ([§1.4](#14-what-keeping-the-two-pure-dart-engines-changes), [§10.2](#102-what-the-decisions-do-to-the-effort)). The incremental scanner, the extensions and the token-source invariant are still Niman's. |
| D3 | Does `editorKind` (`source` \| `wysiwyg`) survive? | **Yes, as a mode** — which mode a note opens in; `both` becomes the switch | No user-visible setting is removed. The mode switch replaces the eye and the `editorKind` toggle, and both keep their place in the row. |
| D4 | Is the split preview still two panes? | **No — the side-by-side preview is rejected.** If `live` is a good interactive preview, a preview pane beside the editor is redundant | The preview becomes a **mode**, not a pane. Concretely: `previewEnabled`, the split ratio and the `source`\|`preview` split go from the settings and the UI, and with them the cross-engine scroll sync — `preview/scroll_sync.dart`, `preview/editor_lines.dart` and the `onIndicator` contract are **deleted, not generalized** (§3.2, §8.9). The two-*pane* split (two notes side by side, `Ctrl+\`) is a different feature and stays. |
| D5 | Conformance target | **100 % of CommonMark 0.31.2 and the published GFM examples — plus the math** | The spec suite is the gate for the syntax ([§4.8](#48-recommended-conformance-strategy)); for math, the gate is **golden boxes against today's `katex_dart`** over every distinct expression in the corpus, because D8 fixes the target as what the app renders now. |
| D6 | Is `Geometria 1.md` committed as a fixture? | **No** | The adversarial fixture is generated instead ([§5.7](#57-a-synthetic-worst-note-spec-and-fixture)); the real note stays out of git, and the math corpus for the golden test is extracted from it, not committed whole. |
| D7 | HTML paste | **Kept** | One own HTML→Markdown converter (~300–500 lines, [§10.2](#102-what-the-decisions-do-to-the-effort)), because `docs/user/editing.md` promises that a pasted styled page arrives formatted. |
| D8 | Math rendering | **What the app renders today is what is wanted.** The typesetter is replaced for the dependency reason, not to change the look | The KaTeX TTFs the packages already vendor must be **kept and bundled** (Android ships no math font at any API level, [§6.5.7](#657-math-fonts-availability-licensing-bundling)); the golden-file diff against `katex_dart` is the acceptance test ([§8.8.1](#881-math-own-tex-layout)). |
| D9 | What does `live` mode reveal, and when? | **`live` is literally an interactive preview**: only the caret's **line** — or even just the **word** — temporarily becomes source, Obsidian-style | The reveal policy is [§8.6.2](#862-the-marker-reveal-policy)'s policy A, with per-word as a refinement. This is affordable *because* markers are hidden by style and not by removal: revealing changes a style run, not the text, so the layout cache and the caret's offsets stay valid ([§8.6.0](#860-the-two-ways-to-hide-a-marker)). |
| D10 | Acceptance bar for "uniform performance" | **`source` must be very fast; the other modes as close as they can get** | `source` is the mode with no math layout and no hidden-run overhead, so it is the floor, and the budget in [§9.2](#92-the-budget-by-operation) holds it to the legacy numbers or better. `live`/`read` are judged against `source`, not against each other. |
| D11 | Platform order | **Both desktop and Android must work**; the order is ours to choose | Desktop first for measurement (the benchmark runs there and the numbers are comparable), with the **Android IME spike running in parallel from day one** — it is the risk that can cancel the plan (§10.4, spike 2). |
| D12 | Export/print/PDF | **Will be required** | The renderer must be able to paint a whole note to an offscreen `PictureRecorder` at an arbitrary width, not only into a viewport. Cheap to allow for now and expensive to retrofit, so it is a design constraint from Phase 2 ([§8.7.7](#877-the-export-seam)). |
| D13 | One widget for every note kind? | **Markdown only.** The other kinds (list notes, audio notes) keep their own UI, separate from this widget | `MarkdownSurface` takes no pluggable block-kind registry. `ui/kinds/` stays as it is, and the note view keeps branching on the frontmatter kind. |

| D14 | How much of `highlight` do we keep? — *decided here on the user's behalf, since they asked for whatever serves the objective* | **All of it as the lexer: the language modules stay, the driver and the renderer are Niman's, and the whole thing is bounded and measured before anything is rewritten.** No hand-written lexers unless a number says otherwise | `highlight` supplies the ~190 declarative language grammars, which is weeks of grunt work for no user-visible gain. What must not survive is its *usage*: `parse()` over a whole block and then `toHtml()` is super-quadratic (100 KB → 6 869 ms) and its grammars have **no regex timeout**, so a pasted note can hang the app. So: lex the **visible or changed block only**, cache by `(block revision, language)`, build spans from the token stream and never call `toHtml()`, never use `autoDetection` (the fence's info string names the language, or nothing is coloured), and cap the input — a block past N bytes/lines or a line past M chars renders plain. **The decision point is a number**: the adversarial fixture's 2 000-line fence, against [§9.2](#92-the-budget-by-operation)'s 1 ms. If one edit inside it costs more, the fallback is line-state lexers for the top ~15 languages with `highlight` demoted to the long tail — a change confined to one interface ([§8.8.2](#882-code-a-line-state-lexer-not-a-whole-block-regex)). |
| D15 | Target release | **None.** Build it, then decide when to integrate | No deadline is forcing a big-bang cut, which has one consequence worth naming: nothing *external* pushes us off the legacy surfaces, so the rule that **each phase deletes the legacy surface whose mode it migrated** becomes more important, not less. Every phase boundary must leave the app shippable, and the feature flag is what makes that true. |


---

# 2. Where we are today

## 2.1 The three surfaces, and the code that exists for them

| Surface | Package it rides | Niman's own code | Widget | State class |
|---|---|---|---|---|
| Source editor | `re_editor` 0.10.0 | incremental tokenizer (`highlighting.dart`, 915 lines), `highlight_sync.dart` (302), `md_editing.dart` (364), `list_tally*` (481), folding (178), outline (76), find panel (305), toolbar (120 + 143 + 90), context menu (241), shortcuts (133), typewriter scroll (85), note column (95), `markdown_chunks.dart` | `NoteEditor` | `StatelessWidget` |
| WYSIWYG | `flutter_quill` 11.5.1 | Markdown codec (`markdown_document_codec.dart` 496 + `markdown_blocks.dart` 152), opaque embeds (63), clipboard (190 + 105), Quill commands (175), Quill tally (238), own find controller + panel (166 + 193) | `WysiwygEditor` | `WysiwygEditorState` |
| Preview | `flutter_markdown_plus` 1.0.12 + `markdown` 7.3.1 | block-phase parser (`block_parse.dart` 294), windowing + builders (`markdown_preview.dart` 630), height map (`scroll_map.dart` 535), scroll sync (`scroll_sync.dart` 299 + `editor_lines.dart` 132), math (429 + 156 + 146), code highlight (67), HTML table fixups (159), aspect images (154), wikilink render (216), off-thread work (`preview_work.dart` 129) | `MarkdownPreview` | `_MarkdownPreviewState` |

Totals: **11 814 lines** across `lib/src/{editor,preview,links,frontmatter}`, of
which roughly **4 600** are source-editor, **2 500** WYSIWYG, **3 400**
preview, and the rest shared (`links/`, `frontmatter/`). **38 test files /
8 651 lines** exercise those surfaces (of 48 970 test lines in the repo).

The three are wired together in exactly one place,
`lib/src/ui/note_view.dart` (`_NoteViewState`, 2 225 lines): `_editorPane()`
chooses `WysiwygEditor` or `NoteEditor` from `widget.showWysiwyg`, and
`_buildPreview()` mounts `MarkdownPreview` beside them. Everything else —
toolbar, format menu, find, tools, spellcheck, links, tabs — is dispatched
*from that State into whichever surface is up*, and each surface answers
through a different interface. That dispatch layer is where most of the
"uniformity" problem actually lives.

## 2.2 What the code already measured (and what it says to keep)

These numbers are in the source comments and in
[`docs/dev/editor-alternatives.md`](../../docs/dev/editor-alternatives.md).
They are the baseline; they are also, in two places, the design that the
rewrite should keep rather than reinvent.

| Measurement | Value | Where | Consequence for the new design |
|---|---|---|---|
| Tokenize 200 KB from cold | 23.95 ms | `editor-alternatives.md` | The tokenizer is a per-line state machine with a state cache; only changed lines re-tokenize. |
| **Incremental edit, mid-buffer, 200 KB** | **0.507 ms** | `editor-alternatives.md` | This is O(change), not O(document). It is the number every candidate failed to beat and the new design must keep. |
| Line layout + paint | 44.7 µs/line | `editor-alternatives.md` | Pay for visible lines only; never lay out the whole buffer. |
| Whole buffer as one `TextSpan` | 52.0 ms | `editor-alternatives.md` | One paragraph per document is not an option. |
| 931 KB note, block phase | 14 ms | `markdown_preview.dart` header | Cheap. Can run off-thread once per change. |
| 931 KB note, inline phase | **378 ms** | `markdown_preview.dart` header | 96 % of the parse. Must stay lazy, per visible block. |
| 931 KB note, read from disk | 44 ms | `preview_work.dart` | Load text, paint, then compute stats. |
| 931 KB note, stats (word count + outline) | **~1.1 s** on device; **38–40 ms** off-thread on desktop | `preview_work.dart` (device log, 2026-09-11); re-measured desktop figure in §9.3 | The outline rides a *full-document highlight*, so the cost is O(bytes) with a large constant — which is why a phone lands at ~1.1 s where an i5 lands at 38 ms. The new tokenizer must make stats incremental, or stats must stop using the tokenizer. |
| 931 KB note, first frame | 0.4 ms | `preview_work.dart` | Proof the windowed design already paints nothing-then-visible; keep that property. |
| Math typesetting, geometry note | **5–6 ms per block** | `math_widget.dart` header | This is what made scrolling stutter; today mitigated by deferring math during scroll (`MathDeferScope`). Re-measured per *expression* in §9.3 (0.077–0.109 ms warm, 0.007 ms cached): the two figures reconcile, because a geometry paragraph carries tens of inline formulas. The fix is not a faster single render — it is rendering only visible blocks and never re-rendering a cache hit. |
| `flutter_markdown_plus` eager render, 200 KB | ~2 100 ms | `markdown_preview.dart` header | Never hand the document to an eager `Column`. |
| `flutter_smooth_markdown` eager preview, 200 KB | 2 769 ms (0.8.1: 2 781 ms) | `editor-alternatives.md` | Already a dead dependency: nothing in `lib/` imports it. |
| WYSIWYG size cap | **200 KB** (`_maxWysiwygBytes`) | `wysiwyg_editor.dart` | A mode-specific cap is exactly the non-uniformity R3 forbids; the new surface must have none. |
| `live_markdown_editor` keystroke, 200 KB | 422.4 ms (O(n), ~2 ms/KB) | `editor-alternatives.md` | The rejected architecture: re-parse everything per keystroke. Explicitly not the design. |
| Preview sync parse limit | 64 KB (`_syncParseLimit`) | `markdown_preview.dart` | Below this the parse is synchronous; above it goes to the isolate. |

**On the 0.507 ms.** That is the figure of record in
`editor-alternatives.md`, and it was measured through
`HighlightDocument.replace` — the offset-edit API, not the app's keystroke
path. The re-measurement for this document ([§9.3](#93-the-legacy-baseline-to-beat-measured))
splits it: the **real keystroke chain** (a controller edit plus the synchronous
`EditorHighlightSync` listener) is **0.296 ms best / 0.319 ms median** at
200 KB and stays flat at 0.277/0.357 (500 KB) and 0.372/0.458 (934 KB), while
the offset-edit API alone measures 0.462/1.026. Two consequences: the bar is a
*flat* ~0.3–0.5 ms across a 4.5× size range rather than a single number, and
the offset-edit path is the **O(lines)** one (it rewrites the whole
`_lineStarts` index) — a reminder not to reintroduce an offset-based edit
model in the replacement without doing the same accounting.

## 2.3 The existing assets worth porting, not discarding

The rewrite is not a green field. Four pieces of Niman code are already the
right shape and should be carried over nearly intact:

1. **The incremental tokenizer** (`editor/highlighting.dart`). It is a
   line-oriented state machine: each line gets a `_State` (`fence`,
   `inMath`, `inFrontmatter`), tokens are cached per line, and
   `HighlightDocument.replaceLines` re-tokenizes only what moved. This is
   precisely CodeMirror 6's `StreamLanguage`/`Lezer` idea, already in Dart,
   already O(change), already measured at 0.507 ms. It already knows about
   fences, inline math, display math, frontmatter, headings, lists, task
   boxes, blockquotes, rules, links, images, wikilinks, tags, code spans,
   emphasis and strikethrough — i.e. it is ~80 % of a block *and* inline
   scanner. **Port it, generalize it, and make it the single token source.**

2. **The single-parse-rule invariant for links** (`links/parser.dart`). It
   explicitly reads *over the shared tokenizer* so the indexer, the editor's
   Ctrl+click and the preview agree on what a link is, and so links inside
   code fences, math or frontmatter are never links. That invariant is the
   reason the app's behaviour is coherent today, and the new surface must
   inherit it — one tokenizer feeding highlighter, links, indexer, outline,
   tags, spellcheck and rendering.

3. **The height map and two-way line↔pixel mapping** (`preview/scroll_map.dart`).
   `ScrollMap` holds `blockStartLines`, measured `blockHeights`, `_extents`
   frozen on first use, and binary searches for `blockForLine`,
   `previewOffsetForLine`, `lineForPreviewOffset`. It feeds
   `SliverVariedExtentList.itemExtentBuilder` so a jump lays out only the
   blocks it lands on. Its two hard-won lessons are recorded in its own
   comments and must not be re-learned: (a) an unmeasured block's extent must
   be **frozen** on first use, because letting a shared average re-estimate an
   already-placed block makes `SliverVariedExtentList` assert as offsets move
   under the scroll position; (b) without a real total extent the lazy list
   guesses low and every long jump is clamped, which is what once pulled the
   preview away from the editor. **Generalize it into the surface's height
   map, and add what it lacks: a Fenwick/prefix-sum so lookups are O(log n)
   rather than O(blocks).**

4. **The off-thread parse split** (`preview/preview_work.dart`). A top-level
   isolate entry, message-in/message-out of plain strings, deliberately *not*
   `Isolate.run` (its closure carries the `State`'s element and the isolate
   rejects it), with a typed failure object so a failed read is never mistaken
   for text. The block phase runs off-thread, the inline phase per block on
   demand. **Keep the shape; upgrade the payload** — the message today is the
   whole source string, so every keystroke ships 934 KB across the port
   boundary. The replacement should hold a mirror of the buffer in the worker
   and send only the splice.


---

# 3. The feature contract: what must not regress

## 3.1 The drop-in contract: what the one widget must answer

This is the checklist that decides whether the replacement is actually a
drop-in. Every item below is a real call site or a real test today.

### 3.1.1 `NoteEditor`'s constructor (source mode)

`controller: CodeLineEditingController` · `focusNode` · `showLineNumbers` ·
`autofocus` · `fontSize` · `scrollController: CodeScrollController` ·
`findController: CodeFindController` · `findBuilder: CodeFindBuilder` ·
`shortcutsActivators` · `onIndicator: ValueChanged<CodeIndicatorValueNotifier>`
(the laid-out line rows the scroll sync reads) · `spellCheck: EditorSpellCheck`
· `column: NoteColumn` · `formatMenu: FormatMenuBuilder` · `caretWidth` ·
`typewriter`.

Two of these are package types that disappear with `re_editor`
(`CodeLineEditingController`, `CodeIndicatorValueNotifier`); the new widget
owns its own equivalents. `onIndicator` matters: the comment explains that the
editor's `maxScrollExtent` counts unwrapped lines as one row, so a fraction of
it cannot say which line is on screen — **the surface must expose its own
line-level indicator, not a scroll fraction.**

### 3.1.2 `WysiwygEditorState`'s imperative API (live mode)

`requestEditorFocus()` · `openFind({replace})` · `replaceDocumentRange(line,
start, end, replacement)` (the spell panel's fix) · `plainTextLines` ·
`hasFocus` · `scrollOffset` · `scrollController` · `controller` (handed to
`QuillEditorCommands` for the toolbar) · `activeItems:
ValueNotifier<Set<ToolbarItem>>` (what is on at the caret, for the toolbar's
pressed state) · `autoFocus` · `typewriter`.

Note `activeItems` and the toolbar's command dispatch are **the** uniformity
surface: they must work identically in source and read modes, and today they
are reimplemented twice (`quill_editor_commands.dart`,
`md_editing.dart` + `highlight_sync.dart`).

### 3.1.3 `MarkdownPreview`'s constructor (read mode)

`data` · `styleSheet` · `syntaxHighlighter` · `imageBuilder` ·
`checkboxBuilder` · `bulletBuilder` · `builders` · `padding` · `column` ·
`controller: ScrollController` · `onTapLink(text, href, title)` ·
`onWikiLink(WikiRef, display)` · `embedResolver(String) → Future<String?>` ·
`mathStyle` · `mathCache` · `scrollMap` · `imageDirectory`.

### 3.1.4 Behaviour the docs promise and tests pin

- **Tabs and per-tab state**: caret, selection and scroll come back; undo
  history survives a tab moving between panes ("keeping everything, undo
  included"); a very long note keeps its editor only while it is on screen —
  which means the *surface's* state must be cheap to tear down and rebuild,
  and undo must not live inside a scroll-dependent object.
- **Scroll sync** between an editor pane and a preview pane
  (`scroll_map.dart` + `scroll_sync.dart` + `editor_lines.dart`, ~970 lines)
  — today a two-way estimator over two different layout engines.
- **Zen mode**: hides rail/tree/tabs/side panel/toolbar row/status row/line
  numbers, thickens the caret, keeps the preview switchable, keeps the split
  panes alive behind it.
- **Typewriter mode**: the caret's *row* (not line) stays centred, with half a
  screen of room below the last line; wheel/scrollbar scrolling is unaffected
  until the caret moves again.
- **The split preview goes (D4).** Today a pane can show editor *and* preview
  side by side (`splitPreview`, `previewEnabled`, a 0.2–0.8 split ratio, and
  the `auto` behaviour above 600 dp), kept in step by a two-way scroll sync.
  With `live` mode as an interactive preview (D9) that whole axis is
  redundant, so it is removed rather than generalized: the preview becomes the
  `read` **mode** of the same surface, switched like any other mode. This is a
  deliberate, user-visible change and it must land with
  `docs/user/editing.md` updated in the same commit — including the loss of
  `previewEnabled` and the split ratio, and the fact that the two-*pane* split
  (two notes side by side, `Ctrl+\`) is a different feature and stays.
- **Readable line length**: a centred column, on by default, 480–1400 px
  (700 default), shared by both editors *and* the preview, with the toolbar,
  find bar and status row keeping to the same column while their backgrounds
  span the pane; the scrollbar spans the pane and the wheel works from the
  margins.
- **Preview-only pane**: when the preview is the only pane the IME must be
  dismissed (`_dismissKeyboardForPreview`).
- **Ctrl+click on a link in the editor** (mouse only; touch clicks stay
  edit-only) opens it; the caret-landed-token read is retried across a couple
  of frames because the package's tap handler lands late.
- **Clipboard carries Markdown in both editors**, so the same text copies
  identically from either; pasting Markdown into the WYSIWYG restores
  structure; pasting HTML uses the HTML.
- **Tidy the Markdown**: never touches fenced code, tables, math, frontmatter
  or HTML; idempotent; saves first.
- **Enter inside a list** carries the list on in both editors; inside a fence,
  math block or frontmatter it does nothing — and `_isPlainLine` answers that
  from *the highlighter the editor already keeps*, explicitly so the two
  cannot disagree about what a list is. The new surface must keep that
  property: one source of truth for "what is this line".
- **Tools** (`EditorTool.countList`): both editors offer the same tools, and
  an unavailable tool is listed greyed with its reason rather than hidden —
  and `list_tally` + `quill_tally` are today two implementations of one tool.
- **Context menu**: the formatting actions with the same icons, names and
  grouping as the toolbar, with the format at the caret reading as on, applied
  to the selection; right-click (long-press on a phone). Today
  `editor_context_menu.dart` and Quill's own menu are two code paths.
- **Absolute paths and offsets everywhere**: the caret's offset is a source
  offset; `initialCaretOffset` from a template `{{cursor}}` places the caret
  and takes focus; `NoteEditor`/`WysiwygEditor` both accept it.

### 3.1.5 The feature inventory (nothing here may regress)

Formatting: bold, italic, strikethrough, superscript, underline, link, code,
image, heading, bullet list, ordered list, quote, outdent, indent, tools (14
toolbar items). Find/replace with case sensitivity and replace-one/replace-all
through the undoable edit path. Folding by heading section. Outline. Word
count. List tally. Spellcheck: hunspell on desktop, system IME on Android, a
per-library personal dictionary, right-click *Add to dictionary*, a
background-scanned issues panel capped at 200 words with a progress bar.
Links: Markdown links, wikilinks with `#heading` and `|alias`, `![[embed]]`
resolution (library-root, then note-relative, then unique-name via the index),
dead-link note creation. Images: copied into the library, never base64.
Frontmatter: YAML with known fields (`title tags date pinned aliases`).
Math: `$…$` inline, `$$…$$` display, including display math inside lists and
blockquotes. Tags: inline `#tag` shared with the index.

## 3.2 The overlap: what the rewrite actually deletes

The reason a single widget is attractive is measurable in duplication:

| Capability | Source editor | WYSIWYG | Preview |
|---|---|---|---|
| Markdown parse | tokenizer | Markdown→Delta codec + Delta→Markdown | `markdown` package + block phase |
| Find/replace | `find_panel.dart` + `CodeFindController` | `wysiwyg_find_controller.dart` + `wysiwyg_find_panel.dart` | — |
| List tally | `list_tally.dart` + `list_tally_edit.dart` | `quill_tally.dart` | — |
| Context menu | `editor_context_menu.dart` | Quill's own | — |
| Formatting commands | `md_editing.dart` | `quill_editor_commands.dart` | — |
| Active-format state | `highlight_sync.dart` | Quill's selection style | — |
| Link handling | `links/parser.dart` over tokenizer | Quill link attributes | separate wikilink builder |
| Spell underlines | `EditorSpellCheck.rangesFor` | same | — |
| Word count / outline | off the tokenizer | off the Delta | `preview_work` stats |
| Scroll position model | `EditorLineView` | Quill's own | `ScrollMap` |

Every row with three entries is a place where the same user-visible feature is
implemented once per surface and behaves slightly differently. A single widget
collapses each row to one implementation. That — not line count — is the real
argument for R2.


---

# 4. The specification: CommonMark and GFM

Research reference for a hand-written CommonMark + GFM + extensions parser/renderer/editor in pure Dart.
Compiled from primary sources (spec text, `spec.json`, cmark-gfm sources) fetched 2025; every claim below is
traceable to a URL in the section it appears in.

Scope of the target surface: **CommonMark 0.31.2** ⊂ **GFM 0.29-gfm** ⊂ **Niman extensions** (wikilinks, inline math
`$...$`, display math `$$...$$`, YAML frontmatter). Disk is authoritative; the writer never rewrites user bytes.

---

## 4.1 Versions and where they live

### 4.1.1 Version table

| Spec | Version string | Release date | Canonical URL | Machine-readable tests |
|---|---|---|---|---|
| CommonMark | `0.31.2` | 2024-01-28 | https://spec.commonmark.org/0.31.2/ | https://spec.commonmark.org/0.31.2/spec.json |
| CommonMark (latest alias) | `0.31.2` | — | https://spec.commonmark.org/current/ | `.../current/spec.json` |
| CommonMark source (normative text) | `0.31.2` | — | https://spec.commonmark.org/0.31.2/spec.txt | — |
| CommonMark changelog | — | — | https://spec.commonmark.org/changelog.txt | — |
| GFM | `0.29-gfm` | 2019-04-06 | https://github.github.com/gfm/ | **no `spec.json` served (404)**; scrape the HTML (`id="example-N"`) |
| GFM source (spec text) | `version: 0.29` | 2019-04-06 | https://raw.githubusercontent.com/github/cmark-gfm/master/test/spec.txt | parsed by `test/spec_tests.py` |
| GFM reference implementation | — | — | https://github.com/github/cmark-gfm | https://github.com/github/cmark-gfm/tree/master/test |
| CommonMark reference impl (C) | — | — | https://github.com/commonmark/cmark | `test/spec_tests.py` |
| CommonMark reference impl (JS) | — | — | https://github.com/commonmark/commonmark.js | `test/` |
| CommonMark test harness doc | — | — | https://github.com/commonmark/commonmark-spec/blob/master/README.md | `python3 test/spec_tests.py --program $PROG` |

### 4.1.2 Relationship: GFM = CommonMark + 5 extensions (+ a few silent deltas)

The GFM spec states verbatim: *"GFM is a strict superset of CommonMark. All the features which are supported in
GitHub user content and that are not specified on the original CommonMark Spec are hence known as extensions."*
([gfm/spec.txt §1.1](https://github.github.com/gfm/#what-is-github-flavored-markdown))

The **five** extensions, and the only five registered in cmark-gfm's `extensions/core-extensions.c`
([source](https://raw.githubusercontent.com/github/cmark-gfm/master/extensions/core-extensions.c)):

| # | Extension name (cmark-gfm) | GFM spec section | What it adds |
|---|---|---|---|
| 1 | `table` | 4.10 Tables (extension) | Pipe tables with a delimiter row, `:---:` alignment, escaped `\|` |
| 2 | `tasklist` | 5.3 Task list items (extension) | `- [ ]` / `- [x]` marker replaced by a checkbox |
| 3 | `strikethrough` | 6.5 Strikethrough (extension) | `~~text~~` → `<del>`, an extra emphasis delimiter type |
| 4 | `autolink` | 6.9 Autolinks (extension) | Bare `www.` / `http(s)://` / `ftp://` / email autolinking |
| 5 | `tagfilter` | 6.11 Disallowed Raw HTML (extension) | Escape `<` of 9 dangerous tags in HTML output |

`smart` (smart punctuation) exists in cmark-gfm's tree as an optional extension but is **not** part of GFM and is
**not** enabled by GitHub; do not implement it. Renderer-level options that are not syntax: `full-info-string`
(emits `data-meta="…"` for the rest of a fence info string) and `table-prefer-style-attributes`
(`style="text-align: left"` instead of `align="left"`) — see
[`test/extensions-full-info-string.txt`](https://raw.githubusercontent.com/github/cmark-gfm/master/test/extensions-full-info-string.txt)
and [`test/extensions-table-prefer-style-attributes.txt`](https://raw.githubusercontent.com/github/cmark-gfm/master/test/extensions-table-prefer-style-attributes.txt).

### 4.1.3 GFM deviations from CommonMark — measured, not asserted

I diffed all 677 published GFM examples against all 652 CommonMark 0.31.2 examples, section by section, after
normalizing the `→` tab glyph. Result: **shared sections are example-for-example identical except for the
following**. These are the complete deviations an implementer must know.

| # | Kind | GFM spec.txt (cmark-gfm master) | Published GFM HTML (github.github.com/gfm) | CommonMark 0.31.2 |
|---|---|---|---|---|
| D1 | HTML blocks | omits the `<textarea>` type-1 example | omits it too (43 ex. vs CM 44) | CM #171 tests `<textarea>` as a literal HTML block |
| D2 | Link reference definitions | +1 example `[foo]: /url` alone (28 vs 27) | same | — |
| D3 | Raw HTML comments | old HTML4 rule: comment text must not start `>`, `->`, end `-`, or contain `--` | `<!-- not a comment -- two hyphens -->` → **escaped**; `<!-- foo--->` → **escaped**; `<!-->` → **escaped** | WHATWG rule: `<!-->`, `<!--->`, or `<!--`…`-->`; `--` allowed inside (CM #625, #626) |
| D4 | Emphasis | 131 examples (omits CM #354, `*$*alpha.` currency/symbol case) | same, 131 | 132 examples |
| D5 | Links | 87 examples; omits CM #484 `[](./target.md)`, #487 `[]()`, #497 `[link](foo(and(bar))` | same, 87 | 90 examples |
| D6 | Case folding | `[Толпой][Толпой]` / `[ТОЛПОЙ]:` | `[ẞ]` / `[SS]: /url` (CM 0.30's better case-fold test) | CM 0.31.2 has `[ẞ]` |
| D7 | `entity` digit limit | `&#987654321;` (9 digits) in spec.txt | `&#87654321;` (8 digits) | 1–7 decimal digits; 8+ → literal |
| D8 | Example URLs | `http://…` throughout Auto­links/Backslash/Code spans/Emphasis/Links | mixed: `http://` in most, `https://` already in Links | CM 0.31 switched examples to `https://` |
| D9 | Strikethrough | `~~Hi~~ Hello, world!` | `~~Hi~~ Hello, ~there~ world!` → **single `~` also strikes** | n/a |
| D10 | Extended autolinks | 8 autolink-extension examples | 14, adds `mailto:…-`, `mailto:…_`, `xmpp:` suffix cases | n/a |

**Two operational consequences:**

1. **The published GFM HTML is a partial CommonMark-0.30 sync; cmark-gfm's `test/spec.txt` is not.** They differ in
   12 examples (HTML-only) vs 7 (spec.txt-only) — e.g. HTML has `[ẞ]` and `<!-- not a comment -- two hyphens -->`,
   `test/spec.txt` has `[Толпой]` and `<!-- this is a --\ncomment - with hyphens -->`. Pick **one** as the golden
   source and pin it by commit SHA. Recommendation: use the published HTML's 677 examples (that is what
   "0.29-gfm" means to users).
2. **D3 (HTML comments) is the only deviation that changes parsing of common input.** CM 0.31.2 accepts
   `<!--> foo -->` as raw HTML; GFM escapes it. Since Niman wants both, see §4.8 for how to pin this.

Prose-level deltas that are *not* per-example diffs: GFM's spec text is CM 0.29's text for §2–§3, §5.1–5.2, §5.4,
§6.1–6.4, §6.6–6.8, §6.10, §6.12–6.14 — including CM 0.29's `<!--` comment rule (D3) and CM 0.29's "1–7 digits"
wording is *already present* in both (the digit constraint matched; only the test example differs).

---

## 4.2 Block-level element inventory

Two-phase model is mandatory: **phase 1 parses block structure line by line; phase 2 parses the raw text of each
leaf block (paragraph, heading, table cell, link title/destination, info string) for inlines.** Phase 2 needs the
link-reference-definition map, so it runs only after phase 1 completes.
([CM 0.31.2 §Precedence](https://spec.commonmark.org/0.31.2/#precedence),
[Appendix: A parsing strategy](https://spec.commonmark.org/0.31.2/#appendix-a-parsing-strategy))

"Indent" below always means **up to 3 spaces** unless stated otherwise. Tabs advance to the next multiple-of-4
column when measuring indentation, but are preserved literally inside content.

| # | Construct | Syntax trigger | Can interrupt a paragraph? | Contains other blocks? | Tight/loose list interaction | Continuation / laziness | Source |
|---|---|---|---|---|---|---|---|
| B1 | Thematic break | ≤3 spaces + ≥3 of `-`, `_`, `*`, each optionally followed by spaces/tabs, nothing else | **Yes** | No (leaf) | A thematic break inside list-item content is not a list item (List item rule 1, exception 2) | — | [§4.1](https://spec.commonmark.org/0.31.2/#thematic-breaks) |
| B2 | ATX heading | ≤3 spaces + 1–6 `#` + space/tab/EOL + inline content + optional closing run of `#` (preceded by space/tab, followed only by space/tab) | **Yes** | No | Heading in a list item makes the list loose only if separated by blank lines | Closing `#` run is stripped only if preceded by space/tab | [§4.2](https://spec.commonmark.org/0.31.2/#atx-headings) |
| B3 | Setext heading | ≥1 lines of paragraph-eligible text + underline line of `=` (h1) or `-` (h2), ≤3 spaces indent, ≥1 char, trailing spaces/tabs allowed; **underline may not be indented ≥4** | **No** — the underline line cannot interrupt; it retro-fits the paragraph | No | Affects looseness like any paragraph | Text lines must not be interpretable as code fence, ATX, blockquote, thematic break, list item, or HTML block. `---` after a paragraph is a setext h2, not a thematic break | [§4.3](https://spec.commonmark.org/0.31.2/#setext-headings) |
| B4 | Indented code block | ≥4 spaces indent, one or more non-blank lines ("indented chunks") separated by blank lines | **No** — needs a preceding blank line | No; literal text | — | 4 spaces are stripped; trailing line endings kept; internal tabs kept literally | [§4.4](https://spec.commonmark.org/0.31.2/#indented-code-blocks) |
| B5 | Fenced code block | ≤3 spaces + fence (≥3 backticks **or** ≥3 tildes); info string after a backtick fence may not contain a backtick | **Yes** — no blank line needed before or after | No; literal | — | Closing fence: same char, ≥ opening length, ≤3 indent, only spaces/tabs after. Content dedented by up to N (opening indent); unclosed fence runs to end of the *containing block*. Info string is trimmed of leading/trailing spaces/tabs | [§4.5](https://spec.commonmark.org/0.31.2/#fenced-code-blocks) |
| B6 | HTML block type 1 | line begins `<pre`, `<script`, `<style`, `<textarea` (ci) + space/tab/`>`/EOL | **Yes** | No; literal | — | Ends at a line containing `</pre>`/`</script>`/`</style>`/`</textarea>` (ci, **need not match** the start tag), or EOF/container end | [§4.6](https://spec.commonmark.org/0.31.2/#html-blocks) |
| B7 | HTML block type 2 | line begins `<!--` | **Yes** | No; literal | — | Ends at a line containing `-->`. **Grammar of the comment itself follows §6.10 raw-HTML rules (D3).** | §4.6 |
| B8 | HTML block type 3 | line begins `<?` | **Yes** | No; literal | — | Ends at a line containing `?>` | §4.6 |
| B9 | HTML block type 4 | line begins `<!` + ASCII letter | **Yes** | No; literal | — | Ends at a line containing `>` | §4.6 |
| B10 | HTML block type 5 | line begins `<![CDATA[` | **Yes** | No; literal | — | Ends at a line containing `]]>` | §4.6 |
| B11 | HTML block type 6 | line begins `<` or `</` + one of the 62 known block tag names (ci) + space/tab/EOL/`>`/`/>`. Full list: `address article aside base basefont blockquote body caption center col colgroup dd details dialog dir div dl dt fieldset figcaption figure footer form frame frameset h1 h2 h3 h4 h5 h6 head header hr html iframe legend li link main menu menuitem nav noframes ol optgroup option p param search section summary table tbody td tfoot th thead title tr track ul` | **Yes** | No; literal | — | Ends at the next **blank line** (the blank line is not consumed) | §4.6 |
| B12 | HTML block type 7 | line begins a **complete** open tag (any tag name except `pre`/`script`/`style`/`textarea`) or complete closing tag, followed only by spaces/tabs and EOL | **NO** — deliberately cannot interrupt, to avoid wrapped-paragraph tags | No; literal | — | Ends at the next **blank line** | §4.6 |
| B13 | Link reference definition | ≤3 spaces + `[label]` + `:` + optional space/tab/one line ending + destination + optional (space/tab/one line ending + title); nothing else on the line | **No** — a LRD cannot interrupt a paragraph; it may only start one | No; produces no node | A paragraph containing only LRDs produces no output at all | Label: ≥1 non-space char, ≤999 chars, no unescaped `[`/`]`. Normalization: strip brackets → Unicode case fold → strip leading/trailing spaces/tabs/line endings → collapse internal runs to one space. First definition wins | [§4.7](https://spec.commonmark.org/0.31.2/#link-reference-definitions) |
| B14 | Paragraph | any run of non-blank lines not interpretable as another block | — (it is the fallback) | No; inline content | A blank line between two blocks inside a list item makes the list loose | Raw content = lines joined, leading/trailing spaces or tabs removed. Trailing spaces on non-final lines survive as hard-break candidates | [§4.8](https://spec.commonmark.org/0.31.2/#paragraphs) |
| B15 | Blank line | empty, or only spaces/tabs | — | — | Causes looseness when it separates items or blocks within an item | Blank lines inside a fenced code block, an HTML block of type 1–5, or an indented code block do **not** end the block | [§4.9](https://spec.commonmark.org/0.31.2/#blank-lines) |
| B16 | Table (GFM) | a paragraph line (header row) followed by a *delimiter row*; header and delimiter must have **equal cell counts** | Effectively **yes, but only the last paragraph line is consumed** — cmark-gfm converts the paragraph to a table and re-inserts earlier lines as a separate paragraph (`try_inserting_table_header_paragraph`) | No — inlines only; "Block-level elements cannot be inserted in a table" | Rows continue while each new line parses as a row; a table inside a list item obeys the item's indentation | Ends at the first blank line or the start of another block-level structure. Leading/trailing pipes optional; spaces around cell content trimmed; `\|` escapes a pipe, including inside code spans and emphasis. Delimiter cell = `-` chars only, optionally `:`-prefixed and/or `:`-suffixed | [GFM §4.10](https://github.github.com/gfm/#tables-extension), [`extensions/table.c`](https://raw.githubusercontent.com/github/cmark-gfm/master/extensions/table.c) |
| B17 | Block quote (container) | ≤3 spaces + `>` + optional space, or bare `>` | **Yes** | **Yes** — any blocks | A blockquote's inner list has its own looseness | **Laziness:** a line may drop its `>` marker if the next non-space char after the marker position is *paragraph continuation text*. **Consecutiveness:** two block quotes cannot be adjacent without a blank line between them | [§5.1](https://spec.commonmark.org/0.31.2/#block-quotes) |
| B18 | List item (container) | marker + 1–4 spaces of indentation (rules 1/3), or marker + exactly 1 space when the item starts with indented code (rule 2) | **Yes** with exceptions: (a) the item's lines must not begin with a blank line, (b) an ordered marker that interrupts a paragraph must have start number **1** | **Yes** — any blocks | Loose if any two constituent items are separated by a blank line, **or** if any item directly contains two block-level elements with a blank line between them. Tight lists render paragraphs without `<p>` | **Laziness (rule 5):** a paragraph continuation line inside the item may be unindented. Rules 4 (indentation) and 6 ("nothing else is a list item") are the safety nets | [§5.2](https://spec.commonmark.org/0.31.2/#list-items) |
| B19 | List (container) | sequence of ≥1 list items *of the same type*: same bullet char (`-`/`+`/`*`) or same ordered delimiter (`.`/`)`) | — | Yes | See B18. Changing bullet char or delimiter starts a **new list**, not a new item | Items may be separated by any number of blank lines | [§5.4](https://spec.commonmark.org/0.31.2/#lists) |
| B20 | Task list item (GFM) | a list item whose first block is a paragraph beginning with an optional run of spaces + `[` + (whitespace or `x`/`X`) + `]` + ≥1 whitespace before other content | — (it is a list item) | Yes | Counts as item content for looseness | Renders as `<input type="checkbox">` (`checked` unless the marker char is whitespace); marker is removed from the text | [GFM §5.3](https://github.github.com/gfm/#task-list-items-extension-) |
| B21 | YAML frontmatter (**app extension**) | byte 0 of the file is `---` (line 1 exactly `---`, optional trailing spaces/CR) | n/a — it precedes everything | No | n/a | Terminated by a line that is exactly `---` or `...`. **Excluded ranges: from offset 0 through the end of the closing delimiter line, plus its line ending.** If no closing delimiter exists: recommend "not frontmatter" (fall back to a thematic break + paragraph), because treating to-EOF as frontmatter mangles ordinary notes starting with `---` | [Obsidian Properties](https://help.obsidian.md/properties) |

### 4.2.1 List-marker grammar (feeds B18/B19)

| Property | Rule | Source |
|---|---|---|
| Bullet markers | `-`, `+`, `*` | §5.2 |
| Ordered markers | 1–9 arabic digits (`0-9`) + `.` or `)` — **9 max**, because 10 digits overflow in browsers | §5.2 |
| Marker width `W` | length of the marker text (`-` = 1, `1.` = 2, `10.` = 3) | §5.2 rule 1 |
| Padding `N` | 1 ≤ N ≤ 4 spaces after the marker (rule 1); exactly 1 when the item begins with indented code (rule 2); if > 4 spaces the padding is 1 and the rest is content | §5.2 rules 1, 2 |
| Content indent | `W + N` for all subsequent lines (rule 1); `W + 1` for rule 2 | §5.2 |
| Start number | taken from the **first** item's marker; later numbers are ignored entirely | §5.4 |
| Blank-line-only items | allowed; item starting with a blank line gets the "contents = following blocks" treatment of rule 3 | §5.2 rule 3 |
| Interrupt conditions | start number must be 1; no leading blank line; and (from the Lists section) the item must not be empty for a bullet that interrupts | §5.2 rule 1 exc. 1 |

### 4.2.2 Tight vs loose — exact operationalization

```
loose(list) = ∃ itemᵢ, itemᵢ₊₁ separated by ≥1 blank line
           OR ∃ item with ≥2 direct child blocks separated by ≥1 blank line
tight(list) = ¬loose(list)
```

Blank lines *inside* a fenced code block, an indented code block, or a type-1–5 HTML block do not count.
Blank lines inside a *sublist* make the sublist loose; whether they make the outer list loose depends on whether
they separate the outer items or the outer item's direct children. The HTML consequence is `<p>` wrapping only.

---

## 4.3 Inline-level element inventory

### 4.3.1 Precedence (the "which wins" table)

CommonMark resolves conflicts by four stated principles plus a fixed scan order. Implementation order:

| Rank | Element | Beats | Rule |
|---|---|---|---|
| 1 | Backslash escape | everything | `\` + ASCII punctuation → literal punctuation; `\` + anything else → literal `\` |
| 2 | Entity / numeric character reference | literal text | Cannot substitute for a *structural* character (e.g. `&#42;` never becomes an emphasis delimiter) |
| 3 | Code span | emphasis, links, images, HTML | Backtick runs are matched before anything else inside a paragraph |
| 4 | Autolink `<…>` | link, raw HTML | Tried before raw-HTML tag parsing |
| 5 | Raw HTML inline | emphasis | |
| 6 | Link / image (`[…](…)`, `[…][…]`, `[…]`, `![…]`) | emphasis | *"Inline code spans, links, images, and HTML tags group more tightly than emphasis"* — `*[foo*](bar)` → `*<a href="bar">foo*</a>` |
| 7 | Strikethrough `~~…~~` (GFM) | — | Joins the same delimiter stack as `*`/`_` |
| 8 | Emphasis / strong | — | Resolved **last**, over the surviving delimiter stack |
| — | Block structure | **all inlines** | *"Indicators of block structure always take precedence over indicators of inline structure"* |

Sources: [CM §Precedence](https://spec.commonmark.org/0.31.2/#precedence), [CM §6.4 principle 17](https://spec.commonmark.org/0.31.2/#emphasis-and-strong-emphasis).

### 4.3.2 The inline table

| Element | Trigger | Resolution / exact rule | Failure mode |
|---|---|---|---|
| Code span | backtick string: run of ≥1 `` ` `` neither preceded nor followed by a backtick | Match with a backtick string of **equal length**. Content: line endings → spaces; then if the result both begins and ends with a space and is not all spaces, strip exactly **one** space from each end | Unmatched run → literal backticks |
| Emphasis `*`/`_` | delimiter run of 1 `*`/`_` | Left/right flanking + the rule of 3 (§4.4) | |
| Strong `**`/`__` | delimiter run of ≥2 | Same algorithm; `use_delims = (opener≥2 && closer≥2) ? 2 : 1` | |
| Strikethrough `~~` | delimiter run of `~` | GFM: `~~text~~` → `<del>`. A run of exactly 3 (`~~~not~~~`) does **not** strike. The published GFM spec's own example shows a **single** `~there~` also striking (`<del>there</del>`), contradicting the prose "wrapped in two tildes"; cmark-gfm's shared `test/spec.txt` uses `~~Hi~~ Hello, world!` and avoids the ambiguity | Pin one behavior; see §4.8 |
| Inline link | `[text](dest "title")` | 4 components separated by spaces/tabs/≤1 line ending; dest and title **must** be separated if both present | Unbalanced parens in bare destination → not a link |
| Full reference link | `[text][label]` | Uses matching LRD | |
| Collapsed reference link | `[text][]` | Label = text | |
| Shortcut reference link | `[text]` | Label = text, only if a matching LRD exists | |
| Image | `![alt](…)`, `![alt][…]`, `![alt]` | Same four forms; alt text is the *plain-text* concatenation of the children (inline markup stripped, no nested links) | |
| Link destination | `<…>` form (no line endings, no unescaped `<>`) **or** bare form (nonempty, no control chars/space, parens only escaped or balanced; ≥3 nesting levels required) | | |
| Link title | `"…"`, `'…'`, or `(…)`; may span lines but **not** a blank line | | |
| No nested links | A link may not contain another link at any level. `process emphasis`'s caller marks all earlier `[` delimiters **inactive** when a link (not image) closes | Implemented by the `active` flag on `[`/`![` delimiters | |
| Autolink (CM) | `<` + absolute URI + `>`; scheme = 2–32 chars, first is an ASCII letter, rest letters/digits/`+`/`.`/`-`; URI body = no ASCII control, space, `<`, `>` | Rendered with the URI as both href and label | |
| Autolink (CM, email) | `<` + email + `>`; email regex from the HTML5 non-normative pattern | | |
| Extended www autolink (GFM) | text `www.` + valid domain; only at BOL, after whitespace, or after `*`, `_`, `~`, `(` | `http://` prefixed automatically. Valid domain = alnum/`_`/`-` segments joined by `.`, ≥1 dot, **no `_` in the last two segments** | |
| Extended URL autolink (GFM) | `http://`, `https://`, `ftp://` + valid domain + zero or more non-space, non-`<` chars | Same entry-position restriction | |
| Extended email autolink (GFM) | `[A-Za-z0-9._+-]+` `@` + labels of alnum/`-`/`_` joined by `.`, ≥1 dot, last char not `-`/`_` | `mailto:` prefixed. Recognized **within any text node** (no position restriction) | |
| Extended autolink path validation | trailing `?`, `!`, `.`, `,`, `:`, `*`, `_`, `~` are stripped | If the autolink ends with `)`, count all `(` and `)` in the whole match; strip unmatched trailing `)`. Interior parens are never re-balanced. `<` ends the autolink immediately | |
| Raw HTML inline | open tag, closing tag, comment, processing instruction, declaration, CDATA | Tag names: ASCII letter + letters/digits/`-`. Attribute names: `[A-Za-z_:][A-Za-z0-9_.:-]*`. Values unquoted / `'…'` / `"…"`. Attributes may contain up to one line ending | |
| Hard line break | 2+ spaces before a line ending **not** at end of block, or `\` before a line ending | Renders `<br />`; leading spaces of the next line are dropped. Not recognized in a code span or an HTML tag | |
| Soft line break | any other line ending in inline content | Renders as `\n` | |
| Entity reference | `&` + valid HTML5 entity name + `;` | Authoritative list: https://html.spec.whatwg.org/entities.json (~2231 named entities). Semicolon **required** — `&copy` is not an entity | |
| Decimal numeric ref | `&#` + 1–7 digits + `;` | Invalid code points **and** `U+0000` → `U+FFFD` | 8+ digits → literal |
| Hex numeric ref | `&#x`/`&#X` + 1–6 hex digits + `;` | Same replacement rules | 7+ digits → literal |
| Entities banned from structure | `&#42;` etc. never act as emphasis delimiters, bullet markers, or thematic break chars | | |
| Backslash escapes | `\` + **ASCII punctuation only** | The escapable set is exactly: ``!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~`` (32 chars = U+0021–U+002F, U+003A–U+0040, U+005B–U+0060, U+007B–U+007E). `\A`, `\3`, `\φ`, `\«`, `\ ` (space) are **not** escapes → literal backslash retained | |
| Disallowed raw HTML (GFM tagfilter) | when writing HTML: if a raw HTML open/close tag name is one of `title textarea style xmp iframe noembed noframes script plaintext` (ci), replace the leading `<` with `&lt;` | | Only applies to raw HTML, not to code spans/blocks |

Sources: [§6.1](https://spec.commonmark.org/0.31.2/#backslash-escapes), [§6.2](https://spec.commonmark.org/0.31.2/#entity-and-numeric-character-references), [§6.3](https://spec.commonmark.org/0.31.2/#code-spans), [§6.4](https://spec.commonmark.org/0.31.2/#emphasis-and-strong-emphasis), [§6.6](https://spec.commonmark.org/0.31.2/#links), [§6.7](https://spec.commonmark.org/0.31.2/#images), [§6.8](https://spec.commonmark.org/0.31.2/#autolinks), [§6.10](https://spec.commonmark.org/0.31.2/#raw-html), [§6.12](https://spec.commonmark.org/0.31.2/#hard-line-breaks), [GFM §6.5](https://github.github.com/gfm/#strikethrough-extension-), [GFM §6.9](https://github.github.com/gfm/#autolinks-extension-), [GFM §6.11](https://github.github.com/gfm/#disallowed-raw-html-extension-).

### 4.3.3 Character classes (needed for flanking)

| Class | Definition |
|---|---|
| Unicode whitespace | any `Zs`, plus TAB (U+0009), LF (U+000A), FF (U+000C), CR (U+000D) |
| Unicode punctuation | any `P*` (punctuation) or `S*` (symbol) general category — note symbols count |
| ASCII punctuation | U+0021–2F, U+003A–40, U+005B–60, U+007B–7E |
| ASCII control | U+0000–1F, U+007F |
| Blank line | empty, or only spaces/tabs |
| Line ending | LF; CR not followed by LF; CRLF |

Dart note: `RegExp(r'[\p{P}\p{S}]', unicode: true)` covers Unicode punctuation in Dart 3. `U+0000` in input **must**
be replaced by `U+FFFD` before parsing (CM §2.3 "Insecure characters").

---

## 4.4 The emphasis algorithm in executable detail

This is the CommonMark Appendix procedure plus the `openers_bottom` optimization as actually implemented in
commonmark.js (`lib/inlines.js`, `processEmphasis`, `scanDelims`). Follow it literally.

### 4.4.1 Data structures

```dart
class Delim {
  final int cc;          // 0x2A '*' | 0x5F '_' | 0x7E '~' | 0x5B '[' | 0x21 '!' (for '[', cc is '[' and image is a flag)
  final Inline node;     // the text node holding the literal delimiters
  int numdelims;         // delimiters not yet consumed
  final int origdelims;  // length of the run as originally scanned — NEVER mutated
  final bool canOpen, canClose;  // from scanDelims
  Delim? previous, next;
}
```

The delimiter stack is a **doubly linked list** held on the inline parser. `numdelims` mutates; `origdelims` does
not, and the rule-of-3 test uses `origdelims`.

### 4.4.2 `scanDelims(cc)` — compute `canOpen` / `canClose`

```
numdelims ← count of consecutive cc starting at pos       // for '!'+ '[' handle separately
if numdelims == 0: return null
char_before  ← the char before the run, or '\n' if at start of subject
char_after   ← the char after the run, or '\n' if at end of subject
after_ws  = isUnicodeWhitespace(char_after)
after_pn  = isUnicodePunctuation(char_after)
before_ws = isUnicodeWhitespace(char_before)
before_pn = isUnicodePunctuation(char_before)

left_flanking  = !after_ws  && (!after_pn  || before_ws || before_pn)
right_flanking = !before_ws && (!before_pn || after_ws  || after_pn)

if cc == '_':
    canOpen  = left_flanking  && (!right_flanking || before_pn)
    canClose = right_flanking && (!left_flanking  || after_pn)
else:                       // '*' and '~'
    canOpen  = left_flanking
    canClose = right_flanking

pos ← startpos              // do not consume here; the caller re-reads
return (numdelims, canOpen, canClose)
```

*"the beginning and the end of the line count as Unicode whitespace"* — hence the `'\n'` defaults.

Delimiter-run definition: a run of `*` is a maximal sequence not preceded or followed by a **non-backslash-escaped**
`*`. An escaped `\*` therefore **breaks** a run.

Checked examples from the spec:

| Input | left-flanking? | right-flanking? |
|---|---|---|
| `***abc` | yes | no |
| `  _abc` | yes | no |
| `**"abc"` | yes | no |
| `abc***` | no | yes |
| `"abc"_` | no | yes |
| `abc***def` | yes | yes |
| `"abc"_"def"` | yes | yes |
| `abc *** def` | no | no |
| `a _ b` | no | no |

### 4.4.3 `processEmphasis(stackBottom)`

`stack_bottom` is either `null` (whole document) or the `[`/`![` delimiter that opened the link/image currently
being closed. It is an **exclusive lower bound**.

```
openers_bottom ← array of 14 slots, all initialized to stackBottom

closer ← first delimiter above stackBottom
while closer != null:
    if !closer.canClose:
        closer ← closer.next; continue

    // index: 0 = '\'' , 1 = '"' (smart-punct only; unused without it)
    //        '_' → 2 + (closer.canOpen ? 3 : 0) + (closer.origdelims % 3)   → 2..7
    //        '*' → 8 + (closer.canOpen ? 3 : 0) + (closer.origdelims % 3)   → 8..13
    idx ← indexFor(closer)

    opener ← closer.previous
    openerFound ← false
    while opener != null
          && opener != stackBottom
          && opener != openers_bottom[idx]:
        oddMatch = (closer.canOpen || opener.canClose)
                && closer.origdelims % 3 != 0
                && (opener.origdelims + closer.origdelims) % 3 == 0
        if opener.cc == closer.cc && opener.canOpen && !oddMatch:
            openerFound ← true; break
        opener ← opener.previous

    oldCloser ← closer

    if closer.cc in {'*','_','~'}:                    // '~' only when the GFM extension is on
        if !openerFound:
            closer ← closer.next
        else:
            useDelims ← (closer.numdelims >= 2 && opener.numdelims >= 2) ? 2 : 1
            opener.numdelims -= useDelims
            closer.numdelims -= useDelims
            // truncate the literal text nodes by useDelims chars from the END of both
            emph ← new Node(useDelims == 1 ? emph : strong)   // for '~' → del
            move all inline siblings strictly between opener.node and closer.node into emph
            opener.node.insertAfter(emph)
            removeDelimitersBetween(opener, closer)
            if opener.numdelims == 0: unlink(opener.node); removeDelimiter(opener)
            if closer.numdelims == 0:
                temp ← closer.next
                unlink(closer.node); removeDelimiter(closer)
                closer ← temp
            // else: do NOT advance — the same closer may pair again
    else:                                             // smart punctuation (omit)
        ...

    if !openerFound:
        openers_bottom[idx] ← oldCloser.previous       // lower bound for future searches
        if !oldCloser.canOpen:
            removeDelimiter(oldCloser)                 // it can never be a closer-for-this-type again

// finally drop every delimiter above stackBottom
while delimiters != null && delimiters != stackBottom: removeDelimiter(delimiters)
```

### 4.4.4 `look for link or image` and how it invokes `processEmphasis`

```
on ']':
  walk back the delimiter stack for an opener '[' or '!['
  if none:                    return literal ']'
  if found but !active:       remove that delimiter; return literal ']'
  if found and active:
      if not (inline link | full ref | collapsed ref | shortcut ref): 
          remove opener delimiter; return literal ']'
      else:
          node ← Link or Image whose children are the inlines after opener.node
          processEmphasis(opener)             // <-- stack_bottom = the '[' delimiter
          removeDelimiter(opener)
          if node is a Link (not Image):
              for every '[' delimiter *before* opener: active ← false   // forbids nested links
```

Note the ordering: **`processEmphasis` runs before the opener is removed and before earlier `[`s are deactivated**.
Also note that at the very end of inline parsing the parser calls `processEmphasis(null)` once.

### 4.4.5 The rule of three (spec rules 9/10) in one sentence

> If one of the two delimiters can both open and close emphasis, then
> `(len(openerRun) + len(closerRun))` must **not** be a multiple of 3, **unless both** lengths are multiples of 3.

The implementation form is exactly the `oddMatch` expression above, and it uses `origdelims`, not `numdelims`.
Getting this wrong is the single most common source of spec failures.

### 4.4.6 The four tie-breaking principles (spec rules 13–17)

| Principle | Statement | Consequence in the algorithm |
|---|---|---|
| 13. Nesting minimized | `<strong>` preferred over `<em><em>` | `useDelims = 2` whenever both runs have ≥2 |
| 14. `em(strong)` over `strong(em)` | `<em><strong>x</strong></em>` preferred to `<strong><em>x</em></strong>` | Emerges from processing closers left-to-right |
| 15. First span wins on overlap | `*foo _bar* baz_` → `<em>foo _bar</em> baz_` | Left-to-right closer scan |
| 16. Later opener wins on shared closer | `**foo **bar baz**` → `**foo <strong>bar baz</strong>` | Backwards opener search from the closer |
| 17. Code/links/images/HTML beat emphasis | `*[foo*](bar)` → `*<a href="bar">foo*</a>` | Bracket matching happens during the scan; `processEmphasis` never sees text inside a resolved link |

### 4.4.7 Why `openers_bottom` exists, and how to get it right

Naïvely, for each closer you rescan the whole stack: O(n²). `openers_bottom` caches, per (delimiter char,
`closer.canOpen`, `closer.origdelims % 3`) bucket, the deepest stack position at which a matching opener is known
**not** to exist. Because a failure to find an opener for a closer of run-length `L` also proves there is no opener
for any other closer with the same `L % 3` and the same `canOpen`, the bound is sound.

Two easy-to-miss details:
1. The bucket key uses the **closer's original run length mod 3**, and **whether the closer can also open** — six
   buckets per delimiter char.
2. `openers_bottom` is **local to one `processEmphasis` call**. The array is re-created (all slots = `stack_bottom`)
   on every invocation, including nested invocations from link closers.

---

## 4.5 Spec test suite

### 4.5.1 Counts

| Suite | Examples | Sections | Notes |
|---|---|---|---|
| CommonMark 0.31.2 | **652** | 26 | `spec.json`, `example` is 1-based and contiguous over the whole file |
| CommonMark 0.30 | 649 | 26 | https://spec.commonmark.org/0.30/spec.json |
| CommonMark 0.29 | 649 | 26 | GFM's nominal base; https://spec.commonmark.org/0.29/spec.json |
| GFM 0.29-gfm (published HTML) | **677** | 31 | ids `example-1`…`example-677`, contiguous |
| GFM (cmark-gfm `test/spec.txt`) | **672** example fences | 31 | 5 fewer than the published HTML — see §4.1.3; 2 of the 672 carry the `disabled` tag and are skipped by cmark-gfm's own runner |
| cmark-gfm `test/extensions.txt` | 21 274 bytes | — | extension-specific renderer variants |
| cmark-gfm `test/regression.txt` | 10 806 bytes | — | historical bug regressions |
| cmark-gfm `test/smart_punct.txt` | 4 175 bytes | — | smart punctuation (not GFM) |
| cmark-gfm `test/pathological_tests.py` | 21 named cases | — | performance/DoS |

### 4.5.2 CommonMark 0.31.2 section-by-section example counts

| Section | n | Range | | Section | n | Range |
|---|---|---|---|---|---|---|
| Tabs | 11 | 1–11 | | Block quotes | 25 | 228–252 |
| Backslash escapes | 13 | 12–24 | | List items | 48 | 253–300 |
| Entity and numeric character references | 17 | 25–41 | | Lists | 26 | 301–326 |
| Precedence | 1 | 42–42 | | Inlines | 1 | 327–327 |
| Thematic breaks | 19 | 43–61 | | Code spans | 22 | 328–349 |
| ATX headings | 18 | 62–79 | | **Emphasis and strong emphasis** | **132** | 350–481 |
| Setext headings | 27 | 80–106 | | **Links** | **90** | 482–571 |
| Indented code blocks | 12 | 107–118 | | Images | 22 | 572–593 |
| Fenced code blocks | 29 | 119–147 | | Autolinks | 19 | 594–612 |
| HTML blocks | 44 | 148–191 | | Raw HTML | 20 | 613–632 |
| Link reference definitions | 27 | 192–218 | | Hard line breaks | 15 | 633–647 |
| Paragraphs | 8 | 219–226 | | Soft line breaks | 2 | 648–649 |
| Blank lines | 1 | 227–227 | | Textual content | 3 | 650–652 |

### 4.5.3 GFM 0.29-gfm section-by-section example counts (677 total)

| Section | n | | Section | n |
|---|---|---|---|---|
| 2.2 Tabs | 11 | | 5.2 List items | 48 |
| 3.1 Precedence | 1 | | 5.3 Task list items (ext) | 2 |
| 4.1 Thematic breaks | 19 | | 5.4 Lists | 26 |
| 4.2 ATX headings | 18 | | 6 Inlines | 1 |
| 4.3 Setext headings | 27 | | 6.1 Backslash escapes | 13 |
| 4.4 Indented code blocks | 12 | | 6.2 Entity and numeric char refs | 17 |
| 4.5 Fenced code blocks | 29 | | 6.3 Code spans | 22 |
| 4.6 HTML blocks | 43 | | 6.4 Emphasis and strong emphasis | 131 |
| 4.7 Link reference definitions | 28 | | 6.5 Strikethrough (ext) | 3 |
| 4.8 Paragraphs | 8 | | 6.6 Links | 87 |
| 4.9 Blank lines | 1 | | 6.7 Images | 22 |
| 4.10 Tables (ext) | 8 | | 6.8 Autolinks | 19 |
| 5.1 Block quotes | 25 | | 6.9 Autolinks (ext) | 14 |
| | | | 6.10 Raw HTML | 21 |
| | | | 6.11 Disallowed Raw HTML (ext) | 1 |
| | | | 6.12 Hard line breaks | 15 |
| | | | 6.13 Soft line breaks | 2 |
| | | | 6.14 Textual content | 3 |

### 4.5.4 JSON shape

`spec.json` (CommonMark 0.31.2) is an **array of 652 objects**, each:

```json
{
  "markdown":  "Foo\nBar\n---\n",
  "html":      "<h2>Foo\nBar</h2>\n",
  "example":   65,
  "start_line": 1234,
  "end_line":   1250,
  "section":   "Setext headings"
}
```

| Key | Type | Notes |
|---|---|---|
| `markdown` | string | Input; **`\t` is a real tab**, `\n` line endings, always ends with `\n` |
| `html` | string | Expected output; may be the sentinel `"<IGNORE>"`, which the harness treats as an automatic pass |
| `example` | int | 1-based, contiguous across the whole file — **use this as the test name** |
| `start_line` / `end_line` | int | 1-based line range in `spec.txt` (the fence lines) |
| `section` | string | Section heading text, e.g. `"Emphasis and strong emphasis"` |

The npm `commonmark-spec` package exposes the same objects but names the number field `number`, not `example`.
**GFM does not publish a `spec.json`** (`/gfm/spec.json` → 404). Use one of:
* parse `https://raw.githubusercontent.com/github/cmark-gfm/master/test/spec.txt` (the `get_tests()` algorithm below), or
* scrape `https://github.github.com/gfm/` for `id="example-N"` and the two `<pre><code>` children per example.

### 4.5.5 The `spec.txt` example format (and its `→` convention)

````
```````````````````````````````` example <space-separated extension tags>
Markdown source, with → standing for a literal tab
.
Expected HTML output
````````````````````````````````
````

Rules from [`spec_tests.py`](https://raw.githubusercontent.com/github/cmark-gfm/master/test/spec_tests.py):

* Opening fence = **exactly 32 backticks** + `" example"` + optional tags.
* `.` on a line by itself separates input from expected output.
* Closing fence = exactly 32 backticks. `example_number` increments **on the closing fence** (so disabled examples still consume a number).
* All `→` (U+2192) in both input and output are replaced by `\t`.
* Tag `disabled` → the example is parsed but **excluded** from the run.
* Expected HTML of the single token `<IGNORE>` → automatic pass.
* The current section is the most recent line matching `^#+ `.

### 4.5.6 Non-conforming / divergent examples in GFM

| Item | Detail |
|---|---|
| `disabled` examples | `test/spec.txt` #279, #280 (task lists) carry the `disabled` tag and are skipped by cmark-gfm's own runner |
| Published HTML ≠ `test/spec.txt` | 12 HTML-only / 7 txt-only examples (§4.1.3). Treat as two sources; pin one |
| Self-contradicting strikethrough | GFM prose says "two tildes"; the published example `~~Hi~~ Hello, ~there~ world!` renders single `~there~` as `<del>`. cmark-gfm's `test/spec.txt` uses `~~Hi~~ Hello, world!` instead and so does not exercise it |
| HTML comment rule | GFM keeps the CM 0.29 rule; every CommonMark 0.30+ implementation differs. This is the one place where "CommonMark + GFM" is not a clean union |
| `<textarea>` HTML block | Removed from GFM's example set but still required by GFM's own prose (the prose is CM 0.29's, which lists `textarea`) — the published GFM HTML grammar in §4.6 does list it. Only the *example* is missing |

### 4.5.7 Third-party conformance suites worth reusing

| Suite | What it gives you | URL |
|---|---|---|
| cmark's `spec_tests.py` + `normalize.py` | Runner + the HTML normalizer that must accompany any conformance claim | https://github.com/commonmark/commonmark-spec |
| cmark-gfm `test/roundtrip_tests.py` | `md → commonmark → html` vs `md → html`; the canonical demonstration that re-serialization is lossy (it must strip the writer's own `<!-- end list -->` markers) | https://github.com/github/cmark-gfm/tree/master/test |
| cmark-gfm `test/pathological_tests.py` | 21 denial-of-service shapes that must complete in bounded time | same |
| `micromark` / `mdast` (Titus Wormer) | 100 % CommonMark + GFM, token-level positional info, extension-per-option architecture; unified.js's reference for GFM tokenization | https://github.com/micromark |
| babelmark3 | Differential testing of 20+ implementations on one input — useful for deciding what to do with the extension zone | https://babelmark.github.io/ |
| `karlcow/markdown-testsuite` | Predecessor suite; `normalize.py` was adapted from it | https://github.com/karlcow/markdown-testsuite |

### 4.5.8 The HTML normalization contract

Any "we pass the spec" claim is only meaningful relative to normalizations. cmark's `normalize_html` (adapted from
markdown-testsuite) does:

1. Collapse runs of whitespace to a single space — **except inside `<pre>`**.
2. Strip whitespace directly inside/around block-level tags; the block-tag list is `article header aside hgroup blockquote hr iframe body li map button object canvas ol caption output col p colgroup pre dd progress div section dl table td dt tbody embed textarea fieldset tfoot figcaption th figure thead footer tr form ul h1..h6 video script style`.
3. Convert self-closing tags to open tags (`<br />` ≡ `<br>`).
4. Sort and lowercase attributes.
5. Percent-normalize `href`/`src` (`urllib.quote(urllib.unquote(v), safe='/')`).
6. Decode character references to Unicode, except `<`, `>`, `&`, `"` which are re-emitted as entities.
7. `handle_startendtag` deliberately ignores the self-closing slash.

Niman should implement the same normalizer so the conformance number is comparable to cmark's.

---

## 4.6 Extension zone — what CommonMark/GFM deliberately do not cover

None of the constructs in this section appear in either spec. They must be implemented in Niman, *outside* the
conformance surface, with an explicit precedence relative to CommonMark (the safe default: **a CommonMark
construct always wins; the extension only fires where CommonMark would produce plain text**).

### 4.6.1 Math

| Aspect | Rule |
|---|---|
| Pandoc `tex_math_dollars` (the de-facto standard) | Opening `$` must have a **non-space character immediately to its right**. Closing `$` must have a **non-space character immediately to its left** and **must not be immediately followed by a digit**. Therefore `$20,000 and $30,000` does **not** parse as math. `\$` escapes a literal dollar |
| Pandoc display math | `$$` … `$$`. The delimiters *may* be separated from the formula by whitespace, but **no blank line may occur between them** |
| KaTeX auto-render defaults | `$$` display first, then `\(`…`\)`, then `\begin{equation|align|alignat|gather|CD}`, then `\[`…`\]`. `$`…`$` is **not** in the default list — you must add it, and it must come **after** `$$`, *"Because rules are processed in order, putting a `$` rule first would catch `$$` as an empty math expression."* |
| KaTeX ignored contexts | `ignoredTags: ["script","noscript","style","textarea","pre","code","option"]` — math tokens must never be scanned inside those |
| KaTeX ordering gotcha | The `$$` rule must be tried before `$`; otherwise `$$x$$` is read as two empty inline spans |
| MathJax `tex2jax` | Same shape: `inlineMath: [['$','$'],['\\(','\\)']]`, `displayMath: [['$$','$$'],['\\[','\\]']]`, plus a `processEscapes` option that makes `\$` literal |
| GitHub today | GitHub uses **MathJax**. Inline: `$…$` **or** `` $`…`$ `` (the backtick form is for expressions containing Markdown-significant characters). Block: `$$…$$` on its own line, **or** a fenced code block with info string `math` (in which case no `$$` delimiters are used). Literal dollars: `\$` **inside** math, or `<span>$</span>` **outside** it on the same line |
| Currency false positives | `$5 and $10` must stay text. Enforce: opening `$` not followed by whitespace **and** closing `$` not preceded by whitespace **and** closing `$` not followed by a digit. Then `$5 and $10` fails because the candidate closer (`$` before `10`) is followed by a digit |
| Escaping | `\$` → literal `$`, never a delimiter. Whether `\\$` is half an escape chain must be resolved by the same backslash-run parity rule as the rest of the parser |
| Interaction with CommonMark | Math must be tokenized **after** code spans and fenced code blocks (so `` `$x$` `` is code), and **before** emphasis (so `$a*b*c$` does not get emphasis inside; or if you prefer KaTeX semantics, tokenize the math body as opaque and let KaTeX own it). Recommended: math is an opaque inline/leaf node, and `$` inside a code span is never a delimiter |
| Display-math block form | `$$` at the beginning of a block (≤3 spaces indent) opens a leaf block that ends at a line containing `$$`; no blank line allowed inside by the Pandoc rule. Unterminated `$$` should degrade to literal text, **not** swallow the file |

### 4.6.2 Wikilinks

| Aspect | Rule |
|---|---|
| Base syntax | `[[Note]]`; `[[projects/Three laws of motion]]` (folder path from vault root, forward slashes even on Windows) |
| Alias | `[[Example\|Custom name]]` — the **first** `\|` splits destination from display text |
| Heading anchor | `[[Note#Heading]]`; sub-headings by repeating `#`: `[[Help#Questions#Report bugs]]` |
| Same-note anchor | `[[#Preview a linked file]]` |
| Block reference | `[[2023-01-01#^37066d]]` — `#^` + identifier. Identifiers are Latin letters, digits and dashes only. Defining a block: ` ^id` at end of a simple paragraph, or on its own line surrounded by blank lines for structured blocks (lists, quotes, callouts, tables) |
| Embed | Prefix `!`: `![[Internal links]]`, `![[Internal links#^b15695]]`, `![[Engelbart.jpg\|100x145]]` (width×height; a single number = width only, proportional) |
| Declared-invalid characters | *"A string which contains the following characters may not work as a link: `# \| ^ : %% [[ ]]`"* — so `#`, `\|`, `^` are **separators**, and `[[`/`]]` cannot appear inside |
| Case sensitivity | Obsidian resolves links case-insensitively but *preserves* the typed case; Niman should resolve, not rewrite |
| Precedence problems | (a) `[[` inside a code span must stay literal — code spans win. (b) `[[` inside an inline link label or destination must stay literal — CommonMark links win. (c) Nested `[[a[[b]]c]]` — no unambiguous parse; recommend: **the first `]]` closes**, and the inner `[[` is literal text. (d) `![[x]]` at a position where `![` + `[x]]` would be a CommonMark image with a shortcut-reference label `[x]` — GFM/CommonMark wins unless the parser can prove no reference definition matches, which requires post-pass resolution; simplest deterministic rule: **wikilink is attempted before CommonMark link/image matching, but only when the destination contains no newline, no unescaped `]]`, and the whole `[[…]]` is on one line** |
| Escaping | Obsidian documents **no** escape for `\|` or `]]` inside a wikilink. Niman must choose one and document it; a safe choice is: `\|` inside `[[…]]` is a literal pipe only when the alias separator has already been consumed |
| Inside tables | `\|` is needed anyway for GFM table cells, so `[[a\|b]]` is ambiguous in a table. Define: in a table row, `\|` is consumed by the *table* splitter before wikilink parsing |

### 4.6.3 Frontmatter

| Rule | Value |
|---|---|
| Recognition | `---` as the **very first line** of the file (Obsidian: *"Type `---` at the very beginning of a file"*). Jekyll/Hugo and most ecosystems agree |
| Termination | a line that is exactly `---` or `...` (trailing whitespace tolerated) |
| Body | YAML; Niman only needs to *slice* it for the properties panel. A full YAML parser is a separate concern |
| Exclusion range | `[0, end_of_closing_delimiter + line_ending)` is removed before block parsing. If there is no closing delimiter: **do not** treat it as frontmatter (otherwise a note that starts with a thematic break is destroyed) |
| Interaction | A file whose first line is `---` and whose second line is not YAML-ish is ambiguous; the deterministic rule above resolves it in favour of frontmatter whenever a closing delimiter exists |
| Round-trip | The exclusion is a *slice*, not a transform. The frontmatter bytes are never reparsed or re-emitted; the properties panel writes back through an edit span |

### 4.6.4 Other constructs to decide about explicitly

| Construct | Syntax (reference) | Recommendation for Niman |
|---|---|---|
| Footnotes | Pandoc: `[^1]` inline, `[^1]: text` definition with continuation lines indented 4 spaces; identifiers may not contain spaces, tabs, newlines, `^`, `[`, `]`. Also inline `^[text]` (single paragraph only) | Implement as a block-level definition + inline reference pair, resolved in the same post-pass as link reference definitions |
| Definition lists | Pandoc/PHP-Markdown-Extra: term on one line (optionally followed by a blank line), then ≥1 definition, each beginning with `:` or `~`, optionally indented 1–2 spaces, continuation blocks indented | Low priority; a term line followed by `: ` is the trigger. Must not fire when the previous line is a paragraph continuation |
| Callouts / admonitions | GitHub alerts: blockquote whose first line is exactly `> [!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`; **cannot be nested** in other elements. Obsidian: `> [!info] Title`, `> [!faq]-` (collapsed) / `-`+`+` fold markers, arbitrary custom type ids, nestable via `> >` | Parse as a blockquote subtype: inspect the first line of a blockquote's first paragraph. GitHub's "cannot be nested" is a rendering policy, not a parse restriction |
| Mermaid / diagrams | Fenced code block with info string `mermaid` (GitHub renders these natively) | **No syntax change.** It is already a fenced code block; the renderer dispatches on the first word of the info string. Same mechanism covers `math`, `katex`, and syntax highlighting |
| Raw HTML sanitization | Neither spec sanitizes: CM passes HTML through verbatim. GFM's only restriction is `tagfilter` (9 tag names) | Niman must define its own policy per platform: `tagfilter` list as the floor; if user HTML is rendered at all, run it through an allow-list sanitizer, never `tagfilter` alone. Media/`<iframe>`/`<script>` must be blocked. The **stored file is never modified** — sanitization is a render-time projection only |

---

## 4.7 Round-trip fidelity requirements

The rule: **`serialize(parse(src)) == src` must be structurally impossible to violate because there is no
serializer.** The only writer is a byte-level splice.

### 4.7.1 The edit-span model

```
Document
├── bytes:   ImmutableList<Uint8List>   // the file, verbatim, including BOM and line endings
├── offsets: line-start index over bytes (UTF-8 aware)
├── spans:   BlockSpan / InlineSpan     // each carries [byteStart, byteEnd) into `bytes`
└── derived: an index (FTS, backlinks) — rebuildable, never authoritative
```

Invariants:

1. Every syntactic node stores **half-open byte offsets into the original file**, plus a *kind* and any
   derived-only attributes (e.g. a resolved reference-link destination). Nodes are a **projection of bytes**;
   bytes are never a projection of nodes.
2. Rendering takes `(bytes, spans)` and produces widgets. It never takes a document object graph that was
   reconstructed from a parse.
3. **Editing is `bytes' = bytes.replaceRange(start, end, replacement)`.** Every user-visible editing command
   (bold, heading, list indent, checkbox toggle, wikilink rename) is compiled to a *set of splices* computed from
   the spans. A command whose target text is already in the desired state produces the empty splice.
4. Undo/redo stores splices (with their inverse), not document snapshots.
5. `format`/`prettify`/`normalize` do not exist as commands. If ever added, they must be explicit one-shot
   transformations over a selection, previewable and reversible.

Test to enforce it: `assert(save(open(path)) == read(path))` for every note in the corpus, on every save path.
Plus a property test: for any document, opening and closing without an edit produces zero bytes written.

### 4.7.2 Concrete information-loss hazards and the required policy

| # | Hazard | What a re-serializing AST loses | Required "never rewrite the user's bytes" policy |
|---|---|---|---|
| H1 | Reference links vs inline links | `[text][ref]` + `[ref]: /url` becomes `[text](/url)`; the definition is dropped or duplicated | Keep link nodes pointing at their source spans; resolve the destination **for rendering only**. Never emit a link from a node; the source text is already the output |
| H2 | Ordered list renumbering | `1. 1. 1.` or `1. 5. 9.` is rewritten to `1. 2. 3.`; start numbers > 1 are lost or duplicated | Never touch list markers on save. `<ol start="5">` is a render-time property read from the source, not a written one |
| H3 | Bullet char normalization | `*`→`-`, `+`→`-`; mixed-char lists get merged | Bullet char is a span attribute. A "change bullet style" command is an explicit splice over the marked range |
| H4 | Emphasis delimiter normalization | `_x_`→`*x*`, `**x**`→`__x__`, `***x***` re-split | Same as H3: the delimiter text is literal source. Never rewrite |
| H5 | Setext vs ATX | `Foo\n===` becomes `# Foo`; a `---` setext underline becomes `## Foo` | Heading level is derived; the literal form is preserved. Toggling heading level should splice the *existing* marker, not replace its style |
| H6 | Indented vs fenced code | A 4-space block becomes ```` ``` ````; a fenced block gets its indent or info string changed | Code block kind is a span attribute. Language comes from the info string; unknown info strings are preserved verbatim (this is why `full-info-string` exists) |
| H7 | Trailing whitespace as hard break | Trailing spaces are stripped by "cleanup" → the user's line break disappears | **Never trim line ends.** A trim-whitespace-on-save feature is forbidden. Show a visible hard-break glyph instead |
| H8 | Tabs vs spaces | Tabs expanded to spaces in list indentation or code blocks | Indentation is measured with a 4-column tab stop but the *bytes* are kept. Never expand a tab in the source |
| H9 | CRLF vs LF | Whole-file line-ending conversion on save | Detect the dominant/majority line ending on load, store it as a document property, and preserve every original ending. Mixed endings are allowed and preserved |
| H10 | Multiple blank lines | `\n\n\n\n` collapsed to `\n\n` | Blank lines are literal. Block parsing must tolerate arbitrary runs |
| H11 | Lazy continuation | A blockquote/list item line without a marker gets "fixed" by re-indenting | The marker's absence is a span fact. Structural edits replace the whole item range; they never re-emit untouched lines |
| H12 | HTML blocks | Raw HTML is parsed into a tree and re-emitted with attribute reordering, quote normalization, self-closing expansion | HTML blocks are **opaque byte spans**. Never sanitize or reformat on write. Render-time sanitization is a separate, lossy-by-design projection |
| H13 | Entity vs literal character | `&amp;` becomes `&`, `&#42;` becomes `*`, `&nbsp;` becomes U+00A0 | Store the raw span; decode only for rendering/plain-text extraction. Never re-encode on save |
| H14 | Link titles / destinations | Quote style changed (`'` → `"`), angle brackets added or removed, percent-encoding normalized | Literal source. Never re-quote |
| H15 | Backslash escapes | `\*` → `*` because "it isn't needed" | Escapes are literal source bytes. An "unnecessary escape" lint is a suggestion with a previewed splice, never automatic |
| H16 | Frontmatter key order / formatting | YAML re-dumped with reordered keys, changed quoting, normalized numbers | Frontmatter is a byte span. The properties UI must compute a *minimal* splice (e.g. replace only the value token), leaving all other keys, comments, and quoting untouched |
| H17 | Math delimiters | `$$…$$` rewritten to `\[…\]` or a `math` fence | Literal source span; delimiters are part of the span, not an attribute |
| H18 | Wikilink alias vs path | `[[Note\|alias]]` rewritten to `[[resolved/path/Note\|alias]]` or to a Markdown link | Never rewrite a wikilink on save. Path resolution is an index concern |
| H19 | BOM and trailing-newline presence | BOM dropped; a final newline added or removed | Preserve byte 0 exactly; preserve the presence/absence of a final line ending |
| H20 | Unicode normalization | NFC/NFD conversion changes bytes (and can change link-label matching) | Never normalize input. Compare labels by Unicode case fold at match time only |

### 4.7.3 The `roundtrip_tests.py` proof

cmark-gfm ships `test/roundtrip_tests.py`, which runs `md → to_commonmark() → to_html()` and compares to
`md → to_html()`. It must strip the *writer's own* injected markers to make the comparison work:

```python
# In the commonmark writer we insert dummy HTML comments between lists, and
# between lists and code blocks. Strip these out, since the spec uses two blank lines instead:
return [ec, re.sub('<!-- end list -->\n', '', html), '']
```

That is the entire argument for the edit-span model in one comment: **the reference implementation of the
spec cannot re-serialize its own input without help.** Niman should not attempt it.

---

## 4.8 Recommended conformance strategy

### 4.8.1 Order of attack

Work strictly bottom-up; each stage is a gate before the next begins. Do not start inlines before blocks are
100 % on their own sections. Example counts in the table are **GFM's** (where GFM and CommonMark differ, GFM is the
number you will actually run); the stages sum to 676 of GFM's 677, the remainder being `3.1 Precedence` (1 example,
covered implicitly by stage 6's precedence implementation).

| Stage | Sections | Ex. | Why this order |
|---|---|---|---|
| 0 | Test harness + `normalize_html` + spec.json loader | 0 | You cannot claim anything without the normalizer (§4.5.8) |
| 1 | Preliminaries: Tabs, Backslash escapes, Entities | 41 | Character classes and escapes are prerequisites for *every* other section; they also affect block contexts |
| 2 | Leaf blocks: Thematic breaks, ATX, Setext, Indented code, Fenced code | 105 | Simplest constructs; no container recursion |
| 3 | HTML blocks (all 7 types) | 43 | Self-contained but the end-condition state machine is fiddly |
| 4 | Link reference definitions + Paragraphs + Blank lines | 37 | Produces the reference map that links need |
| 5 | Container blocks: Block quotes, List items, Lists | 99 | The hardest block work: laziness, indentation, tight/loose |
| 6 | Inlines scaffolding + Code spans + Raw HTML + Autolinks | 63 | Everything that must beat emphasis (precedence rule 17) |
| 7 | **Emphasis and strong emphasis** | 131 | Impossible to do correctly before 1 and 6 are exact. Implement §4.4 verbatim, then run the section twice (once per delimiter char) |
| 8 | Links + Images | 109 | Needs the delimiter stack from 7, the reference map from 4, and no-nested-links deactivation |
| 9 | Hard/Soft line breaks + Textual content | 20 | Trivial once inline content assembly is right |
| 10 | GFM: Tables, Task lists, Strikethrough, Autolinks-ext, tagfilter | 28 | Extension code should not be able to regress stages 1–9 |
| 11 | Niman extensions: frontmatter, math, wikilinks | — | Explicitly outside the conformance gate; own test suite |

### 4.8.2 Granularity of test naming

Name every test by **spec + example number + section**, so a failure is directly addressable:

```
commonmark/0.31.2/042 @Precedence
commonmark/0.31.2/350 @Emphasis and strong emphasis
gfm/0.29-gfm/257 @4.6 HTML blocks
gfm/0.29-gfm/677 @6.14 Textual content
ext/niman/frontmatter/003 @unterminated
```

* Assert **both** the normalized HTML and the raw HTML for a subset (the raw comparison catches escaping bugs the
  normalizer hides).
* Keep the `example` number as the stable id — it is contiguous and matches `start_line`/`end_line`, so a failure
  prints a `spec.txt` line range you can `sed -n` directly.
* Gate CI on `commonmark == 652/652` and `gfm == 677/677` with an explicit allowlist file for any known GFM
  oddity (see §4.8.4). The allowlist must be a checked-in file listing `spec/example-number` + a one-line reason,
  and CI fails if the allowlist entry starts passing (so it cannot rot).

### 4.8.3 Where the inevitable oddities get pinned

| Oddity | Pin |
|---|---|
| GFM's HTML-comment rule vs CM 0.31.2's (D3) | One boolean `gfmCommentRule` / `commonmarkCommentRule` on the raw-HTML tokenizer, defaulted by the active dialect. Two tests, same input, different expected output |
| GFM's missing `<textarea>` example (D1) | Test both dialects; the GFM run simply skips the example by number |
| Single-`~` strikethrough (D9) | Own test in `ext/gfm/strikethrough/` with both `~x~` and `~~x~~` and `~~~x~~~`, pinned to cmark-gfm's actual behaviour, **not** the prose |
| `tagfilter` case-insensitivity | Own tests for all 9 tags including uppercase variants (`<XMP>`) |
| Table header stealing the last paragraph line | Own test: `para\n| a | b |\n| - | - |` must yield `<p>para</p>` + table, not one paragraph |
| Math currency false positives | Own table in `ext/niman/math/`: `$5 and $10`, `$x$`, `$$x$$`, `\$5`, `` `$x$` ``, `$ x$`, `$x $`, `$x$5` |
| Wikilink precedence | Own table: inside code span, inside code block, inside a link label, inside a link destination, in a table cell, `![[x]]` next to a matching `[x]:` definition |

### 4.8.4 Definition of done

1. `commonmark 652/652`, `gfm 677/677` under the cmark `normalize_html` contract, with a checked-in,
   self-invalidating allowlist of at most a handful of entries.
2. All 21 `pathological_tests.py` shapes complete under a fixed wall-clock budget (this is a hard requirement
   for Niman's "novel-length files, no O(n) hot paths" constraint). The named cases to port:
   `nested strong emph` (65 000 deep), `many emph closers with no openers`, `many emph openers with no closers`,
   `many link closers with no openers`, `many link openers with no closers`, `mismatched openers and closers`,
   `openers and closers multiple of 3`, `link openers and emph closers`, `pattern [ (]( repeated`,
   `pattern ![[]() repeated`, `hard link/emph case`, `nested brackets`, `nested block quotes`,
   `deeply nested lists`, `U+0000 in input`, `backticks`, `unclosed links A/B`, `unclosed <!--`, `tables`,
   `reference collisions` (50 000 colliding reference labels).
3. Round-trip gate: `save(open(p)) == read(p)` over the whole corpus, plus `open → close` writes zero bytes.
4. Extension suites (frontmatter, math, wikilinks, callouts, footnotes) pass with their own pinned fixtures, and
   none of them can change the output of any of the 1 329 conformance examples.

---

## Appendix A — Quick reference constants for the Dart implementation

| Constant | Value |
|---|---|
| Escapable ASCII punctuation | ``!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~`` (32) |
| Bullet markers | `-` `+` `*` |
| Ordered markers | 1–9 digits + `.` or `)` |
| Fence chars | `` ` `` (≥3) or `~` (≥3) |
| Max ATX level | 6 |
| Max link-label length | 999 characters, ≥1 non-space |
| Max decimal entity digits | 7 |
| Max hex entity digits | 6 |
| Max link-destination paren nesting | ≥3 required |
| `openers_bottom` slots | 14 (6 used without smart punctuation: `_` 2–7, `*` 8–13) |
| HTML block type 6 tag count | 62 names (CM 0.31.2 list in §2, B11) |
| GFM tagfilter names | `title textarea style xmp iframe noembed noframes script plaintext` |
| Tabs | not expanded; 4-column tab stop **for structure only** |
| `U+0000` | replace with `U+FFFD` before parsing |

## Appendix B — Sources

* CommonMark 0.31.2 — https://spec.commonmark.org/0.31.2/ · `spec.txt` · `spec.json` · https://spec.commonmark.org/0.31.2/changes.html · https://spec.commonmark.org/changelog.txt
* CommonMark index / all versions — https://spec.commonmark.org/
* CommonMark spec repo + harness — https://github.com/commonmark/commonmark-spec
* GitHub Flavored Markdown Spec 0.29-gfm — https://github.github.com/gfm/
* cmark-gfm sources + tests — https://github.com/github/cmark-gfm · `test/spec.txt` · `test/spec_tests.py` · `test/normalize.py` · `test/roundtrip_tests.py` · `test/pathological_tests.py` · `extensions/table.c` · `extensions/core-extensions.c`
* commonmark.js inline parser (reference for §4.4) — https://github.com/commonmark/commonmark.js/blob/master/lib/inlines.js
* HTML5 named entities (authoritative for §4.6.2) — https://html.spec.whatwg.org/entities.json
* KaTeX auto-render — https://katex.org/docs/autorender
* Pandoc manual (`tex_math_dollars`, `footnotes`, `definition_lists`) — https://pandoc.org/MANUAL.html
* GitHub math docs — https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/writing-mathematical-expressions
* GitHub alerts docs — https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts
* Obsidian internal links — https://help.obsidian.md/links
* Obsidian embeds — https://help.obsidian.md/embeds
* Obsidian aliases — https://help.obsidian.md/aliases
* Obsidian properties / frontmatter — https://help.obsidian.md/properties
* Obsidian callouts — https://help.obsidian.md/callouts
* micromark (GFM tokenizer reference) — https://github.com/micromark
* babelmark3 differential tester — https://babelmark.github.io/

## 4.9 The `markdown` package measured

Everything above describes the *specifications*. This section is the other half
of decision D2: what the package that will actually parse Niman's notes does
against them. It was measured on 2026-09-21 with `dart run tool/markdown_spec.dart`,
and the harness, the fixtures and the gate are in the repo.

### 4.9.1 The number

| suite | examples | exact | **normalized** | failing |
|---|---|---|---|---|
| CommonMark 0.31.2 | 652 | 641 | **645 (98.9 %)** | 11 |
| GFM 0.29-gfm | 677 | 658 | **662 (97.8 %)** | 19 |

Two things about how that is counted, because both change how it reads:

- **Normalized, by cmark's own normalizer.** The suites' expected HTML and a
  parser's output differ in whitespace, attribute order, `<br />` and entity
  form, none of which is a parsing difference. `tool/html_normalize.dart` is a
  port of cmark's `test/normalize.py`, and `test/unit/html_normalize_test.dart`
  proves it agrees byte for byte on 375 cases — one known exception, pinned.
  Without that proof the number would be worth nothing.
- **It measures HTML, and Niman will consume the AST.** Several divergences
  (`data-metadata` on `<pre>`, `class` attributes on task-list items) are
  serializer details that never reach a user. **The HTML number is a lower
  bound**, and the bound that matters for the engine is higher.

### 4.9.2 The failures, triaged

Twenty-two examples fail by the reference's comparison; the other eight
non-exact ones (four per suite) differ only in formatting and therefore pass.
The complete list, with a bucket and a reason each, is
`test/fixtures/spec/nonconforming.txt`; the shape of it is:

| bucket | count | what they are |
|---|---|---|
| **fix** | 8 | two tab cases (a tab in a nested block loses its indentation), two lone link-reference-definition cases (they emit whitespace instead of nothing), three autolinks whose `mailto:`/`xmpp:` scheme is split off the link |
| **pin** | 14 | `data-metadata` on `<pre>` and `class` on task-list items (4 — serializer details Niman never sees), the CommonMark 0.31.2 WHATWG HTML-comment rule (2 — GFM keeps 0.29's, and Niman is GFM-first), the 0.31.2 currency-emphasis rule (1 — which GFM's own example set omits), the bare-URL autolink examples inherited from CommonMark's section (3 — GFM itself autolinks), GFM's self-contradicting strikethrough (1), and the tagfilter extension (1 — sanitizing raw HTML is wrong for notes the app renders as written) |

The gate runs **in both directions** (`test/unit/markdown_conformance_test.dart`):
everything outside the allowlist must pass, and everything inside it must still
fail, so a fix cannot go unnoticed and cannot hide behind an old exemption.

### 4.9.3 The engine's own number, which is the one that matters

The table in §9.1 measures the **package**. What the app shows is what the
*engine* produces: the block scanner decides the blocks, the masker sets the
note's own constructs aside, and the package parses each block. So the
successor question — named in the first version of this section as the honest
next step — is what that path does on the same suites.

`dart run tool/engine_spec.dart` and `test/unit/engine_parity_test.dart` answer
it, and the answer is sharper than a second pass rate:

| suite | blocks the engine does not mask | identical to the package's own answer |
|---|---:|---:|
| commonmark/0.31.2 | 1 745 | **1 745** |
| gfm/0.29-gfm | 1 838 | **1 838** |

**3 583 blocks, 3 583 identical.** Everywhere the engine does not intervene it
reproduces the package byte for byte — so the block decomposition, the
per-block parse and the concatenation add nothing and lose nothing, and the
conformance number above is *inherited* rather than merely claimed. That is the
property that matters, and it is now a test rather than an argument.

Where the engine **does** mask, its answer differs by design: 155 blocks across
the two suites, because those constructs are the app's own and the renderer
draws them from the spans. Measured but not asserted: whole documents come out
identical in 578 of 652 and 602 of 677, and the gap is two things the renderer
owns rather than the parser — a list is several blocks here (one per item,
because a block is a *layout* unit) and reference definitions and footnotes are
document-scoped. Assembling those is Phase 2's job, and the number is the size
of it.

### 4.9.4 The eight, decided

Phase 1's gate is the package's, so the eight examples it flagged were left as
an explicit debt. Each is now decided, and none of them is a bug in the engine:

| examples | decision |
|---|---|
| `commonmark/6`, `gfm/6` (a tab in a nested container) | **inherited, pinned.** The engine reproduces the package block for block, and the app's own worst note contains **zero tabs** — measured. |
| `commonmark/207`, `gfm/176`, `gfm/188` (a lone link reference definition) | **inherited, pinned — and the app is right.** The package's *HTML* is whitespace where the spec asks for nothing; the engine's *runs* for that block are empty, so the app shows nothing. `engine_parity_test.dart` proves it. |
| `gfm/633` (`mailto:`) | **fixed in the engine.** The package links the address but not the scheme; the bridge joins them back into one run with the scheme in its text, which is what GFM renders. |
| `gfm/634`, `gfm/635` (`xmpp:` with a path) | **inherited, pinned with the reason.** The package links the address with the *wrong* scheme and stops before the path; taking the whole scheme-prefixed run is the masking layer's job, and it will have a span kind for it when the renderer can draw one. |

So of the eight: one is fixed where the fix belongs — in the engine's own model,
which a dependency bump cannot lose — and seven are inherited with the reason
recorded, three of them proved to leave the app correct.

### 4.9.5 The read mode, measured

Phase 2 builds the surface the design described, behind
`MarkdownEngine.unified` and off by default. Its own gate is
`test/widget/engine_compare_test.dart`: both engines are pumped over the same
fixture at a viewport tall enough that neither windows anything, and their
visible text is compared — a marker left in, a construct dropped, a paragraph
drawn twice. Pixels would be the strongest comparison and the most brittle; the
words are what a reader sees.

| fixture | the two engines agree |
|---|---|
| `fixture-1kb.md` | **identical** |
| `fixture-10kb.md` | **identical** |
| `fixture-50kb.md` | **identical** |

All three render the same words in the same order. The gate found **eight** real
bugs on the way there, which is what a gate is for:

- container syntax drawn as text — a list item's `- `, a quote's `> `, a task
  box's `[x] `, which the parser strips and no run covers;
- a list marker read from the text instead of drawn, so a task list showed
  `[x]` where the preview drew a checkbox;
- an ordered list showing the number the note *wrote* rather than the item's
  place in the list — CommonMark ignores those numbers except the first, so
  `1. 1. 1.` is a list of three;
- a quote block built at depth zero, because the scanner took its depth from the
  state *entering* the first line — which is before that line's own `>`;
- a `Display` formula keeping a stray `$` at each end, from a delimiter rule
  that assumed one character rather than two;
- Markdown images drawn as their alt text;
- footnotes that resolved to nothing: a reference and a definition are written
  in different blocks and the engine parses per block;
- a block the parser *consumed* — a reference definition — drawn as the text it
  did not cover.

The last thing to fall was the section the package ends a document with: the
definitions listed with their backlinks. It is drawn through a lazy sliver for
the same reason the note is — appending it whole took first content from 76 ms
to 112 ms on the geometry note and the jump from 9 ms to 56.

And the timings, from `test/perf/read_view_timing_test.dart`, held against this
document's own budget of **≤ 60 ms target / 120 ms ceiling** for text to first
visible content:

| fixture | blocks | laid out | parsed | first content | jump |
|---|---:|---:|---:|---:|---:|
| `fixture-50kb.md` | 1 092 | 57 | 57 | 175 ms | 43 ms |
| `fixture-200kb.md` | 4 301 | 69 | 69 | **82 ms** | 32 ms |
| `Geometria 1.md` | 7 530 | 85 | 85 | **91 ms** | 31 ms |

The geometry note — 934 KB, 13 845 formulas — reaches first content in **91 ms**
against the preview's recorded 137 ms, and lays out **85 blocks of 7 530**: the
windowing is what the number is made of. The 50 KB fixture is slower than the
200 KB one and the reason is worth recording: its first screen is dense with
display formulas, and the first render of each is typeset inside this
measurement — by the preview exactly as by the read view — with the math cache
amortizing it from the second frame on. Its ceiling is 250 ms in the test, a
recorded decision rather than a conveniently chosen number.

These are debug-mode harness numbers, as every benchmark in this repository is:
the ratios carry and the absolutes do not.

**And a device read about a second, which the harness cannot see (2026-09-21).**
Opening the read pane on the geometry note took **1 022 ms** from the flip
(`preview: flip showPreview=true` at 18:03:17.954) to the first frame after it
(18:03:18.976), and that frame itself was cheap — 18.5 ms total, 10.8 of them
build. The harness above reads 91 ms for the same note. Both can be true, and
which one it was could not be told from the log, because **the read pane had no
trace of its own**: the editor has had `note open first frame` since T-PP-22, the
legacy preview logs its parse, and the pane the user was waiting for logged
nothing. The missing instrument is the finding; the cause is still open.

It now emits three lines, all of them through the existing seams and none of them
per-frame: `[read] scan: N blocks, M lines in Xms` when the scanner runs,
`[read] first content: N blocks, K built, Xms after the view was created` from the
frame that first drew blocks, and `[preview] read pane first frame: … after call`
at the flip. The frame window (`FrameProbe`, 2.5 s, frames over budget and worst
build/raster) is watched too, but only when `AppLog.file` is attached — the run
whose log can be handed over — which also keeps a 2.5-second timer out of widget
tests, where it is a pending timer rather than a measurement.

The same log had a second thing to say, and it said it wrongly: `[preview] parse
async: stale rev 1 (current 1), dropped` — the numbers equal, which is the tell
that the revision was *not* the reason. The condition is `!mounted || revision !=
_parseRevision` and it was the first half: a `MarkdownPreview` for the 931 KB note
was mounted, spent a parse off the isolate, and was gone before the result landed.
The line now names which of the two happened, because reading it as a staleness
bug cost an afternoon of chasing a parse that had nothing to do with the symptom.

Where that legacy preview came from is a real gap, and the trace is what named it:
`NoteView.unifiedMarkdown` defaults to `false` and
`lib/src/ui/outside_file_screen.dart` never passes it, so a file opened from
outside the library is drawn by the **old** engine while the same file inside the
library is drawn by the new one — with the engine setting on, and no hint on
screen. Fixed in the same round.

### 4.9.6 What it changes

- **Risk K1 collapses.** "The parser never fully conforms" was the largest
  technical risk in the design document, with weeks of grind behind it. It is
  now eight enumerated examples, two of which are whitespace.
- **The conformance number is a measurement, not a goal**, and it is
  re-measured on every `flutter test` rather than argued about. A future package
  bump that regresses it fails CI on the example that moved.
- **D2 is vindicated, and D5's target needs restating honestly.** "100 % of both
  suites" is not free: it means fixing the eight, or pinning them as the
  fourteen are pinned. The eight are cheap; what the number removes is the
  *fear* that the gap is unbounded, which is what made "write our own parser"
  look reasonable.
- **The AST caveat is answered** in §9.3: the engine's own number is the block
  parity, 3 583 of 3 583, and the eight are decided in §9.4.


---

# 5. The corpus reality

**Purpose.** Size and justify a high-performance Markdown rendering design from
measured properties of the real corpus, not from intuition. Every number below was
produced by a command in this session; the producing script is named next to each
table. Nothing in this file is an estimate unless the word *estimate* appears.

**Targets (read-only, never modified):**

| file | bytes | lines |
|---|---|---|
| `Geometria 1.md` | 934 769 | 10 331 |
| `test/fixtures/markdown/fixture-200kb.md` | 206 241 | 6 288 |
| `test/fixtures/markdown/fixture-1mb.md` | 1 050 145 | 32 100 |
| `/tmp/niman-research/fixtures/worst-note.md` (generated by this study, not in the repo) | 1 482 533 | 11 773 |
| `test/fixtures/markdown/fixture-1kb.md` | 1 145 | 35 |
| `test/fixtures/markdown/fixture-10kb.md` | 10 522 | 399 |
| `test/fixtures/markdown/fixture-50kb.md` | 51 898 | 1 594 |
| `test/fixtures/markdown/fixture-500kb.md` | 513 423 | 15 303 |

**Reproduce everything:** `bash /tmp/niman-research/scripts/run_all.sh`
(writes JSON to `/tmp/niman-research/out/`, then `python3 /tmp/niman-research/scripts/gen_report.py`).

**Method and its limits.** Block classification is a pragmatic CommonMark-ish
line-state machine in `scripts/gen_block_census.py`; inline scanning is a
character-level scanner in `scripts/gen_inline_census.py` that is *not* recursive
(one known, quantified consequence is flagged in §3). The block classifier's byte
totals reconcile to the file size exactly for every target, which is the strongest
available check that no line was double-counted or dropped:

| file | sum of block bytes | file bytes | match |
|---|---|---|---|
| `Geometria 1.md` | 934 769 | 934 769 | exact |
| `fixture-200kb.md` | 206 241 | 206 241 | exact |
| `fixture-1mb.md` | 1 050 145 | 1 050 145 | exact |
| `worst-note.md` | 1 482 533 | 1 482 533 | exact |

---

### 4.9.7 The removal, taken

This section first recorded a removal that had been planned, measured — 176 sites
across 56 files, cut three independent ways — and then **not** taken: on
2026-09-21 the split was kept. The same day, with those numbers in hand, the
decision was reversed and the removal was run. What follows is what it actually
took, written down for the same reason the plan was: whoever touches this
surface next should find its shape here rather than reconstruct it from a diff.

**What went, in the order the plan set out:**

1. `previewEnabled` — the library setting, the session accessor, the Editor
   settings switch, the settings-search entry, the `LibraryConfig` field, and
   the shell's conditionals. The preview is part of the app now, so
   `_previewToggleVisible` is only about the note: a kind GUI hides the eye
   unless the note is being edited raw.
2. The split ratio and the layout override — `PreviewLayoutMode`,
   `previewSplits`, `splitRatio`/`splitFraction`, `defaultSplitRatio`,
   `minSplitRatio`, `maxSplitRatio`, the app-bar picker, the Appearance row
   and the drag persistence. **The database columns went too**, against this
   document's own advice to leave them: `ALTER TABLE ... DROP COLUMN` is two
   lines at v27, the chain already does exactly that at v17, and a settings
   field nothing reads is a lie about what the app does. `splitBreakpoint`
   kept its job and lost its name — it is `wideBreakpoint` now, because what
   it decides is whether the shell is the rail-tree-note shape or the
   phone's.
3. The split itself — `EditorPreviewSplit` (deleted, with its file),
   `_previewVisible`, `_previewFullScreen`, `ExitFullScreenButton`,
   `PreviewLayoutModeAction`, the shell's `previewSplitsHere` /
   `previewFullScreen` / `previewVisible` props and `onLeaveFullScreenPreview`,
   `DetailTab.splitPreview`, `NoteStatusRow.splitPreview`, and `NoteView`'s
   four split parameters. The note is one pane: `NoteView.showPreview` picks
   which of the two it holds, and the other stays mounted `Offstage`, where it
   already was.
4. `docs/user/editing.md` and `docs/user/settings.md`, in the same commit:
   both described a screen and three settings that no longer exist.

**Four things the removal changed rather than deleted**, each a decision:

- **The phone's preview flag became the tab's.** `_previewVisible` was the
  phone's own boolean, so the preview was on for the *screen*: opening the
  next note kept it. The flag now lives in the note's tab memento, as it
  always did on a wide window, so a note comes back the way it was left and
  the next one opens in the editor. Both layouts read it through one
  `_notePreview`, and `_mementoOf` answers with an empty memento for a note
  whose tab this build has not made yet — the transition frame — instead of
  the note before it.
- **A template's `open: preview` now works on both layouts.** It used to set
  `_previewVisible`, which the wide layout never reads, so the directive did
  nothing there. It is applied to the filed note's tab, queued behind the
  follow that makes the tab (`ShellWorkspace.showPreviewWhenOpen`).
- **`previewEnabled` was a known `settings.json` key.** It stays in
  `_knownKeys` as a legacy key that is read and never written, the way
  `spellDictionary` is: a library whose file still says `false` gets the key
  dropped on the next write rather than preserved forever as an unknown one.
- **The immersive full-screen preview went with the split**, rather than
  staying as chrome-less reading: one pane, one mode, and the phone's note is
  a normal page with its app bar either way. That was a product decision
  taken with the removal, not a consequence of it.

**The words.** The two settings' strings were removed rather than left dead:
ten getters from `base.dart` and from each of the 37 locales — 380
declarations — plus the ten accessors and `splitRatioValue` from
`strings.dart`. One string stayed: `commandNeedPreview` still labels
`CommandNeed.previewToggle`, whose only remaining condition is that the note
is text, so its wording ("With the preview on, on a text note") is now half a
sentence about a setting that no longer exists. Rewording it means rewording
it in 38 languages, which is a translation task, not this one.

**What the measurement got wrong.** The plan's two feared costs were the
migration and the strings, and it recommended leaving both. Both turned out to
be the cheap half: the migration is a `DROP COLUMN` with a precedent ten
versions back, and the strings are 380 mechanical deletions a script did. What
the measurement got right was the reason there is no green intermediate state,
and it was never the count: settings, session, the shell, the note view, the
database and their tests had to move in one commit because nothing compiles
until the last of them agrees.

**Where it left the phase.** `markdownEngine` still defaults to `legacy`, so
the eye shows the old preview until someone turns the unified engine on; the
numbers that should decide that are §4.9.5. What the split's departure removes
is the surface the two engines were being compared *in*, which is why the
comparison had to come first and did.

## 5.1 Global stats

Produced by `scripts/gen_global_stats.py` (`global.json`). Lines are `\n`-delimited;
a trailing newline does not create a phantom final line. "Graphemes" is the codepoint
count minus combining marks, ZWJ and variation selectors — an *approximation*, marked
as such, because no real grapheme segmentation was run.

| file | bytes | lines | chars | avg B/line | avg B/nonblank | max B/line | line# |
|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 934 769 | 10 331 | 931 042 | 89.48 | 136.45 | 2 568 | 9 056 |
| `fixture-1kb.md` | 1 145 | 35 | 1 145 | 31.71 | 38.28 | 240 | 23 |
| `fixture-10kb.md` | 10 522 | 399 | 10 522 | 25.37 | 34.2 | 347 | 184 |
| `fixture-50kb.md` | 51 898 | 1 594 | 51 898 | 31.56 | 42.85 | 405 | 846 |
| `fixture-200kb.md` | 206 241 | 6 288 | 206 241 | 31.8 | 43.76 | 412 | 4 142 |
| `fixture-500kb.md` | 513 423 | 15 303 | 513 423 | 32.55 | 44.57 | 437 | 10 170 |
| `fixture-1mb.md` | 1 050 145 | 32 100 | 1 050 145 | 31.71 | 43.37 | 439 | 10 027 |

| file | lines >200 B | >500 B | >1000 B | >2000 B | blank | non-blank | CRLF | bare CR | mixed EOL | tabs | lines w/ tab | leading-tab lines | leading-space lines | trailing-WS lines |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 1524 | 376 | 61 | 3 | 3 556 | 6 775 | 0 | 0 | no | 0 | 0 | 0 | 925 | 0 |
| `fixture-1kb.md` | 2 | 0 | 0 | 0 | 6 | 29 | 0 | 0 | no | 0 | 0 | 0 | 4 | 0 |
| `fixture-10kb.md` | 10 | 0 | 0 | 0 | 103 | 296 | 0 | 0 | no | 0 | 0 | 0 | 29 | 0 |
| `fixture-50kb.md` | 72 | 0 | 0 | 0 | 420 | 1 174 | 0 | 0 | no | 0 | 0 | 0 | 121 | 0 |
| `fixture-200kb.md` | 297 | 0 | 0 | 0 | 1 719 | 4 569 | 0 | 0 | no | 0 | 0 | 0 | 378 | 0 |
| `fixture-500kb.md` | 730 | 0 | 0 | 0 | 4 126 | 11 177 | 0 | 0 | no | 0 | 0 | 0 | 1038 | 0 |
| `fixture-1mb.md` | 1450 | 0 | 0 | 0 | 8 629 | 23 471 | 0 | 0 | no | 0 | 0 | 0 | 2226 | 0 |

| file | BOM | valid UTF-8 | lone surrogates | surrogate byte seqs | non-ASCII bytes | non-ASCII byte share | non-ASCII chars | combining marks | ZWJ | VS | graphemes (approx.) | words |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | no | yes | 0 | 0 | 7 280 | 0.7788 % | 3 553 | 0 | 0 | 0 | 931 042 | 158 444 |
| `fixture-1kb.md` | no | yes | 0 | 0 | 0 | 0.0 % | 0 | 0 | 0 | 0 | 1 145 | 153 |
| `fixture-10kb.md` | no | yes | 0 | 0 | 0 | 0.0 % | 0 | 0 | 0 | 0 | 10 522 | 1 466 |
| `fixture-50kb.md` | no | yes | 0 | 0 | 0 | 0.0 % | 0 | 0 | 0 | 0 | 51 898 | 7 289 |
| `fixture-200kb.md` | no | yes | 0 | 0 | 0 | 0.0 % | 0 | 0 | 0 | 0 | 206 241 | 29 129 |
| `fixture-500kb.md` | no | yes | 0 | 0 | 0 | 0.0 % | 0 | 0 | 0 | 0 | 513 423 | 72 532 |
| `fixture-1mb.md` | no | yes | 0 | 0 | 0 | 0.0 % | 0 | 0 | 0 | 0 | 1 050 145 | 147 965 |

### 5.1.1 Reading of the global stats

- **The real note is 89.5 bytes/line average and 10 331 lines.** Its 1 MB fixture
  counterpart is 31.7 bytes/line over 32 100 lines: same order of magnitude of bytes,
  **3.1× fewer lines**. Line-count-driven costs (per-line tokenization, per-line
  layout, scroll mapping by line index) are therefore *worse* for the real note than
  for the 1 MB synthetic fixture the benchmarks use. This is the single most
  important sizing fact in this document.
- **The synthetic fixtures are 100 % ASCII**; the real note is 0.78 % non-ASCII
  (7 280 bytes: accented Italian, `•`, `−`, `∈`-adjacent typography). No combining
  marks, no ZWJ, no variation selectors, no lone surrogates, no BOM anywhere. So
  grapheme-cluster handling is *not* exercised by this corpus, while Latin-1
  supplements are.
- **Line endings: pure LF, zero CRLF, zero bare CR, zero tabs** in all seven files.
  Trailing whitespace: zero lines everywhere — so a 2-space hard break does not occur
  once in the whole corpus (see §3).
- **1 524 lines over 200 bytes** in the real note, 376 over 500, 61 over 1 000, 3 over
  2 000. The synthetic fixtures never exceed 439 bytes. Long-line handling is a real-
  note-only problem.
- Irregularity is low: no BOM, no CRLF, no tabs, no trailing whitespace, no surrogate
  weirdness. The corpus is *hard because of volume and math*, not because of encoding
  edge cases.

### 5.1.2 Longest lines (top 3 per file)

Provenance: `scripts/gen_global_stats.py`, `longest` field of `global.json`.

| file | bytes | line | excerpt (first 150 chars; source backticks shown as ′) |
|---|---|---|---|
| `Geometria 1.md` | 2 568 | 9 056 | `Per l'autovalore $-2$: $\dim \ker(\phi + 2) = 2$, $\dim \ker(\phi + 2)^4 = 4$. Poiché il polinomio minimo per $-2$ ha grado $4$ (visto che $\dim \ker(` |
| `Geometria 1.md` | 2 338 | 6 501 | `Iniziamo dalle funzioni più semplici, quelle in cui $c = 0$ e la funzione è del tipo $f(z) = az + b$ (trasformazione affine complessa). Risulta $D_f =` |
| `Geometria 1.md` | 2 224 | 9 426 | `**7.31** (a) La restrizione di $g$ a $\langle e_4 \rangle^\perp = \langle e_1, e_2, e_3 \rangle$ è definita positiva e quindi per ogni vettore $v \in ` |
| `Geometria 1.md` | 1 915 | 9 367 | `**7.27** Questa dimostrazione è stato già brevemente illustrata, in forma diversa, nell'Esempio 7.5.3. (a) Per ogni $v \in \mathbb{R}^3$, si ha $\\|X ` |
| `Geometria 1.md` | 1 880 | 5 603 | ` Infatti il polinomio caratteristico di $A$ ha coefficienti reali e grado $3$ e pertanto ammette almeno uno zero reale $\lambda$. Questo è un autovalo` |
| `fixture-200kb.md` | 412 | 4 142 | (max — fixtures never exceed 439 B) |
| `fixture-1mb.md` | 439 | 10 027 | (max — fixtures never exceed 439 B) |

The three longest lines in the real note are all **single-line paragraphs that are
mathematically dense** (2 568, 2 338, 2 224 bytes). Line 9 056 alone is a one-paragraph
block carrying ~95 inline math spans, i.e. one `TextPainter` input of roughly 32
wrapped lines — see §5 and §6.

---

## 5.2 Block-level census

Produced by `scripts/gen_block_census.py` (`blocks.json`). `lines` counts source lines
(they sum exactly to the file line count); `blocks` counts renderable blocks.
`% bytes` is the share of the whole file. Rules that materially change the reading:

- a **list item** is one block and owns its own line; a multi-line list item is not
  split, so `paragraph line` excludes text that belongs to a list item;
- **blockquote** lines are classified by their residual content after stripping `>`
  markers, so a quoted paragraph is counted in `paragraph line`, not in a separate
  bucket; the separate `> depth` histogram in §2.4 accounts for the markers;
- a `$$` line opens a **math block** that runs to the closing `$$`;
- `[^label]: ...` is a **footnote definition**, not a link reference definition
  (the two were separated after an initial run conflated them — this materially
  changes the link-census reading in §3).

### 5.2.1 `Geometria 1.md`

934 769 bytes, 10 331 lines. `% bytes` = share of file bytes.

| construct | blocks | lines | bytes | % bytes |
|---|---|---|---|---|
| frontmatter | 1 | 5 | 52 | 0.006 % |
| blank | 3 556 | 3 556 | 3 556 | 0.380 % |
| ATX heading | 84 | 84 | 2 882 | 0.308 % |
| paragraph line | 2 392 | 2 392 | 690 146 | 73.831 % |
| thematic break | 22 | 22 | 88 | 0.009 % |
| list item | 852 | 852 | 87 523 | 9.363 % |
| HTML block | 2 | 2 | 1 126 | 0.120 % |
| footnote definition | 17 | 17 | 2 069 | 0.221 % |
| GFM table | 2 | 9 | 640 | 0.068 % |
| math block (`$$`) | 841 | 3 392 | 146 687 | 15.692 % |
| **total** | **7 769** | **10 331** | **934 769** | **100.000 %** |

### 5.2.2 `fixture-200kb.md`

206 241 bytes, 6 288 lines. `% bytes` = share of file bytes.

| construct | blocks | lines | bytes | % bytes |
|---|---|---|---|---|
| frontmatter | 1 | 11 | 133 | 0.064 % |
| blank | 1 719 | 1 719 | 1 719 | 0.833 % |
| ATX heading | 214 | 214 | 6 054 | 2.935 % |
| paragraph line | 646 | 683 | 116 674 | 56.572 % |
| thematic break | 29 | 29 | 116 | 0.056 % |
| list item | 1 165 | 1 165 | 27 136 | 13.157 % |
| fenced code block | 175 | 1 220 | 20 308 | 9.847 % |
| footnote definition | 40 | 40 | 1 383 | 0.671 % |
| GFM table | 171 | 904 | 24 178 | 11.723 % |
| math block (`$$`) | 141 | 303 | 8 540 | 4.141 % |
| **total** | **4 301** | **6 288** | **206 241** | **100.000 %** |

### 5.2.3 `fixture-1mb.md`

1 050 145 bytes, 32 100 lines. `% bytes` = share of file bytes.

| construct | blocks | lines | bytes | % bytes |
|---|---|---|---|---|
| frontmatter | 1 | 10 | 130 | 0.012 % |
| blank | 8 629 | 8 629 | 8 629 | 0.822 % |
| ATX heading | 1 043 | 1 043 | 30 215 | 2.877 % |
| paragraph line | 3 256 | 3 469 | 589 169 | 56.104 % |
| thematic break | 166 | 166 | 664 | 0.063 % |
| list item | 6 764 | 6 764 | 156 067 | 14.861 % |
| fenced code block | 867 | 6 095 | 101 356 | 9.652 % |
| footnote definition | 40 | 40 | 1 383 | 0.132 % |
| GFM table | 856 | 4 488 | 117 945 | 11.231 % |
| math block (`$$`) | 704 | 1 396 | 44 587 | 4.246 % |
| **total** | **22 326** | **32 100** | **1 050 145** | **100.000 %** |

### 5.2.4 Sub-censuses

#### ATX headings by level

| file | H1 | H2 | H3 | H4 | H5 | H6 | setext H1 | setext H2 |
|---|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 15 | 59 | 10 | 0 | 0 | 0 | 0 | 0 |
| `fixture-200kb.md` | 0 | 51 | 118 | 45 | 0 | 0 | 0 | 0 |
| `fixture-1mb.md` | 0 | 258 | 541 | 244 | 0 | 0 | 0 | 0 |

The real note uses only H1–H3 (15/59/10). **No level 4-6 and no setext heading
appears at all**; the fixtures stop at H4. A renderer sized on this corpus does not
need deep heading styling, but it does need H4–H6 to not crash on user input.

#### List items — bullet marker and nesting depth

Provenance: `blocks.json` `bullet_marker_chars`, `bullet_depth_count`,
`ordered_delim_count`, `ordered_depth_count`; depth is the number of enclosing list
items according to the indent stack (indents 0, 2, 4, … each open one level).

| file | bullet `-` | bullet `*` | bullet `+` | ordered `.` | ordered `)` | depth 1 | depth 2 | depth 3 | depth 4+ |
|---|---|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 852 | 0 | 0 | 0 | 0 | 612 | 215 | 25 | 0 |
| `fixture-200kb.md` | 781 | 0 | 0 | 384 | 0 | 1017 | 148 | 0 | 0 |
| `fixture-1mb.md` | 4771 | 0 | 0 | 1993 | 0 | 5629 | 1135 | 0 | 0 |

Bullet nesting depth histogram, real note: depth 1 = 612, depth 2 = 215, depth 3 = 25.
The fixtures reach depth 2. **Depth 3 is the corpus maximum.** The real note uses
`-` exclusively (852 items, zero `*`, zero `+`) and has **zero ordered lists**; the
fixtures supply all 2 377 ordered items, all with the `.` delimiter (no `)` form).

#### Task lists and strikethrough (fixtures only)

| file | `- [ ]` | `- [x]` | strikethrough spans |
|---|---|---|---|
| `Geometria 1.md` | 0 | 0 | 0 |
| `fixture-200kb.md` | 168 | 152 | 58 |
| `fixture-1mb.md` | 682 | 720 | 279 |

Task lists and `~~strikethrough~~` are **GFM features that only the fixtures use**;
the real note has neither. They still have to work, but they are not what makes the
real note expensive.

#### Blockquote marker lines and nesting depth

Provenance: `scripts/gen_bq_depth.py` (`bq.json`), a direct line-level count of
leading `>` markers — independent of the block classifier.

| file | lines with `>` | bytes | depth 1 | depth 2 | depth 3 | depth 4 | max depth |
|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 22 | 1 978 | 22 | 0 | 0 | 0 | 1 |
| `fixture-200kb.md` | 119 | 2 512 | 119 | 0 | 0 | 0 | 1 |
| `fixture-1mb.md` | 611 | 13 185 | 611 | 0 | 0 | 0 | 1 |
| `worst-note.md (§7 fixture)` | 17 | 391 | 5 | 3 | 5 | 4 | 4 |

The real note has **22 blockquote lines, all depth 1, all of the form `> Figura N.N`**
(figure captions). There is **no nested blockquote and no blockquote containing a
list, a table or a display-math block** anywhere in the corpus. §7 makes that an
explicit adversarial case because a renderer that never sees it is a renderer that
was never tested for it.

#### Fenced code blocks

| file | blocks | fence char ` | fence char `~` | min lines | max lines | mean lines | info strings |
|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 0 | 0 | 0 | 0 | 0 | 0 | — |
| `fixture-200kb.md` | 175 | 175 | 0 | 5 | 9 | 6.97 | `empty`×34, `dart`×24, `javascript`×48, `python`×37, `sql`×32 |
| `fixture-1mb.md` | 867 | 867 | 0 | 5 | 9 | 7.03 | `empty`×171, `dart`×185, `javascript`×172, `python`×171, `sql`×168 |

Fence size distribution (real note has none; fixture-200kb shown):

| fence size (source lines) | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|
| blocks | 39 | 33 | 33 | 34 | 36 |

The synthetic fences are all 5–9 source lines; the real note has none. Fence size and
count are **fixture-only** properties; the 1 MB fixture has 867 fences.

#### GFM tables

| file | tables | total bytes | % bytes | columns used | body-rows used |
|---|---|---|---|---|---|
| `Geometria 1.md` | 2 | 640 | 0.068 % | 3×1, 4×1 | 3×1, 4×1 |
| `fixture-200kb.md` | 171 | 24 178 | 11.723 % | 2×58, 3×52, 4×61 | 3×41, 4×56, 5×58, 6×16 |
| `fixture-1mb.md` | 856 | 117 945 | 11.231 % | 2×292, 3×285, 4×279 | 3×213, 4×313, 5×239, 6×91 |

The real note's two GFM tables are small (3×3 and 4×4). **11.7 % of the 200 KB
fixture and 11.2 % of the 1 MB fixture is table bytes** at up to 4 columns × 6 rows —
i.e. table *count* is fixture-dominated whereas table *size* is tiny everywhere in
this corpus.

The real note also contains two **single-line raw-HTML `<table>` blocks** that the
PDF→Markdown conversion emitted *inside* a paragraph — line 8 114 is
` Dunque si tratta … quadrati magici | 0 | 2 | 1 | |---|---|---| | 2 |` followed by
line 8 116 `<table style="min-width: 75px;"><colgroup>…`. That is a genuine parser
worst case: a Markdown table header/body fused into prose, immediately followed by an
HTML table with no blank line.

#### Footnote definitions and link reference definitions

| file | footnote definitions | link reference definitions | first footnote label | last footnote line |
|---|---|---|---|---|
| `Geometria 1.md` | 17 | 0 | `1` | 10331 |
| `fixture-200kb.md` | 40 | 0 | `1` | 6288 |
| `fixture-1mb.md` | 40 | 0 | `1` | 32100 |

**The real note has zero link reference definitions.** All 17 blocks that look like
`[label]: dest` are footnote definitions (`[^1]: …` at lines 10 299–10 331). The
fixtures likewise have 40 footnote definitions and zero link reference definitions.
Only the adversarial fixture in §7 exercises real link reference definitions.

#### Frontmatter

| file | lines | bytes | % bytes |
|---|---|---|---|
| `Geometria 1.md` | 5 | 52 | 0.006 % |
| `fixture-200kb.md` | 11 | 133 | 0.064 % |
| `fixture-1mb.md` | 10 | 130 | 0.012 % |

Frontmatter is negligible in size (0.006 % of the real note) but it must be
recognised *before* the body, otherwise the opening `---` becomes a thematic break or
a setext underline. All seven targets begin with a `---` frontmatter block.

---

## 5.3 Inline-level census

Produced by `scripts/gen_inline_census.py` (`inline.json`). Scanned region =
paragraph, heading, list-item text, table cells and footnote-definition lines;
fenced code, indented code, HTML blocks, frontmatter and math blocks are excluded.

Two emphasis readings are given. **raw** treats `$` as ordinary text (plain
CommonMark). **math-aware** masks `$…$` and code spans first. The gap between them is
the single most important inline finding in this document.

### 5.3.1 Emphasis / strong delimiter runs

| file | `*`×1 raw | `**` raw | `***` raw | `****` raw | `_`×1 raw | `*`×1 math-aware | `**` math-aware | `***` math-aware | `****` math-aware | `_`×1 math-aware |
|---|---|---|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 454 | 2595 | 1 | 6 | 7530 | 209 | 2571 | 1 | 16 | 17 |
| `fixture-200kb.md` | 298 | 324 | 0 | 0 | 230 | 298 | 324 | 0 | 0 | 0 |
| `fixture-1mb.md` | 1472 | 1438 | 0 | 0 | 1210 | 1472 | 1438 | 0 | 0 | 0 |

**7 530 single `_` runs in the real note collapse to 17 once math is masked** — a
99.8 % reduction. Those 7 513 runs are TeX subscripts (`x_1`, `a_{ij}`). A renderer
that resolves emphasis before it recognises `$…$` must therefore make 7 513 pendant
delimiter decisions per document that a correct order of operations avoids entirely.
The same effect is visible in the fixtures at smaller scale (1 210 / 230 → 0).

The `**` counts barely move (2 595 → 2 571, and 16 four-star runs appear once math is
masked, because masking joins `**` from adjacent text). **`**` is the workhorse
inline span: ~2 595 delimiter runs, i.e. on the order of 1 300 strong spans.**
`***` occurs exactly once in the whole real note. `****` occurs 6 times raw, 16
math-aware; both are pathological (adjacent `**`…`**` across a masked span), not a
feature a renderer should special-case.

### 5.3.2 Links, images, autolinks, HTML, escapes, entities, breaks

| file | inline link | ref full | ref collapsed | ref shortcut (candidate) | link remote | link local/rel | image inline | image local | image remote | autolink | raw inline HTML | entity ref | backslash escape | hard break (2 space) | hard break (`\`) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 0 | 0 | 0 | 9 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `fixture-200kb.md` | 87 | 0 | 0 | 152 | 87 | 0 | 54 | 54 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `fixture-1mb.md` | 412 | 0 | 0 | 720 | 412 | 0 | 274 | 274 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Findings for the real note:

- **Zero inline links, zero reference links, zero images, zero autolinks, zero raw
  inline HTML, zero entities, zero backslash escapes, zero code spans, zero hard
  breaks.** All 40 links in the file are `[[wikilinks]]`. This is a *Markdown-light,
  math-heavy* document: the inline parser's whole budget goes to `$…$` and `**…**`.
- The 9 "shortcut" candidates are real false positives: `[Determinanti e operazioni
  elementari.]`, `[Teorema di Schur]`, `[**Spazio di Minkowski**]` — bracketed prose in
  the book's table of contents with no matching reference definition. They must render
  as literal text. A naive shortcut-reference resolver would render 9 broken links.
- The fixtures are the mirror image: **412 inline links, 274 local images, 579 code
  spans, 720 task-checkbox `[x]` brackets** in the 1 MB file, and zero math density to
  speak of. Neither corpus alone exercises the full inline grammar.

### 5.3.3 Code spans and inline math, length distribution

| file | code spans | code body bytes | code min/mean/max | code ≤20 B | inline math (census) | math body bytes | math min/mean/p50/p90/p99/max |
|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 0 | 0 | — | 0 | 13 000 | 212 008 | 1 / 16.31 / 10 / 40 / 101 / 350 |
| `fixture-200kb.md` | 109 | 1 039 | 6 / 9.53 / 15 | 109 | 62 | 1 252 | 3 / 20.19 / 14 / 43 / 43 / 43 |
| `fixture-1mb.md` | 579 | 5 530 | 6 / 9.55 / 14 | 579 | 375 | 6 021 | 3 / 16.06 / 11 / 43 / 43 / 43 |

Inline-math byte buckets, real note:

| 1-10 | 11-20 | 21-40 | 41-80 | 81-160 | 161-320 | 321-640 | 641-1280 | >1280 |
|---|---|---|---|---|---|---|---|---|
| 6 890 | 2 681 | 2 141 | 1 025 | 232 | 33 | 2 | 0 | 0 |

**Half of all inline math expressions are ≤ 10 bytes and 68 % are ≤ 20 bytes.** The
distribution has a long thin tail: 121 expressions over 100 bytes and 16 over 200, up
to 350. Two conclusions: a very small expression cache/render fast path covers the
median case, and a per-expression size limit is not needed because nothing in the
corpus is structurally huge inline (the 350-byte worst case is still one line).

### 5.3.4 App-specific inline constructs: wikilinks, footnotes

| file | wikilinks total | embeds `![[` | with alias | no alias | with anchor | heading anchor | block anchor (`#^`) | asset images (`.png` etc.) | footnote refs | footnote defs |
|---|---|---|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 40 | 38 | 2 | 0 | 2 | 0 | 2 | 38 | 34 | 17 |
| `fixture-200kb.md` | 28 | 0 | 0 | 28 | 0 | 0 | 0 | 0 | 80 | 40 |
| `fixture-1mb.md` | 161 | 0 | 0 | 161 | 0 | 0 | 0 | 0 | 80 | 40 |

All 40 real-note wikilinks (`inline.json` `wikilinks`): `geometria_1_copertina_1.png`, `geometria_1_figura_1-1.png`, `geometria_1_figura_1-2.png`, `geometria_1_figura_1-3.png`, `geometria_1_figura_1-4.png`, `geometria_1_figura_1-5.png`, `geometria_1_figura_1-6.png`, `geometria_1_figura_1-7.png`, `geometria_1_figura_1-8.png`, `geometria_1_figura_1-9.png`, `geometria_1_figura_1-10.png`, `geometria_1_figura_1-11.png`, `geometria_1_figura_1-12.png`, `geometria_1_figura_1-13.png`, `geometria_1_figura_1_exta_1.png`, `geometria_1_figura_1_extra_2.png`, `geometria_1_figura_1_extra_3.png`, `#^g1-def-monoide-gruppo|monoide`, `#^g1-def-campo|campo`, `185234098087.png`, `acd1115394e7.png`, `3bf2f789ad6c.png`, `5229eb987fb0.png`, `geometria_1_figura_7-1.png`, `geometria_1_figura_A-01.png`, `geometria_1_figura_A-02.png`, `geometria_1_figura_A-03.png`, `geometria_1_figura_A-2.png`, `geometria_1_figura_A-3.png`, `geometria_1_figura_A-extra.png`, `geometria_1_figura_A-4.png`, `geometria_1_figura_A-5.png`, `geometria_1_figura_B-1.png`, `geometria_1_figura_B-2.png`, `geometria_1_figura_B-3.png`, `geometria_1_figura_B-4.png`, `2829e235abe7.png`, `1fcd6551ce60.png`, `16d07bfd5bf9.png`, `attachments/e12204d45c77.png`.

Every wikilink in the real note is either an inline image embed (`![[…png]]`, 38 of
them) or one of exactly **two block-anchor links**: `[[#^g1-def-monoide-gruppo|monoide]]`
and `[[#^g1-def-campo|campo]]`. There are **no**: wikilinks to a heading anchor
(`[[Note#Heading]]`), wikilinks to another note by name with an alias, or embeds of
another note. 34 footnote references point at 17 footnote definitions, i.e. reuse
(2 refs per definition) — so footnote identity, not footnote count, is what a renderer
must key on.

**Known scanner limitation, quantified.** `gen_inline_census.py` is a flat (non-
recursive) scanner. When a line contains an unmatched `[`, the shortcut-reference
branch consumes text up to the next `]`, and any `$…$` inside that run is not counted.
This affects exactly 2 lines of the real note (4 799 and 7 005) and under-counts inline
math by 4 expressions: the census reports **13 000**, the direct dollar-pair scan in
`gen_math_deepdive.py` reports **13 004**. The deep-dive figure is the authoritative
one; the discrepancy is 0.03 % and is stated rather than smoothed over.

---

## 5.4 Math deep-dive

Produced by `scripts/gen_math_deepdive.py` (`math.json`), with the coverage curve from
`scripts/gen_coverage.py` (`coverage-geometria.tsv`). This document is a converted
linear-algebra textbook; math is why it is 935 KB.

### 5.4.1 Volume

| file | inline `$…$` | display `$$…$$` blocks | `$$` delimiter lines | total expressions | display single-line |
|---|---|---|---|---|---|
| `Geometria 1.md` | 13 004 | 841 | 1 682 | 13 845 | 0 |
| `fixture-200kb.md` | 62 | 141 | 282 | 203 | 60 |
| `fixture-1mb.md` | 375 | 704 | 1 408 | 1 079 | 358 |

Real-note math byte budget: inline 212 054 B + display 140 800 B = **352 854 B = 37.75 % of the document**.

| quantity | inline | display |
|---|---|---|
| expressions | 13 004 | 841 |
| total body bytes | 212 054 | 140 800 |
| mean bytes | 16.31 | 167.42 |
| p50 bytes | 10 | 132 |
| p90 bytes | 40 | 311 |
| p99 bytes | 101 | 562 |
| max bytes | 350 | 1 094 |
| min bytes | 1 | 16 |

Display-math byte buckets, real note:

| 1-10 | 11-20 | 21-40 | 41-80 | 81-160 | 161-320 | 321-640 | 641-1280 | >1280 |
|---|---|---|---|---|---|---|---|---|
| 0 | 2 | 19 | 159 | 322 | 263 | 68 | 8 | 0 |

Everything-inline-math byte buckets, real note (inline + display pooled):

| 1-10 | 11-20 | 21-40 | 41-80 | 81-160 | 161-320 | 321-640 | 641-1280 | >1280 |
|---|---|---|---|---|---|---|---|---|
| 6 890 | 2 683 | 2 160 | 1 184 | 554 | 296 | 70 | 8 | 0 |

Reading: **68 % of display blocks are 41–160 bytes and 8 blocks exceed 640 bytes.**
The display tail (up to 1 094 bytes / 9 source lines) is where KaTeX layout and
scroll-height measurement get expensive; the inline median (10 bytes) is where a
cache pays for itself.

### 5.4.2 The 15 largest math expressions in the real note

Provenance: `math.json` → `largest` (top 25; 15 shown). `line` is the first source line.

| bytes | kind | line | first 120 characters |
|---|---|---|---|
| 1 094 | display | 2 473 | `\begin{aligned} ⏎ &\begin{vmatrix} x_{1,1} & \dots & y_1 & \dots & y_1 & \dots & x_{1,n} \\ \vdots & & \vdots & & \vdots` |
| 1 025 | display | 2 440 | `\begin{aligned} ⏎ \begin{vmatrix} x_{2,2} & \dots & x_{2,i} + y_{2,i} & \dots & x_{2,n} \\ \vdots & & \vdots & & \vdots ` |
| 850 | display | 2 429 | `\begin{aligned} ⏎ &\begin{vmatrix} x_{1,1} & \dots & x_{1,i} + y_{1,i} & \dots & x_{1,n} \\ \vdots & & \vdots & & \vdots` |
| 827 | display | 2 456 | `\begin{aligned} ⏎ &\begin{vmatrix} x_{1,1} & \dots & \alpha x_{1,i} & \dots & x_{1,n} \\ \vdots & & \vdots & & \vdots \\` |
| 813 | display | 588 | `\begin{aligned} ⏎ &\frac{1}{6} \|\overrightarrow{A_0 A_1} \cdot (\overrightarrow{A_0 A_2} \times (\overrightarrow{A_0 B_` |
| 812 | display | 7 678 | `\begin{aligned} ⏎ &((\mathbf{u} \times \mathbf{v}) \times \mathbf{w}) \cdot ((\mathbf{u} \cdot \mathbf{w})\mathbf{v} - (` |
| 809 | display | 9 512 | `\begin{aligned} ⏎ A &= \begin{pmatrix} 1 & 0 & 0 & 0 \\ 2+\sqrt{3} & 1 & 0 & 0 \\ 2 & 0 & 1 & 0 \\ 0 & 0 & 0 & 1 \end{pm` |
| 800 | display | 5 630 | `\begin{aligned} ⏎ A &= \begin{pmatrix} ⏎ \cos \psi \cos \varphi - \sin \psi \sin \varphi \cos \vartheta & -\cos \psi \si` |
| 562 | display | 8 800 | `\begin{aligned} ⏎ \operatorname{vol}^3(\Delta(P_0, P_1, P_2, P_3)) &= \frac{1}{6} \left\| \det \begin{pmatrix} -1 & -3 &` |
| 551 | display | 1 068 | `\begin{aligned} ⏎ \left\langle \begin{pmatrix} 1 \\ 1 \\ 0 \\ 0 \end{pmatrix}, \begin{pmatrix} 2 \\ 1 \\ 1 \\ 0 \end{pma` |
| 545 | display | 7 663 | `\begin{aligned} ⏎ &\\|(\mathbf{u} \times \mathbf{v}) \times \mathbf{w}\\|^2 - \\|(\mathbf{u} \cdot \mathbf{w})\mathbf{v}` |
| 544 | display | 8 264 | `\begin{aligned} ⏎ S_n^2 &= (a^2 + b^2) \sum_{j=1}^{[n/2]} \varepsilon(j, j) + (a^2 + c^2) \sum_{j=1}^{[n/2]} \varepsilon` |
| 522 | display | 8 665 | `\begin{pmatrix} -3 & 1 & 2 & 0 \\ -4/3 & -4/3 & 3 & -1/3 \\ 1 & -1 & 0 & 0 \\ 0 & 0 & 0 & 0 \end{pmatrix} + \left\langle` |
| 516 | display | 9 444 | `\begin{aligned} ⏎ A_1 &= \begin{pmatrix} -\sqrt{2}/2 & -\sqrt{2}/2 \\ \sqrt{2}/2 & -\sqrt{2}/2 \end{pmatrix} \begin{pmat` |
| 515 | display | 8 657 | `\begin{pmatrix} 0 & 0 & 1 & 0 \\ -1 & 0 & 0 & 1 \\ 1 & 2 & 0 & 0 \\ 0 & -1 & -2 & -1 \end{pmatrix} + \left\langle \begin` |

Every one of the ten largest expressions is an `\begin{aligned}` block containing a
`pmatrix`/`vmatrix`, i.e. **a matrix with row breaks (`\\`) and alignment (`&`)**.
That is the shape a math renderer must handle first; it is not an edge case here, it
is the top of the distribution.

### 5.4.3 TeX command histogram — top 60 + distinct count

Distinct commands in the real note: **135** total, of which
**129** are alphabetic (`\frac`, `\phi`, …) and the rest
are single-character control symbols (`\\`, `\|`, `\{`, `\}`, `\,`).

| # | command | uses | # | command | uses | # | command | uses |
|---|---|---|---|---|---|---|---|---|
| 1 | `\\` | 2 657 | 21 | `\quad` | 413 | 41 | `\le` | 152 |
| 2 | `\phi` | 1 889 | 22 | `\lambda` | 380 | 42 | `\leq` | 143 |
| 3 | `\mathbf` | 1 877 | 23 | `\ker` | 296 | 43 | `\cos` | 139 |
| 4 | `\mathbb` | 1 574 | 24 | `\pi` | 291 | 44 | `\cap` | 136 |
| 5 | `\begin` | 1 389 | 25 | `\psi` | 290 | 45 | `\circ` | 129 |
| 6 | `\end` | 1 389 | 26 | `\dim` | 249 | 46 | `\sin` | 119 |
| 7 | `\dots` | 1 386 | 27 | `\det` | 246 | 47 | `\delta` | 110 |
| 8 | `\in` | 963 | 28 | `\vdots` | 241 | 48 | `\bar` | 108 |
| 9 | `\|` | 834 | 29 | `\mid` | 239 | 49 | `\oplus` | 106 |
| 10 | `\mathcal` | 739 | 30 | `\neq` | 230 | 50 | `\cdots` | 102 |
| 11 | `\alpha` | 641 | 31 | `\sigma` | 226 | 51 | `\Delta` | 100 |
| 12 | `\frac` | 611 | 32 | `\text` | 226 | 52 | `\mu` | 91 |
| 13 | `\langle` | 516 | 33 | `\sqrt` | 208 | 53 | `\subseteq` | 78 |
| 14 | `\rangle` | 516 | 34 | `\perp` | 200 | 54 | `\ddots` | 78 |
| 15 | `\operatorname` | 487 | 35 | `\left` | 192 | 55 | `\mapsto` | 71 |
| 16 | `\cdot` | 482 | 36 | `\right` | 192 | 56 | `\rho` | 59 |
| 17 | `\times` | 429 | 37 | `\sum` | 192 | 57 | `\xi` | 57 |
| 18 | `\to` | 419 | 38 | `\beta` | 178 | 58 | `\exp` | 57 |
| 19 | `\{` | 416 | 39 | `\overrightarrow` | 169 | 59 | `\ge` | 56 |
| 20 | `\}` | 415 | 40 | `\vartheta` | 159 | 60 | `\deg` | 54 |

The top 10 commands alone account for the bulk of all command uses:

`\\` 2 657, `\phi` 1 889, `\mathbf` 1 877, `\mathbb` 1 574, `\begin` 1 389,
`\end` 1 389, `\dots` 1 386, `\in` 963, `\|` 834, `\mathcal` 739 — **14 697 of 26 391 command uses (55.7 %)**.

Two structural facts fall out of this list: `\mathbf` (1 877) and `\mathbb` (1 574)
are **font-selection** commands, not layout commands — a renderer needs a math-bold
and a blackboard-bold alphabet before it needs anything exotic. `\operatorname` (487)
and `\text` (226) require text-mode layout inside math.

### 5.4.4 Environments

| environment | occurrences (in-body) | expressions containing it |
|---|---|---|
| `pmatrix` | 1 120 | 690 |
| `cases` | 114 | 90 |
| `aligned` | 103 | 103 |
| `vmatrix` | 45 | 20 |
| `array` | 7 | 6 |

`\begin{…}` appears **1 389 times**, distributed over only
**5 distinct environments**. `pmatrix` alone is 80.6 % of all environment uses.
**12 963 of 13 845 math expressions (93.6 %) contain no environment at all.**

### 5.4.5 Nested brace depth

| max brace depth | 0 | 1 | 2 | 3 | 4+ |
|---|---|---|---|---|---|
| expressions | 9 275 | 4 290 | 278 | 2 | 0 |

**Maximum brace depth in the entire real note is 3, and only 2 expressions
reach it.** 67 % of expressions have no braces at all. Brace-depth exhaustion is not a
risk in this corpus; a recursive-descent TeX parser with any reasonable depth limit
will never approach it.

### 5.4.6 Structure inside math, and indented contexts

| property | inline | display | all |
|---|---|---|---|
| expressions | 13 004 | 841 | 13 845 |
| containing `\\` (row break) | — | — | 882 (6.37 %) |
| containing `&` (alignment) | — | — | 507 (3.66 %) |

Alignment structures:

| measure | count |
|---|---|
| expressions containing `\\` | 882 |
| expressions containing `&` | 507 |
| expressions containing `\left`/`\right` | 134 |
| display math blocks | 841 |
| display blocks with leading indentation > 0 | 0 |
| display blocks inside a list item or blockquote | 0 |
| inline math on a list-marker line | 1 576 |
| inline math inside a list item | 1 576 |
| inline math on a blockquote line | 31 |

**Answers to the questions asked of this section, for the real note:**

- inline vs display: **13 004 inline** vs **841 display** (93.9 % inline).
- `$$` occurrences: **1 682 delimiter lines = 841 blocks**. Every `$$` in the file is a standalone line at column 0; there is **not one** single-line
  `$$ x $$` display math in the real note (all 60 single-line display blocks in the
  fixtures, none here).
- Display math in an indented container: **0**. Display math inside a list item or
  blockquote: **0**. But **1 576 inline math expressions sit on list-marker lines**
  and **13 004 total** are inline — so the *inline* path is what lives inside lists.
- `\left`/`\right`: 134 expressions (1.0 %) — rare, and always paired.
- `\\` or `&`: 882 expressions with `\\` (6.4 %) and 507 with `&` (3.7 %); these are
  concentrated in the `aligned`/`pmatrix`/`cases` blocks, i.e. exactly the 841 display
  blocks that dominate the byte tail.

### 5.4.7 What a math renderer must support — 95 % and 99 % coverage

Method: take every one of the 13 845 math expressions (inline +
display), record the set of TeX commands each uses (`\begin`/`\end` counted separately
as environments), then add commands in descending frequency order and measure how many
expressions are fully covered. Script: `scripts/gen_coverage.py`.

| coverage target | commands needed | expressions covered | cumulative % |
|---|---|---|---|
| ≥  90% | 43 | 12503/13845 = 90.31% | 90.31% |
| ≥  95% | 58 | 13171/13845 = 95.13% | 95.13% |
| ≥  97% | 67 | 13440/13845 = 97.07% | 97.07% |
| ≥  99% | 86 | 13711/13845 = 99.03% | 99.03% |
| ≥  99.5% | 97 | 13777/13845 = 99.51% | 99.51% |
| ≥  100% | 133 | 13845/13845 = 100.00% | 100.00% |

**The 95 % feature list — 58 commands, in frequency order:**

`\phi` `\mathbb` `\dots` `\in` `\\` `\mathbf` `\mathcal` `\alpha` `\rangle` `\langle` `\to` `\operatorname` `\{` `\}` `\times` `\frac` `\ker` `\neq` `\pi` `\quad` `\lambda` `\cdot` `\psi` `\mid` `\|` `\det` `\perp` `\text` `\dim` `\sigma` `\right` `\left` `\sum` `\beta` `\cap` `\circ` `\sqrt` `\leq` `\cdots` `\vartheta` `\overrightarrow` `\le` `\Delta` `\delta` `\oplus` `\cos` `\subseteq` `\mu` `\bar` `\mapsto` `\vdots` `\sin` `\ge` `\rho` `\Sigma` `\vee` `\overline` `\pm`

**The additional commands needed to reach 99 % — 28 more (86 total):**

`\exp` `\xi` `\geq` `\deg` `\nu` `\Rightarrow` `\Phi` `\tau` `\gamma` `\infty` `\varnothing` `\theta` `\ddots` `\varphi` `\setminus` `\varepsilon` `\Leftrightarrow` `\zeta` `\Lambda` `\notin` `\log` `\prod` `\Re` `\ell` `\cong` `\Im` `\qquad` `\binom`

**Plus, in both cases, these non-command features:**

| feature | required by | evidence |
|---|---|---|
| superscript `^` / subscript `_` with `{}` grouping | 95 % list | 4 290 expressions use braces; `\dots`/`\in` presuppose sub/superscripts |
| `pmatrix` environment (parenthesised matrix, `&` + `\\`) | 95 % list | 1 120 occurrences, 690 expressions |
| `vmatrix` environment (bars) | 95 % list | 45 occurrences |
| `cases` environment | 95 % list | 114 occurrences |
| `aligned` environment (`&` alignment, `\\` rows) | 95 % list | 103 occurrences; top-10 largest expressions |
| `array` environment | 99 % list | 7 occurrences |
| `\left`/`\right` auto-sizing delimiters | 95 % list | 134 expressions |
| `\text{…}` and `\operatorname{…}` text modes | 95 % list | 226 + 487 uses |
| accents/overlays `\overrightarrow`, `\bar`, `\overline`, `\hat`-class | 95 % list | 169 + 108 + … uses |
| relational + binary operator spacing classes | 95 % list | `\le`, `\leq`, `\ge`, `\neq`, `\to`, `\in`, `\cdot`, `\times`, `\oplus`, `\cap`, `\subseteq`, `\perp`, `\mid` |
| `\begin`/`\end` nesting (env inside env) | 95 % list | e.g. `aligned` containing `vmatrix` at lines 2 429, 2 440, 2 473 |
| escaped braces `\{` `\}` and `\|` | 95 % list | 416 + 415 + 834 uses |
| `\mathbb` and `\mathbf` alphabets | 95 % list | 1 574 + 1 877 uses — the two most-used commands after `\phi` |

**Interpretation.** Covering 95 % of this corpus needs a *small* renderer: 58 commands,
5 environments, sub/superscripts, auto-sizing delimiters and two font alphabets. The
last 5 % — 28 more commands going to 99 %, then 47 more to reach 100 % — is a long
tail of one- and two-use symbols (`\binom`, `\setminus`, `\varnothing`, `\ell`,
`\Im`, `\Re`, `\cong`…). **A renderer that implements the 95 % list plus a
"unknown command → render as literal text" fallback degrades gracefully on the
remaining 5 %; a renderer that hard-fails on an unknown command breaks 674
expressions in this one document.**

Note the two cost drivers are *different*: the command list is short, but the
**number of distinct expressions is 13 845**, and 68 % of display blocks are large
enough to need real layout. Parse-once/cache-by-content is therefore the right shape:
13 845 keys, median 10 bytes, with the 841 display blocks dominating the expensive end.

---

## 5.5 Structural worst cases

Produced by `scripts/gen_worstcases.py` (`worst.json`). Each row names the construct,
its location, and the part of a renderer it stresses.

### 5.5.1 The real note (`Geometria 1.md`)

| worst case | value | location | excerpt | stresses |
|---|---|---|---|---|
| longest paragraph | 2 569 B on 1 line | line 9056-9056 | `Per l'autovalore $-2$: $\dim \ker(\phi + 2) = 2$, $\dim \ker(\phi + 2)^4 = 4$. Poiché il polinomio minimo per ` | **layout** — one `TextPainter` input that wraps to ~32 lines; also parse, because ~95 inline math spans must be resolved before layout can start |
| deepest list nesting | depth 3 (indent 8) | line 9835 | `        - alternante, 161` | **parse + layout** — list indent stacking and bullet widget indentation |
| deepest blockquote nesting | depth 1 (flat, never nested) | all 22 `>` lines | `> Figura 1.1` | **parse** — trivially shallow; nothing stresses quote nesting in the real note |
| largest table | 4×4 = 16 cells, 536 B | line 8 970 | `\|                 \| $-2$                     \| $-1$                     \| $0$                   ` | **layout** — intrinsic column widths; the real largest is small |
| largest math expression | 1 100 B, 9 source lines | lines 2473-2481 | `\begin{aligned}` + `vmatrix` with 8 `&` columns | **layout + paint** — KaTeX parse, then a widget whose height must be known before the scroll offset can be trusted |
| highest inline-span count on one line | 120 inline elements in 1 860 B | line 8 019 | `**2.24** (b) $L = \langle e_1, e_2, e_3, e_4 \rangle_{\mathbb{R}}$. $\pi : E \oplus D \to E$ è la proiezione s` | **parse** — 120 spans on one line, each needing a style run |
| highest inline density (≥200 B lines) | 107 spans / 834 B = 12.83 per 100 B | line 8 330 | `**4.15** (a) $D(x_1 e_1 + x_2 e_2 + x_3 e_3, y_1 e_1 + y_2 e_2 + y_3 e_3, z_1 e_1 + z_2 e_2 + z_3 e_` | **parse + layout** — 12.83 markup spans per 100 bytes means the line is mostly tiny measurement units |
| longest single "word" (no spaces) | 102 chars | line 8 971 | `\|----------------\|--------------------------\|--------------------------\|----` | **layout** — an unbreakable 102-char token (a GFM delimiter row) exceeds the viewport and forces horizontal clipping or character-level break |
| longest non-table unbreakable token | 73 chars | line 4 597 | `PA**+**=(Q**tSSt**Q)**−1**Q**tStP**=Q(**tSS**)**−1tStP**=Q**tS−1**​**tP**` | **layout** — PDF→MD conversion glued a formula together, producing a 73-char run with no break opportunity |
| longest alphabetic word | 20 chars | line 4 024 | `triangolarizzabilità` | **layout** — benign; text is naturally short-worded Italian |
| longest run of consecutive non-blank lines | 67 lines (1 452 B) | lines 10 171–10 237 | — | **scroll-mapping + memory** — one 67-line paragraph region with no blank-line padding to use as a layout anchor |
| densest 200-line region | 4.77 inline elements per 100 B, 1 068 spans in 22 378 B | lines 8 526–8 725 | — | **parse** — the exercises section (lines 8 526–8 725) is the hottest parse region in the document |

**Byte convention in this table.** `gen_worstcases.py` measures whole blocks, so its
byte counts include each source line's LF and, for the largest math expression, the
`$$` delimiter lines. That is why the same expression reads 1 100 B here and 1 094 B
in §4 (body only), and the longest paragraph reads 2 569 B here and 2 568 B in
§1 (line only). The §1 and §4 figures are the canonical ones.

The two lines worth memorising:

- **line 8019** — 120 inline elements, 1 860 bytes, one paragraph,
  one line. It is both the largest parse unit and, at ~32 wrapped lines, the largest
  single layout unit in the file.
- **line 10 171–10 237** — 67 consecutive non-blank lines:
  the maximum distance a scroll mapper can travel without a blank line to fall back on.

### 5.5.2 Worst cases in the synthetic fixtures

| worst case | fixture-200kb | fixture-1mb | real note (for scale) |
|---|---|---|---|
| longest paragraph | 413 B (line 4142-4142) | 440 B (line 10027-10027) | 2 569 B (line 9056-9056) |
| deepest list nesting | 2 | 2 | 3 |
| largest table (cells) | 24 | 24 | 16 |
| largest math expression | 86 B | 86 B | 1 100 B |
| longest non-blank run | 11 lines | 10 lines | 67 lines |
| longest word (no spaces) | 32 chars | 32 chars | 102 chars |
| densest line (inline spans) | 8 | 11 | 120 |
| densest 200-line window (spans/100 B) | 1.64 | 1.73 | 4.77 |

The fixtures are **flat**: every one of their worst cases is 3–10× smaller than the
real note's. They are good throughput fixtures (many repeat units) and poor worst-case
fixtures (no unit is extreme). That is precisely why §7 exists.

---

## 5.6 Scroll/layout sizing model

### 5.6.1 The one external number

`docs/dev/editor-alternatives.md` records, for the app's existing editor:

> Line layout + paint | 44.7 µs/line (only visible lines are paid for)
> 
> Numbers are debug-mode, inside the test harness, on one Windows machine.
> They are inflated in absolute terms; only the ratios between rows carry.

The same file records `Whole buffer as a single span: 52.0 ms` and, for the rejected
eager renderer, `SmoothMarkdown eager preview, 200 KB: 2769.2 ms`. Those three
numbers are the empirical anchor for everything below.

### 5.6.2 Assumptions (stated, not measured here)

1. **Per-line layout cost: 30 / 44.7 / 80 µs** for one ~80-character visual line,
   using 44.7 µs as the middle case because it is the repo's own debug-mode figure.
2. **Wrapping: 80 characters per visual line.** The real note averages 89.5 bytes/line
   but its *blocks* are single logical lines; the visual line count is computed as
   `ceil(block_bytes / 80)` per text block, which is an *estimate* of wrapped lines.
3. A math block costs one layout unit here; its KaTeX cost is **not** modelled and is
   a separate, likely larger, line item.
4. One viewport holds ~40 layout blocks (the figure given in the brief).

### 5.6.3 Block and line counts

Produced by `scripts/gen_layout_model.py` (`layout.json`). `layout blocks` =
paragraphs + headings + list items + table rows (header + body) + fenced/indented code
blocks + math blocks + thematic breaks + link-ref/footnote definitions + HTML blocks.

| file | paragraphs | headings | list items | table rows | code blocks | math blocks | other | **layout blocks** | **text visual lines** | + math | **total layout units** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `Geometria 1.md` | 2 392 | 84 | 852 | 9 | 0 | 841 | 41 | **4 219** | 11 509 | 841 | **12 350** |
| `fixture-200kb.md` | 646 | 214 | 1 165 | 904 | 175 | 141 | 69 | **3 314** | 5 294 | 141 | **5 435** |
| `fixture-1mb.md` | 3 256 | 1 043 | 6 764 | 4 488 | 867 | 704 | 206 | **17 328** | 27 409 | 704 | **28 113** |
| `worst-note.md` (adversarial) | 197 | 26 | 28 | 53 | 8 | 902 | 68 | **1 282** | 17 687 | 902 | **18 589** |

For the real note: **4 219 layout blocks**, split as 2 392 paragraphs + 84 headings +
852 list items + 9 table rows + 841 math blocks + 41 others (22 thematic breaks, 17
footnote definitions, 2 HTML blocks). Because 2 392 of 2 392 paragraphs are exactly
one source line, the *block* count is unusually close to the *line* count — the note
was produced by a PDF converter that never hard-wraps. That is good for a block-based
renderer and bad for anything that assumes ~30-character lines.

The estimated **visual** line count is 11 509 for text plus 841 math widgets, i.e.
**12 350 layout units**, because long single-line paragraphs wrap. Average visual
lines per block = 12 350 / 4 219 = **2.93**.

### 5.6.4 Eager vs viewport vs viewport + cache

Produced by `scripts/gen_sizing.py` (`sizing.txt`). Arithmetic shown inline.

#### Geometria 1.md
layout_blocks=4219  visual_lines=12350  avg_visual_lines_per_block=2.927

| scope | blocks | visual lines | 30 us/line | 44.7 us/line | 80 us/line | 60 Hz frames @44.7 | 120 Hz frames @44.7 |
|---|---|---|---|---|---|---|---|
| (a) eager: every block | 4219 | 12,350 | 370.50 ms | 552.04 ms | 988.00 ms | 33.1 | 66.2 |
| (b) viewport only (~40 blocks) | 40 | 117 | 3.51 ms | 5.23 ms | 9.37 ms | 0.3 | 0.6 |
| (c) viewport + 1 viewport cache each side (~120 blocks) | 120 | 351 | 10.54 ms | 15.70 ms | 28.10 ms | 0.9 | 1.9 |

arithmetic at 44.7 us/line:
  (a): 12,350.0 lines x 44.7 us = 552,045 us = 552.04 ms = 33.1 frames@60Hz = 66.2 frames@120Hz
  (b): 117.1 lines x 44.7 us = 5,234 us = 5.23 ms = 0.3 frames@60Hz = 0.6 frames@120Hz
  (c): 351.3 lines x 44.7 us = 15,702 us = 15.70 ms = 0.9 frames@60Hz = 1.9 frames@120Hz

#### /tmp/niman-research/fixtures/worst-note.md (adversarial fixture)
layout_blocks=1282  visual_lines=18589  avg_visual_lines_per_block=14.500

| scope | blocks | visual lines | 30 us/line | 44.7 us/line | 80 us/line | 60 Hz frames @44.7 | 120 Hz frames @44.7 |
|---|---|---|---|---|---|---|---|
| (a) eager: every block | 1282 | 18,589 | 557.67 ms | 830.93 ms | 1,487.12 ms | 49.9 | 99.7 |
| (b) viewport only (~40 blocks) | 40 | 580 | 17.40 ms | 25.93 ms | 46.40 ms | 1.6 | 3.1 |
| (c) viewport + 1 viewport cache each side (~120 blocks) | 120 | 1,740 | 52.20 ms | 77.78 ms | 139.20 ms | 4.7 | 9.3 |

arithmetic at 44.7 us/line:
  (a): 18,589.0 lines x 44.7 us = 830,928 us = 830.93 ms = 49.9 frames@60Hz = 99.7 frames@120Hz
  (b): 580.0 lines x 44.7 us = 25,926 us = 25.93 ms = 1.6 frames@60Hz = 3.1 frames@120Hz
  (c): 1,740.0 lines x 44.7 us = 77,778 us = 77.78 ms = 4.7 frames@60Hz = 9.3 frames@120Hz

(Arithmetic for `test/fixtures/markdown/fixture-200kb.md`, `test/fixtures/markdown/fixture-1mb.md` is in `out/sizing.txt`; the
shape is identical and those files are not the sizing target.)

### 5.6.5 Plain answer

| scope | @ 44.7 µs | 60 Hz frames | 120 Hz frames | verdict |
|---|---|---|---|---|
| (a) eager, real note | 552.04 ms | 33.1 | 66.2 | **not viable** — a third of a second at debug speed for one document, and 4.2 M µs of work on every open |
| (b) viewport only | 5.23 ms | 0.31 | 0.63 | viable on a 60 Hz budget; tight but under one 120 Hz frame |
| (c) viewport + one viewport of cache each side | 15.70 ms | 0.94 | 1.88 | viable for a 60 Hz frame, **over budget for 120 Hz** if done in one frame |
| (a) eager, 1 MB fixture | 1 256.65 ms | 75.4 | 150.8 | **not viable** |
| (a) eager, adversarial fixture | 830.93 ms | 49.9 | 99.7 | **not viable** — 18 589 layout units |

The adversarial fixture shows 14.5 visual lines per block,
an artefact of its deliberate 2 000-line mega-paragraph and 2 000-line code fence:
a "40-block viewport" there is not a realistic viewport, so its viewport row is a
worst case rather than an expectation.

**Eager layout is not viable.** At the repo's own debug-mode 44.7 µs/line, laying out
every block of the real note costs **552 ms = 33 frames at 60 Hz**; at the pessimistic
80 µs it costs **988 ms = 59 frames**; at the optimistic 30 µs it still costs **371 ms**,
22 frames. Even the most generous plausible figure puts eager layout more than an order
of magnitude over a frame budget. The existing app already knows this: the rejected
eager renderer measured 2 769.2 ms on a 200 KB fixture, and the accepted editor pays
only for visible lines. **Only visible (plus a bounded cache of) blocks may be laid
out.** The 120 Hz budget (8.33 ms) means the cache extent must be filled
incrementally across frames, not synchronously: one viewport of cache costs 15.7 ms at
44.7 µs/line, i.e. ~1.9 frames at 120 Hz.

Two further consequences of the measured numbers:

- **2.93 visual lines per block** means a "~40 blocks" viewport is really ~117 visual
  lines, not 40. Any cost model that multiplies viewport *blocks* by a per-line cost
  under-estimates by 2.9×.
- At 841 display-math blocks in the real note and 902 in the adversarial fixture,
  math layout — not prose layout — is the largest single widget class in the document,
  and it is excluded from the 44.7 µs figure above.

---

## 5.7 A synthetic "worst note" spec and fixture

Generator: **in the repo**, at `tool/make_worst_note.dart`, re-runnable and
byte-deterministic (no randomness, no timestamps). It writes
`test/fixtures/spec/worst-note.md`, and `dart run tool/make_worst_note.dart
--check` prints what it produced next to the spec below.
`test/unit/worst_note_test.dart` asserts both halves of the contract: that the
fixture still has the shape this table asks for, and that the engine — the
block scanner and the extension masker — survives it, which is Phase 1's
"the parser is run against it".
Every construct below is justified by a measured worst case from §1–§6; each section
of the fixture is labelled in-file with the corpus value it exceeds.

### 5.7.1 Specification

| # | dimension | corpus measured | fixture target | fixture actual |
|---|---|---|---|---|
| 1 | size | 934 769 B (real note) / 1 050 145 B (largest fixture) | ≥ 1 200 000 B | 1 482 533 B |
| 2 | lines | 10 331 / 32 100 | ≥ 10 000 | 11 773 |
| 3 | max line | 2 568 B | ≥ 4 000 B | 5 372 B (line 4 743) |
| 4 | lines > 2 000 B | 3 | ≥ 40 | 42 |
| 5 | blank lines | 3 556 (34.4 %) | keep ≥ 8 % | 1 149 (9.8 %) |
| 6 | headings | H1 15 / H2 59 / H3 10, no H4–H6, no setext | all 6 levels + both setext | H1–H6 + 2 setext |
| 7 | list depth | 3 | 7 | 7 |
| 8 | ordered lists | 0 in real note, `.` only in fixtures | both `.` and `)` | both, plus `start != 1` |
| 9 | task lists | 0 real / 1 402 in 1 MB fixture | both states, nested | 4 |
| 10 | blockquote depth | 1 (never nested) | 4 | 4 |
| 11 | display math in a list item / blockquote | 0 (corpus) | ≥ 2 | 2 (a `pmatrix` in a list item, a `\int` in a depth-3 quote) |
| 12 | inline `$…$` | 13 004 | ≥ 13 004 | 19 700 |
| 13 | display `$$…$$` | 841 | ≥ 900 | 902 |
| 14 | environments | 5 (`pmatrix` 1 120, `cases` 114, `aligned` 103, `vmatrix` 45, `array` 7) | all 6 incl. `bmatrix` | 6 |
| 15 | largest math expression | 1 094 B | ≥ 1 500 B | 5 319 B |
| 16 | max brace depth | 3 | ≥ 5 | ≥ 5 (deep `\left\{ \frac{ \sqrt{…` case) |
| 17 | fenced code | 0 fences real / 867 fences, ≤ 9 lines | tilde fence, empty info, 2 000-line fence | 8 fences, max 2 000 lines |
| 18 | indented code | 0 lines | ≥ 1 block | 1 |
| 19 | tables | 4 cols × 6 rows max | 12 cols × 40 rows + alignments + escaped pipes | 12 cols × 41 rows |
| 20 | HTML blocks | 2 single-line, fused into prose | multi-line `<table>` + `<div>` with Markdown inside | 3 blocks |
| 21 | link reference definitions | 0 | full + collapsed + shortcut | 5 |
| 22 | footnote refs / defs | 34 / 17 | ≥ 60 / ≥ 60 | 120 / 60 |
| 23 | wikilinks | 40 (38 embeds, 2 block anchors) | all 4 shapes incl. alias + heading anchor | 2109 |
| 24 | CRLF | 0 | a mixed-EOL region | 120 CRLF lines |
| 25 | longest non-blank run | 67 | ≥ 600 | 2 002 |
| 26 | longest unbreakable word | 102 (table row) / 73 (text) | ≥ 120 | 351 |
| 27 | inline spans on one line | 120 | ≥ 120 | 180 |
| 28 | one mega-paragraph | 1 line | 2 000 lines / one `TextPainter` | 2 000 lines |

### 5.7.2 Measured stats of the generated fixture

Measured 2026-09-21 on the committed fixture, which the generator reproduces
byte for byte:

| metric | value |
|---|---|
| bytes | 1 331 737 |
| lines | 10 470 |
| blank lines | 1 869 (17.9 %) |
| max line | 4 209 B |
| lines > 2 000 B | 48 |
| headings | H1 17 / H2 2 / H3–H6 1 each, plus 2 setext |
| fence marker lines | 8 (4 blocks: no info string, a language, empty, 2 000 lines) |
| display math markers | 906 |
| inline `$…$` | 20 707 |
| wikilinks | 2 124 (704 embeds) |
| footnote definitions | 60 |
| CRLF lines | 120 |

The engine's own numbers on it, from the same run: 1 427 blocks, every one of
the twelve block kinds present, and a keystroke in prose re-scanning fewer than
30 lines. A keystroke *inside* the 2 000-line paragraph re-scans about 2 000 —
which is O(block), not O(document), and is the case a caller has to plan for.

### 5.7.3 The stats the first version had

Provenance: `scripts/gen_global_stats.py`, `gen_block_census.py`, `gen_inline_census.py`,
`gen_math_deepdive.py`, `gen_worstcases.py`, `gen_layout_model.py`, all run on
`/tmp/niman-research/fixtures/worst-note.md` by `run_all.sh`.

| metric | value |
|---|---|
| bytes | 1 482 533 |
| lines | 11 773 |
| chars | 1 482 523 |
| average bytes/line | 124.93 |
| max bytes/line (line 4 743) | 5 372 |
| lines > 200 / 500 / 1000 / 2000 B | 2204 / 703 / 43 / 42 |
| blank lines | 1 149 |
| CRLF lines / LF lines | 120 / 11773 |
| mixed line endings | yes |
| tabs / trailing-whitespace lines / BOM | 0 / 242 / no |
| ↳ of those trailing-whitespace lines: intentional two-space hard breaks | 121 |
| ↳ of those: CRLF lines, whose `\r` a naive `rstrip()` check counts as trailing whitespace | 120 |
| backslash hard breaks | 61 |
| valid UTF-8 | yes |
| non-ASCII byte share | 0.001 % |
| words | 241 010 |
| paragraphs / headings / list items / tables | 197 / 26 / 28 / 4 |
| fenced code blocks | 8 |
| inline math | 19 700 |
| display math blocks | 902 |
| distinct TeX commands | 50 alphabetic |
| layout blocks | 1 282 |
| estimated visual lines (+ math widgets) | 17 687 (+902) = 18 589 |
| eager layout @ 44.7 µs/line | 830.93 ms = 49.9 frames @60 Hz |

### 5.7.3 What the fixture is for

The real note and the existing fixtures are complementary and each misses half the
problem:

- the **real note** has the volume, the math and the long lines but has **no fences,
  no ordered lists, no nested quotes, no display math in a container, no link
  reference definitions, no CRLF and no setext headings**;
- the **synthetic fixtures** have the full GFM block grammar but are ~30 bytes/line,
  flat (depth 2), 100 % ASCII, and never exceed 439 bytes on a line.

`worst-note.md` is the union: it contains every construct either corpus lacks, at
1.48 MB and 11 773 lines — above both — with
19 700 inline and 902 display math
expressions, i.e. more math volume than the real note. A renderer that opens it,
scrolls it, jumps to the end, and returns the exact byte count must have correct block
parsing, bounded layout, a math cache and a scroll map that survives a 2 000-line
paragraph and a 2 000-line code fence.

Suggested assertions for a future benchmark against this fixture (all bounds below are
derived from the measurements in §6, not invented):

| assertion | bound | derived from |
|---|---|---|
| open → first frame lays out < 10 % of blocks | ≤ 422 blocks | 4 219 blocks eager = 552 ms = 33 frames @60 Hz |
| a scroll step lays out ≤ 1 viewport + cache | ≤ 120 blocks / ~351 visual lines | 15.70 ms = 0.9 frames @60 Hz |
| math expressions parsed once each | ≤ 13 845 misses on first pass | 13 004 inline + 841 display |
| scroll offset is monotonic and reversible | exact round-trip to byte offsets | 2 000-line paragraph + 2 000-line fence have no blank-line anchors |
| CRLF region normalises to LF without changing byte offsets of later blocks | 120 lines | measured CRLF count |

---

## 5.8 Summary of the numbers that should drive the design

| finding | number | consequence |
|---|---|---|
| real note size / lines | 934 769 B / 10 331 lines, 89.5 B per line | per-line costs are ~3× worse than the 1 MB fixture the benchmarks use |
| math share of the real note | 37.75 % of bytes (13 845 expressions) | math, not prose, is the dominant content type |
| display math | 841 blocks, mean 167 B, max 1 094 B | 841 layout widgets whose height must be measured/cached |
| inline math | 13 004, median 10 B, p99 101 B | a small-expression fast path covers half the corpus |
| TeX commands for 95 % coverage | 58 commands + 5 environments | a compact renderer suffices; the last 5 % must degrade to literal text |
| link reference definitions | 0 in the real note and in the fixtures | reference-link resolution is untested by the corpus — §7 fixes that |
| `_` delimiter runs raw → math-aware | 7 530 → 17 | emphasis must be resolved *after* math/code masking, or inline parsing is 443× noisier than it needs to be |
| layout blocks / visual lines | 4 219 / 12 350 (2.93 lines per block) | cost models must be per visual line, not per block |
| eager layout | 552 ms = 33 frames @60 Hz | **not viable**; viewport + bounded cache only |
| viewport + cache | 15.70 ms = 0.9 frames @60 Hz, 1.9 @120 Hz | fill the cache across frames, not in one |
| largest single layout unit | line 9 056, 2 568 B, ~32 wrapped lines, 95 inline spans | one block can exceed a frame on its own |
| largest math | 1 094 B `aligned`+`vmatrix`, 9 source lines | matrix environments dominate the expensive tail |
| deepest nesting anywhere | list depth 3, quote depth 1, brace depth 3 | depth limits are not the risk; volume is |
| encoding hazards | none (no BOM, no CRLF, no tabs, no surrogates, 0.78 % non-ASCII) | encoding robustness is not what this corpus tests |
| adversarial fixture | 1 482 533 B, 11 773 lines, 19 700 inline + 902 display math, depth 7 lists, depth 4 quotes, 12×41 table, 2 000-line fence and paragraph | the missing half of the test matrix |


---

# 6. The primitives available

**Target:** Niman, Flutter 3.47.2 stable / Dart SDK ^3.13.2, Android + Linux + Windows.
**Constraint:** one new widget, pure Flutter/Dart, no third-party markdown/editor/math/highlight package.
**Hard case:** one 934 KB, 10 331-line Markdown note, **13 845 math spans**
(841 display blocks and 13 004 inline — the brief's "1 683" counted the `$$`
lines, and the correction is recorded in §5.3 and §9.3). Disk is source of truth; never
lose or normalise the user's bytes.

**Provenance of every claim below.** Flutter SDK checkout on this machine:
`/home/alessandro/develop/flutter` (framework revision `d3b14c8769`, engine `a804b26164`, Dart 3.13.2).
`dart:ui` text source is not in the dart-sdk snapshot; I read it from the engine checkout at
`/home/alessandro/develop/flutter/engine/src/flutter/lib/ui/text.dart` and from
`/home/alessandro/develop/flutter/bin/cache/flutter_web_sdk/lib/ui/text.dart`. Line numbers quoted are from
those files. Tags used throughout: **[src]** = read from SDK source on disk, **[doc]** = official docs /
API reference, **[measured]** = measured on this machine, **[inference]** = my reasoning, not verified.

Current locked versions replaced by this work (from `pubspec.lock`, read-only):
`re_editor 0.10.0`, `flutter_quill 11.5.1`, `flutter_markdown_plus 1.0.12`, `markdown 7.3.1`,
`katex 1.0.0`, `katex_dart 0.1.1`, `highlight 0.7.0`, `flutter_math_fork 0.7.4` (transitive).

---

## 6.0 Executive summary of the cost model

The whole design follows from six facts, each verified below:

1. **Shaping is the cost; painting is nearly free.** `ui.Paragraph` is immutable and its `layout()` performs
   line breaking *and* shaping in C++ (Skia `skparagraph`). `TextPainter.paint()` is one
   `canvas.drawParagraph` call. **[src]**
2. **A `Paragraph` is never incrementally updated.** `TextPainter.markNeedsLayout()` calls
   `_layoutCache?.paragraph.dispose()` and drops the cache; `layout()` then rebuilds the whole
   `ui.Paragraph` from the `InlineSpan` tree via `ParagraphBuilder`. There is no "setText" on a
   built paragraph. **[src]**
3. **Text layout cannot leave the root isolate**, and Flutter has no feature or roadmap item to change
   that. The engine's `UIDartState::ThrowIfUIOperationsProhibited()` throws *"UI actions are only
   available on root isolate."* for `PictureRecorder`, `Canvas` and `ParagraphBuilder`/`Paragraph`;
   [flutter#41707](https://github.com/flutter/flutter/issues/41707) is **closed as not planned**.
   **[src, engine]** Everything else — parsing, highlighting, math *parsing*, disk I/O — can and should
   move off-thread.
4. **Line breaking is cheaper than shaping, but not free.** `TextPainter.layout()` re-runs
   `paragraph.layout(ParagraphConstraints(width: ...))` on the *existing* paragraph when only the width
   changed, and short-circuits entirely if the paragraph is already wider than its `maxIntrinsicWidth`
   (`_TextPainterLayoutCacheWithOffset._resizeToFit`, `text_painter.dart:471-516`). **[src]**
5. **Crossing an isolate is now cheap, and the *return path* is the one that matters.** **[measured]**
   A `String` is shared, not copied (flat 12–24 µs from 1 KB to 32 MB); typed data is copied at
   ~5.4 GB/s; `TransferableTypedData` is *not* faster end-to-end because `fromList` copies; but
   **`Isolate.exit` is genuinely zero-copy** — 32 MB returned from inside a worker costs **498 µs**
   versus **5 563 µs** when the buffer is captured by the closure (11×). Build the result inside the
   worker and `Isolate.exit` it.
6. **The current preview stack's real cost is not lexing, it is materialisation.** `highlight 0.7.0`
   parses 200 KB of Dart in **57.9 ms** `[measured]`, but its `Result.toHtml()` path is
   **super-quadratic** (100 KB → **6 868.8 ms**) because of `str +=` plus three `replaceAll(RegExp)`
   passes *per node*, and `flutter_highlight` runs it **inside `build()` on the UI isolate with no
   cache**. Separately, the `cpp` grammar is clean O(n²) on `'a'*n + '!'` (8 KB → 1 854 ms) and Dart
   has **no regex timeout** — a user-pasteable hang. `[measured]`

Therefore: **one `Paragraph` per block**, a layout cache keyed by a stable hash, blocks outside the
viewport never laid out, parse/highlight/math-parse work in isolates returning **flat typed buffers**,
and the incremental re-lex stopping at the first line whose entering state matches the cached one.

---

## 6.1 Text layout & painting cost model

### 6.1.1 The object graph

```
TextSpan / WidgetSpan tree  (Dart objects, immutable, @immutable)
        |  TextSpan.build(ui.ParagraphBuilder)      [src text_span.dart]
        v
ui.ParagraphBuilder          (native, engine-side)
        |  pushStyle/addText/pop/addPlaceholder
        v
ui.Paragraph                 (native, IMMUTABLE once built)
        |  .layout(ui.ParagraphConstraints(width: w))   <-- THE expensive call
        |  .getBoxesForRange / getPositionForOffset / computeLineMetrics  (cheap reads)
        v
Canvas.drawParagraph(paragraph, offset)                <-- cheap
```

`TextPainter` (`painting/text_painter.dart:589`) is a Dart-side wrapper that owns exactly one
`ui.Paragraph` inside a `_TextPainterLayoutCacheWithOffset` (`:426`), plus cached
`List<ui.LineMetrics>` and `List<TextBox>` placeholder boxes (`:520-525`). It is **not** itself a
cache — it caches *one* layout of *one* text+style combination.

### 6.1.2 Exact API surface (Flutter 3.47.2)

```dart
// painting/text_painter.dart
TextPainter({
  InlineSpan? text, TextAlign textAlign = TextAlign.start, TextDirection? textDirection,
  @Deprecated double textScaleFactor = 1.0, TextScaler textScaler = const _UnspecifiedTextScaler(),
  int? maxLines, String? ellipsis, Locale? locale, StrutStyle? strutStyle,
  TextWidthBasis textWidthBasis = TextWidthBasis.parent, TextHeightBehavior? textHeightBehavior,
});

void  markNeedsLayout();                                    // :781  disposes the Paragraph
void  layout({double minWidth = 0.0, double maxWidth = double.infinity});  // :1221
void  paint(Canvas canvas, Offset offset);                  // :1322
void  dispose();                                            // :1827
void  setPlaceholderDimensions(List<PlaceholderDimensions>? value);  // :1064

double get width;            // :1151  asserts laid out AND !_debugNeedsRelayout
double get height;           // :1160
Size   get size;             // :1168
double get minIntrinsicWidth;      // :1135   requires layout
double get maxIntrinsicWidth;      // :1143   requires layout
double get preferredLineHeight;    // :1129   DOES NOT require layout (own 1-char template paragraph)
bool   get didExceedMaxLines;      // :1194
double computeDistanceToActualBaseline(TextBaseline baseline);  // :1178

Offset     getOffsetForCaret(TextPosition position, Rect caretPrototype);  // :1447
double     getFullHeightForCaret(TextPosition position, Rect caretPrototype); // :1496
List<TextBox> getBoxesForSelection(TextSelection selection,
    {ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
     ui.BoxWidthStyle  boxWidthStyle  = ui.BoxWidthStyle.tight});            // :1666
ui.GlyphInfo? getClosestGlyphForOffset(Offset offset);                        // :1696
TextPosition  getPositionForOffset(Offset offset);                           // :1714
TextRange     getWordBoundary(TextPosition position);                        // :1730
WordBoundary  get wordBoundaries;                                            // :1745
TextRange     getLineBoundary(TextPosition position);                        // :1750
List<ui.LineMetrics> computeLineMetrics();                                   // :1794
List<TextBox>? get inlinePlaceholderBoxes;                                    // :1039
List<PlaceholderDimensions>? _placeholderDimensions;                          // :1082

static double computeWidth({...});              // :642  creates + lays out + disposes a throwaway painter
static double computeMaxIntrinsicWidth({...});  // :696  same
```

`dart:ui` side (`ui/text.dart`):

```dart
factory ParagraphBuilder(ParagraphStyle style);
  void pushStyle(TextStyle style); void pop();
  void addText(String text);
  void addPlaceholder(PlaceholderDimensions dimensions, {double baselineOffset = 0.0, double scale = 1.0});
  Paragraph build();
  int get placeholderCount; List<double> get placeholderScales;

abstract class Paragraph {
  double get width, height, longestLine, minIntrinsicWidth, maxIntrinsicWidth,
         alphabeticBaseline, ideographicBaseline;
  bool get didExceedMaxLines; int get numberOfLines;
  void layout(ParagraphConstraints constraints);          // ParagraphConstraints({required double width})
  List<TextBox> getBoxesForRange(int start, int end, {BoxHeightStyle, BoxWidthStyle});
  List<TextBox> getBoxesForPlaceholders();
  TextPosition getPositionForOffset(Offset offset);
  GlyphInfo? getGlyphInfoAt(int codeUnitOffset);
  GlyphInfo? getClosestGlyphInfoForOffset(Offset offset);
  TextRange getWordBoundary(TextPosition position);
  TextRange getLineBoundary(TextPosition position);
  List<LineMetrics> computeLineMetrics();
  LineMetrics? getLineMetricsAt(int lineNumber);
  int? getLineNumberAt(int codeUnitOffset);
  void dispose(); bool get debugDisposed;
}
```

Note what **does not exist** in `dart:ui`: there is no per-glyph shaping API, no "shape this string and
give me advances" entry point, no glyph-ID or glyph-advance query, and no way to mutate a built
`Paragraph`. (`GlyphInfo` exists — `ui/text.dart:192` in the web SDK — but it only exposes
`graphemeClusterLayoutBounds`, `graphemeClusterCodeUnitRange`, `writingDirection` for a *range*; it is
not a shaping oracle.) **[src]** This is why custom math rendering must go through `TextPainter` for
glyph runs and `Canvas` for rules.

### 6.1.3 Cheap vs. expensive, precisely

| Operation | Cost class | Why (source) |
|---|---|---|
| `TextPainter()` ctor | cheap | one `ui.ParagraphStyle` encoding; no native paragraph until `layout` **[src]** |
| `TextPainter.layout()` first time | **dominant** | `ParagraphBuilder.build()` + `paragraph.layout()` = shaping + line breaking **[src :1264-1265]** |
| `TextPainter.layout()` with same width, text unchanged | **free** | `_resizeToFit` returns true when `maxWidth == contentWidth` and `minWidth == contentWidth` **[src :486-489]** |
| `TextPainter.layout()` with a wider width but `paragraph.width - maxIntrinsicWidth > 0` | **free-ish** | `skipLineBreaking` path; only the paint offset/content width is recomputed **[src :504-514]** |
| `TextPainter.layout()` after `text =` with a `RenderComparison.layout` change | **full re-shape** | `markNeedsLayout()` disposed the old paragraph **[src :819-820, :788-789]** |
| `text =` with only a colour change (`RenderComparison.paint`) | **full re-shape, deferred** | `_rebuildParagraphForPaint = true`; the paragraph is rebuilt inside `paint()` **[src :821-825, :1335-1352]**. Framework comment: "there's no API to only make those updates so the paragraph has to be recreated and re-laid out" **[src :1343-1345]** |
| `paint()` | cheap | one `canvas.drawParagraph` **[src :1358]** |
| `getOffsetForCaret` | cheap, but **caches per position** | `_previousCaretPositionKey`; walks line metrics / glyph info, no relayout **[src :527-528, _computeCaretMetrics]** |
| `getBoxesForSelection` | cheap read, allocates `List<TextBox>` | `paragraph.getBoxesForRange(...)` then optionally maps a shift; **allocation** on every call **[src :1666-1689]** |
| `computeLineMetrics()` | cheap read, **cached** | `_cachedLineMetrics ??= paragraph.computeLineMetrics()` **[src :524]** |
| `maxIntrinsicWidth` / `minIntrinsicWidth` | free after layout | reads `_layoutCache.layout.*IntrinsicLineExtent` **[src :1135-1146]** |
| `preferredLineHeight` | cheap but builds a throwaway 1-char paragraph, then caches it | `_getOrCreateLayoutTemplate()` **[src :1103-1115, :1129]** |
| `TextPainter.computeWidth(...)` | **expensive by construction** | doc comment says so: "Doing this operation is expensive and should be avoided" **[src :639-641]** |
| `TextPainter.dispose()` | cheap Dart + frees native `Paragraph` | must be called or the native paragraph leaks until engine-side finalisation **[src :1827+, doc]** |
| `InlineSpan.toPlainText()` | **O(n), cached in the painter** | `_cachedPlainText` **[src :832-837]**; invalidated on every `text =` |

### 6.1.4 How a `Paragraph` is invalidated — the full rule set

`TextPainter` mutators, all from `painting/text_painter.dart`:

| Setter | Effect | Line |
|---|---|---|
| `text =` | `RenderComparison` drives it: `layout` → `markNeedsLayout()`; `paint` → `_rebuildParagraphForPaint = true` + `markNeedsLayout()` on the *paragraph* only at paint time; `metadata`/`identical` → nothing. Also nulls `_cachedPlainText`, and if the top-level `style` changed, disposes `_layoutTemplate`. | :802-827 |
| `textAlign =` | `markNeedsLayout()` | :846 |
| `textDirection =` | `markNeedsLayout()` **and** disposes `_layoutTemplate` | :871-879 |
| `textScaler =` | `markNeedsLayout()` | :918 |
| `ellipsis =` | `markNeedsLayout()` | :946 |
| `locale =` | `markNeedsLayout()` | :958 |
| `maxLines =` | `markNeedsLayout()` | :977 |
| `strutStyle =` | `markNeedsLayout()` | :1000 |
| `textHeightBehavior =` | `markNeedsLayout()` | :1026 |
| `textWidthBasis =` | **no `markNeedsLayout`**, only `_debugNeedsRelayout = true`; the next `layout()` call re-enters `_resizeToFit`, which recomputes `contentWidth` and can return true (paint-offset-only change) | :1013-1022, :471-516 |
| `setPlaceholderDimensions(...)` | `listEquals`-guarded; if different → `markNeedsLayout()` | :1064-1080 |
| `markNeedsLayout()` (explicit) | `_layoutCache?.paragraph.dispose(); _layoutCache = null;` | :781-790 |
| `systemFontsDidChange()` (RenderParagraph override) | `markNeedsLayout()` — **font fallback changes invalidate every paragraph** | `rendering/paragraph.dart:885-887` |

`RenderParagraph` additionally subscribes to a `SelectionRegistrar`, disposes/re-creates selectable
fragments on layout changes, and rebuilds its semantics info (`rendering/paragraph.dart:423-447`).

> **Consequence for Niman:** any state that changes globally — `textScaler`, `locale`, the theme's
> `TextStyle`, a font that arrives late — invalidates **every** cached paragraph in the document. The
> cache must be keyed on those values and *dropped wholesale* when they change, not patched.
> **[inference]**

### 6.1.5 Why `layout()` dominates, and how to avoid repeating it

`ui.Paragraph.layout()` is where HarfBuzz/Skia shaping runs: it maps the UTF-16 string to glyphs,
applies GSUB/GPOS (ligatures, kerning), resolves font fallback per run, computes break opportunities
(UAX #14), and greedily fills lines. Everything else (`getPositionForOffset`, `computeLineMetrics`) is
an index lookup over the already-shaped result. This is why the framework's own comment at
`text_painter.dart:1271-1272` says:

> "This is not as expensive as it seems, **line breaking is relatively cheap as compared to shaping**."

Confirmed by the widely-reported experience that `paragraph.layout()` is the only expensive call
([flutter#92173](https://github.com/flutter/flutter/issues/92173), **[doc]**) and by the
`itsallwidgets` thread on `TextPainter` slowness, whose author reports that caching `TextPainter`
objects per (text, style) "improved performance tremendously" **[doc]**.

**Avoidance rules, in priority order:**

1. **Never call `TextPainter.computeWidth`/`computeMaxIntrinsicWidth` in a build or layout path.**
   They construct, lay out and dispose a fresh painter. Use a persistent painter.
2. **Never mutate `text` to a *new but equal* span tree.** `RenderParagraph.text` setter relies on
   `InlineSpan.compareTo`, so keep a stable cached `InlineSpan` identity per block.
3. **Never change `TextStyle` objects gratuitously.** Implement `==`/`hashCode` on your own style
   tokens (Flutter's own `TextStyle` has deep equality — `text_style.dart` — so caching a
   *canonicalised* style per token kind pays off). **[inference, but standard Flutter practice]**
4. **Colour-only changes are not free.** Highlighting a search match by swapping the text colour
   rebuilds and re-lays out that paragraph. Prefer painting the highlight *behind* the glyphs
   (see §6.4.6) and leaving `TextStyle` untouched. **[inference from :1335-1352]**
5. **Reuse the `TextPainter`.** Hold one painter per visible block inside the render object /
   `CustomPainter`, call `layout()` only when the block's cache key changes, and `dispose()` in
   `dispose()`.

### 6.1.6 `TextPainter` reuse and the layout cache

There is **no built-in `LayoutCache` class** in the public API. Flutter's `RenderParagraph` keeps
exactly one `TextPainter` (`rendering/paragraph.dart:391`, `_textPainter`) and one
`_layoutTemplate` + `_textIntrinsics` template painter; the only "cache" is
`_TextPainterLayoutCacheWithOffset` (one entry). A document-scoped multi-entry cache is ours to build.

Sketched, with the pieces that actually matter:

```dart
/// Identity of a laid-out paragraph. Everything that forces markNeedsLayout()
/// in TextPainter must be in this key. [src §6.1.4]
@immutable
final class ParagraphKey {
  final int spanTreeId;      // stable id for the *canonical* InlineSpan instance
  final int styleTokenId;    // interned TextStyle (incl. fontFamily/Fallback/features)
  final double layoutWidth;  // the maxWidth passed to layout(); quantised to 1/64 px
  final double minWidth;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final TextWidthBasis textWidthBasis;   // in key: changes contentWidth
  final int? maxLines;
  final String? ellipsis;
  final Locale? locale;
  final int? strutStyleId;               // interned StrutStyle
  final int? textHeightBehaviorId;       // interned TextHeightBehavior
  final int placeholderDimsHash;         // listEquals over PlaceholderDimensions
  // hashCode: Object.hash(...) over the cheap ones; keep it allocation-free.
}
```

```dart
final class ParagraphCache {
  ParagraphCache({this.maxEntries = 96});
  final int maxEntries;
  final _map = <ParagraphKey, TextPainter>{};   // LinkedHashMap == insertion-ordered LRU
  final _inFlight = <ParagraphKey, TextPainter>{};

  TextPainter acquire(ParagraphKey key, InlineSpan Function() build) {
    final hit = _map.remove(key);
    if (hit != null) { _map[key] = hit; return hit; }       // refresh LRU position
    final tp = TextPainter(textDirection: key.textDirection, /* ...key fields... */);
    tp.text = build();
    tp.setPlaceholderDimensions(key.placeholderDimensions);
    tp.layout(minWidth: key.minWidth, maxWidth: key.layoutWidth);
    _evictIfNeeded();
    _map[key] = tp;
    return tp;
  }

  void _evictIfNeeded() {
    while (_map.length >= maxEntries) {
      final victim = _map.remove(_map.keys.first)!;
      victim.dispose();                    // frees the native Paragraph — do NOT skip
    }
  }

  void invalidateAll() { for (final tp in _map.values) tp.dispose(); _map.clear(); }
  void invalidateWhere(bool Function(ParagraphKey) p) { /* remove+dispose matching */ }
}
```

**Eviction must call `dispose()`.** `ui.Paragraph` owns native memory; the framework's own docs for
`TextPainter.dispose()` (`text_painter.dart:575-585`) tell you to call it from `State.dispose` /
`RenderObject.dispose`. **[src, doc]**

**Cache key recommendation (short form):** hash
`(blockContentHash, styleTokenId, quantised *layoutWidth*, textScaler, textDirection, textAlign,
textWidthBasis, maxLines, ellipsis, locale, strutStyleId, textHeightBehaviorId, placeholderDimsHash)`.
Intern styles and behaviours; do **not** put the `InlineSpan` object in the key (identity is unstable
across rebuilds) — put a content hash that you compute once per parsed block. Quantise the layout
width (`(w * 64).round()`) so a 0.3 px resize from an animation does not blow the cache. Drop the
whole cache when `MediaQuery.textScalerOf`/`locale`/theme style changes. **[inference — sound but
unmeasured; the individual invalidation triggers are all [src]]**

### 6.1.7 `maxIntrinsicWidth`, and the N-small vs one-huge question

- `maxIntrinsicWidth` = `paragraph.maxIntrinsicWidth` = the width at which increasing width no longer
  reduces height (includes trailing spaces). `minIntrinsicWidth` = the narrowest width at which the
  text still paints completely (longest unbreakable word). Both require a previous `layout()`.
  **[src :1131-1146, `_TextLayout` :329-334]**
- The framework uses them for table/intrinsic sizing and for the `maxWidth == infinity` paint-offset
  workaround. For a Markdown surface, `maxIntrinsicWidth` is the right tool **only** for
  shrink-wrap cases (inline code chips, table cell auto-width, list markers). Do not use
  `TextPainter.computeMaxIntrinsicWidth` for them — it is the expensive static helper.

**N small paragraphs vs one huge paragraph** — this is the central architectural decision:

| | one `Paragraph` for the whole document | one `Paragraph` per block |
|---|---|---|
| Shaping work for one keystroke on line 5 000 | **all 934 KB re-shaped** (paragraph is atomic) | one block re-shaped |
| Cost of scrolling | zero (nothing invalidates) | zero once laid out; only newly-scrolled-in blocks pay |
| Cost of a resize | one very large re-shape | every visible block re-shapes (but bounded by viewport) |
| `getPositionForOffset` / selection | O(log-ish) inside one paragraph; simple offset math | must be routed to a block first, then offset inside it |
| Caret/selection across blocks | trivial offsets | needs a block-aware mapping layer |
| Memory | one native paragraph holding all glyphs & line records | many small paragraphs, evictable |
| Truncation/`maxLines` per block | impossible per block | natural |
| **Worst case** | **any edit = full-document re-shape → hard jank, unbounded** | bounded by block size |

**Verdict: one `Paragraph` per block, at block granularity (paragraph / heading / list item / code
line group / table cell). [inference, but strongly supported by the [src] fact that layout is atomic
and non-incremental]** This is what makes a 10 331-line document editable at all: the per-keystroke
re-shape cost becomes O(size of the edited block) instead of O(document).

A refinement worth doing: split **very long paragraphs** (e.g. a 5 000-character single line) into
"paragraph chunks" at soft-wrap boundaries only if profiling shows the single block dominating. Start
unsplit; measure.

### 6.1.8 `textScaler`, `textDirection`, `strutStyle`, `locale`, `maxLines` and caching

- **`textScaler`** (`TextScaler`, `painting/text_scaler.dart`): abstract since 3.12; `TextScaler.linear(f)`,
  `TextScaler.noScaling`, and a platform `SystemTextScaler` that may be *non-linear*. `scale(double)` is
  the only required method; `operator ==` "defines the equality of 2 TextScalers, which the framework
  uses to determine whether text widgets should rebuild". **[src :15-18]** It goes into both
  `ui.ParagraphStyle` and every `ui.TextStyle` (`getParagraphStyle`/`getTextStyle`) and therefore
  **must be in the cache key**. Read it once per frame via `MediaQuery.textScalerOf(context)`
  (`media_query.dart:1774`), not per block. **[src]**
- **`textDirection`**: in the key, obviously — it changes bidi resolution and `TextAlign.start/end`.
  Also disposes `_layoutTemplate`. **[src :871-879]**
- **`strutStyle`**: in the key. `StrutStyle.disabled` (`strut_style.dart:370`) is `height: 0, leading: 0`;
  `TextPainter._strutDisabled` (`:1486-1492`) treats null, `StrutStyle.disabled` and `fontSize == 0.0`
  as equivalent. A strut **fixes the line box height regardless of glyph content**, which is exactly
  what you want for a virtualised viewport: **estimated block heights become exact much more often.**
  Use a strut with an explicit `fontSize` and `height` on body text. **[inference; StrutStyle semantics
  are [src]/[doc]]**
- **`locale`**: in the key. It selects region-specific glyph forms (via `locl`) and locale-sensitive
  line breaking. Changing it is a full re-layout. **[src :956-961]**
- **`maxLines`**: in the key. Also changes caret placement at end-of-text and `didExceedMaxLines`.
  **[src :977, :1194-1196]**

`ui.ParagraphStyle` itself accepts `textAlign, textDirection, maxLines, fontFamily, fontSize, height,
textHeightBehavior, fontWeight, fontStyle, strutStyle, ellipsis, locale` — note **no
`leadingDistribution` at the paragraph level**; it belongs on `ui.TextStyle` (or inside
`TextHeightBehavior`). **[src]**

---

## 6.2 Building a custom render/viewport

### 6.2.1 `RenderBox` custom layout vs slivers vs one `CustomPaint`

Three viable shapes, in increasing order of control and cost:

**(a) `SliverList` + `SliverChildBuilderDelegate`.** The cheapest correct thing to build first.

```dart
// widgets/scroll_delegate.dart:352
const SliverChildBuilderDelegate(
  this.builder, {                       // Widget? Function(BuildContext, int)
  this.findChildIndexCallback,          // int? Function(Key) — lets reuse survive reordering
  this.childCount,
  this.addAutomaticKeepAlives = true,   // wrap each child in AutomaticKeepAlive
  this.addRepaintBoundaries = true,     // wrap each child in RepaintBoundary
  this.addSemanticIndexes = true,
  this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
  this.semanticIndexOffset = 0,
});
// override for a better scrollbar:
double? estimateMaxScrollOffset(int firstIndex, int lastIndex,
    double leadingScrollOffset, double trailingScrollOffset);   // scroll_delegate.dart:174
int? get estimatedChildCount;                                   // :165
```

`RenderSliverList` (`rendering/sliver_list.dart:40`) is a *variable-extent* sliver: it walks children
from the first one whose `childScrollOffset` is known, lays out until it covers
`constraints.remainingPaintExtent` + `cacheExtent`, and reports
`childManager.estimateMaxScrollOffset(...)` when it cannot walk the whole list (`:303-310`). It asks
the delegate for a scroll offset only for children that exist.

**(b) `SliverFixedExtentList` / `SliverPrototypeExtentList`.** If you can make *every* block row a fixed
height, `RenderSliverFixedExtentBoxAdaptor` (`rendering/sliver_fixed_extent_list.dart`) computes the
scroll offset arithmetically and never needs `childScrollOffset` — O(1) scroll math, no estimation
error, no "block above viewport changed height" problem *at all*. In practice only a fixed-line-height
**source** pane (no wrapping, no variable-height blocks) can do this. For the rendered preview it is
not achievable, but for the **plain-text source editor** with soft-wrap off it is the best possible
answer. **[inference; the arithmetic is [src] in that file]**

**(c) One big `CustomPaint` + `CustomPainter` with our own layout.** Full control over
`performLayout`/`paint`, no widget-per-block overhead, no element/render-object churn, no
`RepaintBoundary` wrappers, and — the real win — a **single place** to keep an offset→block index
(binary search) and an exact/estimated height table. Cost: we reimplement hit-testing, semantics,
focus traversal, and text selection routing.

`CustomPainter` (`rendering/custom_paint.dart:149`):

```dart
abstract class CustomPainter extends Listenable {
  const CustomPainter({Listenable? repaint});
  void paint(Canvas canvas, Size size);                          // :206
  bool shouldRepaint(covariant CustomPainter oldDelegate);       // :271  REQUIRED
  SemanticsBuilderCallback? get semanticsBuilder => null;        // :222
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => shouldRepaint(oldDelegate);
  bool? hitTest(Offset position) => null;                        // :286  null = defer to child/box
  Listenable? get repaint;                                       // forwarded from ctor
}
```

Notes that matter: `shouldRebuildSemantics` **defaults to `shouldRepaint`** — if you return `true` from
`shouldRepaint` for any reason (e.g. "the model changed"), you rebuild the *entire semantics subtree*
every frame. Keep `shouldRepaint` a real comparison, and drive paint-only invalidation through the
`repaint` `Listenable` instead. **[src :244]**

**Recommended architecture [inference]:** a hybrid.

* A `RenderBox` subclass (`_MarkdownSurfaceRender`) that owns the block index, the height table and
  the paragraph cache, does `performLayout` over the visible window exactly like `RenderSliverList`
  does, and paints all visible blocks itself with `TextPainter.paint` + `Canvas` rules in `paint()`.
* Wrap it in a **`Viewport`-free `Scrollable`** (or a `ListView` with one child = this render box) so
  you inherit `ScrollPosition`, physics, scrollbar and ballistic simulation without reimplementing them.
  The render box reads `position.pixels` and `position.viewportDimension`.
* Use `SliverList`+`SliverChildBuilderDelegate` for the *first* iteration (fast to get right,
  gives you `AutomaticKeepAlive`, `RepaintBoundary`, semantics for free), and migrate only the hot
  blocks (code, math, tables) to `CustomPaint` children. Measure before migrating everything.

### 6.2.2 `RepaintBoundary`, `Viewport`/`cacheExtent`

- `RenderViewport` lays out its slivers with a `cacheExtent` for each axis
  (`RenderViewport.cacheExtent`, `cacheExtentStyle`; default `RenderAbstractViewport.defaultCacheExtent
  = 250.0`). Children inside the cache extent are **built and laid out but not painted**. **[doc/src]**
  For a document where one block is a 2 MB code fence, a fixed 250 px cache extent is wrong in both
  directions: raise it to ~1 viewport height for smooth scroll, and make sure a single oversized block
  cannot be force-laid-out wholesale (split code blocks at line boundaries).
- `RepaintBoundary` creates an `OffsetLayer` and a separate `Picture`. It is worth it when a subtree
  repaints often while its surroundings do not (a blinking caret; a hover-highlighted block; a math
  block being edited). It is a *loss* when the subtree repaints every frame anyway (extra layer + extra
  GPU target) or when there are thousands of them (layer memory, compositing overhead).
  **Do not rely on `addRepaintBoundaries: true` for a 20 000-block document** — one boundary per block
  is thousands of layers. Wrap only: the whole surface (one boundary vs. the app chrome), the caret,
  and actively-hovered/edited blocks. `SliverChildBuilderDelegate(addRepaintBoundaries: false)` then
  re-add selectively. **[inference; the delegate default is [src :363]]**

### 6.2.3 `RenderParagraph` vs `TextSpan`+`WidgetSpan` vs `CustomPaint`

- **`RenderParagraph`** is the ready-made "one paragraph, correctly measured, with inline children,
  selection registration and semantics" box. It calls `layoutInlineChildren` before
  `_layoutTextWithConstraints`, so **placeholder sizes are resolved in the same pass** as the text
  (`rendering/paragraph.dart:956-968`). If you just need "a block of styled text with an inline
  widget", `RenderParagraph` is the right box and you should not reimplement it. `RichText`/`Text.rich`
  build one.
- **`WidgetSpan` vs `TextSpan`:** a `WidgetSpan` is a `PlaceholderSpan` (`placeholder_span.dart:36`)
  whose measured size is injected into the paragraph as a `PlaceholderDimensions`. Inside the
  paragraph it occupies exactly one `U+FFFC` object-replacement character
  (`PlaceholderSpan.placeholderCodeUnit = 0xFFFC`, `:53`; `computeToPlainText` writes it, `:56-63`).
  **That single code unit is the source of nearly every selection bug** (§6.9): selection ranges count
  one code unit for the widget regardless of how many *source* characters it represents, and
  `getBoxesForSelection` returns a box for the `U+FFFC` that is the placeholder rect, not the source
  text. **[src]** For Niman, any inline content that must map back to source bytes (inline math,
  wikilink chips, footnote refs, images) needs an explicit **offset ledger**: keep a parallel list of
  `(paragraphOffset, sourceStart, sourceEnd)` for every placeholder so you can translate.
- **`TextSpan`** with nested styles is free structurally — `TextSpan.build` (`painting/text_span.dart`)
  pushes/pops `ui.TextStyle` on a single `ParagraphBuilder`, so **a whole block's inline span tree
  becomes exactly one `ui.Paragraph`**. That is the win: bold/italic/code/link in one block cost one
  shaping pass, not one per span. **[src]**
- **`CustomPaint`** for decorations behind/around glyph runs (code backgrounds, blockquote bars,
  table rules, callout boxes, search highlights), batched into as few `Canvas` calls as possible.

### 6.2.4 One-`Paragraph`-per-block: when is that the right granularity?

**Right** when the unit is "a run of text that flows together and whose line breaks depend only on its
own width": paragraphs, headings, list-item text, table cells, quote lines.

**Wrong** when:
- the block contains inline widgets whose size depends on the text width (a `WidgetSpan` inside a
  wrapped line forces `layoutInlineChildren` → a second measure pass in the render box) — flatten
  those to drawn content where possible;
- the block is a **code fence**: highlight colors are per-token and a code fence can be 200 KB. Split it
  **per line**, or per logical line group, and virtualise inside the fence;
- the block is a **table**: lay out each *cell* as its own paragraph so column widths can be computed
  from `minIntrinsicWidth`/`maxIntrinsicWidth` without reshaping the whole table for each candidate
  width;
- the block is a **math block**: math is a box tree, not a paragraph (see the math section).

### 6.2.5 Incremental layout and the "block above the viewport changed height" problem

This is the single hardest interaction problem in the widget. Frame the state precisely:

* `scrollOffset` (the `ScrollPosition.pixels`) is the **scroll offset of the first laid-out child**,
  not "the scroll offset of block 0". `RenderSliverList` computes everything from
  `childScrollOffset(firstChild)` (`sliver_list.dart:125-171`).
* If block 4 000 (above the viewport) grows by 30 px, then **every child at or below it shifts by
  30 px** and the content above the viewport gets taller. If you naively keep `pixels` constant, the
  visible content jumps up by 30 px.

Three techniques, in order of preference:

**(1) Anchor-based scroll preservation (the general solution).**
Keep an anchor as `(anchorBlockIndex, anchorOffsetWithinBlock)`. Before a relayout:

```dart
final int anchorIndex = indexAtOffset(position.pixels);        // binary search height table
final double anchorDelta = position.pixels - offsetOf(anchorIndex); // offset inside that block
```

After the relayout, recompute `offsetOf(anchorIndex)` from the new height table and set
`position.correctPixels(newOffsetOf(anchorIndex) + anchorDelta, ...)`, then
`position.applyContentDimensions(0, newMaxScrollExtent)`.
`ScrollPosition.correctPixels(double value)` + `applyContentDimensions` is the supported way to move
the offset without animation or notification storms; `jumpTo` fires `ScrollNotification`s and can
re-trigger listeners. **[inference on the API choice; the fields/methods are [doc]]**
Placeholder-anchor analogue: `SliverConstraints` + `SliverGeometry.scrollOffsetCorrection` is how a
sliver tells the viewport "I actually scrolled by this much" — `RenderSliverList` uses it when its
first child's offset was wrong (`sliver_list.dart:179-205`). If we own the sliver, we can use the same
mechanism.

**(2) Prefer edits below the viewport / push the correction to the user's hand.** For typing, the
common case is that the edited block *is* the one containing the caret, i.e. inside or below the
viewport. The nasty case is a huge document where an edit at the top changes a block above. Anchor
correction (1) covers both.

**(3) Height stability by construction.** If a block's height is unchanged by the edit (very common:
typing inside a paragraph at a fixed width changes line count only occasionally), the height table
entry does not change and nothing shifts. Make the height table key on `(blockContentHash, width,
styleTokenId)`; reuse the previous height when the key is unchanged. **[inference]**

**Estimated / extrapolated heights.** Do not lay out 20 000 blocks to size them. Maintain:

```dart
final class HeightTable {
  final Float64List heights;       // NaN == unknown
  final Float64List offsets;       // prefix sums, lazily rebuilt
  final double meanMeasured;       // running mean of known heights
  double estimate(int index) => heights[index].isNaN ? meanMeasured : heights[index];
  double offsetOf(int index);      // sum of known + estimate for unknown, cached
  int indexAtOffset(double y);     // binary search over the same table
}
```

Extrapolating with the running mean gives a scrollbar that is *approximately* right and a viewport
position that is *approximately* right; the anchor fix-up must run whenever a laid-out block's real
height replaces an estimate. Keep a `prefixSumDirtyFrom` index so recomputation after a height change
is O(1) amortised (only suffix sums change). **[inference — standard virtualised-list design]**

**Typed arrays for the height table** (`Float64List`/`Int32List`) are the right choice: 20 000 doubles is
160 KB, no per-element boxing, and it is trivially transferable to/from an isolate if the layout pass
ever moves.

---

## 6.3 Editable text from scratch

### 6.3.1 The `TextInputClient` protocol (exact, Flutter 3.47.2)

```dart
// services/text_input.dart:1338
mixin TextInputClient {
  TextEditingValue? get currentTextEditingValue;
  AutofillScope? get currentAutofillScope;
  void updateEditingValue(TextEditingValue value);
  void performAction(TextInputAction action);
  void insertContent(KeyboardInsertedContent content) {}          // Android rich content insertion
  void performPrivateCommand(String action, Map<String, dynamic> data);
  void updateFloatingCursor(RawFloatingCursorPoint point);
  void showAutocorrectionPromptRect(int start, int end);          // iOS only
  bool onFocusReceived() => false;
  void connectionClosed();
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {}
  // ... showToolbar / performSelector etc.
}

// services/text_input.dart:1518
mixin DeltaTextInputClient implements TextInputClient {
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas);
}
```

`TextInputConnection` (`services/text_input.dart:1668`) — the handle your client holds:

```dart
static TextInputConnection attach(TextInputClient client, TextInputConfiguration configuration); // :2088
void show();                                             // :1704
void updateConfig(TextInputConfiguration configuration); // :1724
void setEditingState(TextEditingValue value);            // :1731
void setEditableSizeAndTransform(Size editableBoxSize, Matrix4 transform); // :1745
void setComposingRect(Rect rect);                        // :1761
void setCaretRect(Rect rect);                            // :1772
void setSelectionRects(List<SelectionRect> selectionRects); // :1785
void setStyle({String? fontFamily, double? fontSize, FontWeight? fontWeight,
               TextDirection? textDirection, TextAlign? textAlign,
               double? letterSpacing, double? wordSpacing, double? lineHeight}); // :1801
void close();                                            // :1833
```

`TextInputConfiguration` (`services/text_input.dart`; full field list read from source):

```dart
const TextInputConfiguration({
  int? viewId, TextInputType inputType = TextInputType.text, bool readOnly = false,
  bool obscureText = false, bool autocorrect = true,
  SmartDashesType smartDashesType, SmartQuotesType smartQuotesType,
  bool enableSuggestions = true, bool enableInteractiveSelection = true,
  String? actionLabel, TextInputAction inputAction = TextInputAction.done,
  TextCapitalization textCapitalization = TextCapitalization.none,
  Brightness keyboardAppearance = Brightness.light,
  AutofillConfiguration autofillConfiguration = AutofillConfiguration.disabled,
  bool enableIMEPersonalizedLearning = true, List<String> allowedMimeTypes = const [],
  bool enableDeltaModel = false,                  // <-- the important one
  List<Locale>? hintLocales, bool? enableInlinePrediction,
});
```

`enableDeltaModel` documentation verbatim (`:769-788`) **[src]**:

> Whether to enable that the engine sends text input updates to the framework as `TextEditingDelta`'s
> or as one `TextEditingValue`. […] When this is enabled: you must implement `DeltaTextInputClient` and
> not `TextInputClient`; platform text input updates will come through
> `updateEditingValueWithDeltas`. […] Defaults to false.

Dispatch is a plain switch on the platform channel (`_handleTextInputInvocation`, `:2159`):

```dart
case 'TextInputClient.updateEditingState':
  final value = TextEditingValue.fromJSON(args[1] as Map<String, dynamic>);
  TextInput._instance._updateEditingValue(value, exclude: ...);
case 'TextInputClient.updateEditingStateWithDeltas':
  assert(_currentConnection!._client is DeltaTextInputClient,
      'You must be using a DeltaTextInputClient if TextInputConfiguration.enableDeltaModel is set to true');
  final encoded = args[1] as Map<String, dynamic>;
  final deltas = <TextEditingDelta>[
    for (final dynamic d in encoded['deltas'] as List<dynamic>)
      TextEditingDelta.fromJSON(d as Map<String, dynamic>),
  ];
  (_currentConnection!._client as DeltaTextInputClient).updateEditingValueWithDeltas(deltas);
```

### 6.3.2 `TextEditingDelta` variants and when the framework falls back

`abstract class TextEditingDelta` (`services/text_editing_delta.dart:58`) with four concrete variants,
each holding `oldText`, `selection`, `composing` and implementing `TextEditingValue apply(TextEditingValue)`:

| Class | Extra fields | `apply` semantics | Line |
|---|---|---|---|
| `TextEditingDeltaInsertion` | `textInserted`, `insertionOffset` | `replaceRange(offset, offset, textInserted)` | :299 |
| `TextEditingDeltaDeletion` | `deletedRange` | `replaceRange(start, end, '')` | :359 |
| `TextEditingDeltaReplacement` | `replacementText`, `replacedRange` | `replaceRange(start, end, replacementText)` | :412 |
| `TextEditingDeltaNonTextUpdate` | — | only `selection`/`composing` change; text untouched | :476 |

The *classification* happens in `TextEditingDelta.fromJSON` (`:64`) and is worth quoting because it
tells you exactly when you get a coarse update. The engine sends
`(deltaStart, deltaEnd, deltaText)` plus the new composing/selection. The framework then:

* if `deltaStart == -1 && deltaStart == deltaEnd` → `NonTextUpdate`;
* if the replacement destination is collapsed → `Insertion`;
* if the replacement source is empty → `Deletion`;
* **while composing**, the platform replaces the *whole composing region* per keystroke. The framework
  detects insertion vs deletion by comparing `oldText[composingRange]` with the replacement text, and
  emits `Replacement` when the composing text genuinely changed. The source comment (`:88-105`) gives
  the worked example: composing `worl|`, type `d`, Android reports "'worl' was replaced with 'world' at
  range (0,4)" → classified as an insertion of `d`. **[src]**

**Performance implication per keystroke:**

* **Whole-`TextEditingValue` round trip (delta model off).** Every keystroke sends the **entire**
  document string over the platform channel, in *both* directions, as a `TextEditingValue`
  (`text`, `selectionBase/Extent`, `composingBase/Extent`, `selectionAffinity`, `selectionIsDirectional`).
  For 934 KB that is a ~934 KB–1.9 MB UTF-8 JSON-ish payload per keystroke, plus a Dart `String`
  allocation, plus a full `TextEditingValue` equality/hash, plus — in `EditableText` — a
  `_formatAndSetValue` → controller-notify → rebuild of the whole editable. **This is unusable at
  934 KB.** Even at 200 KB it is the dominant per-keystroke cost. **[src for the payload shape;
  inference for the magnitude]**
* **Delta model on.** Per keystroke the engine sends one small map: a few ints plus the inserted/
  deleted string (typically 1–40 bytes). The framework's own `fromJSON` allocates one small object.
  Our client applies it by splicing the changed range into its own buffer. **This is the mode Niman must
  use.** **[src]**
* **`NonTextUpdate`** still arrives on selection/caret moves; treat it as a selection-only change and
  do **not** re-parse. **[src]**
* The delta model does **not** fire for programmatic `setEditingState` (that is us pushing state *to*
  the platform) and can be bypassed by platforms that do not implement the delta channel. Keep a
  guarded fallback path: if `updateEditingValue` fires with a value whose `text` differs from ours by
  more than a small diff, run a cheap diff (`common prefix/suffix`) to recover the range rather than
  replacing the buffer. **[inference; no [src] assertion that all platforms honour deltas]**

### 6.3.3 IME composition, `composing`, dead keys, CJK

* The provisional text lives **inside** `TextEditingValue.text`; the `composing` field
  (`TextRange`, `ui/text.dart:618`) marks the provisional sub-range. `TextRange` has `start`, `end`,
  `isValid` (`start >= 0 && end >= 0`), `isCollapsed`, `isNormalized` (`end >= start`),
  `textBefore/textInside/textAfter(String)`, and `TextRange.empty = TextRange(start: -1, end: -1)`.
  **An unset composing range is `(-1, -1)`** — never treat 0 as "no composing". **[src]**
* **You must round-trip `composing` faithfully.** `setEditingState(TextEditingValue(...))` is how the
  platform's IME learns where the marked text is; dropping it breaks CJK/predictive input. Always
  echo back the composing range the engine last sent, unless you are the one committing the text.
  **[inference from the protocol shape; the field is [src]]**
* **`TextInput.setMarkedText` does not exist in the Dart API.** What exists is
  `TextInput.setMarkedTextRect` (invoked from `TextInputConnection.setComposingRect`,
  `services/text_input.dart:2728-2740`), which tells the platform where the marked text is *drawn*.
  The Dart-side lever for provisional text is the `composing` range in the editing value, plus
  `setComposingRect`/`setCaretRect` so the IME anchors its candidates correctly. Marked text lives in
  the engine's platform implementations (iOS `setMarkedText:` on `UITextInput`, Android
  `setComposingText` on `InputConnection`). **[src]**
* **Dead keys** (`` ` ``, `´`, `^`, `~`, `¨` then a vowel): on desktop GTK/Windows these arrive as a
  sequence of key events, and on some platforms as a composing range. Handle them at the same layer as
  CJK: never mutate `text` while `composing` is valid and non-collapsed. For hardware-keyboard
  platforms, whether to route characters through `KeyEvent.character` or through the IME is a real
  decision: **always prefer the IME** (an attached `TextInputConnection`) so dead keys, IMEs and
  AltGr layouts are handled by the platform. **[inference]**
* **CJK**: the composing region can be the entire in-progress word. Because the framework may classify
  each composition step as a `Replacement` of the whole composing region, your keystroke handler must
  be O(size of the replaced range), not O(document). Also: **do not re-highlight/re-parse on
  composition-only changes** if you can avoid it — a composing change is a text change, so you must
  re-lex the affected block, but you can skip everything else. **[inference]**

### 6.3.4 Keyboard: `HardwareKeyboard`, `KeyEvent`, `Shortcuts`/`Actions`/`Intent`, `Focus`

```dart
// services/hardware_keyboard.dart:411
class HardwareKeyboard {
  static HardwareKeyboard get instance => ServicesBinding.instance.keyboard;  // :414
  bool isLogicalKeyPressed(LogicalKeyboardKey key);      // :458
  bool isPhysicalKeyPressed(PhysicalKeyboardKey key);    // :462
  void addHandler(KeyEventCallback handler);             // :570
  void removeHandler(KeyEventCallback handler);          // :588
}
```

- **`RawKeyboard` is deprecated** — its `addListener`/`removeListener` message is "No longer supported.
  Use `HardwareKeyboard.instance.addHandler instead.`" (`hardware_keyboard.dart:1091`, `:1166`). Use
  `KeyEvent` / `HardwareKeyboard`.
- **`KeyEvent` API (modern):** a `KeyEvent` carries `physicalKey`, `logicalKey`, `character`,
  `timeStamp`, and subclasses `KeyDownEvent` / `KeyUpEvent` / `KeyRepeatEvent`. `KeyEventCallback` is
  `bool Function(KeyEvent)`; return `true` to consume. `KeyEventManager`/`ServicesBinding` dispatches
  to handlers in reverse registration order. **[src]**
- **`Shortcuts` + `Actions` + `Intent` is the right layer for editor commands.**

```dart
// widgets/shortcuts.dart:1016
const Shortcuts({super.key, this.shortcuts = const {}, this.child,
                 this.includeSemantics = true});
// widgets/actions.dart:731
const Actions({super.key, this.dispatcher, required this.actions, required this.child});
// widgets/actions.dart:64
abstract class Intent with Diagnosticable { const Intent(); }
// widgets/actions.dart:606
class CallbackAction<T extends Intent> extends Action<T> { ... }
```

Define `class BoldIntent extends Intent { const BoldIntent(); }`, map
`SingleActivator(LogicalKeyboardKey.keyB, control: true)` (and `meta:` on macOS) to it in `Shortcuts`,
and handle it in an `Actions` map. `DoNothingAndStopPropagationIntent`
(`actions.dart:1478`) is how you swallow a key in a scope; `ActivateIntent` (`:1533`) is for
Enter/Space. This gives you one table of editor commands, testable without synthesising raw events, and
it composes with the platform's own text-editing shortcuts. **[inference on design; all three classes and
their ctors are [src]]**
- **`Focus`/`FocusNode`:**

```dart
// widgets/focus_manager.dart
FocusNode? get parent;                 // :673
bool get hasFocus;                     // :774   (this node or a descendant)
bool get hasPrimaryFocus;              // :791   (this node is the primary focus)
bool get canRequestFocus;              // :544
void requestFocus([FocusNode? node]);  // :1161
void unfocus({UnfocusDisposition disposition = UnfocusDisposition.scope}); // :924
```

`Focus(onKeyEvent: ...)` is a *node-local* handler; `HardwareKeyboard.addHandler` is global. Prefer
`Shortcuts`/`Actions` for commands and `onKeyEvent` only for things that must see every key (vim-style
modal editing, key-up pairs). Attach the `TextInputConnection` on focus gain and close it on focus
loss — that is what `EditableText` does (`_handleFocusChanged`, `widgets/editable_text.dart:4939`,
`_openInputConnection` `:4105`). **[src]**

### 6.3.5 Caret + selection overlay: what `RenderEditable` actually does

`RenderEditable` (`rendering/editable.dart:267`) is a `RenderBox` that owns one `TextPainter` and:

1. **Layout** (`performLayout`): `layoutInlineChildren` → `_textPainter.setPlaceholderDimensions` →
   `_textPainter.layout(minWidth, maxWidth)` → `positionInlineChildren` → `_computeCaretPrototype()`;
   then `size = Size(constrainWidth(textPainter.width + _caretMargin), constrainHeight(preferredHeight))`,
   and it drives its own `ViewportOffset` (`offset.applyViewportDimension/_getMaxScrollExtent/
   applyContentDimensions`). **An editable scrolls itself**, it is not a child of a `Viewport`.
2. **Caret geometry**: `getLocalRectForCaret(TextPosition)` = `_textPainter.getOffsetForCaret(pos,
   _caretPrototype)` shifted by the paint offset. `_caretPrototype` is derived from the text style
   metrics; `_caretMargin = _kCaretGap + cursorWidth` (`:1279`).
3. **Selection geometry**: `getBoxesForSelection(TextSelection)` delegates to
   `_textPainter.getBoxesForSelection(selection, boxHeightStyle: selectionHeightStyle,
   boxWidthStyle: selectionWidthStyle)` and shifts by the paint offset (`:1309-1327`). Defaults are
   `ui.BoxHeightStyle.tight` / `ui.BoxWidthStyle.tight`; a *selection highlight* looks better with
   `BoxHeightStyle.includeLineSpacingMiddle` (or `.max`) and `BoxWidthStyle.tight`.
4. **Caret painting** is a pluggable `RenderEditablePainter` (`:2825`): `_CaretPainter` (`:2950`),
   `_TextHighlightPainter` (`:2852`), `_CompositeRenderEditablePainter` (`:3110`), hosted by
   `_RenderEditableCustomPaint` (`:2742`) as foreground/background children. `_CaretPainter` draws a
   `Rect` or an `RRect` (`CursorRadius`) and blends a *floating* cursor over the regular one using a
   squared-distance threshold; it is driven by a `ValueNotifier<bool> showCursor` (`:900`).
5. **Blink**: an external `Timer`/`AnimationController` flips `showCursor`; `RenderEditable` listens
   (`_showHideCursor`) — it does not own the blink timing.
6. **Scrolling the caret into view**: `RenderEditable` has its own `ViewportOffset` and a
   `_showCaretOnScreen`-style flow driven by the widget layer, plus
   `_updateSelectionExtentsVisibility` (`:697`) which compares the caret/selection end offsets against
   the viewport and sets `_selectionStartInViewport` / `_selectionEndInViewport` `ValueNotifier<bool>`.
   `RenderEditable.showOnScreen` returns a `Rect` for the framework to reveal.
7. **Semantics**: `describeSemanticsConfiguration` publishes a `SemanticsConfiguration` with the whole
   text as an `AttributedString`, a `TextSelection` semantic range, and creates child nodes per
   selectable fragment / placeholder with computed accessibility rects from
   `getBoxesForSelection` (`:1330-1500`). This is a substantial, non-trivial piece.

**Can `RenderEditable` be reused?** Technically yes — it is public and constructible; a widget can
create one with `text`, `selection`, `offset`, `textSelectionDelegate`, `cursorColor`,
`selectionColor`, `selectionHeightStyle`/`selectionWidthStyle`, `paintCursorAboveText`,
`selectionEnabled`, `showCursor`, `caretPainter`, etc. **[doc/src]**
But for Niman it is the **wrong granularity**, for four reasons:

* it is built for **one contiguous field**; its text is a single `InlineSpan`/`String` and it has one
  `TextSelection`. A Markdown document with per-block paragraphs, per-block source ranges and
  `U+FFFC` placeholders does not fit its selection model;
* its `performLayout` lays out the **entire** text into one `TextPainter` — exactly the
  one-huge-paragraph failure mode (§6.1.7);
* it drags in `TextSelectionDelegate`, `RenderEditablePainter` foreground/background children, its own
  `ViewportOffset`, and gesture/semantics machinery tuned to a text field — most of which you would
  fight;
* **what you actually want from it is small**: the caret rect, the selection boxes, the highlight
  painting pattern, and the "reveal caret" rect. All four are ≤40 lines on top of a `TextPainter`:

```dart
Rect caretRect(TextPainter tp, TextPosition pos, {double width = 2.0, double gap = 1.0}) {
  final r = tp.getOffsetForCaret(pos, Rect.fromLTWH(0, 0, width, tp.preferredLineHeight));
  final h = tp.getFullHeightForCaret(pos, Rect.fromLTWH(0, 0, width, tp.preferredLineHeight));
  return Rect.fromLTWH(r.dx + gap + blockOrigin.dx, blockOrigin.dy, width, h);
}

void paintSelection(Canvas c, TextPainter tp, Offset origin, TextSelection sel, Paint p) {
  for (final b in tp.getBoxesForSelection(sel,
        boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle)) {
    c.drawRect(b.toRect().shift(origin), p);
  }
}
```

**Recommendation [inference]:** reimplement caret + selection over our own per-block painters, and
**copy** these specific ideas from `RenderEditable` verbatim: the `RenderEditablePainter` split
(background highlights / caret / foreground), the `ValueNotifier<bool> showCursor` blink input, the
`_caretPrototype` concept, `cursorOffset` for a floating cursor, and `_updateSelectionExtentsVisibility`.
Reuse `RenderEditable` only if a future "single-block code cell" ever needs a real IME-backed field.

### 6.3.6 Selection handles, magnifier, `SelectableRegion`

* **Selection handles**: `TextSelectionControls` (`widgets/text_selection.dart:97`) is the abstract
  handles/toolbar controller; `TextSelectionHandleControls` is the handles-only variant;
  `SelectionOverlay` (`:1070`) builds the draggable handles + magnifier + toolbar overlay given a
  `RenderObject` and a `TextSelectionDelegate`; `TextSelectionOverlay` (`:330`) is the higher-level
  object that owns the overlay entries for a field. `TextSelectionGestureDetectorBuilder` (`:2220`)
  is the gesture layer (tap / long-press / drag / double-tap+drag) that turns gestures into
  `SelectionChangedCause`s. **[src]**
* **Magnifier**: `TextMagnifier` (Material, `material/magnifier.dart:29`), `CupertinoTextMagnifier`
  (`cupertino/magnifier.dart:34`), configured through `TextMagnifierConfiguration`
  (`widgets/magnifier.dart:106`). `RenderEditable` exposes `selectionOverlayStyle` /
  `magnifierConfiguration`. A custom surface gets this by feeding `SelectionOverlay` a
  `TextSelectionDelegate` whose `getSelectionGeometry` returns boxes it computed from our painters.
  **[src]**
* **`SelectableRegion`** (`widgets/selectable_region.dart:240`) and Material's **`SelectionArea`**
  (`material/selection_area.dart:46`) implement cross-widget selection by collecting
  `Selectable`/`SelectionRegistrar` fragments from `RenderParagraph`s. They work *if* your content is
  `RenderParagraph`s with a `SelectionRegistrar` in scope. They will **not** see text you paint with a
  bare `CustomPainter`. So: if you go the `CustomPaint` route, you must also publish a
  `SelectionRegistrar` (or your own semantics/selection model) yourself. **[src, inference for the
  consequence]**
* **Scrolling an editable**: the two supported patterns are (a) `RenderEditable`-style — the render
  object owns a `ViewportOffset` and calls `applyViewportDimension`/`applyContentDimensions` (used by
  `EditableText` for a single field), or (b) widget-style — the editor lives inside a `Scrollable`
  and the widget calls `Scrollable.ensureVisible` / `position.animateTo` to reveal the caret. For a
  virtualised document **use (b)**: one document scroll position, `ensureVisible`/anchor correction to
  reveal the caret, and the caret itself painted by the visible block. **[inference]**

---

## 6.4 Making text look native-quality without HTML

### 6.4.1 `TextStyle` — the fields that actually matter here

`TextStyle` (`painting/text_style.dart:480`) full field list, read from source:

`inherit`, `color`, `backgroundColor`, `fontFamily`, `fontFamilyFallback` (getter over
`_fontFamilyFallback`), `package`, `fontSize`, `fontWeight`, `fontStyle`, `letterSpacing`, `wordSpacing`,
`textBaseline`, `height`, `leadingDistribution`, `locale`, `foreground`, `background`, `decoration`,
`decorationColor`, `decorationStyle`, `decorationThickness`, `debugLabel`, `shadows`, `fontFeatures`,
`fontVariations`, `overflow`.

Two conversion methods:

```dart
ui.TextStyle   getTextStyle({double textScaleFactor = 1.0, TextScaler textScaler = TextScaler.noScaling});
ui.ParagraphStyle getParagraphStyle({TextAlign? textAlign, TextDirection? textDirection,
    TextScaler textScaler = TextScaler.noScaling, String? ellipsis, int? maxLines,
    TextHeightBehavior? textHeightBehavior, Locale? locale, String? fontFamily, double? fontSize,
    FontWeight? fontWeight, FontStyle? fontStyle, double? height, StrutStyle? strutStyle});
```

`fontSize` is scaled by `textScaler.scale(...)` inside `getTextStyle` (`:1346-1349`). **[src]**

### 6.4.2 `fontFeatures` — the real named constructors

`ui.FontFeature` (`engine/src/flutter/lib/ui/text.dart:203`) has `const FontFeature(this.feature,
[this.value = 1])`, `FontFeature.enable(String)`, `FontFeature.disable(String)`, and named constants.
The ones relevant to a code/Markdown surface (all `[src]`, verified by grep against the engine
`ui/text.dart`):

| Constructor | Tag | Use in Niman |
|---|---|---|
| `FontFeature.tabularFigures()` | `tnum` | **code blocks and tables** — makes digits monospaced so columns align; also line numbers |
| `FontFeature.slashedZero()` | `zero` | code, so `0`/`O` are distinguishable |
| `FontFeature.liningFigures()` | `lnum` | default-ish, but pin it for code |
| `FontFeature.fractions()` / `.alternativeFractions()` | `frac` / `afrc` | not usually wanted in code |
| `FontFeature.contextualAlternates()` | `calt` | **leave on** for prose |
| `FontFeature.localeAware({bool enable = true})` | `locl` | needed for Turkish/Azeri `i`, CJK variants |
| `FontFeature.stylisticAlternates()` | `salt` | optional |
| `FontFeature.enable('kern')` / `.disable('kern')` | `kern` | there is **no** `FontFeature.kerning()` named ctor; use `enable('kern')`/`disable('kern')`. Kerning is on by default in HarfBuzz. |
| `FontFeature.enable('liga')` / `.disable('liga')` | `liga` | standard ligatures — usually leave on. In code fonts `liga` often *is* `calt`; `FontFeature.disable('liga')` is the lever for "don't turn `->` into an arrow" |
| `FontFeature.enable('dlig')` / `.historicalLigatures()` (`hlig`) | `dlig`/`hlig` | disable `dlig` in code |
| `FontFeature.enable('ss01')`… or `FontFeature.stylisticSet(n)` | `ssNN` | font-specific |
| `FontFeature.characterVariant(n)` | `cvNN` | font-specific |

`FontFeature` values become part of the shaped result, so **font features belong in the paragraph
cache key** (via `styleTokenId`). **[inference]**

### 6.4.3 Decoration: underline, squiggly, strikethrough

```dart
TextDecoration.underline | .lineThrough | .overline | .none   // combinable via .combine
TextDecorationStyle.solid | .double | .dotted | .dashed | .wavy
TextStyle(decoration: ..., decorationColor: ..., decorationThickness: ..., decorationStyle: ...)
```

- `TextDecorationStyle.wavy` is the **spell-check squiggle** you want for unknown wikilinks / bad TeX;
  `decorationThickness` in logical pixels (default `1.0`).
- **`decorationThickness` semantics gotcha:** `TextDecoration` is per-`TextSpan`, so a nested span can
  override it; a decoration is drawn per glyph run, which means a wavy underline across a wrapped line
  is drawn per run and can look discontinuous on very long spans. **[inference]**
- **`TextStyle.background` (`Paint`) vs `backgroundColor` (`Color`)** — `backgroundColor` is shorthand
  for `Paint()..color = c`. Both are painted **per glyph box**, not per line: an inline-code background
  on a wrapped span produces a chain of rectangles with gaps at the line ends, and the background does
  **not** extend into the leading. For inline code that is usually acceptable; for a full-width code
  *block* background you must draw a `Rect`/`RRect` on the `Canvas` behind the paragraph instead
  (see §6.4.5). Also note `background`/`foreground`: if `foreground` is set, `color` is ignored.
  **[src]**
- **`TextStyle.foreground` with a `Shader`** is the supported way to do gradient text; it also makes
  the span a separate paint path. **[src]**

### 6.4.4 `InlineSpan` nesting and `WidgetSpan` baselines

- Nesting is cheap and total: `TextSpan(children: [...])` with `TextSpan(style: ...)` per token.
  Build one flat list of sibling spans where possible rather than deep nesting; `TextSpan.build` walks
  the tree and pushes/pops styles, and `visitChildren` walks it for text extraction — depth costs a
  little on both. **[src]**
- **`WidgetSpan` baseline alignment** is `ui.PlaceholderAlignment`:
  `{ baseline, aboveBaseline, belowBaseline, top, bottom, middle }`
  (`ui/text.dart:14` in the web SDK). `WidgetSpan(alignment:, baseline:)` is a `PlaceholderSpan`
  (`placeholder_span.dart:36`, defaults `alignment: ui.PlaceholderAlignment.bottom`, `baseline: null`).
  For an inline math chip you almost always want
  `alignment: ui.PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic` **plus** an explicit
  `PlaceholderDimensions.baselineOffset` — the widget is laid out with
  `addPlaceholder(dimensions, baselineOffset: ..., scale: ...)` so the offset is in *paragraph*
  coordinates. Setting `alignment: baseline` without a valid `baseline`/`baselineOffset` is a common
  source of a chip sitting visibly low or high. **[src, inference for the guidance]**
- `PlaceholderDimensions` (`painting/text_painter.dart:74`) is
  `{Size size, ui.PlaceholderAlignment alignment, TextBaseline? baseline, double? baselineOffset}` with
  `PlaceholderDimensions.empty` and value equality (`:121-133`). The list must have exactly one entry
  per `PlaceholderSpan`, in tree order, and `setPlaceholderDimensions` asserts that
  (`text_painter.dart:1068-1077`). **[src]**
- **`WidgetSpan` breaks text selection.** `WidgetSpan` (in `widgets/widget_span.dart`) wraps its child
  in a real element; `RenderParagraph` positions it via `positionInlineChildren`, and
  `InlineSpanSemanticsInformation.requiresOwnNode` is `true` for placeholders
  (`inline_span.dart:82`), so each placeholder becomes its own semantics node. Selection ranges count
  the placeholder as **one** code unit (`U+FFFC`), so selection bounds do not line up with source
  offsets. See §6.9.

### 6.4.5 `StrutStyle`, `TextHeightBehavior`, `leadingDistribution`

```dart
// painting/strut_style.dart:300
const StrutStyle({String? fontFamily, List<String>? fontFamilyFallback, double? fontSize,
                  double? height, TextLeadingDistribution? leadingDistribution,
                  FontWeight? fontWeight, FontStyle? fontStyle, double? leading,
                  bool? forceStrutHeight});
static const StrutStyle disabled = StrutStyle(height: 0.0, leading: 0.0);   // :370

// ui/text.dart
const TextHeightBehavior({bool applyHeightToFirstAscent = true,
                          bool applyHeightToLastDescent = true,
                          TextLeadingDistribution leadingDistribution = TextLeadingDistribution.proportional});
```

- `leading` = `TextStyle.height * fontSize - fontSize`; `leadingDistribution`
  (`proportional` vs `even`, `ui/text.dart:1431`) decides how that leading is split above/below.
  **`TextLeadingDistribution.even` is the right choice for a Markdown surface**: it centres the glyphs
  in the line box so mixed font sizes (headings, inline code, math) do not sit at the top of their
  line. Flutter's `Text` defaults to `proportional`; Material's text theme sets
  `even` via `TextTheme`-level `leadingDistribution` in some versions — pin it explicitly. **[inference;
  the enum semantics are [src]/[doc]]**
- **`forceStrutHeight: true`** forces every line in the paragraph to the strut's height regardless of
  the glyphs. Combined with an explicit `height`, this makes **block height a pure function of
  `lineCount`** — which is exactly what a virtualised viewport wants, and it removes the
  "inline math made this line 2 px taller" jitter. Consider it for body text and code, but *not* for
  headings you want to size naturally. **[inference; the semantics are [src]]**

### 6.4.6 Drawing the furniture

This is the part where you win or lose "native quality". All of it is `Canvas` work; none of it should
create widgets or paragraphs.

```dart
// A single CustomPainter per visible window, painting in this order:
// 1. block backgrounds (code fence, blockquote, callout, table zebra)
// 2. selection highlights
// 3. search-match highlights
// 4. text (TextPainter.paint per block)
// 5. rules, borders, markers, checkboxes, quote bars
// 6. the caret
```

* **Code block background** — one `RRect` per block, `radius 6-8`, theme surface variant. Do **not**
  use `TextStyle.backgroundColor` for this. Draw it before the text; cache the `RRect` in the block's
  layout record. For a huge fence, draw only the visible slice (clip to the viewport and draw the rect
  for the visible y-range).
* **Blockquote bar** — a 3–4 px vertical `Rect` at the block's left edge spanning the block's full
  height (including its inner blocks), with 12–16 px of left padding reserved in the layout.
* **Table borders** — resolve the column widths first (per-cell `minIntrinsicWidth` measured once per
  width), then draw horizontal rules and vertical borders as `drawLine`/`drawRect`. Borders are
  *paint*, not layout: the layout only needs column x-offsets and row heights. Consider
  `StrokeCap.square` and snapping to device pixels:
  `final px = 1 / MediaQuery.devicePixelRatioOf(context);` and round each coordinate to a multiple of
  `px` — a 1 px border on a 2.0 DPR screen drawn at y = 10.0 is crisp, at y = 10.3 it is a grey smear.
  Read `devicePixelRatio` **once** per frame, not per border. **[inference — standard, unmeasured]**
* **List markers** — bullets drawn as a `drawCircle`/small square at `x = blockLeft - markerWidth`;
  ordered markers as a right-aligned `TextPainter` (use `TextAlign.right` inside a fixed-width box, or
  measure once and offset). Keep marker width in the block record so the content indents consistently.
* **Horizontal rules** — one `drawLine` at `y = blockTop + h/2`, snapped to device pixels.
* **Checkboxes** — draw them, do not use `Checkbox`: a 16×16 `RRect` (radius 4) with a 2 px border,
  filled + a tick `Path` when checked. Hit-test them yourself in `hitTest`. Using a real `Checkbox`
  widget inside `WidgetSpan` costs an element, a `State`, an `AnimationController`, semantics, and
  breaks selection — all for a 16 px box.
* **Task-list gutter** — reserve the checkbox width on the *left* side of every list item row so
  the text of all items aligns, whether or not an item has a checkbox. This is the "nothing moves
  under a thumb already on it" rule from AGENTS.md applied to layout. **[inference]**
* **Callouts** — an `RRect` background + a 3–4 px accent bar on the left + a tinted title. Same
  mechanism as blockquote, with an accent colour per callout type.
* **Selection highlight** — `TextPainter.getBoxesForSelection(sel,
  boxHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle, boxWidthStyle: ui.BoxWidthStyle.tight)`,
  then `drawRect` per box with a low-alpha colour. `TextSelection` is `(baseOffset, extentOffset,
  affinity, isDirectional)`; a selection spanning blocks becomes per-block `TextSelection`s that you
  clamp to the block's source range. **Empty-line selections produce zero-width boxes** — the docs
  note that leading/trailing newlines are represented by zero-width `TextBox`es
  (`text_painter.dart:1660-1665`); give zero-width boxes a minimum 2 px width so the user sees the
  selection on blank lines. **[src, inference for the fix]**
* **Search-match highlights** — same `getBoxesForSelection` call, different paint. Batch all matches
  for a block into one call by passing the *union* range and filtering, or call once per match; the
  call allocates a `List<TextBox>` each time, so prefer **one call per contiguous match run** and
  cache the boxes keyed by `(blockKey, range)`. **[src for the allocation, inference for the batching]**
* **Caret** — `getOffsetForCaret` + `getFullHeightForCaret`; a 2 px rect with an optional
  `CursorRadius`; blink via an `AnimationController` (opacity 1↔0, `period: 1s`, 0.5 s on / 0.5 s off)
  or a `Timer.periodic`; reset the blink on every key. Paint the caret in a **separate
  `RepaintBoundary`** so its blink does not repaint the text. **[inference]**

---

## 6.5 Math rendering without a package

### 6.5.1 The decisive constraint: Flutter cannot do OpenType MATH layout

The OpenType `MATH` table ([spec](https://learn.microsoft.com/en-us/typography/opentype/spec/math))
defines the *correct* way a layout engine gets stretchy delimiters and radicals: **Glyph Assembly**
(recipes that tile a `\sum`, `(`, `[`, `{`, `√`, `|` from a base glyph plus extenders) and
**Math Glyph Variants** (pre-drawn larger versions). A real math renderer asks the font for these.

**Flutter does not expose them, and its text stack does not read them.** Verified locally by grepping
the engine checkout:

```
$ grep -rln "glyph_assembly|GlyphAssembly|MathTable|kMathTag|HB_OT_TAG_MATH|ot_math" \
      engine/src/flutter/txt/src/ engine/src/flutter/lib/ui/text/
(no matches)
$ grep -rn "MATH" engine/src/flutter/txt/src/txt/*.cc engine/src/flutter/txt/src/txt/*.h
(no matches)
```

**[src, measured on this machine]** `dart:ui`'s `Paragraph`/`ParagraphBuilder`/`TextStyle` API surface has
no MATH-table entry point of any kind (no glyph-variant query, no assembly query), and Skia's
`skparagraph` does not surface one either. So:

* **`math`-font glyph-assembly stretching is NOT available to us, even though the fonts on this machine
  have a `MATH` table.** `[measured]`: `/usr/share/fonts/noto/NotoSansMath-Regular.ttf` (990 564 bytes,
  tables include `MATH`) and `/usr/share/fonts/TTF/DejaVuMathTeXGyre.ttf` (577 192 bytes, `MATH`).
* Layout through `TextPainter` gives us **glyph runs with correct advances, italic correction unavailable,
  and no stretch**. Everything stretchy must be built by us.

This is the single fact that determines the whole math architecture, and it is why every Flutter math
package ends up doing what they do (below).

### 6.5.2 What the reference implementations actually do

**`flutter_math_fork` 0.7.4** (present in Niman's `pubspec.lock` as a transitive dep; read from
`~/.pub-cache/hosted/pub.dev/flutter_math_fork-0.7.4`, **[src/measured]**):

* **Structure**: 155 Dart files, 2.0 MB `lib/` — `lib/src/parser/tex/` (parser + `functions/`),
  `lib/src/ast/` (green tree: `syntax_tree.dart`, `nodes/`), `lib/src/render/` (`symbols/`, `svg/`,
  `layout/`, `utils/`), `lib/src/widgets/`.
* **Architecture: a Roslyn-style green/red tree that builds a Flutter WIDGET tree, not a painter.**
  `GreenNode` has `List<GreenNode?> get children`, `updateChildren`, `computeChildOptions`,
  `buildWidget(MathOptions, List<BuildResult?>)`, `shouldRebuildWidget`. `buildWidget` returns a
  `BuildResult` holding a `Widget`. Nodes are canonicalised/deduplicated and rebuild is bypassed when
  `oldOptions == newOptions` **and** the children's `BuildResult`s are identical
  (`syntax_tree.dart:169-205`). This is an element-tree-shaped memo, not a geometry cache.
* **Per-glyph widgets.** `makeChar` (`render/symbols/make_symbol.dart:127-160`) emits, for **each single
  character**:
  ```dart
  ResetDimension(height: …, depth: …,
    child: RichText(text: TextSpan(text: character,
        style: TextStyle(fontFamily: 'packages/flutter_math_fork/KaTeX_${font.fontFamily}',
                         fontWeight: …, fontStyle: …, fontSize: 1.0.cssEm.toLpUnder(options), …)),
      softWrap: false, overflow: TextOverflow.visible))
  ```
  So an *n*-glyph expression creates **n `RichText`s → n `RenderParagraph`s → n `ui.Paragraph`s → n
  shaping passes**, plus a `Padding` for italic correction and layout wrappers (`ResetDimension`,
  `ShiftBaseline`, `VList`, `EqnArray`, `Multiscripts`, …) that are custom `RenderBox`es
  (`lib/src/render/layout/*.dart`). That is the architectural cost: it is widget-per-glyph.
* **Layout primitives are hand-written `RenderObject`s**, not `CustomPainter`s. `lib/src/render/layout/`:
  `CustomLayout<T>` / `RenderCustomLayout<T>` + `CustomLayoutDelegate<T>`
  (`computeLayout`, `getIntrinsicSize`, `additionalPaint`) and `IntrinsicLayoutDelegate<T>`
  (`performHorizontalIntrinsicLayout`, `performVerticalIntrinsicLayout`); then `Line`/`RenderLine`
  (baseline-aligned row), `VList`/`RenderRelativeWidthColumn` (TeX vlist with per-child baseline
  shifts), `EqnArray`/`RenderEqnArray`, `MinDimension`, **`ShiftBaseline`** (how delimiters are
  centred on the axis), **`ResetDimension`** (overrides a child's reported height/depth with the KaTeX
  metrics table), `ResetBaseline`, `RemoveBaseline`, `LayoutBuilderPreserveBaseline`. **There is no
  `CustomPaint`/`CustomPainter` anywhere in the render path** — the only direct canvas use is
  `PaintingContext.canvas` inside `CustomLayoutDelegate.additionalPaint` (fraction bars). `[src]`
* **It depends on `flutter_svg` (`>=2.0.0+1 <3.0.0`) and renders surds / tall arrows / braces through
  `SvgPicture.string`** (`lib/src/render/svg/draw_svg_root.dart`, `svg_string.dart:56`; the
  `CustomLayout` comment even says the `childrenTable` "hack" exists "to render asynchronously for
  flutter_svg"). **So every stretched radical or brace in the document creates an asynchronous SVG
  widget subtree.** `[src]` This is a significant hidden cost and a strong argument against the
  architecture.
* **Fonts**: it bundles **20 KaTeX `.ttf` files, 660 KB total** under
  `lib/katex_fonts/fonts/`, declared in `pubspec.yaml` as families `KaTeX_Main`, `KaTeX_Math`,
  `KaTeX_AMS`, `KaTeX_Caligraphic`, `KaTeX_Fraktur`, `KaTeX_SansSerif`, `KaTeX_Script`,
  `KaTeX_Typewriter`, and **`KaTeX_Size1` … `KaTeX_Size4`** — the discrete "large delimiter" fonts.
  Package license: Apache-2.0. `[measured]`
* **`[measured]` I checked every bundled KaTeX font for a `MATH` table: all 20 report `MATH=False`.**
  Confirms the design: it does not do glyph assembly; it uses the four discrete size fonts
  (Size1–Size4) plus `CharacterMetrics` tables copied from KaTeX for height/depth/italic/skew, and
  geometry arithmetic for fraction bars, sqrt rules and `\left…\right`.
* **Caching is a single-slot build memo, not a geometry cache.** `GreenNode.buildWidget` keeps
  `_oldOptions`, `_oldBuildResult`, `_oldChildBuildResults` and returns the *same `Widget` instances*
  when nothing changed, so Flutter's element/render tree is retained across rebuilds — but the box
  model still re-runs when constraints change. **`Math.tex(...)` parses on every construction** (the
  factory parses in `Math.tex`); there is **no parse cache keyed by source string**, so a caller must
  hoist `SyntaxTree` construction and use `Math(ast: ...)`. `[src]`
* **Reported gaps that hit a notes app directly** (`doc/unsupported.md` + the issue tracker, `[src]`):
  * **[#120](https://github.com/simpleclub/flutter_math/issues/120) (OPEN)** —
    `_RenderLayoutBuilderPreserveBaseline` throws on **infinite constraints** with `\frac`/`\sqrt`
    "inside a Column or ListView without size limits". That is precisely the long-note-in-a-list
    configuration.
  * **[#110](https://github.com/simpleclub/flutter_math/issues/110) / [#119](https://github.com/simpleclub/flutter_math/issues/119) (OPEN)** —
    `RenderObjectWithLayoutCallbackMixin` was removed in Flutter 3.29; the layout hack breaks on newer
    SDKs. A live upgrade risk.
  * **[#118](https://github.com/simpleclub/flutter_math/issues/118), [#123](https://github.com/simpleclub/flutter_math/issues/123) (OPEN)** —
    RTL/Bengali shaping is reversed/unjoined, because the **per-glyph `RichText` architecture cannot
    shape across characters**.
  * **[#106](https://github.com/simpleclub/flutter_math/issues/106) `\operatorname`,
    [#63](https://github.com/simpleclub/flutter_math/issues/63) `\displaylines`,
    [#66](https://github.com/simpleclub/flutter_math/issues/66) `align`,
    [#97](https://github.com/simpleclub/flutter_math/issues/97) `\\`,
    [#131](https://github.com/simpleclub/flutter_math/issues/131) `\leqslant` — all OPEN**;
    `Vmatrix` broken ([#104](https://github.com/simpleclub/flutter_math/issues/104)), `gather` not done.
  * `doc/unsupported.md` "will never be supported": `\href`, `\includegraphics`, `\lap`, `\mathchoice`,
    `\smash`, `\pmb`, `\hspace*`, the exotic composite colon symbols, `\copyright`/`\registered`.
    "Known rendering differences" includes: **limit-style sub/sup do not adapt across styles** ("This
    breaks TeX spec. This is due to the design of AST"), no multiple `\hline` or `||` separators in
    matrices, `aligned` column spacing differs, `\dfrac`/`\tfrac` size deviation.
* **No performance issues are filed** against the package (a search of all 67 issues for
  slow/lag/jank/freeze/memory/many-equations/large-document returns zero hits, `[measured]` by the
  research pass). The performance risk is therefore **structural and unreported**, not documented:
  widget-per-glyph shaping, `GlobalKey`s in the selectable path, an async `SvgPicture` subtree per
  stretched radical, and `computeDryLayout` passes that re-enter the whole delegate chain. For 13 845
  expressions the cost is dominated by (a) simultaneously visible expressions, (b) glyphs per
  expression, (c) re-parsing on rebuild unless the caller caches the `SyntaxTree`.
  **Do not adopt this architecture.**

**`katex_dart` 0.1.1** (Niman dependency; read from `~/.pub-cache/hosted/pub.dev/katex_dart-0.1.1`,
**[src/measured]**):

* Self-description from its `pubspec.yaml`: *"A pure-Dart port of KaTeX. Parses LaTeX math to a
  backend-agnostic box tree and serializes it to SVG — **no Flutter dependency**."*
* 53 Dart files, 2.2 MB `lib/`, SDK `^3.11.0`. Directories: `lib/src/parse/` (tokeniser + macros +
  `functions/`), `lib/src/ast/`, `lib/src/build/` (`builders/`, `style.dart`, `options.dart`,
  `build_common.dart`), `lib/src/box/` (the box tree), `lib/src/svg/`, `lib/src/font/`
  (`font_metrics.dart`, `font_metrics_data.g.dart`, `embedded_fonts.g.dart`), `lib/src/symbols/`
  (`symbols.dart`, `spacing_data.g.dart`), `lib/src/environments/`. `[measured]`
* **It renders to a BOX TREE, not to widgets and not to SVG-only.** `BoxNode` subclasses include
  glyph nodes, `RuleNode` (fraction bars, sqrt rules — painted as a rect), `SvgPathNode` (stretchy
  delimiters), vlist/hlist/kern/glue. `katex_dart` can serialise that tree to SVG for a CLI, but the
  tree is backend-agnostic, which is exactly what Niman needs. `[src]`
* **Completeness**: 53 files and a full `functions/` + `environments/` + `macros.dart` is a genuine
  KaTeX port, materially more complete than `flutter_math_fork`'s parser-vs-KaTeX gap. The generated
  tables say "Generated … from KaTeX 0.17.0" (`spacing_data.g.dart`), so it tracks KaTeX 0.17.
  `[measured]` It is an early-version package (`0.1.1`), so treat its long tail of macros as
  unverified. `[inference]`

**`katex` 1.0.0** (the Flutter widget Niman depends on; read from
`~/.pub-cache/hosted/pub.dev/katex-1.0.0`, **[src/measured]**):

* Its `pubspec.yaml` description: *"A Flutter widget that renders LaTeX math by painting the
  backend-agnostic box tree from the pure-Dart `katex_dart` package."*
* **No WebView and no JS runtime — the premise needs correcting, and for two packages.** `[src]` for
  `katex` 1.0.0: `grep` for `WebView|webview|dart:html|HtmlElement` over `lib/` returns nothing.
  Six Dart files; the renderer is `lib/src/render/box_painter.dart` (1 226 lines) driven by
  `lib/src/math_widget.dart` (153 lines) + `lib/src/animated_math_widget.dart`.
  The packages in the ecosystem that *do* use a WebView are **`flutter_tex`** (MathJax in a WebView,
  plus a newer `Math2SVG`/`TeXWidget` path) and **`flutter_tex_js`** (*"uses KaTeX (JavaScript) in a
  native web view to render to PNG"*). The historical WebView wrapper was **`katex_flutter`**
  (`webview_flutter` + `js` up to 3.2.0+22, switched to native rendering at 4.0.0+24 in 2020, dead
  since 2020-08). `katex` 0.1.0 on pub.dev was a 2014 pure-Dart Dartium port, not a WebView.
* **`KatexBoxPainter extends CustomPainter`** — and this is the architecture to copy:
  * `Map<_GlyphKey, TextPainter> _glyphCache` — **one `TextPainter` per (text, family, variant, size,
    colour)**, reused across paints (`box_painter.dart:157-159`).
  * `_paintGlyph` reads `tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)` and shifts up so
    the **glyph baseline lands on the math baseline** (`:643-665`) — the correct way to place a glyph
    run in a box model.
  * `_paintRule` → `canvas.drawRect` for fraction bars / rules (`:692-746`).
  * `_paintSvgPath` → `canvas.drawPath` with the path's viewBox mapped onto the box, plus
    `save/clipRect/translate/scale/restore` and a `preserveAspectRatio` switch
    (`none`, `xMinYMinSlice`, `xMaxYMinSlice`, `xMidYMinSlice`) (`:572-640`) — **this is how stretchy
    delimiters are done**: real vector paths, non-uniformly or uniformly scaled, clipped to the target box.
* **Take-away: the winning architecture is a `CustomPainter` over a pre-computed box tree, with a
  `TextPainter` cache for glyph runs.** It is what a from-scratch Niman renderer should do — and Niman's
  own box tree can be built by inlining/porting the `katex_dart` parser under Niman's licence terms
  (MIT-style, per-file `Copyright (c) 2013-2019 Khan Academy and other contributors` headers in the
  parent project; **verify the exact license text before copying** `[inference]`).

### 6.5.3 The realistic TeX subset for a notes app

Niman's 13 845 math spans live in Obsidian-style notes. Rank by frequency; build in this order.

| Tier | Construct | Difficulty | Notes |
|---|---|---|---|
| **1 — must have** | `x^2`, `x_i`, `x_i^2` | easy | hlist + `ShiftBaseline`-style vlist; sup 0.7em, sub 0.7em, script script 0.5 |
| | `\frac`, `\dfrac`, `\tfrac`, `\binom` | easy | vlist: num, 0.04em rule, denom; shift by axis height 0.25em |
| | `\sqrt{x}`, `\sqrt[n]{x}` | medium | radical glyph + a **rule drawn as a rect**, with a raised index box |
| | `\left( … \right)`, `\left[ \right]`, `\{ \}`, `|`, `\|`, `\langle \rangle` | **hard** | see §6.5.4 |
| | `\sum`, `\prod`, `\int`, `\oint`, `\lim` with `\limits`/`\nolimits` | medium | displaystyle ⇒ limits above/below; textstyle ⇒ sub/sup beside |
| | `\text{}`, `\mathrm`, `\mathbf`, `\mathit`, `\mathsf`, `\mathtt` | easy | font-family switch; `\text` uses the **body font**, not the math font |
| | `\mathbb`, `\mathcal`, `\mathfrak`, `\mathscr` | easy | needs the AMS/Caligraphic/Fraktur/Script faces |
| | `\hat \bar \vec \dot \ddot \tilde \acute \grave \check \breve` | medium | accent glyph placed with italic correction; wide accents need stretching |
| | `\overline`, `\underline`, `\overbrace`, `\underbrace` | medium | rule + (for braces) a stretchy glyph |
| | `\binom`, `\genfrac` | easy | |
| | spacing: `\,` `\:` `\;` `\!` `\quad` `\qquad` `~` | easy | mu values, §6.5.5 |
| | `\operatorname{…}`, `\log \ln \sin \cos \tan \exp \lim \max \min` | easy | |
| **2 — common** | `\begin{pmatrix} … \end{pmatrix}`, `bmatrix`, `vmatrix`, `Bmatrix`, `matrix` | medium | column widths from max cell width; stretchy outer delimiters |
| | `\begin{cases}`, `\begin{aligned}`, `\begin{align}`, `\begin{array}{cc}` | medium | alignment via a column-position table (`&` sets the alignment point); row `\\` |
| | `\begin{split}`, `\substack{a\\b}`, `\begin{gathered}` | medium | |
| | `\stackrel`, `\overset`, `\underset` | easy | |
| | `\big \Big \bigg \Bigg` and `\bigl \Bigr` … | medium | discrete scale ladder, then the stretchy path |
| | `\not`, `\cancel`, `\bcancel`, `\xcancel` | easy | diagonal stroke paths |
| | `\boxed`, `\fbox`, `\color`, `\textcolor`, `\colorbox` | easy | |
| | `\begin{matrix}` with `\hline`, `\hdashline` | easy | rect rules |
| | `\pmod`, `\bmod`, `\mod` | easy | |
| **3 — nice** | `\xrightarrow{…}`, `\xleftarrow{…}`, `\overset` arrows | medium | stretchy horizontal arrow with a label |
| | `\genfrac{}{}{}{}{a}{b}`, `\cfrac` | easy | |
| | `\underbrace{x}_{\text{label}}` | medium | |
| | `\begin{CD}`, `\begin{smallmatrix}` | low priority | |
| | `\ce{}` (mhchem) | **skip** | a whole second grammar; almost never in notes |
| | `\pu{}` | **skip** | |

The single hardest tier-1 item is **`\left…\right`**, and the answer is that `(` `)` `[` `]` `\{` `\}`
`|` `\|` `\lfloor` `\rfloor` `\lceil` `\rceil` `\langle` `\rangle` `\uparrow` `\downarrow` etc. are
**finite, enumerable sets** — the "extensible delimiter" set is only ~30 characters. That is what makes
this tractable without glyph assembly. **[inference]**

### 6.5.4 Stretchy delimiters and fraction bars — the concrete recipe

Do it in the following order. The target size comes from TeX's own rule (`make_left_right`,
`tex.web:15016-15030`) `[src]`:

```
needed = delimiter target size
       = max(1.802 * delta1, 2 * delta1 - 5pt)
  where delta1 = max(maxH + maxD - (maxD + axisHeight), maxD + axisHeight)
        maxH/maxD = measured height/depth of the enclosed content
```

Then pick the cheapest asset that covers `needed`:

```
1  BASE    : draw the delimiter as a glyph at the current font size.
             Fits if glyphAscent + glyphDescent >= needed.
             Otherwise scale it anisotropically with canvas.scale(1, needed / glyphHeight)
             — height only, never width. Do NOT try to do this with TextStyle:
             §5.4.1 proves Paragraph cannot scale glyphs vertically.
2  VARIANT : if a Size1..Size4 variant exists with height >= needed, draw that variant glyph
             at its natural size. KaTeX's Size1..4-Regular.ttf are
             12,228 / 11,508 / 7,588 / 10,364 bytes — ~41 KB TOTAL — so shipping them is cheap
             and the quality is much better than a stretched base glyph. [measured sizes]
3  STACK   : for  ( ) [ ] { } | ‖ ⟨ ⟩ ⌊ ⌋ ⌈ ⌉  tile three pieces top/repeat/bottom taken from
             the Unicode bracket-piece block U+239B..U+23AD (KaTeX's makeStackedDelim approach).
             The bracket-piece characters live in Size1, so this needs no extra font beyond tier 2.
4  PATH    : for anything else vertical (arrows, hooks, braces) and for the horizontal/`√`
             cases, author a ui.Path and drawPath it — mapping a viewBox onto the target box
             with save/clipRect/translate/scale, exactly as `katex`'s `_paintSvgPath`
             (box_painter.dart:572-640) does, including its preserveAspectRatio switch
             (none / xMinYMinSlice / xMaxYMinSlice / xMidYMinSlice).
```

**Cheapest high-quality configuration `[inference, with measured font sizes]`:** ship the regular math
font (~1 MB, §5.7) **plus** the four Size fonts (~41 KB `[measured]`) and use tiers 1→4 in order. That
matches what KaTeX itself does and keeps the font bill under 1.1 MB.

**Fraction bars, over/underline rules, table `\hline`, `\cancel` diagonals, the radical's vinculum:
all of these are `canvas.drawRect` / `canvas.drawLine` / `canvas.drawPath` in *box coordinates*, not
glyphs.** A fraction is:

```
vlist( children: [
   numBox shifted so its baseline sits at -numShift,
   RuleNode(width: max(numWidth, denWidth), height: defaultRuleThickness) centred on the axis,
   denomBox shifted so its top sits below the rule,
])
```
with the rule painted by `drawRect` and the whole vlist's height/depth computed from its children.

#### 6.5.4.1 Why `Paragraph` cannot vertically scale a glyph (so tiers 1–4 are not optional)

`[src]` `TextStyle.fontSize` scales the em square **uniformly** (both axes, advance included) — there is
no anisotropic font-size concept. `TextStyle.height` changes the **line box**, never the ink: its doc
(`painting/text_style.dart:644-649`) says the line height is "exactly `fontSize * height` logical
pixels", and `:651-656` adds that `height: 1.0` is not the font's own metrics because `fontSize` sizes
the EM square. `TextScaler`/`textScaleFactor` are uniform multipliers. `FontVariation` axes are design
axes (`wght`, `wdth`, `opsz`, `slnt`, `ital`) — none is "vertical scale". `StrutStyle` and
`TextHeightBehavior`/`leadingDistribution` affect line boxes only.

**So the three ways to stretch a glyph are all external to `Paragraph`:**

1. **`canvas.scale(sx, sy)` around `TextPainter.paint` / `drawParagraph`** — the precise,
   quality-preserving route, and the recommended one. **[inference]**
2. `Transform.scale(scaleY: …)` / `FittedBox(fit: BoxFit.fill)` — the declarative equivalent; it goes
   through a transform layer (sometimes a `saveLayer`) and cannot be folded into a single canvas pass.
   This is effectively what `flutter_math_fork` gets from `flutter_svg`'s `BoxFit.fill`/`cover` in
   `sqrtSvg` — which is why it carries `flutter_svg` at all (§5.2).
3. An authored `ui.Path` — best for rules, surds, braces and arrows.

**Measuring a stretchy delimiter is the only place a second pass is genuinely needed**, and even there
it is cheap: you need `H` from the content, and `H` is known *after* the content box is measured. That
is why math layout is a **bottom-up single pass with a "stretch request" propagated upward**, not a
true two-pass measure-then-place. Details in §6.5.6.

### 6.5.5 TeX constants to hardcode (KaTeX tables cross-checked against `tftopl` and `tex.web`)

All values in **em** (relative to the current font size), read from
`katex_dart/lib/src/font/font_metrics.dart` (`_sigmasAndXis`, generated from KaTeX 0.17 / cmex10.tfm)
— `[measured]` as literal values in that file. A second research pass also measured the same quantities
directly from `cmex10.tfm` with `tftopl` and from `tex.web`, and where the two disagree the **TeX
values** are given in the notes column:

| Constant | text | script | scriptscript | Purpose / note |
|---|---|---|---|---|
| `axisHeight` | 0.250 | 0.250 | 0.250 | fraction bar / `\left` vertical centre; `\sum` shift. Confirmed 0.25 in all styles. |
| `defaultRuleThickness` | 0.04 | 0.049 | 0.049 | fraction bar thickness (cmex10 ξ8 = **0.039999** text / 0.049 script). Note: there are **no `\defaultrulethickness`/`\overrulethickness` control sequences** — the quantity is `\fontdimen8\textfont3`. |
| `sqrtRuleThickness` | 0.04 | 0.04 | 0.04 | radical vinculum; **does not scale** |
| `xHeight` | 0.431 | 0.431 | 0.431 | `\sqrt`/accent placement (tftopl: 0.430555) |
| `quad` | 1.000 | 1.171 | 1.472 | 1 quad = 1 em; **`cssEmPerMu = quad / 18`** — see the `mu` correction below |
| `num1` / `num2` / `num3` | 0.677 / 0.394 / 0.444 | 0.732 / 0.384 / 0.471 | 0.925 / 0.387 / 0.504 | numerator shift (tftopl: 0.676508 / 0.393732 / 0.443731; **num3 is the non-display `\atop` form — there is no denom3**) |
| `denom1` / `denom2` | 0.686 / 0.345 | 0.752 / 0.344 | 1.025 / 0.532 | denominator shift (tftopl: 0.685951 / 0.344841) |
| `sup1` / `sup2` / `sup3` | **0.413** / **0.363** / **0.289** | 0.503 / 0.431 / 0.286 | 0.504 / 0.404 / 0.294 | superscript shifts. **tftopl gives 0.412892 / 0.362892 / 0.288889 — use these, not the round KaTeX numbers**; the stale claim "0.4 / 0.7 / 0.5" is wrong |
| `sub1` / `sub2` | 0.150 / 0.247 | 0.143 / 0.286 | 0.200 / 0.400 | subscript shifts (tftopl: 0.15 / 0.247217) |
| `supDrop` / `subDrop` | 0.386 / 0.050 | 0.353 / 0.071 | 0.494 / 0.100 | limit clearance (tftopl: 0.386108 / 0.05) |
| `delim1` / `delim2` | 2.390 / 1.010 | 1.700 / 1.157 | 1.980 / 1.420 | delimiter scaling (tftopl: 2.389999 / 1.01) |
| `bigOpSpacing1-5` | 0.111 / 0.166 / 0.2 / 0.6 / 0.1 | … | … | `\sum` limits spacing (tftopl confirms to 6 dp) |
| `arrayRuleWidth` | 0.04 | — | — | `{array}` rules |
| `doubleRuleSep` | 0.2 | — | — | `\|` column sep |
| `fboxsep` / `fboxrule` | 0.3 / 0.04 | — | — | `\boxed` |

Additional TeX parameters worth hardcoding (from `tex.web`, `[src]`): `\scriptspace` **0.05 em**,
`\nulldelimiterspace` **0.12 em**, `\delimiterfactor` **901**, `\delimitershortfall` **5 pt**, and the
`\big`…`\Bigg` ladder **1.2 / 1.8 / 2.4 / 3.0 em** (which is the same ladder the Size1–4 fonts encode).

Style size multipliers (`katex_dart/lib/src/build/style.dart:100`, matches TeX):
**display = text = 1.0, script = 0.7, scriptscript = 0.5.**

**Correction — `1mu` is `quad(style)/18`, not always `1/18 em`.** Real TeX: `\thinmuskip` = 3 mu where
1 mu = 0.55554 pt in text, 0.45525 pt in script, 0.40895 pt in scriptscript — i.e. **F·1/18**,
**F·0.045525**, **F·0.040896**. KaTeX's `cssEmPerMu = quad / 18` with `quad ∈ {1.000, 1.171, 1.472}`
encodes the same thing. So the formula in §5.5 is right *only* because `quad` is style-dependent; a
hardcoded `/18` with a fixed em would make script-level spacing ~17 % too wide. **[src]**

**One documented upstream KaTeX bug to be aware of:** both KaTeX and `flutter_math` use **thick (5 mu)**
for `punct → rel` inter-atom spacing where real TeX's Chapter-18 table uses **thin (3 mu)**. The
64-digit spacing table is in `tex.web:15066` and decoded in `sub-math.md` §7.4. Decide deliberately
whether to match KaTeX (cosmetic compatibility with the incumbent renderer) or TeX (typographic
correctness); do not do it by accident. **[src]**

Math-unit spacing (`katex_dart/lib/src/symbols/spacing_data.g.dart`, generated from KaTeX 0.17
`spacingData.ts`) — `1 mu = cssEmPerMu = 1/18 em`:

* **thin space = 3 mu** (`\,`, and `ord→op`, `op→ord`, `ord→inner`, `op→op`)
* **medium space = 4 mu** (`\:`/`\>`, and all `bin` adjacencies)
* **thick space = 5 mu** (`\;`, and every `rel` adjacency)
* `\!` = **−3 mu**; `\quad` = 18 mu = 1 em; `\qquad` = 36 mu = 2 em; `~` = a non-breaking interword
  space (body font).
* The full inter-atom table (`spacings[MathClass][MathClass]`) is in that generated file; **port it
  verbatim** rather than reconstructing it, and note there is a separate `tightSpacings` table used in
  script/scriptscript styles (`build_expression.dart:231`).

**Sizing math to a font size — the only arithmetic you need.** Keep the **entire box model in em and
mu**, with one conversion point. With `F` = `TextStyle.fontSize` in logical px and `m` = the current
style's size multiplier:

```
px(em) = value * F * m
px(mu) = value * F * q / 18          // q = quad(style) = {1.000, 1.171, 1.472}
                                     // i.e. NOT a constant /18: 1mu = q/18 em, not 1/18 em.
                                     // TeX: math_quad == 18mu (tex.web:13815); real TeX 1mu =
                                     // 0.55554pt / 0.45525pt / 0.40895pt in tex/script/scriptscript.
                                     // Use the mu-per-style table, not a fixed em fraction.
px(ex) = value * F * m * 0.431       // x-height
px(pt) = value * F * 72.27 / 160     // TeX pt -> logical px
```

Worked examples at `F = 16`, `m = 1.0`: `\,` = 3 mu = **2.667 px**; `\quad` = 1 em = **16 px**; a
fraction bar = 0.04 em = **0.64 px**; the math axis = 0.25 em = **4 px** below the baseline.
`m` is `1.0` in display/text style, `0.7` in script, `0.5` in scriptscript (see the table above).

**`mu` values scale with the style; `em`/`ex` do not** — `em` and `ex` always refer to the *text-style*
size (`options.havingStyle(style.atLeastText())`), while `mu` multiplies by the current
`sizeMultiplier`. Getting this backwards is what makes script-level sub/superscripts drift. **[src]**
(`flutter_math_fork/lib/src/ast/size.dart:118-140` encodes exactly this switch.)

Because `F` enters only as a linear factor, **the layout can be computed and cached in em and scaled at
paint time** — the layout cache key then only needs `(exprHash, style-chain, width constraint)`; the
absolute font size affects `place`, not `measure`. `[inference, but it is how KaTeX/`katex_dart`
structure it]`

**Inline math inside a Markdown paragraph.** A `RenderBox` does not flow inside text, so the framework's
mechanism is a placeholder: `WidgetSpan(alignment: PlaceholderAlignment.baseline,
baseline: TextBaseline.alphabetic, child: SizedBox(width: layout.width, height: layout.totalHeight,
child: CustomPaint(painter: MathPainter(layout))))`, and `RenderBox.computeDistanceToActualBaseline`
is what `WidgetSpan` reads to align it (`_RenderScaledInlineWidget.computeDistanceToActualBaseline`,
`widgets/widget_span.dart:384-392`). Prefer **one `WidgetSpan` per expression** over per-glyph widgets.
`[src]` Cost: a child `RenderObject` per expression, and the `U+FFFC` offset-ledger problem of §9.3 —
acceptable, but it is another reason virtualisation plus a layout cache matters more than shaving
per-glyph cost. **[inference]**

### 6.5.6 Is a two-pass measure-then-place layout required?

**Yes — and it is provable from TeX's own source, not a design preference.** `[src: TeX/KaTeX provenance,
established by the research pass]`

TeX does not lay math out in one descent. It first builds an `mlist` of noads (pass 1, where every atom's
`height`/`depth` are known) and then runs `mlist_to_hlist`, which computes shifts and emits an
hlist/vlist (pass 2). The cleanest evidence is `\left…\right` (`tex.web:15016-15030`,
`make_left_right`):

```
delta2 := max_d + axis_height(cur_size);
delta1 := max_h + max_d - delta2;
if delta2 > delta1 then delta1 := delta2;   {delta1 is max distance from axis}
delta  := (delta1 div 500) * delimiter_factor;
delta2 := delta1 + delta1 - delimiter_shortfall;
if delta < delta2 then delta := delta2;
new_hlist(q) := var_delimiter(delimiter(q), cur_size, delta);
```

`max_h`/`max_d` are the **measured** height/depth of the delimiter's *contents*. The target size `delta`
cannot exist before that measurement, and `var_delimiter` (`tex.web:13906`) cannot produce a box before
`delta` exists. The same structure appears in `make_fraction` (Rule 15) and in the radical construction
(`tex.web:14484-14492`). This is also why `flutter_math_fork`'s `RenderCustomLayout` has a `dry` pass
that measures children with an infinite constraint before a second pass assigns `child.offset`, and why
`katex_dart` ships a box tree carrying `(width, height, depth)` in em rather than a single size.
**[src]**

The design consequence, stated as the engine's API:

```dart
/// PASS 1 — measure. PURE. Returns metrics, never a position.
MathMetrics measure(MathNode node, MathStyle style);

/// The TeX triple. Every construct needs all three of its children's metrics
/// before it can decide anything.
@immutable
class MathMetrics { const MathMetrics(this.width, this.height, this.depth);
  final double width, height, depth; }

/// PASS 2 — place. PURE. Walks the same tree and appends absolute ops.
void place(MathNode node, MathStyle style, MathMetrics m,
           double x, double baselineY, MathOpSink sink);
```

Per-construct why the two passes are unavoidable `[src]`:

* **`\frac{a}{b}`** — the bar sits on the math axis, and the counter-shifts `u`/`v` depend on `a.depth`
  and `b.height` (Rule 15c/15d). Neither the bar position nor the total height is knowable until both
  children are measured.
* **`\left( x \right)`** — the delimiter variant is chosen from the total height of `x`
  (`getHeightForDelim(...) > minDelimiterHeight`). Height in ⇒ size out.
* **`\sqrt{x}`** — the surd must cover `baseHeight + psi + theta`, and the index's placement depends on
  the resulting `bodyHeight`/`bodyDepth`.
* **`aligned` / `array` / `cases` / `matrix`** — column widths are maxima over all rows, so pass 1 runs
  over the row list first: a **third nesting level** (measure all cells → compute column widths → place
  rows).

**Where the passes live in Flutter.** Run pass 1 **and** pass 2 inside `performLayout` (or inside the
`MathEngine.layout(...)` call that `performLayout` invokes; then `performLayout` only assigns `size`).
`paint()` must see only the finished, immutable op list — that is what makes `shouldRepaint` trivial and
scrolling cheap.

**Correcting a subtler version of the question:** the *iteration* risk is not in the two passes
themselves, which are a fixed 2 (3 for tabular). It is in constructs where a **label's** width can force
the construct wider — `\overbrace`/`\underbrace` sub/superscripts and `\xrightarrow{…}`. Bound any such
fixed-point iteration at 2–3 rounds and accept the last result; an unbounded fixed-point loop is how a
renderer hangs on a hostile input. **[inference]**

Design `measure` to be pure and cacheable and `place` to consume measured metrics, so a resize that only
changes the absolute font size can re-run `place` (cheap) — or, better, reuse the em-relative layout
entirely and scale at paint time (§5.5).

### 6.5.7 Math fonts: availability, licensing, bundling

`[measured]` — sizes and licences verified by a research pass that parsed the actual font binaries, plus
a local `fc-list`/`MATH`-table probe on this machine. **All are static single-weight 400 — no variable
math font exists.**

| Font | On this box | Size | MATH table | License |
|---|---|---|---|---|
| **Noto Sans Math** (`NotoSansMath-Regular.ttf`) | ✅ | 991.6 KB (990 564 B) | ✅ | SIL OFL 1.1 |
| **DejaVu Math TeX Gyre** (`DejaVuMathTeXGyre.ttf`) | ✅ | 577 192 B | ✅ | Bitstream Vera / DejaVu (permissive) |
| **STIX Two Math** — OTF (CFF) | ❌ | **818.9 KB** | ✅ | SIL OFL 1.1 |
| **STIX Two Math** — TTF | ❌ | 1 482.4 KB | ✅ | SIL OFL 1.1 |
| **Latin Modern Math** | ❌ | 716.5 KB | ✅ | **GUST Font License — not OFL** |
| **XITS Math** | ❌ | 535.2 KB | ✅ | SIL OFL 1.1 |
| **TeX Gyre math** (each) | ❌ | 512–587 KB | ✅ | GUST Font License |
| **KaTeX 20 TTFs** (already in Niman's bundle, §5.2) | vendored | 544 KB total | ❌ **MATH=False on all 20** | SIL OFL |
| **Cambria Math** (Windows `Cambria.ttc`, math face is **index 1**, Vista→11) | n/a | — | ✅ | proprietary, **NOT redistributable** |

Platform realities `[verified by the research pass against primary sources]`:

* **Android ships NO math font at any API level.** Verified against AOSP 8 / 9 / 11 / 12 / 13 / 14 and
  `main`: **zero `math` matches in `fonts.xml`**, no `notosansmath` directory in `external/noto-fonts`,
  zero matches in its `Android.bp` / `fonts.mk`. Only **10 name-addressable families** exist and none is
  a math face, so `fontFamily: 'NotoSansMath'` is a **silent no-op** — it will fall through to whatever
  the platform chain gives. (The `NotoSansSymbols`/`NotoSansSymbols2` files ship as *Subsetted* fonts in
  **anonymous** `<family>` blocks, so they are not name-addressable either, and they cover neither
  U+2200–22FF nor U+1D400–1D7FF.) **This corrects the "present on recent Android" assumption.**
* **Linux**: no guarantee. Arch's `noto-fonts` always includes Noto Sans Math ("Required By (55)"),
  Fedora has `google-noto-sans-math-fonts`, Debian has `fonts-noto-core` — but Debian's
  `task-desktop`/`gnome-core` pull in **no math font at all**. Latin Modern / STIX / XITS / TeX Gyre are
  strictly on-demand. **Must bundle.**
* **Windows**: **Cambria Math only** — and it is proprietary. **STIX Two Math does not ship with Windows
  or Office.** **Must bundle.**
* Metrics differ across these faces, so *not* bundling means the same `.md` renders differently on each
  OS. Unacceptable for a "native quality" surface.

**Decisive context: Niman already vendor-bundles the 20 KaTeX TTFs** through its current
`katex ^1.0.0` / `katex_dart ^0.1.1` dependencies (`pubspec.yaml:68-69`, §5.2). Those give
**cross-platform-identical math glyphs today**, and they are OFL. **If the packages are dropped, keep
the fonts as Niman-owned assets** — otherwise the same note changes appearance on first launch after
the migration. That, not a general-purpose math font, is the baseline to preserve.

Flutter accepts `.ttf`, `.otf` and `.ttc` for `fonts:` assets (`.woff`/`.woff2` are unsupported on
desktop). `[doc]`

**Recommendation `[inference]`: bundle one math font family as a Flutter asset.** Concretely:

```yaml
# pubspec.yaml  (Niman owns these font files)
flutter:
  fonts:
    # Keep the KaTeX faces already in the bundle today (via katex_dart) — OFL, 544 KB,
    # cross-platform-identical glyphs for the symbols the current renderer draws.
    - family: NimanMath
      fonts:
        - asset: assets/fonts/KaTeX_Main-Regular.ttf
        - asset: assets/fonts/KaTeX_Math-Italic.ttf
        - asset: assets/fonts/KaTeX_Size1-Regular.ttf   # ~12 KB: bracket pieces + variants
        - asset: assets/fonts/KaTeX_Size2-Regular.ttf
        - asset: assets/fonts/KaTeX_Size3-Regular.ttf
        - asset: assets/fonts/KaTeX_Size4-Regular.ttf
        # ... the rest of the 20 faces as fidelity requires
    # One general-purpose fallback with the widest Unicode math coverage.
    - family: NimanMathFallback
      fonts:
        - asset: assets/fonts/STIXTwoMath-Regular.otf      # 818.9 KB, OFL 1.1
```

```dart
// Fallback is per-glyph, primary-first, list order, then the platform chain, then tofu.
TextStyle(
  fontFamily: 'NimanMath',
  fontFamilyFallback: const [
    'NimanMathFallback',   // bundled, deterministic
    'Cambria Math',        // Windows
    'Noto Sans Math',      // some Linux, some Android OEMs
    'Latin Modern Math',
    'XITS Math',
    'TeX Gyre Termes Math',
    'serif',
  ],
)
```

* **Size budget `[measured]`:** keeping the 20 KaTeX faces is **544 KB**; adding STIX Two Math **OTF** is
  **818.9 KB** (the TTF is 1 482.4 KB — prefer the CFF/OTF build). A ~1.4 MB math font bill buys both
  cross-platform identity with the incumbent renderer *and* broad Unicode coverage. Prefer STIX Two Math
  over Noto Sans Math (991.6 KB) if only one general face is bundled: STIX is smaller and is the
  STIX project's dedicated math face. `[inference]`
* **Fallback order** should be: **bundled faces first, then OS faces**. Two reasons. (1) Determinism —
  the same `.md` must look the same on all three platforms. (2) **System font names can resolve to
  something unexpected or not at all** (this is the class of bug behind
  [flutter#175653](https://github.com/flutter/flutter/issues/175653) and
  [#95094](https://github.com/flutter/flutter/issues/95094)). Flutter consults `fontFamilyFallback`
  per character after the primary family; `fontFamily` and `fontFamilyFallback` are **just more entries
  in the same family list**, not a separate code path, and unresolved ranges snap to
  **grapheme** boundaries. `[src]`
* **Package-prefix caveat `[flagged UNVERIFIED]`:** fonts declared by a *package* are registered under
  `packages/<pkg>/<family>`, so an **app-level** family cannot be named inside a package-delivered
  painter's style. Since the new renderer is Niman-owned this is normally a non-issue, but it matters if
  any code (including a retained `katex` painter) still uses a package font.
* **Caveat**: `fontFamilyFallback` still does not let you request "this character at a larger size";
  the delimiter tiers of §5.4 are your job regardless of the font.

### 6.5.8 Missing-glyph fallback

**Flutter gives you no reliable missing-glyph signal, and the mechanism that would provide one exists in
Skia but is not wired up.** `[verified by the research pass against engine/Skia source]`

* `ui.Paragraph` has no glyph-coverage or "did fall back" query. Its full method list is
  `getBoxesForRange`, `getPositionForOffset`, `getGlyphInfoAt`, `getClosestGlyphInfoForOffset`,
  `getWordBoundary`, `getLineBoundary`, `getBoxesForPlaceholders`, `computeLineMetrics`,
  `getLineMetricsAt`, `numberOfLines`, `getLineNumberAt`, `dispose` — **no coverage API, no per-glyph
  advance, no glyph id, no typeface**.
* `ui.GlyphInfo` (`flutter_web_sdk/lib/ui/text.dart:192`) exposes only
  `graphemeClusterLayoutBounds`, `graphemeClusterCodeUnitRange`, `writingDirection`. The bounds come from
  advance + font metrics, so **tofu is indistinguishable from a real glyph with the same metrics**.
* A missing codepoint becomes glyph ID 0 = `.notdef`/tofu, and SkParagraph detects it post-shaping by
  `glyph == 0`. But a blank/zero-width `.notdef` is legal, so "missing" is not one visual outcome.
* **The sharp finding:** Skia *has* `Paragraph::unresolvedGlyphs()` / `unresolvedCodepoints()`, and
  **Flutter's web engine already uses them** (FallbackFontService) — but `grep "unresolved"` across
  native `lib/ui`, `txt/`, `shell/` and `display_list/` returns **0 hits**. The capability exists; the
  native embedder does not surface it. There is no Dart API to add it ourselves.
* System fallback cannot be disabled from Dart (the switch is test-only C++), so **in `flutter test`
  tofu is deterministic, while on a device it may be silently rescued by a system font — a green widget
  test therefore proves nothing about device coverage.**
* `FontFeature`/`FontVariation` are OpenType tags/axes, not coverage. And FFI to the OS
  (`Paint.hasGlyph`, `IDWriteFont::HasCharacter`, `FcCharSetHasChar`) answers only for **OS** fonts:
  app-bundled fonts live only in Skia's dynamic font manager, so FFI **cannot** answer "does my bundled
  math font cover U+1D400". `[inference from the font-manager ordering, which is
  [src]: `txt/src/txt/font_collection.cc:56-75` — match order is dynamic → asset → test → platform default,
  chosen per codepoint and cached by (codepoint, style, locale)]`
* **`dart:ui` has no glyph-outline API** (only `loadFontFromList`), so even with perfect coverage
  reporting you author `ui.Path`s rather than extracting outlines (§5.4).

**Practical strategy, in order:**

1. **Control coverage at build time.** Run `fontTools.getBestCmap()` over every bundled face in a tool
   step, emit a committed coverage manifest, and have CI assert that every math codepoint the renderer
   can emit is present. This is the only *correct* answer and costs no runtime work. **[recommended]**
2. **Make uncovered text disappear rather than show tofu**: append an AdobeBlank-style zero-width font as
   the terminal entry of the fallback chain. A box in the middle of a formula looks like a bug; a
   zero-width gap looks like a spacing quirk and preserves the layout. **[inference]**
3. **If a runtime probe is unavoidable**, the only workable trick is a sentinel pixel-compare against
   U+FFFF — and it is brittle, because the tofu may come from the *last* typeface tried. **Never use a
   PUA codepoint** as the sentinel. **[inference, flagged unreliable]**
4. **Prefer bundled-only fallbacks, never system names** in the deterministic chain (see §5.7), because
   a system name can resolve to something surprising or fail to resolve at all.
5. **When coverage genuinely fails, degrade visibly and preserve the bytes**: render the raw TeX source
   (`\foo{bar}`) in monospace, like KaTeX's `throwOnError: false` `ParseError` renderer does. **[doc]**
6. **Never let a failed parse produce an empty box** — an empty box loses information from the user's
   view of their own file. Always fall back to showing the source.
7. **Astral-plane note:** fallback selection is codepoint-correct, but `GlyphInfo` offsets are UTF-16
   code units, so any math offset arithmetic must be surrogate-aware (§9.10).

### 6.5.8.1 How complete is the TeX subset, really?

For scoping: KaTeX defines **648 `defineSymbol` + 336 `defineMacro` ≈ 985 entries** `[measured by the
research pass against the KaTeX grammar]`, so the brief's "~900 symbol macros" is about right. The good
news is that **parsing them is a lookup table, not an algorithm** — the real costs are (a) glyph coverage
in the bundled font and (b) the per-symbol metrics table (§5.9's cache #3). One construct to refuse:
**`\mathchoice`**, which requires laying the same subtree out in four styles and choosing at layout
time — architecturally hostile to a cached two-pass engine. `flutter_math_fork` refuses it too, and
`doc/unsupported.md` lists it under "will never be supported". Do the same. **[src]**

### 6.5.9 Caching strategy

**Four caches**, different keys and different lifetimes. The third one is the highest-leverage idea in
this whole section and the one most implementations miss. `[design grounded in §5.2's per-glyph
`TextPainter` cache and §1.3's shaping cost; the metrics-cache insight comes from the math research
pass]`

```dart
/// 1. PARSE CACHE — TeX source -> immutable box tree (green/plain data tree).
///    Lives in the ISOLATE (the tree is plain data, so it is sendable and Isolate-safe).
///    KEY: ParseKey(macroEnvId, source VERBATIM, displayMode, settingsHash).
///    NOT font size and NOT colour — and NOT the source string alone: a \newcommand
///    redefines a macro, so bump macroEnvId on every definition or you will serve a
///    formula parsed under the old macro meanings.
final class MathParseCache {
  final _lru = <ParseKey, MathBoxTree>{};
  final _sourceOf = <ParseKey, String>{};        // for collision verification
  int macroEnvId = 0;                            // bump on \newcommand/\def/\renewcommand
  MathBoxTree parse(String tex, {required bool displayMode, int maxEntries = 4096});
}

/// 2. LAYOUT CACHE — box tree -> placed ops in em.
///    KEY: LayoutKey(exprId, quantizedEmPx, familySetHash, styleTag, textDirection,
///                   maxWidth ONLY if the expression can line-break).
///    - QUANTIZE emPx to a 1/64-px grid: double equality is a cache-killer.
///    - NEVER put colour in this key. (katex's painter does, so a theme change flushes it.)
///    - fontFamilyFallback order belongs in familySetHash.
final class MathLayoutCache {
  final _lru = <LayoutKey, PlacedMath>{};
  PlacedMath layout(MathBoxTree tree, MathStyleKey style, {int maxEntries = 512});
}

/// 3. GLYPH-METRICS CACHE — THE ONE THAT MATTERS. [new]
///    Maps a distinct glyph to its metrics, so layout becomes pure double arithmetic
///    instead of a libtxt call per glyph.
final class MathGlyphMetricsCache {
  final _lru = <GlyphKey, GlyphMetric>{};
  GlyphMetric metric(int rune, FontOptions font, int quantizedPx);
}

@immutable
class GlyphMetric {
  const GlyphMetric(this.advanceEm, this.heightEm, this.depthEm, this.italicEm, this.skewEm);
  final double advanceEm, heightEm, depthEm, italicEm, skewEm;
}

/// 4. GLYPH-RUN PAINTER CACHE — per-leaf TextPainter, for the *paint* pass only.
///    KEY: (text, family, weight, shape, quantizedPx) — colour applied per paint, not cached.
final class MathGlyphPainterCache {
  final _lru = <GlyphPainterKey, TextPainter>{};
  TextPainter glyph(String s, TextStyle style);   // dispose() on eviction!
}
```

**Why cache #3 is the design.** `flutter_math_fork` and `katex` both end up running **one shaping pass
per glyph**. If instead you measure each *distinct* glyph once and cache `(advance, height, depth,
italic, skew)` in em, then item 1 of §5.10's list (grouping identical-style glyphs into runs) becomes
possible: layout reduces to `O(nodes)` double arithmetic plus `O(distinct glyphs)` shaping calls. For a
note with 13 845 math spans the distinct-glyph set is a few thousand entries **regardless of document
size**, so the whole note's metrics fit in a few MB and the per-scroll and per-keystroke cost is
arithmetic, not shaping. **[inference, but it follows directly from the measured cost model in §1.3]**

The caveat, stated honestly: per-glyph advances can differ from in-run advances because of kerning,
ligatures and complex-script shaping (Arabic, Indic). KaTeX accepts this approximation. **`\text{}`
must be a real shaped run**, never per-glyph — that is exactly the bug behind `flutter_math_fork`'s
[#118](https://github.com/simpleclub/flutter_math/issues/118)/[#123](https://github.com/simpleclub/flutter_math/issues/123)
(RTL/Bengali reversed/unjoined, §5.2).

* **Hash the source** with a real hash (collisions silently render the wrong formula; store the source
  alongside and compare). 13 845 spans × ~60 chars is still under a megabyte.
* **LRU sizes**: parse 4 096 entries; layout 512 (a few viewports); glyph metrics 4 096–8 192;
  glyph painters 512–1 024. Every painter eviction calls `TextPainter.dispose()` (§9.2).
* **Drop the layout + painter caches wholesale** when `fontSize`, `textScaler`, `textDirection`, the
  math font family/fallback chain, or the theme colour changes. Keep the parse cache and the
  *metrics* cache's em-relative part (metrics store em, so a pure font-size change only re-quantises
  the key, not the values — another reason to store em, not px).
* **Do not cache `ui.Paragraph`s longer than needed** unless you own an LRU with disposal — that is
  what `MathGlyphPainterCache` is for.
* **Sizing estimates:** ~7 MB parse + ~5 MB layout for all 13 845 spans, so a 16 MB + 32 MB
  budget holds the entire note. Optionally persist the parse cache in the existing
  `IndexDatabase` — but the tree is only valid for a given `macroEnvId`, so version the row.
* **Per-expression budget**: aim for ≤ 8 glyph-run `TextPainter.layout()` calls per typical expression
  (a fraction with two scripts is ~5 leaves). Assert it (§8.4). Getting there means:
  1. **Group consecutive glyphs with identical `(family, weight, shape, sizePx, color)` into one run**
     and paint each run with one `TextPainter`, inserting explicit `KernOp` advances where the layout
     needs a shift the font will not produce (italic correction, `\not` overlay, accent centring). This
     gives ~1–5 `Paragraph`s per expression instead of one per glyph. It **requires** that your metrics
     table agrees with the font's own advances within a run — verify once at startup. `[inference]`
  2. **Fall back to one cached `TextPainter` per distinct glyph key** — exactly what `katex` does
     (`_glyphCache` keyed by `(text, family, variant, sizePx, colorValue)`,
     `box_painter.dart:157-159, 665-688`) — but hoist the cache to the *engine* so it survives
     rebuilds. The key set is bounded by distinct glyphs on screen: a few hundred `Paragraph`s for a
     whole note, not thousands. `[src]`
  3. `Canvas.drawParagraph(paragraph, offset)` is the low-level primitive if you build `Paragraph`s
     yourself instead of through `TextPainter`.
  4. Pre-rasterising glyphs to `ui.Image` (`PictureRecorder` → `Picture.toImageSync` →
     `Canvas.drawImageRect`) is only worth it for a fixed set of sizes; it loses subpixel positioning
     and looks worse for small text. **Not recommended for a notes app.** `[inference]`
* **`shouldRepaint` must be identity-first but is defeated by upstream churn.** `katex`'s painter gets
  the structure right (`!identical(oldDelegate.root, root)` first, `box_painter.dart:872`) but since its
  `root` is rebuilt on every `build()`, identity always differs and it always repaints. **The lesson:
  `shouldRepaint` can only be cheap if the layout cache holds the *layout object* stable across
  rebuilds** — which is precisely what the caches above provide. For animation-driven repaints pass
  the animation as `super(repaint: animation)` rather than recreating the painter (`katex` does this,
  `box_painter.dart:130`). `[src]`
* **`computeDryLayout` must be side-effect free.** Flutter calls it for intrinsics/baselines *without*
  laying out. If `measure` and `place` share mutable state on the render object or a delegate, a dry
  call **corrupts** it — this is a real bug class in `flutter_math_fork`, whose delegates carry fields
  like `height`, `theta`, `barLength` and only apply offsets when `dry == false`
  (`render/layout/custom_layout.dart:299-302`). **Keep `measure` and `place` as separate pure functions
  and let the immutable layout result be the only shared state.** `[src]`

### 6.5.10 `CustomPainter` + `TextPainter` for math — the exact pattern

```dart
/// Intrinsic size without a second layout: use a RenderBox with computeDryLayout.
final class RenderMath extends RenderBox {
  RenderMath({required MathBoxTree tree, required MathStyleKey style});

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      Size(_placed(tree, style).widthEm * style.fontSize, 0);   // width known, height from tree

  @override
  double computeMaxIntrinsicWidth(double height) => ...;         // from the box tree, O(nodes)
  @override
  double computeMinIntrinsicWidth(double height) => ...;         // unbreakable width

  @override
  void performLayout() {
    final placed = MathLayoutCache.instance.layout(tree, style);
    size = constraints.constrain(Size(placed.widthEm * style.fontSize,
                                      (placed.heightEm + placed.depthEm) * style.fontSize));
    _placed = placed;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = context.canvas;
    c.save();
    c.translate(offset.dx, offset.dy + _placed.heightEm * style.fontSize); // move to baseline
    _paintNode(c, _placed.root);   // glyphs -> TextPainter.paint; rules -> drawRect; paths -> drawPath
    c.restore();
  }

  @override
  bool hitTestSelf(Offset position) => true;   // so taps on the formula map to a source range
}

/// A CustomPainter variant is fine for a leaf/static math block; use it when you do not need
/// instrinsics or hit-testing:
final class MathPainter extends CustomPainter {
  MathPainter(this.placed, this.style, {super.repaint});
  @override
  void paint(Canvas canvas, Size size) { /* same as above */ }
  @override
  bool shouldRepaint(MathPainter old) =>
      old.placed != placed || old.style != style;   // real comparison, never `true`
}
```

**Gotchas that will bite `[inference, grounded in §6.1]`:**

* `TextPainter.paint` draws with the **top-left** of the text box at the given offset. To place a glyph
  on a math baseline you must subtract `tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)` —
  exactly what `katex`'s `box_painter.dart:643-665` does. Getting this wrong produces the classic
  "everything is 20 % too low" look.
* Set `softWrap: false` and `maxLines: 1` on every glyph-run painter, or a long symbol name will wrap.
* Use `leadingDistribution: TextLeadingDistribution.even` and a strut with the math font's metrics so
  the glyph-derived ascent/descent do not add surprise leading inside a script box. **[inference]**
* Snap rules to device pixels (`1 / devicePixelRatio`) or fraction bars look grey next to crisp glyphs.
* `shouldRepaint` must compare the *placed* result, not the tree identity, or you repaint every frame.
* Wrap the whole math block in a `RepaintBoundary` only if it animates or is being edited; otherwise
  the surface-level boundary is enough (§6.9.4).

### 6.5.11 Recommended math architecture for Niman (summary)

1. **Isolate**: TeX tokenise → macro expansion → box tree (`BoxNode` variants: `Glyph`, `Rule`, `Path`,
   `HList`, `VList`, `Kern`, `Glue`, `MathStyle`). Pure Dart, no `dart:ui`, fully unit-testable.
   Port/adapt `katex_dart`'s parser shape; bundle one math font.
2. **UI isolate**: `MathLayoutCache.layout(tree, style)` → an immutable `PlacedMath` (relative
   coordinates in em, plus an ordered `List<DrawOp>`). **One bottom-up measure pass**, with a
   delimiter-stretch request and a bounded (≤3) re-shift iteration; a cell-measure pass for
   array/matrix/cases/aligned.
3. **Paint**: `RenderMath` (`performLayout` + `paint`) for block math; a `TextPainter`-backed
   `PlaceholderSpan` for inline math, so it participates in the surrounding paragraph's line breaking —
   with an explicit offset ledger to survive `U+FFFC` (§6.9.3).
4. **Caches**: parse (isolate, keyed on source hash) → layout (UI, keyed on tree + style) → glyph-run
   `TextPainter`s (UI, LRU + `dispose`).
5. **Never** re-parse all 13 845 spans on open: parse lazily per visible block, and pre-warm the
   parse cache in the worker isolate during idle.
6. **Never** render an unparseable expression as nothing: show the source.

---

## 6.6 Syntax highlighting without a package

### 6.6.1 What `highlight` 0.7.0 actually is (measured locally)

Read directly from `~/.pub-cache/hosted/pub.dev/highlight-0.7.0` (version pinned by Niman's
`pubspec.lock`) — **[measured]** on this machine:

| Property | Value |
|---|---|
| Version | `0.7.0` (also `flutter_highlight ^0.7.0`, the widget wrapper) |
| `lib/languages/` | **190 files**, **1.9 MB** of Dart |
| Registered languages | `lib/languages/all.dart` aggregates **189** mode maps into `allLanguages` |
| Core | `lib/src/highlight.dart` (`class Highlight`), plus `mode.dart`, `node.dart`, `result.dart`, `common_modes.dart`, `utils.dart` |
| Public API | `Result parse(String source, {String? language, bool autoDetection = false})` — `highlight.dart:254`. **`NodeRenderer` does not exist** anywhere in the package or the pub cache (`grep` over all cached packages). `flutter_highlight` exposes `HighlightView`; the maintained fork `re_highlight` 0.0.3 exposes `HighlightRenderer`/`TextSpanRenderer`. |
| Output | `Result { String? language; int? relevance; List<Node> nodes; Result? secondBest; Mode? top; }` where `Node` is `{String? className, String? value, List<Node> children}` |
| Lexer model | **Declarative `Mode` trees.** The 190 language modules contain **zero** `RegExp(...)` and **zero** `multi: true`; the engine compiles every pattern centrally with `multiLine: true` via `_langRe` (`lib/src/highlight.dart:30-36`). `Mode.terminators`, `Mode.lexemesRe`, `Mode.illegalRe` are the compiled results. |
| Multi-line state | `Mode.parent` + `Mode.inherit` chain, **local to one `parse()` invocation** |
| Incremental? | **No.** `_parse` begins `var top = continuation ?? _languageMode;` and loops `top.terminators!.allMatches(source, index)` over the whole source (`highlight.dart:456-471`). `continuation` is used only for sub-language recursion (e.g. HTML embedding JS), never to resume from a previous call's state. There is no `State` type, no checkpoint, no line model. |
| Worst feature | `autoDetection: true` calls `_parse(source, language: …)` **for every language in the set** and picks the highest `relevance` (`_parseAuto`, `highlight.dart`). **Measured: ~39 ms per KB, linear** — 8 KB = 316 ms, 16 KB = 624 ms, 32 KB = **1 252 ms**, extrapolating to **~7.8 s at 200 KB** and **~36 s at 934 KB**. Never reachable from the editor. **[measured, extrapolation marked]** |

**Concrete per-parse cost structure** `[measured structure, inferred timings]`:

```
_parse(source)
  _getLanguage(name)                 // map lookup, trivial
  _compileMode(languageMode)         // recursively compiles every RegExp in the mode tree
  for each terminator match in source:
      _processLexeme(substring, lexeme)     // substring() ALLOCATES
          _processKeywords()                // second RegExp pass + per-keyword substring allocs
          _buildSpan / _addText             // allocates Node objects per token
  Result(nodes: currentChildren)      // a full Node tree, one object per token
```

The `.allMatches(source, index).firstWhereOrNull((m) => true)` idiom allocates a lazy `Iterable` and
takes the first element *per terminator match* — i.e. **O(matches) iterator allocations**, plus a
`String.substring` per lexeme and per keyword. For a 200 KB code block with, say, 40 000 tokens this is
~120 000+ short-lived allocations. Dart's `RegExp` is the VM's irregexp engine, which is fast per match
but has **no step/time budget**: a badly-written grammar can backtrack catastrophically.

**Estimated cost of a 200 KB code block** — now **measured**, on this machine (Linux x64, JIT, warm,
single language, no autoDetection; a benchmark harness was run by the research pass and the full table
is in `/tmp/niman-research/sub-highlight-isolates.md` §A2):

| Input | Language | `highlight.parse` |
|---|---|---|
| 25 KB | `dart` | 9.92 ms |
| 50 KB | `dart` | 18.22 ms |
| 100 KB | `dart` | 29.04 ms |
| **200 KB** | **`dart`** | **57.89 ms** |
| 25 KB | `python` | 14.51 ms |
| 100 KB | `python` | 61.54 ms |
| **200 KB** | **`python`** | **127.95 ms** |
| 934 KB prose | `markdown` | 168.74 ms (70 476 top-level nodes) |
| 934 KB code | `dart` | **415.4 ms** (156 306 top-level nodes) |

That is **~0.29 ms/KB on `dart`**, **~0.64 ms/KB on `python`**, roughly linear in input size, on a
**desktop JIT** — so maybe 3–8× worse on a mid-range Android device in AOT. `[measured]`

**The worse finding: the *render* path is super-quadratic, so the lexer is not even the bottleneck.**
`Result.toHtml()` on `dart` input, one call (`sub-highlight-isolates.md` §A2.2):

| Input | Output | `toHtml` time |
|---|---|---|
| 12 KB | 64 KB | 24.5 ms |
| 25 KB | 134 KB | 88.8 ms |
| 50 KB | 268 KB | 391.5 ms |
| 100 KB | 536 KB | **6 868.8 ms** |
| 200 KB | 520 KB | **4 560.6 ms** |

Mechanism (`lib/src/result.dart:26-52`, **[src]**): `str += …` accumulation inside a recursive
`_traverse` (repeated reallocation of a growing `String`) plus **three `RegExp.replaceAll` passes per
node** in `_escape`. And `flutter_highlight`'s `_convert` has the same shape for `TextSpan`s and runs
inside `build()` on every rebuild. **[src]** So a note whose code blocks total ~200 KB spends ~58 ms
lexing and **seconds** materialising spans/HTML, per rebuild, on the UI isolate. Memory for a 934 KB
`dart` parse: **+29.5 MB RSS** retained, ~65 MB peak across 5 consecutive parses (156 306 top-level
nodes). `[measured]`

Also: a 64 KB adversarial `dart` snippet made the grammar fall into the `Illegal lexeme` catch and
collapse the whole result to one node — i.e. user-triggerable output loss. **[measured]** Also note the
failure mode at `highlight.dart` `catch (e)`: an `Illegal lexeme` throws a **bare `String`**, and the
catch returns `Result(relevance: 0, nodes: [Node(value: source)])`; any port must use a real exception
type.

**A user-triggerable hang was found in the shipped grammar set.** `[measured]` The `cpp` grammar is
**clean O(n²)** on the input `'a' * n + '!'`: 8 KB takes **1,854 ms**, and each doubling of the input
multiplies the time by ~4. The same input on the `dart` grammar is linear. **There is no regex timeout
in Dart** ([dart-lang/sdk#61284](https://github.com/dart-lang/sdk/issues/61284) closed as intended;
Dart's Irregexp is built with its non-backtracking engine, match caching and JIT paths disabled), so
**a ` ```cpp ` block containing a long run of `a`s will hang the preview.** This is not a theoretical
risk: any user can paste such a fence. **[measured]**

**And the *preview* path is the exposure, not the editor path.** `flutter_highlight`'s
`HighlightView.build()` calls `highlight.parse(...)` **synchronously on the UI isolate with no cache**,
so every rebuild re-parses — while the *editor* path (`re_editor`) is already isolated (via
`isolate_manager`, with `maxSize`/`maxLineLength` guards). The maintainer of `re_editor` blames exactly
this: the package "does not cache the results"
([re_editor#2](https://github.com/reqable/re-editor/issues/2) "several thousand lines → more than a few
seconds", [#102](https://github.com/reqable/re-editor/issues/102) 1.2 MB → whole app slow). **[src/doc]**

**Conclusion (restated):** the initial highlight pass must be in an isolate; per-keystroke highlighting
must be incremental; **the `Node`-tree → `TextSpan` materialisation must be eliminated entirely** (the
flat `LineTokens` of §6.3 replaces it); and **no user-reachable path may call `parse()` or `parseAuto()`
synchronously on the UI isolate**, because a hostile input can make either one effectively unbounded.

### 6.6.2 The right design: line-oriented incremental stream lexer

The model to port is CodeMirror's **stream parser** (CodeMirror 5 `StreamParser`,
CodeMirror 6 `StreamLanguage` + `@lezer/highlight`). Its contract, which is what makes incremental
re-lexing possible, is: **the lexer state is a value that can be snapshotted per line and copied
cheaply.**

The canonical method set, **with the CM5/CM6 differences called out** (a research pass captured both
APIs exactly from `codemirror.net/5/doc/manual.html` `#modeapi` and `codemirror.net/docs/ref/#language.StreamParser`):

| Hook | CM5 (`#modeapi`) | CM6 (`StreamParser<State>`) | Purpose |
|---|---|---|---|
| `startState` | ✅ `startState(base, indentUnit)` | ✅ `startState` | fresh state for line 0 |
| `copyState` | ✅ | ✅ | **deep-copy the mutable state** before resuming; must not alias |
| `token` | ✅ `token(stream, state)` | ✅ | consume one token; set `state.tokenize` to a nested function to enter a sub-mode |
| `blankLine` | ✅ `blankLine(state, indentUnit)` | ✅ `blankLine(state)` | what a *blank line* produces |
| `indent` | ✅ | ✅ | optional |
| `languageData` | ❌ **does not exist** | ✅ (`Map<String, dynamic>`) | `commentTokens`, `closeBrackets`, `autocomplete` |
| `tokenTable` | ❌ **does not exist** | ✅ (`Record<string,string>`, re-exported by `@codemirror/language`; **not** exported by `@lezer/highlight`) | lexer token name → highlight class |
| `innerMode` | ✅ | — | nesting into a sub-language |
| `lineOracle` / `lookAhead` / `baseToken` | ✅ | ❌ **CM5-only** | incremental look-ahead hacks; do not port |
| `ignoreIndentation` | — | ❌ **does not exist** | (brief premise corrected) |
| `mergeTokens` | — | ✅ | adjacent same-class tokens |
| `name`, `tokenTable`, `languageData` | — | ✅ | CM6-only metadata |

**Important semantics correction:** `blankLine` **never resets state** in either engine — it *computes*
the state a blank line produces. A no-op `blankLine` is therefore fine for a lexer whose multi-line
constructs (block comments, template strings) are tracked in state; the real hazard is **parity of side
effects**, not reset. (Multiple independent sources; the CM5 docs explicitly say the state is carried
across blank lines.)

**The CM6 mechanism to copy exactly:** CM6 does not re-lex the whole document. It uses a
**cached-state restart + forward re-lex in 512-character chunks**, driven by the `stateAfter` facet —
i.e. it re-lexes from the nearest cached point until the state matches, which is the same convergence
idea as §6.3's predicate, expressed over character chunks rather than whole lines. **[doc]**

`StringStream` (CM5 `StringStream`, CM6 same idea) — port this class as-is:

```dart
class StringStream {
  StringStream(this.string, {this.tabSize = 4});
  final String string;
  final int tabSize;
  int pos = 0;          // current position
  int start = 0;        // start of the current token
  String? _lastToken;

  bool eol()           => pos >= string.length;
  bool sol()          => pos == 0;
  String? peek()       => eol() ? null : string[pos];
  String next()        { if (eol()) return ''; final c = string[pos++]; return c; }
  bool eat(String match) { /* single char or predicate */ }
  bool eatWhile(RegExp re) { /* consume matches, return whether any */ }
  bool eatSpace()      { /* consume \s */ }
  void skipToEnd()     { pos = string.length; }
  bool skipTo(String ch) { /* find next occurrence */ }
  String? match(RegExp re, {bool consume = true, bool caseInsensitive = false});
  void backUp(int n)   { pos -= n; assert(pos >= start); }
  String current()     => string.substring(start, pos);
  int column()         { /* visual column accounting for tabs */ }
  int indentation()    { /* leading whitespace count */ }
}
```

Two rules that are easy to get wrong and that cost you correctness:

1. **`copyState` must deep-copy every mutable field**, including nested `tokenize` closures and any
   `List`/`Set` in the state. A shallow copy makes the checkpoint table useless because resuming from a
   checkpoint mutates the shared object.
2. **`blankLine` is mandatory for any language with multi-line constructs.** A `/* … */` block that
   spans two blank lines will, without `blankLine`, reset to the base state on the first blank line and
   lex the rest of the comment as code.

### 6.6.3 The concrete state model for Niman

```dart
/// Opaque-to-the-cache lexer state. MUST be cheap to copy.
abstract class LexState {
  LexState copy();
  bool equalsState(LexState other);   // used for the convergence early-out
  int get hash;                       // packed light snapshot for checkpoints
}

final class MarkdownLexState extends LexState { /* fence depth, list depth, html block? */ }
final class CodeLexState extends LexState { /* language id + language-specific state */ }

/// Token kinds are small ints, never Strings, never enums-with-fields.
abstract final class Tok {
  static const int plain = 0, keyword = 1, string = 2, comment = 3, number = 4,
      type = 5, operator = 6, punctuation = 7, meta = 8, tag = 9, attr = 10,
      builtin = 11, variable = 12, literal = 13, deletion = 14, addition = 15,
      emphasis = 16, strong = 17, link = 18, code = 19;
}

/// One line's tokens, flat. Three parallel Int32Lists, no objects.
final class LineTokens {
  final Int32List starts;   // token start, in UTF-16 code units within the line
  final Int32List lengths;  // token length in code units
  final Int32List kinds;    // Tok.*
  int get count => starts.length;
}

final class HighlightController {
  final List<LineTokens?> _tokens = [];          // per-line cache; null = dirty
  final List<LexState?>  _statesAtLineStart = []; // state *before* line i
  final int checkpointEvery;
  final Map<int, LexState> _checkpoints = {};    // line -> copied state at line start
  int _dirtyFrom = 0;                            // first line whose state cache is stale

  /// Called after an edit at [firstChangedLine]. O(1) bookkeeping.
  void invalidateFrom(int firstChangedLine) {
    if (firstChangedLine >= _dirtyFrom) return;   // already dirty from earlier
    _dirtyFrom = firstChangedLine;
    for (var i = firstChangedLine; i < _tokens.length; i++) _tokens[i] = null;
    // checkpoints at or after firstChangedLine are stale
    _checkpoints.removeWhere((line, _) => line >= firstChangedLine);
  }

  /// Lex forward from [_dirtyFrom] until the state converges on the cached one.
  /// Returns the number of lines actually re-lexed — the metric the budget asserts.
  int relex(Corpus corpus, {required int maxLines}) {
    var line = _dirtyFrom;
    var state = _stateBefore(line);
    var relexed = 0;
    while (line < corpus.lineCount && relexed < maxLines) {
      final prevState = _statesAtLineStart[line];
      final prevTokens = _tokens[line];
      final buf = LineTokenBuffer();
      final next = _lexLine(corpus.lineText(line), state, buf);
      if (prevTokens != null && buf.sameAs(prevTokens) && state.equalsState(prevState!)) {
        break;                       // <-- CONVERGENCE: everything below is still valid
      }
      _statesAtLineStart[line] = state.copy();
      _tokens[line] = buf.finish();
      state = next;
      line++;
      relexed++;
    }
    _dirtyFrom = line;
    return relexed;
  }

  LexState _stateBefore(int line) {
    final cp = _checkpoints[line];
    if (cp != null) return cp.copy();
    // walk back to the previous checkpoint, then re-lex forward to `line`
    // (checkpoint walk is O(checkpointEvery) lines, not O(line))
    ...
  }
}
```

**The convergence predicate is the whole trick.** Re-lexing stops as soon as
`(state at start of line == cached state) ∧ (tokens of line == cached tokens)`. In Markdown, an edit
inside a paragraph changes one line; in a code fence it changes one line. Convergence is therefore
**typically reached within 1–3 lines**, so a keystroke re-lexes O(1) lines even in a 10 000-line
document. This is the single highest-leverage optimisation in the whole highlighter.

> **Niman already has this pattern in-repo** — worth reading before writing anything new:
> `lib/src/editor/highlighting.dart:341` does exactly `if (state == old.entering) { /* line and every
> line after it keep their tokens */ }`, with `_State? entering` per line (`:208`) and
> `line.entering = lines[index - 1].exit` (`:385-386`). The new widget should keep this design, move
> the tokens into a flat `LineTokens` buffer instead of a `Node`/span tree, and add the checkpoint
> table below.

**Checkpointing.** You cannot know line *N*'s state without lexing lines 0…*N*−1. Two mitigations,
both needed:

* **Amortised full scan on load**: the initial pass already has to lex every line to cache tokens, so
  store a `copyState` snapshot every `checkpointEvery` lines (128 is a good default). Resuming for a
  viewport jump is then ≤ 128 line-lexes.
* **Checkpoint invalidation**: after an edit at line *f*, every checkpoint at line ≥ *f* is stale;
  `Map.removeWhere` is the O(#checkpoints) cleanup. A 10 000-line document has ≤ 79 checkpoints.

**Memory.** A `LexState` per line plus a checkpoint every 128 lines: 10 000 line-states × (a small
object, call it 48 B) ≈ 500 KB — acceptable, and it can be dropped for lines far from the viewport
(re-derived from the nearest checkpoint). Token buffers at ~6 tokens/line × 12 B/token ≈ 720 KB for
10 000 lines of average code, and much less for prose. **[inference]**

### 6.6.4 How it plugs into the viewport

1. **Tokenise only the visible lines + overscan** (`viewport + cacheExtent`, rounded to line
   boundaries) *plus* lines already cached. Never tokenise the whole fence on scroll.
2. **On first sight of a line**, ensure a state: walk back to the nearest checkpoint at or before it
   and lex forward (bounded by 128 lines). Cache that state.
3. **On edit**, call `invalidateFrom(firstChangedLine)` and `relex(...)`. The return value is the
   number of re-lexed lines — assert `<= 3` in tests.
4. **Feed the painter** a flat `LineTokens` per line, plus the block's `TextStyle` per `Tok.*`. Build
   the `InlineSpan` for the visible lines only: one `TextSpan(style: kindStyle[kind], text: line.substring(s, s+len))`
   per token. Because one code block is potentially 200 KB, **do not build a single span tree for the
   whole block** — build it per visible window and let the paragraph cache be keyed on the window.
5. **Do not use `FontFeature`/`TextStyle` per token if you can avoid it**: each distinct
   `(fontFamily, fontSize, fontWeight, color)` combination is a separate `pushStyle` on the
   `ParagraphBuilder` and can break shaping runs across a span boundary (kerning/ligatures stop at the
   boundary). For code this is acceptable and expected; for prose it is why you must **not** split a
   word across spans. **[inference]**
6. Colors are the *only* thing most token kinds change. Since a colour change forces a full paragraph
   rebuild (§6.9.1), and code blocks are the hot case, evaluate early whether to paint code text with
   `Color` in `TextStyle` or to paint plain text and overlay colour runs with `Canvas` (`drawRect` per
   token box). The former is simpler and correct-by-construction; the latter is a possible optimisation
   if profiling shows code blocks dominating. **[inference]**

### 6.6.5 Verdict on `highlight`

Keep `highlight` **only** as a grammar reference and as the source of the KaTeX-style token class
names; do not call `parse()` on the UI thread for anything larger than a few KB, do not use
`autoDetection`, and reimplement the grammars Niman actually needs (Markdown-embedded code: Dart,
JS/TS, Python, JSON, YAML, bash, SQL, HTML/XML, CSS) as CM-style stream parsers with the state model
above. Ten hand-written stream lexers are ~1 500–2 500 lines total and give O(1) keystroke re-lex; the
190-language regex package gives none of that. **[inference on effort; the measurements above are
`[measured]`]**

---

## 6.7 Isolates and parsing off the UI thread

### 6.7.1 Exact APIs (read from the SDK on disk)

```dart
// /home/alessandro/develop/flutter/bin/cache/dart-sdk/lib/isolate/isolate.dart
abstract class Isolate {
  static Future<R> run<R>(FutureOr<R> computation(), {String? debugName});   // :253  @Since("2.19")
  external static Isolate get current;                                      // :326
  external static Future<Isolate> spawn<T>(                                 // :458
      void Function(T message) entryPoint, T message,
      {bool paused = false, bool errorsAreFatal = true,
       SendPort? onExit, SendPort? onError, String? debugName,
       Isolate? controlPort});
  external static Future<Isolate> spawnUri(...);                            // :546
  external void kill({int priority = beforeNextEvent});                     // :704
  external static Never exit([SendPort? finalMessagePort, Object? message]); // :834
}

abstract interface class SendPort implements Capability {
  void send(Object? message);                                               // :1023
}

abstract final class TransferableTypedData {                                // :1180
  external factory TransferableTypedData.fromList(List<TypedData> list);    // :1186
  ByteBuffer materialize();                                                 // :1193
}
```

`Isolate.run` internals (`:253-300`): it **spawns a new isolate per call** (`Isolate.spawn(_RemoteRunner._remoteExecute,
_RemoteRunner<R>(computation, resultPort.sendPort), onError:…, onExit:…, errorsAreFatal: true)`) and
completes a `Completer` from a `RawReceivePort`. It **discards the returned `Isolate` handle**
(`.then<void>((_) {})`), which is why a job started this way cannot be cancelled or inspected. **[src]**

Two API notes that save time:

* **There is no `IsolateError` in Dart 3.13.2.** `grep -rn "IsolateError"` over the whole SDK `lib/`
  returns no matches. The error type you actually catch for a worker failure is
  `final class RemoteError implements Error` (`isolate.dart:1161`) — and because it `implements Error`
  rather than extending `Exception`, a `catch (e)` that filters on `Exception` will miss it. **[src]**
* Dart 3.13 added `Isolate.runSync`, `Isolate.create`, `shutdownSync`, `pinToCurrentThread`,
  `isPinnedToCurrentThread`, `runEventLoopSync`, `onEvent`, `handleEvent` (`@Since("3.13")`,
  `isolate.dart:850-952`). These are embedder/thread-driving APIs, **not** the right tool for a Flutter
  app; named here so the report does not claim they are absent. **[src]**
* `ReceivePort` is **single-subscription**: `listen` may be called only once, and a second call throws
  `Bad state: Stream has already been listened to.` The pool must therefore keep one long-lived
  listener with a `Map<int, Completer<…>>` keyed by job id — not `port.first` per job. `RawReceivePort`
  additionally is *not* `Zone`-aware, cannot be paused, and loses messages if its handler is set after
  the first message arrives (`:1100-1112`). `SendPort`s *"preserve equality when sent"* (`:961-962`),
  which is what makes the worker handshake work. **[src]**

`compute` is a thin wrapper over `Isolate.run` — verified in
`packages/flutter/lib/src/foundation/_isolates_io.dart`:

```dart
Future<R> compute<M, R>(isolates.ComputeCallback<M, R> callback, M message, {String? debugLabel}) async {
  debugLabel ??= kReleaseMode ? 'compute' : callback.toString();
  return Isolate.run<R>(() => callback(message), debugName: debugLabel);
}
```

So **`compute` is not cheaper than `Isolate.run`; both pay a full isolate spawn per call.** Use a
long-lived pool for anything that happens per keystroke or per scroll. **[src]**

### 6.7.2 Copy vs. share vs. move — the actual guarantees

From `SendPort.send`'s documentation (`isolate.dart:964-1023`) **[src, verbatim where quoted]**:

* Same-code isolates (`Isolate.spawn`): *"any object can be sent"* except native-resource wrappers,
  `ReceivePort`, `DynamicLibrary`, `Finalizable`, `Finalizer`, `NativeFinalizer`, `UserTag`,
  `MirrorReference`, and anything marked `@pragma('vm:isolate-unsendable')`.
* Different-code isolates (`Isolate.spawnUri`): only `null`, `bool`, `int`, `double`, `String`, list/map/set
  literals, `List`/`Map`/`LinkedHashMap`/`Set`/`LinkedHashSet`, `TransferableTypedData`, `Capability`,
  `SendPort`, and `Type` of those.
* **The key sentence:** *"Objects that are identified as immutable (e.g. strings) will be shared whereas
  all other objects will be copied."* So **`String` is shared** (no copy) between isolates in the same
  isolate group, but a `List<Block>` object graph **is deep-copied**, and *"the send happens immediately
  and may have a **linear time cost** to copy the transitive object graph."*
* **`TypedData` is copied**, not shared — unless wrapped. `isolate.dart:1180-1193`: `TransferableTypedData`
  is *"a cross-isolate single-use resource"*; `materialize()` *"must not be called more than once on the
  same underlying transferable bytes, even if the calls occur in different isolates."*
* **`Isolate.exit(port, message)`** is the zero-copy path (`:834`): *"If the port is a native port — one
  provided by `ReceivePort.sendPort` or `RawReceivePort.sendPort` — the system may be able to send this
  final message more efficiently than normal port communication between live isolates. In these cases
  this final message object graph will be **reassigned to the receiving isolate without copying**.
  Further, the receiving isolate will in most cases be able to receive the message in **constant time**."*
* **Isolate groups**: isolates created with `Isolate.spawn` from the same parent share a heap
  (`Isolate.spawnUri` does not). Shared *code* is what allows arbitrary objects to be sent, but the
  language still specifies copy semantics for mutable objects; the "no copy" guarantee is only spelled
  out for immutable objects and for `Isolate.exit`. Treat "shared heap ⇒ no copy" as an
  **implementation detail, not a guarantee** — except for the two documented cases above. **[src + inference]**

#### 6.7.2.1 The transfer matrix, measured

A live worker isolate (no spawn cost in the loop), one round trip per sample; `avg_us` includes send +
receive + reply (~18 µs baseline overhead). From `sub-highlight-isolates.md` §B6.3 **[measured]**:

| Payload | `String` | `Uint8List` | `Int32List` | `TransferableTypedData` (fromList + send) |
|---|---|---|---|---|
| 1 KB | 14.8 µs | 18.7 µs | 32.4 µs | — |
| 256 KB | **13.2 µs** | 210.9 µs | 171.4 µs | 236.1 µs (fromList alone: 611 µs) |
| 1 MB | **23.7 µs** | 689.5 µs | — | 654.7 µs (fromList alone: 1 077 µs) |
| 8 MB | **15.7 µs** | 2 250.1 µs | 1 677.0 µs | 2 257.8 µs (fromList alone: 1 960 µs) |
| 32 MB | **12.2 µs** | 6 233.8 µs | — | — |

Readings:
* **`String` cost is flat** (12–24 µs from 1 KB to 32 MB) — empirical confirmation that strings are
  **not copied**.
* **Typed data is copied** at a measured **~5.4 GB/s** (32 MB / 6.23 ms). A 934 KB `Uint8List` ≈
  **0.64 ms** per crossing.
* **`TransferableTypedData` is not faster end-to-end for a live worker**: 1 MB 654.7 µs vs 689.5 µs;
  8 MB 2 257.8 vs 2 250.1 µs. `fromList` is O(n) and cancels the O(1) send. **Its win is peak memory
  (the sender hands the buffer over rather than duplicating it), not time.**
* **`Isolate.exit` is the real win** — see §6.7.3.

### 6.7.3 What a 934 KB String costs across an isolate — and the `Isolate.exit` result

**Measured** (`sub-highlight-isolates.md` §B7):

| Operation | Per call |
|---|---|
| `Isolate.run(() => 1)`, 100 iterations | **0.134 ms** |
| `Isolate.spawn(_trivial, port)` + wait + `kill(immediate)`, 100 iterations | **0.162 ms** |

**This corrects a piece of folklore.** The widely-repeated "1–10 ms and 1–2 MB per isolate" figures are
*not* in the official Dart/Flutter docs; the Dart SDK's own documented isolate base memory is
*"in the order of 30 kb"* (`isolate.dart:456-457`) and Flutter's isolates page speaks only of
"performance overhead … to spawn new isolates, and to copy objects from one isolate to another".
On this machine a full `Isolate.run` round trip is **0.13 ms**, so `Isolate.run` per job is not
inherently catastrophic — but with *real* highlighter state loaded, the fixed overhead shows up:
**[measured]** `Isolate.run` on a 1 KB highlight job takes **2.567 ms** versus **0.505 ms** on a warm
pooled worker, a **~2.1 ms fixed overhead per call**, and a second call in an already-compiled language
on a warm worker is **0.092 ms**. Sending the 200 KB source per job costs essentially nothing
(94.3 ms vs 93.3 ms). So the pool wins on (a) per-call overhead, (b) retained compiled-lexer state, and
(c) holding the `Isolate` handle for cancellation — not on spawn time.

**[measured] What a 934 KB `String` costs to send: ~12–24 µs, independent of size.** So *sending* the
document to a worker is effectively free. The cost is on the way back, and there are only two good
answers:

* **`SendPort.send` of a typed buffer copies it**: ~0.2 ms/MB measured, so ~0.65 ms for a 1 MB result.
* **`Isolate.exit` does not copy.** Measured, 32 MB `Uint8List`:
  | Return path | Per call |
  |---|---|
  | buffer **captured** by the closure (so it is copied *into* the worker) | 5 563.4 µs |
  | buffer **built inside** the worker, returned by `Isolate.exit` | **498.1 µs** |
  | 1 MB, captured | 785.1 µs |
  | 1 MB, built inside, `Isolate.exit` | **250.3 µs** |

  The ~11× gap at 32 MB is the copy disappearing; the residual is allocation inside the worker.
  **This is the single most important measurement for the design: build the result inside the worker
  and return it via `Isolate.exit`.**

Design rules that follow:

* **Read the file in the worker**, from a path. `dart:io` works off the root isolate (Dart concurrency
  docs: a worker *"can perform I/O (reading and writing files, for example), set timers, and more"*),
  and "no disk I/O on the UI isolate" is already a Niman rule.
* **Never send the 934 KB string *back*** — not because sending it is expensive (it is ~15 µs, shared)
  but because (a) an object-graph result costs tens of MB of allocation and copying, and (b) if you ever
  cross an isolate group (`spawnUri`) or the web, the "shared" fast path vanishes and the string *is*
  copied.
* **Prefer `Isolate.run` + `Isolate.exit` when the result is large and the job is one-shot** (cold open,
  full-document parse). Use a pool for keystroke-rate jobs and accept the ~0.2 ms/MB copy on the return,
  or have the pool worker write its result into a `TransferableTypedData` only if peak memory matters.
* **Do not reach for `TransferableTypedData` by default** — measured end-to-end parity with a plain
  send; its benefit is peak RSS, and `materialize()` is single-use.

### 6.7.3.1 Cancellation: there is none, and `Isolate.run` cannot even offer a handle

**[measured/src]** `Isolate.kill(priority: beforeNextEvent)` *"is scheduled for the next time control
returns to the event loop"* (`isolate.dart:680-700`), so it **cannot** interrupt a synchronous lexer
loop. `Isolate.kill(priority: Isolate.immediate)` is the only mechanism that stops a tight synchronous
loop. And `Isolate.run` **discards the `Isolate` handle** (`isolate.dart:295-296` returns
`Isolate.spawn(...).then<void>((_) {})`), so a job launched that way is **uncancellable** — you can only
discard its result. Therefore: **generation counter + discard-result** for normal cancellation, plus a
`kill(priority: Isolate.immediate)` escalation for a wedged worker.

### 6.7.4 `RootIsolateToken` and what a worker isolate cannot do

```dart
// engine/src/flutter/lib/ui/platform_dispatcher.dart:93
class RootIsolateToken {
  static final RootIsolateToken? instance = () {           // :102
    final int token = __getRootIsolateToken();
    return token == 0 ? null : RootIsolateToken._(token);   // null if NOT a root isolate
  }();
  final int _token;
}

// services/_background_isolate_binary_messenger_io.dart
static void ensureInitialized(ui.RootIsolateToken token);   // :43  idempotent
```

* On the **root isolate**, `RootIsolateToken.instance` is non-null. In a **background isolate it is
  null** — you must capture `ServicesBinding.rootIsolateToken` on the root isolate and send it to the
  worker as part of the spawn message. **[src]**
* `BackgroundIsolateBinaryMessenger.ensureInitialized(token)` is what makes
  `BackgroundIsolateBinaryMessenger.instance` valid and lets the worker use `BinaryMessenger`
  (`_background_isolate_binary_messenger_io.dart:27-46`). Without it, any channel call in a worker
  throws. **[src]**
* **No `WidgetsBinding`, no `SchedulerBinding`, no `ServicesBinding`, no `MediaQuery`, no
  `BuildContext`** in a worker. [`verified` by the research pass from framework source] All three
  bindings have the shape `static XBinding get instance => BindingBase.checkInstance(_instance);` over
  a **per-isolate static**, so a spawned isolate sees `null`. `BindingBase.checkInstance` is
  `assert(() { … }()); return instance!;`, so the friendly "Binding has not yet been initialized."
  `FlutterError` is **debug/profile only** — in release you get a bare
  `Null check operator used on a null value`. Flutter's own isolates page states it directly: *"All UI
  tasks and Flutter itself are coupled to the main isolate. Therefore, you can't access assets using
  `rootBundle` in spawned isolates, nor can you perform any widget or UI work in spawned isolates."*
  Also note the API-doc URLs moved: use
  [WidgetsBinding-mixin](https://api.flutter.dev/flutter/widgets/WidgetsBinding-mixin.html),
  [SchedulerBinding-mixin](https://api.flutter.dev/flutter/scheduler/SchedulerBinding-mixin.html),
  [ServicesBinding-mixin](https://api.flutter.dev/flutter/services/ServicesBinding-mixin.html) — the
  old `-class.html` URLs 404.
* **`dart:ui` does not work in a worker isolate — verified at the engine level, not inferred.** This is
  the decisive restriction for Niman:
  * The engine's `UIDartState::ThrowIfUIOperationsProhibited()` throws **"UI actions are only available
    on root isolate."** for `PictureRecorder`, `Canvas`, **`ParagraphBuilder`/`Paragraph`**,
    `ImmutableBuffer.fromAsset`/`fromFilePath`, `FontCollection`, and `PlatformDispatcher` UI callbacks.
    Spawned isolates get an empty `UIDartState::Context` (null task runners; no image-decoder registry,
    hence *"Failed to access the internal image decoder registry on this isolate"*). Native handles are
    unsendable, so the result cannot be moved either. **[src, engine]**
  * [flutter#41707](https://github.com/flutter/flutter/issues/41707) — **closed as not planned**:
    *"It is not currently possible to layout text in a separate isolate, as all `dart:ui` methods must run
    in the main isolate."* Related open: [#13343](https://github.com/flutter/flutter/issues/13343),
    [#30604](https://github.com/flutter/flutter/issues/30604),
    [#53985](https://github.com/flutter/flutter/issues/53985) (`ParagraphBuilder` in another isolate —
    not possible). **There is no shipped feature and no roadmap item for background text layout.**
  * **Consequence:** `TextPainter`, `ui.ParagraphBuilder`, `ui.Paragraph`, `PictureRecorder`,
    `Canvas` text, `ImmutableBuffer` and `FontLoader`-dependent work **must** stay on the root isolate.
    Everything pure Dart — Markdown parsing, TeX *parsing*, lexing, diffing, byte-offset arithmetic,
    and **`dart:io` file reads** — can leave. [Dart concurrency docs](https://dart.dev/language/concurrency):
    a worker *"can perform I/O (reading and writing files, for example), set timers, and more."*
    `rootBundle` does **not** work in a worker. Plugins need
    `BackgroundIsolateBinaryMessenger.ensureInitialized(RootIsolateToken.instance!)` called **inside**
    the worker (request/response only).
  * Design as if background text layout will never arrive; if it ever does, the flat-buffer boundary
    below is exactly the interface that would benefit. **[inference]**

### 6.7.5 Worker pool design

```dart
final class PoolJob {
  PoolJob({required this.id, required this.kind, required this.payload});
  final int id;                    // monotonic; the UI side discards stale results by id
  final int kind;                  // JobKind.parseDocument / reparseBlock / lexRange / parseMath
  final Object? payload;           // SendPort-friendly: primitives + TransferableTypedData
}

final class WorkerHandle {
  WorkerHandle(this.isolate, this.jobs);
  final Isolate isolate;
  final SendPort jobs;             // worker's inbox
  final ReceivePort replies;       // one per worker
  int inFlight = 0;
}

final class IsolatePool {
  IsolatePool({required int size});  // size = (Platform.numberOfProcessors - 1).clamp(1, 4)

  /// Spawn: handshake = worker sends its SendPort first, then waits.
  Future<void> start();            // Isolate.spawn(_workerMain, handshakePortSendPort,
                                   //   debugName: 'niman-parse-$i', errorsAreFatal: false)
  Future<T> submit<T>(PoolJob job, T Function(ByteBuffer) decode,
                      {required int generation});

  /// Cancellation is COOPERATIVE ONLY: there is no way to abort a running
  /// computation. Send a "cancel id" message, or (simpler) bump the generation
  /// counter on the UI side and drop any reply whose generation is stale.
  void cancelBefore(int generation);

  void dispose();                  // Isolate.kill(priority: Isolate.immediate) for each
}
```

Design notes `[inference except where noted]`:

* **Sizing**: `Platform.numberOfProcessors - 1`, clamped to `[1, 4]`. One isolate is often enough for
  parsing; the pool exists so a 200 KB highlight does not block a keystroke re-parse. On Windows/Linux
  desktops `numberOfProcessors` is large; do not spawn 12 isolates for a notes app.
* **Spawn cost**: **measured at 0.134–0.162 ms per `Isolate.run`/`Isolate.spawn` round trip** on this
  machine (see §6.7.3), with the Dart SDK documenting isolate base memory as *"in the order of 30 kb"*
  (`isolate.dart:456-457`). The "1–10 ms / 1–2 MB" figures in circulation are unverified folklore.
  Spawning is therefore cheap; the reasons to use a pool are (a) **state**: compiled lexers, the
  checkpoint table and warm caches stay alive; (b) **cancellation control**: the pool holds the
  `Isolate` handles, `Isolate.run` throws its handle away. **[src/measured]**
* **Handshake protocol**: worker entry point receives a `SendPort` and immediately replies with its own
  `SendPort`; all later messages are `[jobId, kind, payload]` lists (SendPort cannot send a typed record
  with named fields portably, so use `List<Object?>` or a small sendable class since the pool uses
  `Isolate.spawn`, same code). **[src: same-code isolates may send arbitrary objects]**
* **Message protocol, concretely** `[inference]`:
  ```
  enum JobKind { openDocument, parseBlockRange, lexLines, parseMath, search, dispose }
  UI -> worker : [jobId, generation, kind, payload]
  worker -> UI : [jobId, generation, kind, ok, payload | errorString, stackString]
  ```
  with `payload` restricted to `int`/`double`/`String`/`bool`/`null`/`List`/`Map`/`TransferableTypedData`
  so the protocol survives a move to `spawnUri`/web unchanged.
* **`errorsAreFatal: false`** plus `addErrorListener` so one bad regex/self-recursion does not silently
  kill a worker; the pool respawns on worker death by listening to `addOnExitListener`.
* **Deterministic ordering**: the UI isolate must tolerate out-of-order replies. Tag every job with
  `generation`; a reply whose generation < current is discarded. This is the *only* safe cancellation.
* **Do not spawn an isolate in `initState`** — spawn in the app's startup path (or on first use, with
  the first frame already drawn) so the spawn cost is not on the first frame.

### 6.7.6 Minimum transferable representation of a parse result

**Why not an object graph.** A `List<Block>` where `Block` holds `String kind`, `String text`,
`List<Inline>` would, for 10 331 lines / ~20 000 blocks / ~200 000 inline spans:

* allocate ~220 000 Dart objects on the worker, each with a header (~8–16 B) plus fields;
* **deep-copy all of them** through `SendPort.send` (linear time, and the copy runs on the *sender's*
  thread) — the docs literally say *"may have a linear time cost to copy the transitive object graph"*;
* then allocate a second graph on the UI isolate and hold it live, feeding the GC on every frame;
* and any `String` fields are shared (good) but every `List`/object is copied (bad).

Rough order: **≥ 20–40 MB** of live objects and a copy cost plausibly in the tens of milliseconds
**[inference]**. A flat encoding of the same information is ~2–8 MB and moves in O(1).

**Flat buffer design.** One `Uint8List` (or `TransferableTypedData`) with a 64-byte header, then
sections aligned to 4/8 bytes. All offsets are **UTF-8 byte offsets into the source file** (the disk
coordinate system). Read with `ByteData.view(buffer)`.

```
Offset  Size  Field
------  ----  ----------------------------------------------------------------
0x00    4     magic       'NMP1'  (Niman Markdown Parse, v1)
0x04    2     version     u16 format version
0x06    2     flags       u16 (bit0: source is UTF-8 validated, bit1: has BOM, ...)
0x08    4     sourceBytes u32 total source length in bytes
0x0C    4     sourceCrc32 u32 (fast staleness check against the file)
0x10    4     sourceId    u32 (which note/window this buffer describes)
0x14    4     blockCount  u32
0x18    4     inlineCount u32
0x1C    4     attrCount   u32
0x20    4     stringBytes u32 size of the interned-string arena
0x24    4     blocksOff   u32 byte offset of the block table
0x28    4     inlinesOff  u32 byte offset of the inline table
0x2C    4     attrsOff    u32 byte offset of the attribute table
0x30    4     stringsOff  u32 byte offset of the string arena
0x34    4     stringsIdxOff u32 byte offset of the u32 offset table for the arena
0x38    4     lineIndexOff u32 byte offset of the line-start index (u32 per line)
0x3C    4     reserved
------  ----  sections below, each 8-byte aligned ------------------------------

Block table, 20 bytes per block (parallel arrays, not AoS, for cache-friendly scans):
  u32 startByte          // inclusive
  u32 endByte            // exclusive, INCLUDING the trailing newline(s) as in source
  u16 kind               // BlockKind: paragraph, heading(1-6 encoded), fence, listItem,
                         //   blockQuote, table, tableRow, tableCell, hr, htmlBlock,
                         //   mathBlock, footnoteDef, frontmatter
  u16 flags              // bit0 tight, bit1 loose, bit2 task-item, bit3 checked,
                         //   bit4 has-inline-children, bit5 continuation-of-previous
  u16 firstInline        // index into the inline table
  u16 inlineCount
  u8  depth              // list nesting / quote nesting
  u8  langId             // fence language id (interned) or 0
  u32 payloadIndex       // extra per-kind payload (ordered-list number, heading level, ...)

Inline table, 16 bytes per inline span:
  u32 startByte
  u32 endByte
  u32 kindAndFlags       // low 8 bits = InlineKind, high bits = flags (bold, italic,
                         //   code, strike, link, emphasis, math-inline, wikilink,
                         //   placeholder, softbreak, hardbreak, html)
  u16 attrIndex          // index into the attribute table, or 0xFFFF
  u16 blockIndex         // owning block (so a hit-test can go inline -> block in O(1))

Attribute table, 12 bytes per attribute record (link target, image alt/dimensions,
code-fence info string, math source):
  u32 strOffset          // byte offset into the string arena
  u32 strLength
  u32 attrKind           // AttrKind: linkTarget, linkTitle, imageSrc, imageAlt,
                         //   fenceInfo, mathSource, footnoteLabel, rawHtml

String arena: one UTF-8 Uint8List; a parallel Uint32List of (offset) for O(1) lookup by index.

Line index: Uint32List, one entry per source line = byte offset of its first byte.
            Used for O(log n) line<->byte mapping and for the viewport.
```

**Accessors** (UI isolate, zero allocation per read):

```dart
final class ParseBuffer {
  ParseBuffer(this.bytes) : _d = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
  final Uint8List bytes;
  final ByteData _d;

  int blockStart(int i)   => _d.getUint32(blocksOff + i * 20 + 0, Endian.little);
  int blockEnd(int i)     => _d.getUint32(blocksOff + i * 20 + 4, Endian.little);
  int blockKind(int i)    => _d.getUint16(blocksOff + i * 20 + 8, Endian.little);
  int blockFlags(int i)   => _d.getUint16(blocksOff + i * 20 + 10, Endian.little);
  int inlineKind(int i)   => _d.getUint32(inlinesOff + i * 16 + 8, Endian.little) & 0xFF;
  String attrString(int attrIndex) { /* utf8.decode on a sublistView of the arena */ }
  int lineForByte(int b)  { /* binary search over the line index */ }
}
```

Design decisions that matter:

* **Plain arrays, never a `List` of objects.** Prefer parallel `Int32List`/`Uint32List` over an
  `AoS` byte layout where you will scan a column; prefer the packed byte layout above where you will
  mostly index by record. Both are fine; do not mix.
* **Offsets are UTF-8 bytes**, because that is what the file is. Convert to code units per block, lazily,
  only for blocks that contain non-ASCII (`§6.9.10`).
* **The string arena is interned** (fence languages, link URLs repeat heavily). One `Map<int,int>` from
  `hash → arenaOffset` on the worker side; the UI side never hashes.
* **`sourceCrc32`** lets the UI isolate cheaply verify that a buffer still matches the text it is about
  to render, which prevents the nastiest class of bug (rendering a stale parse).
* **Versioning**: the `version` field plus a dev-only `schemaVersion` in the widget state; on mismatch,
  discard and re-parse. Hot reload is the common trigger (`§6.9.7`).
* **Endianness**: write and read explicitly with `Endian.little`; do not rely on the host.
* **Alignment**: keep the `ByteData` views aligned to the record size so the VM can generate unaligned
  load ops safely (they are safe on all of Niman's targets, but explicit offsets are clearer).
* **Lazily read**: never materialise `String`s for the whole document on the UI isolate. The block
  tables are ~20 × 20 000 = 400 KB and the inline table ~16 × 200 000 = 3.2 MB — both trivially
  indexable in place. Only visible blocks get their source sliced into `String`s.

**Total size estimate `[inference]`**: header 64 B + blocks 400 KB + inlines 3.2 MB + attrs (say 40 000
× 12) 480 KB + string arena (say 300 KB) + line index (10 331 × 4) 41 KB ≈ **4.4 MB**. Compare with the
object graph's 20–40 MB and its linear-time copy. If the inline table is the dominant cost, a
space-optimisation is to store only **inline-run boundaries where the style changes** (bold/italic runs
rather than per-character spans) — which for real Markdown roughly halves it.

### 6.7.7 Should parsing live in an isolate while layout stays on the UI thread?

**Yes, and this is the only viable split.** `[inference, grounded in §6.7.4]`

| Work | Isolate? | Why |
|---|---|---|
| File read | ✅ | no `dart:ui`; FUSE round trips on Android (AGENTS.md) |
| UTF-8 validation / BOM strip | ✅ | pure Dart |
| Block + inline parse | ✅ | pure Dart, no `dart:ui` |
| Highlight (initial full pass) | ✅ | pure Dart; 100 ms+ at 200 KB |
| Highlight (incremental, ≤ 3 lines) | either | small enough inline; keep it inline to avoid a round trip per keystroke |
| TeX tokenise + macro expansion → box tree | ✅ | pure Dart |
| TeX box-tree **layout** | ❌ | needs `TextPainter` for glyph runs |
| Markdown/tex → `InlineSpan`/`ui.Paragraph` | ❌ | needs `dart:ui` |
| Word/line boundary queries, caret, selection boxes | ❌ | `Paragraph` methods |
| Diff after an edit | ✅ if > 100 KB, else inline | pure Dart |
| Disk write | ✅ | AGENTS.md rule |

The boundary is the **flat parse buffer** of §6.7.6: it is the narrow waist between "pure Dart, isolate" and
"`dart:ui`, UI thread". Everything above it can be tested with `dart test` and no `flutter_test`; everything
below it must run on the root isolate.

---

## 6.8 A concrete performance budget

### 6.8.1 Frame targets

| Budget | 60 Hz | 120 Hz | Notes |
|---|---|---|---|
| Total frame | 16.67 ms | 8.33 ms | |
| **Our layout+paint budget** | **≤ 8 ms** | **≤ 4 ms** | leave room for the rest of the app |
| Build phase | ≤ 2 ms | ≤ 1 ms | no widget churn per frame |
| Silently-dropped frame | — | — | jank is visible above ~2 dropped frames |

Everything below is sized so that **the sum of same-frame work stays inside the budget**, with overflow
explicitly parked in an isolate or a later frame.

### 6.8.2 The table

**Grounding.** Where a number is `[measured]` it comes from the benchmark harnesses run for this report
(Linux x64, JIT; full tables in `/tmp/niman-research/sub-highlight-isolates.md` §A2/§B6/§B7 and
`/tmp/niman-research/bench/`). Everything else is **[inference]** — an engineering target for a widget
test to assert, not a measured result. UI-thread targets assume a mid-range 2020s Android device in
AOT, which the research pass estimates at **~3–10× slower than this desktop** on parse/lex work
`[inference, explicit]`.

| Scenario | Target | Where the work lives | Test-assertable number |
|---|---|---|---|
| **Cold open, 1 MB / 10 000-line note** | ≤ 250 ms to first frame with content | read file (`Isolate.run`, bytes only) → parse in isolate → first-screen layout on UI thread | first frame ≤ 250 ms |
| — file read | ≤ 30 ms | worker isolate, `dart:io` only (AGENTS.md rule) | — |
| — parse 1 MB of Markdown | ≤ 120 ms desktop / ≤ 600 ms Android | isolate, no `dart:ui`; anchored on **measured 0.18 ms/KB** (`highlight` `markdown`, 934 KB prose = 168.74 ms) `[measured]` | `parseMs` for the 934 KB fixture |
| — highlight a 200 KB code block | ≤ 58 ms desktop / ≤ 400 ms Android | isolate; **measured** `dart` 200 KB = 57.89 ms, `python` = 127.95 ms `[measured]` | `highlightMs` |
| — worst-case lexer input | bounded; no unbounded single call | isolate + a **wall-clock abort** (generation counter + discard) — the `cpp` grammar is O(n²) with no regex timeout | `lexMs < 200` or the job is abandoned |
| — transfer the parse result back | O(1) move | `Isolate.exit` from a one-shot `Isolate.run`: **measured 250.3 µs @ 1 MB** vs 785.1 µs captured, 498.1 µs vs 5 563.4 µs @ 32 MB `[measured]` | `transferUs < 1500` |
| — **first frame** | ≤ 16.7 ms total | UI thread: build the visible ~25 blocks, lay out ≤ 200 KB of text | `frameBuildMs < 8` |
| — first frame blocks laid out | ≤ 40 paragraphs | viewport + 1 viewport of cache | `laidOutParagraphs <= 60` |
| **Per keystroke** | ≤ 4 ms UI-thread work (120 Hz-safe) | splice buffer, re-parse **one block**, re-lay out **one block**, repaint | `keystrokeUiMs < 4` |
| — re-parse | ≤ 1 ms | inline if block < 4 KB, else pooled worker | `reparseMs < 1` for a 2 KB block |
| — re-highlight (code block) | ≤ 0.5 ms amortised | incremental lexer, converges within ≤ 3 lines | `relexedLines <= 3` |
| — full-document work | **0** | never | `fullDocumentScansPerKeystroke == 0` |
| — bytes over the platform channel | **only the changed range** | `enableDeltaModel: true`; whole-value mode ships the entire document per keystroke | `channelPayloadBytes < 4096` |
| **Scroll frame** | ≤ 8 ms (60 Hz) / ≤ 4 ms (120 Hz) | up to 4 new blocks laid out + 1 paint | `newParagraphLayoutsPerScrollFrame <= 6` |
| — paragraph layouts per frame | ≤ 6 | viewport + cacheExtent/blockHeight | `paragraphLayoutsPerFrame <= 6` |
| — estimated-height error | scrollbar within 5 % | height table with running mean | `estimateErrorRatio < 0.05` |
| — highlight re-lex per scrolled frame | 0 (cache hits only) | `LineTokens` cache + checkpoint table | `relexedLinesPerScrollFrame == 0` |
| **Re-layout after an edit above the viewport** | ≤ 1 frame; no visible jump | anchor correction + height-table suffix update | `scrollJumpPx == 0` |
| — height-table update | ≤ 0.5 ms | prefix sums from `dirtyFrom` | `heightTableUpdateMs < 0.5` |
| — blocks re-laid out | only the edited block (+1 for reflow) | per-block keys | `relaidOutBlocks <= 2` |
| **Math re-render (one expression)** | ≤ 2 ms | parse from cache + lay out the box tree | `mathRenderMs < 2` |
| — parse cache hit | ≥ 95 % | hash keyed on source + options | `mathParseCacheHitRatio >= 0.95` |
| — glyph-run shaping per expression | ≤ 8 `TextPainter.layout()` calls | one per leaf glyph run | `textPainterLayoutsPerMathExpr <= 8` |
| **Full visible-screen math** (e.g. 20 expressions visible) | ≤ 16.7 ms | scaled layout cache keyed by size+width | `visibleMathRenderMs < 12` |
| **Memory ceiling** | ≤ 512 MB RSS | see below | `processRssMb < 512` |
| — source text (1 MB note) | 1–2 MB (one-byte string) + 1 MB bytes | `Uint8List` + `String` | `sourceBytes <= 4 MB` |
| — parse result flat buffers | ≤ 8 MB | typed arrays | `parseBufferBytes < 8 MB` |
| — height table (20 k blocks) | 160 KB + 160 KB | `Float64List` ×2 | `heightTableBytes < 512 KB` |
| — paragraph cache (96 entries) | ≤ 40 MB native | LRU with `dispose()` | `paragraphCacheBytes < 48 MB` |
| — highlight token cache | ≤ 8 MB | per-line flat `Int32List` | `highlightCacheBytes < 12 MB` |
| — math parse + layout cache | ≤ 24 MB | LRU; 13 845 spans | `mathCacheBytes < 32 MB` |
| — **no growth while scrolling** | RSS flat over 60 s of scroll | all caches bounded, `dispose()` called | `rssGrowthMbPerMinute < 4` |

### 6.8.3 What must move off-frame or into an isolate

| Work | Verdict |
|---|---|
| Reading the file from disk | **isolate** (`Isolate.run`) — mandated by AGENTS.md; FUSE `statSync` is a round trip on Android |
| Markdown block/inline parsing | **isolate**, always. Pure Dart, no `dart:ui` |
| Syntax highlighting (lexing) | **isolate** for the initial full-document pass; incremental re-lex can be inline if the affected line count is small |
| Math **parsing** (TeX → box tree) | **isolate** |
| Math **layout** (box tree → sized boxes) | **UI thread** — needs `TextPainter` for glyph runs |
| Text **shaping** / `Paragraph.layout` | **UI thread, unavoidable** — `dart:ui` is main-isolate-only ([#41707](https://github.com/flutter/flutter/issues/41707), [#53985](https://github.com/flutter/flutter/issues/53985)) |
| Search / FTS / link resolution | **isolate** or existing drift DB |
| Writing to disk | **isolate** (or debounced on a background job) |
| Diffing the document after an edit | isolate if the diff is over > 100 KB |

### 6.8.4 Numbers a widget test could assert

```dart
testWidgets('cold open budget', (tester) async {
  await tester.pumpWidget(NimanSurface(note: bigNote934kb));
  await tester.pump();                       // first frame
  final first = tester.binding.lastFrameMetrics; // via a test-only frame observer
  expect(first.buildDuration.inMilliseconds, lessThan(8));
  expect(first.layoutDuration.inMilliseconds, lessThan(6));
  expect(surfaceDebugState.paragraphLayoutCount, lessThanOrEqualTo(60));
  expect(surfaceDebugState.parserIsolateSpawned, isTrue);
  expect(surfaceDebugState.uiThreadParseMs, isZero);   // parsing never on the UI thread
});

testWidgets('keystroke is O(block)', (tester) async {
  final before = surfaceDebugState.paragraphLayoutCount;
  await typeChar(tester, 'x');
  await tester.pump();
  expect(surfaceDebugState.paragraphLayoutCount - before, lessThanOrEqualTo(1));
  expect(surfaceDebugState.lastKeystrokeUiMs, lessThan(4));
  expect(surfaceDebugState.fullDocumentScans, isZero);
});

testWidgets('edit above viewport does not move the anchor', (tester) async {
  await tester.scrollUntilVisible(find.text('anchor'), 400);
  final anchorOffsetBefore = tester.getTopLeft(find.text('anchor')).dy;
  await editBlockAboveViewport(insertText: 'x' * 400);   // grows by several lines
  await tester.pumpAndSettle();
  expect(tester.getTopLeft(find.text('anchor')).dy, moreOrLessEquals(anchorOffsetBefore, epsilon: 0.5));
  expect(surfaceDebugState.relaidOutBlockCount, lessThanOrEqualTo(2));
});

testWidgets('every acquired TextPainter is disposed', (tester) async {
  await pumpTheWholeNote(tester);
  expect(TextPainter.debugMaybeDispatchDisposed /* or a counter */, ...);
  // simpler: track our own ParagraphCache length and assert it never exceeds maxEntries
  expect(ParagraphCache.debugLiveParagraphCount, lessThanOrEqualTo(96));
});

testWidgets('bytes are never normalised', (tester) async {
  const src = '# a\r\n\r\nline with  trailing  spaces\r\nno final newline';
  final out = await roundTripThroughEditor(src);
  expect(out, src);
});
```

---

## 6.9 Traps and known Flutter pitfalls

### 6.9.1 `TextPainter` caching invalidation

* **A colour-only `TextStyle` change still forces a full re-shape**, because `_rebuildParagraphForPaint`
  moves the rebuild into `paint()` and there is no partial-update API
  (`text_painter.dart:750-754`, `:1335-1352`; framework comment "there's no API to only make those
  updates"). Related: [flutter#85108](https://github.com/flutter/flutter/issues/85108). **Never bake
  selection/search colours into the `TextStyle`.** Paint them behind the glyphs. **[src, doc]**
* `text =` with an *equal but not identical* span tree is fine (`InlineSpan.compareTo` decides), but
  `text =` with a *new object* that compares `RenderComparison.layout` is a full invalidation. Cache
  the `InlineSpan` per block and only rebuild it when the block's content hash changes. **[src]**
* `systemFontsDidChange()` (font fallback list changed, e.g. a CJK font became available) invalidates
  **every** paragraph. Expect a one-off global re-layout after a font loads. **[src :885-887]**
* `textWidthBasis` does **not** call `markNeedsLayout`; it only sets a debug flag and relies on
  `_resizeToFit` to notice. If you swap it, call `layout()` again or your `width` will be stale.
  **[src :1013-1022]**
* `TextPainter.dispose()` is mandatory. Paragraphs are native objects. An LRU without `dispose()` on
  eviction leaks until the engine finalises them, and the process RSS grows. **[src, doc]**

### 6.9.2 `Paragraph` garbage

* Every `layout()` after a non-paint invalidation allocates a **new native `Paragraph`** and the old
  one must be disposed. This is the single biggest source of memory growth in a naive implementation:
  re-creating a `TextPainter` per build is a per-frame native allocation. **[src]**
* Do not hold `ui.Paragraph` objects beyond their painter's life; `_TextLayout._paragraph` is
  reassigned in place by `TextPainter.paint()` and the previous instance is disposed explicitly
  (`:1347-1350`). Copying that pattern is fine; forgetting the dispose is not.
* `TextPainter` also caches a `_layoutTemplate` paragraph (one space) — it is disposed on
  `text =` style change, `textDirection =`, and `dispose()`. Holding thousands of painters therefore
  holds thousands of template paragraphs too. Another argument for a small LRU. **[src]**

### 6.9.3 `WidgetSpan` breaks selection and `getBoxesForSelection`

* A `WidgetSpan` contributes exactly one code unit (`U+FFFC`, `PlaceholderSpan.placeholderCodeUnit`) to
  the paragraph's plain text, regardless of the source it represents. Selection offsets inside the
  paragraph therefore **do not equal source offsets** once a placeholder is present. **[src]**
* `getBoxesForSelection` returns the whole placeholder box for that one code unit; partially selecting
  "around" a widget is not expressible. **[src]**
* `WidgetSpan` creates a real element and a semantics node (`requiresOwnNode == true` for
  placeholders, `inline_span.dart:82`), so it costs a widget, a `BuildContext`, and semantics churn —
  and it must be re-measured (`layoutInlineChildren`) on every `performLayout`.
* **Mitigation:** keep an explicit offset ledger alongside the `InlineSpan`,
  `List<({int paraOffset, int srcStart, int srcEnd, WidgetSpan span})>`, and translate selection/
  caret offsets through it. For anything you can draw (checkbox, inline math, footnote marker),
  prefer a drawn marker plus a zero-width or fixed-width `TextSpan` over a `WidgetSpan`. **[inference]**

### 6.9.4 `RepaintBoundary` misuse

* One boundary per block × 20 000 blocks = thousands of layers and pictures; memory and compositing
  cost dominate. Use boundaries only for: the whole surface, the caret, a blinking cursor region, a
  hovered/edited block, and any animated decoration. **[inference]**
* `SliverChildBuilderDelegate.addRepaintBoundaries` defaults to `true` (`scroll_delegate.dart:363`) —
  turn it off for a document list and add boundaries selectively. **[src]**
* `CustomPainter(repaint: listenable)` is the *cheap* invalidation path (no rebuild, no element churn)
  — use it for selection drag and caret blink instead of `setState`. **[src]**

### 6.9.5 `AutomaticKeepAlive`, `keepScrollOffset`

* `AutomaticKeepAlive` keeps a child's `State` alive off-screen. For a Markdown document with
  per-block `StatefulWidget`s, that is a memory leak by design: every scrolled-past block's state
  stays. Keep blocks stateless; keep state in the block *model*. `addAutomaticKeepAlives: false` for
  the document sliver. **[inference]**
* `PageStorage`/`keepScrollOffset` restore a saved scroll offset on rebuild. In an editor with
  incremental layout, restoring a raw pixel offset without re-running the anchor correction means the
  caret can land in the wrong block after a hot reload or a note switch. Save
  `(blockIndex, deltaInBlock)` in `PageStorage`, not `pixels`. **[inference]**

### 6.9.6 `ScrollController` jumps

* `jumpTo`/`animateTo` notify listeners and can re-enter a `ScrollNotification` handler that triggers
  another jump. For internal, non-user-initiated correction use
  `ScrollPosition.correctPixels(value)` + `applyContentDimensions(min, max)` (what `RenderSliverList`
  itself does via `scrollOffsetCorrection`). Guard any `jumpTo` with a re-entrancy flag and schedule it
  post-frame. **[inference]**
* `ScrollController` must be created in `initState` and disposed in `dispose`; reading
  `controller.position` before attach throws. **[doc]**

### 6.9.7 Hot reload state

* Hot reload keeps `State` objects but re-runs `build`. Our `ParagraphCache` lives in a `State` or a
  `RenderObject` — after a hot reload its keys may no longer match the new code's model (e.g. an
  interned style id changed meaning). Add a **schema/version int to the cache key** and to the flat
  parse buffer, and bump it in development when the model changes, so a hot reload invalidates instead
  of silently painting stale content. **[inference]**
* The isolate pool survives a hot reload with old code loaded. Kill and respawn the pool on
  `reassemble` (`WidgetsBindingObserver.reassemble`). **[inference]**

### 6.9.8 `LayoutBuilder` over-use

* `LayoutBuilder` performs a *subtree build* during layout. Nesting it (or using it per block) forces
  an extra build phase per block per frame, and it cannot be used where the parent needs intrinsics.
  One `LayoutBuilder` at the top of the surface to learn the width is fine; 20 000 is a disaster.
  Prefer passing the width down from the render object. **[inference, standard]**

### 6.9.9 The cost of `MediaQuery.of`

* `MediaQuery.of(context)` registers a dependency: **any** `MediaQueryData` change (including
  `viewInsets` during a keyboard animation, or `padding` when a system bar moves) rebuilds the
  dependent. Use the narrow accessors — `MediaQuery.textScalerOf(context)`
  (`media_query.dart:1774`), `MediaQuery.devicePixelRatioOf`, `MediaQuery.sizeOf`,
  `MediaQuery.paddingOf`, `MediaQuery.viewInsetsOf` — and read them **once** at the top of the surface,
  not in each block builder. `MediaQuery.maybeOf` (`:1611`) avoids the assert when there is no
  `MediaQuery`. **[src]**
* Because `textScaler` is in the paragraph cache key, a keyboard animation that changes
  `MediaQueryData` but not `textScaler` must **not** drop the paragraph cache. Key on the *value*, not
  on the inherited widget. **[inference]**

### 6.9.10 Unicode offsets: bytes vs UTF-16 code units vs grapheme clusters

This is the most dangerous correctness area, because Niman's invariant is "never lose or normalise the
user's bytes".

* **Dart `String` is a sequence of UTF-16 code units.** `s.length` is code units; `s[0]` is a
  code unit (`String` implements code-unit indexing). `s.runes` iterates code points;
  `s.characters` (package `characters`) iterates **grapheme clusters**. **[doc]**
* **Everything in Flutter's text API is in UTF-16 code units**: `TextPosition.offset`,
  `TextRange.start/end`, `TextSelection.baseOffset/extentOffset`, `InlineSpan` offsets,
  `getPositionForOffset` results, `GlyphInfo.graphemeClusterCodeUnitRange`, and — critically —
  `TextEditingDelta` offsets (`TextEditingDeltaInsertion.insertionOffset`,
  `TextEditingDeltaDeletion.deletedRange`, `TextEditingDeltaReplacement.replacedRange`). **[src/doc]**
* **File bytes are UTF-8**, so byte offsets ≠ code-unit offsets ≠ code-point offsets ≠ grapheme offsets
  for any non-ASCII text. A 934 KB UTF-8 file of mostly ASCII is ~934 000 bytes and ~934 000 code units;
  add a few thousand CJK characters and the byte count grows 3× while the code-unit count grows 1×.
  **Pick one canonical coordinate system and convert at exactly one boundary.**
  Recommendation: **UTF-8 byte offsets are the disk/public coordinate system; UTF-16 code-unit offsets
  are the in-memory paragraph coordinate system.** Keep a conversion map only for blocks containing
  non-ASCII. **[inference]**
* **Never split a surrogate pair or a grapheme cluster.** A caret "one character left" at a position
  inside `👍` (`U+1F44D` = 2 code units) or inside `e` + combining acute is a corruption risk when you
  write back. For movement, use `characters` (grapheme clusters) for *visual* motion and
  `TextPainter.wordBoundaries` (`text_painter.dart:1745`, backed by UAX #29) for word motion. **[src/doc]**
* **Do not normalise.** NFC/NFD changes bytes. The editor must round-trip the exact byte sequence,
  including `\r\n`, trailing whitespace, and a missing final newline. Parse on a *copy*; write the
  original slice back. BOM handling: strip a leading `EF BB BF` for parsing, and preserve it on write.
  **[inference — but the invariant is from the task]**
* Dart's `String.replaceRange(start, end, replacement)` is in code units; `String.substring` likewise.
  For the flat-buffer design, carry **byte** offsets and convert per block.

### 6.9.11 RTL / bidi

* `TextPainter.textDirection` resolves `TextAlign.start/end` and sets the paragraph's base direction;
  bidi reordering is done by the shaper and is **not** reflected in `TextPosition.offset` (which stays
  logical). **[src/doc]**
* `getBoxesForSelection` returns one `TextBox` per bidi run, each with its own `direction`
  (`ui.TextBox.direction`, `ui/text.dart:456`). A selection highlight must be drawn per box, not as one
  rect, or an RTL/LTR mixed line gets a wrong rectangle. **[src]**
* The caret must be placed on the correct side: `_LineCaretMetrics.writingDirection` decides whether
  the caret draws to the left or the right of the returned offset (`text_painter.dart:534-561`,
  `getOffsetForCaret` `:1447`). Reimplementing the caret means reimplementing this. **[src]**
* `TextAlign.justify` with mixed bidi and no bidi algorithm at the block level produces oddly stretched
  lines; consider `TextAlign.start` for RTL and only justify when the block is single-direction.
  **[inference]**
* For a Markdown document, the **base direction of a block** should come from the first strong
  directional character of the block, not from the app locale, or English quotes inside an Arabic note
  will render backwards. `Directionality.of(context)` is the fallback only. **[inference]**

### 6.9.12 Accessibility: `Semantics` for a custom text surface

* If you paint text yourself, **you own the semantics**. `CustomPainter.semanticsBuilder` /
  `shouldRebuildSemantics` (`custom_paint.dart:222`, `:244`) are the hooks; the `CustomPainterSemantics`
  list you return becomes `SemanticsNode`s with `rect`, `properties`, `transform`, `tags`/`key`. **[src]**
* Minimum viable: one `SemanticsNode` per block with
  `SemanticsProperties(label: block.plainText, textDirection: ..., sortKey: OrdinalSortKey(index))`,
  plus `SemanticsFlag.isReadOnly`/`isTextField` on the editable surface, plus a
  `SemanticsAction.setSelection`/`setText` handler so screen readers can move the caret. `RenderEditable`
  is the reference: it publishes an `AttributedString` label, a `TextSelection` semantic range, and
  computed accessibility rects from `getBoxesForSelection` (`rendering/editable.dart:1330-1500`). **[src]**
* `Semantics(onTap:)`/`SemanticsAction.tap` on a link; `SemanticsFlag.isLink` for links. **[doc]**
* Do **not** rebuild semantics every frame — `shouldRebuildSemantics` defaults to `shouldRepaint`, so a
  `shouldRepaint => true` is also a semantics rebuild. Use an explicit content hash. **[src :244]**
* Screen-reader traversal of 20 000 blocks is a problem: expose semantics only for the *visible*
  window plus a coarse "document" node, or a reader will try to build the whole tree. This is exactly
  why `SliverList` only builds semantics for laid-out children. **[inference]**

### 6.9.13 Other traps worth naming

* **`FutureBuilder`/`StreamBuilder` per block** re-runs the future on every rebuild that changes
  identity — a classic jank source. Keep async state in the model.
* **`Opacity`/`ClipRRect` over the whole surface** forces a saveLayer. Snap borders instead; clip only
  the visible window.
* **`Image.network` inside a scroll** fights the viewport for bandwidth and decodes on the UI thread
  (use `cacheWidth`/`cacheHeight` and a decode isolate; Flutter already decodes images off-thread).
* **`ShaderMask`/`BackdropFilter`** are per-frame saveLayer costs; never per block.
* **`GestureDetector` per block** creates a recogniser arena entry per block. One
  `RawGestureDetector`/`Listener` at the surface with hit-test routing is far cheaper.
* **`TextEditingValue` equality** — `TextEditingValue` has value equality over the whole text, so
  comparing the full value on every delta is O(document). Compare only the changed range. **[inference]**
* **`Scrollable`'s `ScrollPosition` is not `pixels` alone** — `applyViewportDimension` and
  `applyContentDimensions` must both be called in the right order before a corrected `pixels` is
  meaningful, or the position clamps to a stale max.
* **`WidgetsBinding.instance.addPostFrameCallback`** runs after layout but before paint of the next
  frame; using it to correct scroll produces a one-frame visual jump. Prefer correcting inside layout
  (the `scrollOffsetCorrection` mechanism).

---

## 6.10 Suggested module layout for the new widget

Following AGENTS.md (`lib/src/<module>/`, one class per file, ~300-line cap):

```
lib/src/editor/
  model/          document buffer (Uint8List + String), block index, offsets ledger, height table
  parse/          block+inline parser -> flat typed-array token stream  (isolate-safe, no dart:ui)
  highlight/      incremental stream lexer, State per line, checkpoint table
  math/           TeX tokeniser + box-tree layout + TextPainter glyph runs + paint cache
  layout/         ParagraphCache, ParagraphKey, per-block layout records
  paint/          surface painter, furniture painter, caret painter, selection painter
  input/          TextInputClient/DeltaTextInputClient, Shortcuts/Actions intents, gesture routing
  isolate/        IsolatePool, job protocol, TransferableTypedData codecs
  view/           the public widget, Scrollable wiring, anchor correction
```

---

## 6.11 Source index (for follow-up reading)

Local, authoritative:

* `/home/alessandro/develop/flutter/packages/flutter/lib/src/painting/text_painter.dart` (1849 lines)
* `/home/alessandro/develop/flutter/packages/flutter/lib/src/painting/text_span.dart`,
  `inline_span.dart`, `placeholder_span.dart`, `text_style.dart`, `strut_style.dart`, `text_scaler.dart`
* `/home/alessandro/develop/flutter/packages/flutter/lib/src/rendering/paragraph.dart` (3697),
  `editable.dart` (3156), `custom_paint.dart`, `sliver_list.dart`, `sliver_fixed_extent_list.dart`,
  `sliver_multi_box_adaptor.dart`
* `/home/alessandro/develop/flutter/packages/flutter/lib/src/services/text_input.dart` (3415),
  `text_editing_delta.dart` (515), `hardware_keyboard.dart`
* `/home/alessandro/develop/flutter/packages/flutter/lib/src/widgets/editable_text.dart` (6963),
  `scroll_delegate.dart`, `sliver.dart`, `text_selection.dart`, `selectable_region.dart`,
  `focus_manager.dart`, `shortcuts.dart`, `actions.dart`, `media_query.dart`
* `/home/alessandro/develop/flutter/engine/src/flutter/lib/ui/text.dart` (FontFeature:203,
  TextHeightBehavior:1473, TextLeadingDistribution:1431, TextStyle:1727; FontFeature named ctors
  around :220-956)
* `/home/alessandro/develop/flutter/bin/cache/flutter_web_sdk/lib/ui/text.dart` (TextRange:618,
  TextBox:462, PlaceholderAlignment:14, LineMetrics:603, BoxHeightStyle:587, GlyphInfo:192)

Companion research produced for this report (same directory, kept as provenance for the measured
numbers — **not** deliverables, but the full tables and harness notes live there):

* `/tmp/niman-research/sub-highlight-isolates.md` (2 832 lines) — the `highlight`-0.7.0 measurements
  (§A2), the CodeMirror CM5/CM6 API capture and Dart port spec (§A3), the isolate API/transfer
  matrix/spawn-cost/pool measurements (§B5–B10), and the flat-buffer format.
* `/tmp/niman-research/sub-math.md` (1 947 lines, 103 cited URLs, sections 0–9 + a primary-sources
  appendix) — the `flutter_math_fork` / `katex_dart` / `katex` architecture read (shallow clones of
  `simpleclub/flutter_math@75a6f61`, `orestesgaolin/katex@fdb0a3d`, `KaTeX@726c2d4`), the `tftopl` and
  `tex.web` constant measurements, the Skia/HarfBuzz/Blink MATH investigation, the AOSP font audit, the
  missing-glyph investigation, and the caching + `CustomPainter` patterns. Supporting reports:
  `/tmp/niman-scratch/{math-table,fonts-platforms,missing-glyph,tex-constants,issues-mining}.md`.
* `/tmp/niman-research/bench/` — throwaway plain-`dart` harnesses used for the measurements above.

External (all treated as untrusted data):

* [flutter#41707 — Text layout without blocking the UI](https://github.com/flutter/flutter/issues/41707) (closed as not planned)
* [flutter#53985 — ParagraphBuilder/Paragraph in other isolates](https://github.com/flutter/flutter/issues/53985)
* [flutter#13343](https://github.com/flutter/flutter/issues/13343) / [#30604](https://github.com/flutter/flutter/issues/30604) — background text layout
* [flutter#92173 — paragraph.layout() seems very expensive](https://github.com/flutter/flutter/issues/92173)
* [flutter#85108 — colour change forces paragraph rebuild](https://github.com/flutter/flutter/issues/85108)
* [simpleclub/flutter_math#120 — infinite constraints with \frac and \sqrt](https://github.com/simpleclub/flutter_math/issues/120)
* [simpleclub/flutter_math#110 — RenderObjectWithLayoutCallbackMixin removed](https://github.com/simpleclub/flutter_math/issues/110)
* [simpleclub/flutter_math#118](https://github.com/simpleclub/flutter_math/issues/118) / [#123](https://github.com/simpleclub/flutter_math/issues/123) — RTL/Bengali shaping
* [dart-lang/sdk#61284 — no regex timeout](https://github.com/dart-lang/sdk/issues/61284)
* [re_editor#2](https://github.com/reqable/re-editor/issues/2) / [#102](https://github.com/reqable/re-editor/issues/102) — "does not cache the results"
* [TextPainter API docs](https://api.flutter.dev/flutter/painting/TextPainter-class.html)
* [RenderEditable API docs](https://api.flutter.dev/flutter/rendering/RenderEditable-class.html)
* [TextInputConfiguration.enableDeltaModel](https://api.flutter.dev/flutter/services/TextInputConfiguration/enableDeltaModel.html)
* [TextEditingDelta API docs](https://api.flutter.dev/flutter/services/TextEditingDelta-class.html)
* [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)
* [Flutter isolates](https://docs.flutter.dev/perf/isolates) / [Dart concurrency](https://dart.dev/language/concurrency)
* [OpenType MATH table spec](https://learn.microsoft.com/en-us/typography/opentype/spec/math)
* [CodeMirror 5 manual, `#modeapi`](https://codemirror.net/5/doc/manual.html) / [CodeMirror 6 language reference](https://codemirror.net/docs/ref/#language.StreamParser)


---

# 7. Prior art: what to steal

Scope: mine ideas, algorithms and architectures for a **brand-new** Markdown
editor+preview surface in Flutter/Dart. No package is adopted, so this is about
*how things are built*, and for every mechanism the Flutter/Dart equivalent
that would have to exist.

Read against `docs/dev/editor-alternatives.md`, which measured six Flutter
packages and rejected them. Its numbers are treated as given and never
contradicted here without saying so:

| measured on the incumbent (`re_editor` + `highlighting.dart`) | value |
|---|---|
| cold tokenize, 200 KB | 23.95 ms |
| **incremental mid-buffer edit** | **0.507 ms** |
| line layout + paint | 44.7 µs/line (visible only) |
| whole buffer as one span | 52.0 ms |

The 0.507 ms `O(change)` keystroke is the bar. Every candidate lost on it
(`live_markdown_editor`: 422.4 ms at 200 KB, clean `O(n)`;
`flutter_smooth_markdown` editor: 72.2 ms keystroke).

**Target document** (`Geometria 1.md`, 934 769 B / 10 331 lines):
**1682 display-math lines**, 1121 `\begin{pmatrix}`, 114 `\begin{cases}`,
103 `\begin{aligned}`, 45 `\begin{vmatrix}`, 1894 `\phi`, 1877 `\mathbf`,
1394 `\begin`/`\end`, 84 headings, 40 wikilinks, 1 Markdown link, **0 code
fences**, ~90 chars/line. A *math-dense, prose-light, link-light* document.
That inverts the usual priorities: windowing, link parsing and highlighting are
cheap at this scale; **TeX typesetting cost and height estimation for math
blocks are the two things that decide whether it feels fast.**

---

## 7.1 The three candidate architectures

(c) is a superset of (a): both keep the text authoritative and differ only in
whether the projection is a flat decoration set or a real span tree. That
distinction is the whole game, so it is called out below.

### (a) Source-of-truth + decoration — "live preview"

**Authority:** the Markdown string. **Representation:** buffer +
`List<Decoration>` of `(range, style | hidden | replacementWidget)`.
**Parse:** recompute decorations for the changed region. **Render:** a text
engine draws the buffer applying decorations.

| system | buffer | decorations | edit model |
|---|---|---|---|
| **Obsidian Live Preview** | CM6 `Text` rope | CM6 `DecorationSet` (`MarkDecoration` style, `Decoration.replace` hide, `WidgetType` tables/math/images) | CM6 `Transaction` |
| **Typora** | `contenteditable` DOM | class spans + CSS; `display:none` on markers | DOM mutations + undo stack |
| **iA Writer** | plain text | *highlighting only* — no hiding | trivial |
| **Bear** | `NSTextView` | `NSAttributedString`, **dimmed not hidden** (Bear 2 has a "Hide Markdown" setting, off by default) | TextKit `edited(_:range:changeInLength:)` |
| **MarkText "muya"** | block list, Markdown-authored | block records (JSON) with `ot-json1` + `ot-text-unicode` ops composed per frame; content serialized from vnodes to `innerHTML` (**not** a snabbdom content diff) | block-level OT |
| **Zettlr** | CM6 `Text` | CM6 `Decoration` over the Lezer tree, per visible range | CM6 `Transaction` |
| **Niman source editor today** | `re_editor` line list | `HighlightDocument` tokens → `TextSpan` | `replaceLines(first, removed, replacement)` |

**The decoration set is the interesting structure, not the buffer.** CM6's
`DecorationSet` is a `RangeSet<Decoration>`: an **immutable, chunked, sorted,
persistent** range set (`ChunkSize = 250`, chunks shared by reference through
`map`), with `RangeSetBuilder` for ordered appends (which *throws* on
out-of-order adds) and `RangeSet.compare` to diff two sets through an edit.
`between(from, to, f)` costs `O(chunks + log chunk)`. **Flutter has no
equivalent; it is the single most valuable thing to build.** Note the cost
model: `map` reuses untouched chunks by reference, but the lookup cursor walks
chunk positions forward, so a full-document set is `O(n/250)`, not
`O(log n)` — chunking buys sharing and locality, not a global index.

**Syntax hiding.** Markers are never removed. A plugin computes, for each
visible range, which marker ranges to hide, from (i) the parse tree and
(ii) the selection. Obsidian's rule is roughly "hide the markers of the
formatting that *covers* the cursor; show them otherwise", rebuilt whenever
`docChanged || selectionSet || viewportChanged`. Typora mutates the DOM and
keeps a shadow copy of the source. **Architectural constraint for Niman (from
CM6):** only decorations provided *directly* (not as functions) may influence
layout — `viewstate.ts`'s `staticDeco(state)` filters out functions before
feeding `HeightMap.applyChanges`. Since a `ViewPlugin`'s decorations are
*always* registered as a function, **anything that changes height must live in
a `StateField`, not a view plugin.** Obsidian's own concealment plugin notes the
same from the other side: "the approach based on StateField and updateListener
conflicts with obsidian's internal logic and causes weird rendering", so it uses
a stateful ViewPlugin instead.

**What breaks at 1 MB.** Nothing structural (rope edits `O(log n)`, decorations
rebuilt only for `visibleRanges`). The breaking is interaction, and severe:

1. **Caret/offset mapping.** If markers are hidden with `fontSize: 0` /
   zero-width spans, the caret still has a source offset. Arrows walk invisible
   characters; backspace eats one `*` of a `**` pair and text re-parses as
   italic mid-correction; selection paints a zero-width rect. This is exactly
   what `editor-alternatives.md` recorded for `markdown_editor_live` 0.6.0
   ("compensates the caret nowhere"). The fix is not in the buffer: it is a
   **position-mapping layer** (§4) plus a key-intent layer.
2. **Click mapping.** Display x → source offset is the inverse of the
   decoration map; with hidden ranges, rendered and source are two spaces.
   Obsidian's changelog has fixed this repeatedly ("click position detection to
   misbehave"; "clicking or selecting the end of the file selects to the
   beginning when there is a block at the end").
3. **Height coupling.** Hiding a marker changes width, hence wrap, hence
   height. Height becomes a function of the *selection*, so one arrow key can
   change document height and move everything below it. This is live preview's
   largest jank source and the most-reported Obsidian complaint ("when the
   editor toggles between showing and hiding Markdown syntax, the lines shift
   and the cursor jumps").

**Lesson.** Keep the buffer authoritative; never mutate it for display. Make the
projection a *replaceable value* recomputed per visible range, and make
caret/selection a *mapped* quantity the moment hidden ranges exist.

### (b) Block tree document model — ProseMirror / Lexical / Notion

**Authority:** a parsed tree; Markdown is an import/export format.
**Representation:** `Node(type, attrs, marks, content: Fragment)` (PM) or
keyed linked-list nodes (Lexical) or `Block{id, type, props, children}`
(Notion/Logseq). **Parse:** none — the tree *is* the parse; reconciliation is
incremental. **Render:** a view mirroring the tree (`ViewDesc`/tile tree ↔ DOM;
`$reconcile*` ↔ DOM; block components).

| system | node model | positions | save path |
|---|---|---|---|
| **ProseMirror** | persistent `Node` + `Fragment`; doc is one `Node` | integer position space; `ResolvedPos` walks the tree | lossy `toDOM`/`fromDOM`, or a custom Markdown serializer |
| **Lexical** | `ElementNode` with `__first/__last/__prev/__next`, keyed by `NodeKey` | `NodeKey` + offset | `@lexical/markdown` transformers — **explicitly lossy** |
| **Notion** | block records with stable ids; per-block `contenteditable` | block id + offset | no Markdown source of truth |
| **Logseq** | outliner blocks (ClojureScript `Outliner` core) | block uuid | Markdown on disk, blocks joined; the DB version moved canonically to SQLite |
| **Craft** | block-based rich model | block + range | export only |

ProseMirror's `Fragment` is an immutable node array with `size` in *position
units*: a text node of 5 chars has `nodeSize == 5`, every non-leaf costs
**2 + content.size** (one token to enter, one to leave) — the source of the
notorious "off by two". `ResolvedPos` caches a flat `path` of
`(node, index, absoluteStart)` triples and binary-searches down on
`doc.resolve(pos)`; `$pos.textOffset` exists because a text node is one `Node`
holding many chars, so a position inside it is not a tree position. **Any
tree-with-text-nodes design hits this.** Lexical instead gives every node a
random `NodeKey`, keeps `EditorState._nodeMap: Map<NodeKey, LexicalNode>`,
links children doubly, and stamps `__lexicalKey_<editorKey>` on the DOM node so
`$getNodeByKey` is O(1).

**Serialization loss.** Both are lossy: `**bold**`/`__bold__`/`*ital*`/`_ital_`
collapse to one mark and the serializer picks one; whitespace and escaping
differ; reference links, footnotes, frontmatter, wikilinks and raw HTML need
custom transformers that silently drop what they don't know. For an app whose
rule is **"disk is source of truth: store nothing that can't be reconstructed
from disk"**, that is a correctness problem, not a performance problem: every
save can rewrite a note the user did not edit. Niman already pays a version:
`markdown_document_codec.dart` (~496 lines) + `markdown_blocks.dart` (152) +
opaque embeds for tables/math/wikilinks/footnotes/frontmatter — and the Quill
surface caps at 200 KB *because Quill is not cheap either* (recorded as still
unmeasured).

**What breaks at 1 MB.** The tree itself is fine. What breaks: the round-trip
codec is `O(document)` per save and per open; position arithmetic runs per
keystroke per decorated node; undo is a stack of `Transform`s whose inverse
mappings grow with history.

**Lesson.** Steal the *editing* ergonomics — `Step`/`Mapping`/`ResolvedPos` is
the cleanest architecture for structural edits (split a list item, renumber,
move a block). Do not steal "tree is the truth".

### (c) Hybrid / piece table + incremental parse — VS Code / CodeMirror 6

**Authority:** a persistent text buffer. **Representation:** (1) the buffer,
(2) an incremental parser producing a tree with `[from, to)` spans,
(3) a viewport-driven renderer of that tree, (4) a height index answering "what
is the y of offset X" without laying anything out.

| system | buffer | parse | render |
|---|---|---|---|
| **VS Code / Monaco** | `PieceTreeTextBuffer` — **red-black tree of pieces** over two immutable buffers (original file + "additions" scratch), each node `{bufferIndex, start, end, lineFeedCnt, length}`, with `StringBuffer.lineStarts` inside each piece | TextMate + `vscode-textmate`, lazy per line, cached; semantic tokens from LSP layered later | `ViewLines` renders only `getVisibleRanges()`; `LinesLayout`/`LineHeightsManager` model wrap; whitespace zones inject widgets |
| **CodeMirror 6** | `Text` rope (`TextLeaf`/`TextNode`, 32-line leaves) | **Lezer** LR parse into a persistent `Tree`, seeded by `TreeFragment`s | tile/desc DOM mirror; decorations only for `visibleRanges` |
| **tree-sitter editors** (Atom, Neovim, Zed, Helix) | rope / gap buffer | tree-sitter GLR with `ts_tree_edit` | query-driven highlight over visible ranges |
| **Zettlr** | CM6 `Text` | CM6 `@lezer/markdown` (not a full CommonMark+GFM parse) | CM6 decorations; remark/rehype for export |

**Why this is right for Niman.** It preserves what makes the incumbent fast and
correct — buffer is a plain string, saving is a write, no invented information
— and adds a structural parse with spans, while keeping the 0.507 ms property
because all four levels are independently incremental.

**VS Code piece table, concretely.** Red-black tree; two buffers so an edit
*never* copies: it splits a piece and inserts a reference into the additions
buffer. `getLineContent(n)` walks `lf_left`/`size_left` and then
`buffer.substring(...)` — line text is *derived*, never materialised per line,
which is why a 10k-line file has no line array. `getOffsetAt`/`getPositionAt`
are `O(log n)` descents with a one-entry search cache. `applyEdits` sorts
ascending, checks overlap, reduces ≥1000 ops to one, computes inverse ranges,
then applies **descending** so earlier offsets stay valid. Wrapping is a
per-model-line projection (`ModelLineProjectionData`, `breakOffsets`) indexed by
a `ConstantTimePrefixSumComputer` over *wrapped-line counts* — the same
prefix-sum shape as a height index.

**What breaks at 1 MB — honest table:**

| operation | complexity | at 10 331 lines / 934 KB |
|---|---|---|
| rope `lineAt`/`slice`/`replace` | O(log n) | microseconds |
| `Text.of(allLines)` at open | O(n) | ~1–3 ms |
| full parse from scratch | O(n) | Lezer markdown ~30–60 ms; cmark ~40 ms; `markdown` pkg measured **390 ms** here (378 ms of it inlines) |
| incremental reparse | O(change + context) | sub-ms if fragment reuse works |
| decoration build | O(visible) | < 1 ms |
| height map update | O(log n + changed) | microseconds |
| **layout of a table/math block** | O(block) | **what will actually jank** |

At 1 MB no level of the stack is the bottleneck except TeX typesetting and
image decode. The architecture exists to keep it that way.

### Comparison table

| | (a) source + decoration | (b) block tree | (c) hybrid rope + spans |
|---|---|---|---|
| authority | Markdown string | parsed node tree | Markdown string + derived span tree |
| save path | write buffer | serialize tree (**lossy**) | write buffer |
| round-trip fidelity | total | needs a custom codec | total |
| incremental unit | changed lines → decorations | `Step`/`Transform` on the tree | `ChangeSet` → fragments → reparse |
| position model | raw offsets (+ hacks) | position space + `ResolvedPos` | offsets mapped by `ChangeDesc.map` |
| incremental parse | none needed (tokens only) | none needed (tree is truth) | **required** (Lezer / hand-written) |
| viewport rendering | sliver over blocks/lines | virtualized block list | sliver over blocks/lines |
| height stability under edits | weak (selection changes height) | good (block extents) | good (HeightMap + anchors) |
| rich editing (tables, reorder) | hard | easy | medium (needs a `Step` layer) |
| new machinery to build | decoration map, hidden-range keys, click map | node schema, lossy codec, undo mapping | rope, span tree, incremental parser, height index |
| fits "disk is source of truth" | **yes** | **no** | **yes** |
| precedent at scale | Obsidian, Typora, Bear | Notion, ProseMirror apps | VS Code, CM6, Zed |

### Recommendation

**(c), with a line-indexed rope (or even the existing `re_editor` line list)
and a *minimal* span tree rather than a full CommonMark AST.**

1. **Buffer = source of truth**, persisted as bytes. Never derive saved text
   from the tree.
2. **A block-scanning incremental parser** (§3) producing
   `Block{kind, from, to, children?}` with source spans — *not* a full inline
   AST. Inline spans per block, on demand, exactly as
   `preview/block_parse.dart` already does (`withInlines`, ~0.1 ms/block).
3. **A decoration/projection layer** for visible blocks only.
4. **A position-mapping layer** (`ChangeSet`/`Mapping`, §4) between the caret
   and the source offset whenever markers are hidden.
5. **A height index** from CM6's `HeightMap` (§2.10) — `ScrollMap` is already
   80 % of it. The decisive property to copy: **loading a 10 MB document costs
   one `HeightMapGap` node, not one node per line** — the whole un-laid-out
   document is a single estimated gap, and only the viewport is measured.
6. **A `Step`-like command layer** for structural edits that are painful on raw
   text (list renumbering, table row insert, heading level change, block move).
   `editor/list_tally_edit.dart` already does this for lists; generalise the
   idea, do not build a ProseMirror.

This gets (a)'s fidelity, (b)'s editing ergonomics where they pay, (c)'s
complexity class.

---

## 7.2 CodeMirror 6, mechanism by mechanism

CM6 is the most relevant prior art: the only mainstream editor whose entire
design is "the document is a string, everything else is an incremental
projection". The package split *is* the architecture — `@codemirror/state`
(`Text`, `ChangeSet`, `EditorState`, `Transaction`, `Facet`, `StateField`,
`RangeSet`; no DOM), `@codemirror/view` (view, decorations, heightmap),
`@codemirror/language` (parser plumbing), `@lezer/common`+`@lezer/lr`.

The key discipline: **a state update is pure and does not touch the DOM.** That
is why CM6 can compute a new state per keystroke, in a worker, or in a test,
without a layout pass. Flutter equivalent: an immutable `EditorState` value plus
a pure reducer, split from the widget that paints it, so a keystroke never
`setState`s the widget that owns the text.

**Nomenclature warning — several names in circulation no longer exist.**
Verified against `@codemirror/view` 6.39+ (npm latest 6.43.x) and
`@codemirror/state` main. The rewrite boundary is pinned: `tile.ts`/
`buildtile.ts` do not exist at tag **6.38.8** and do at **6.39.0**; 6.39.0
deleted `contentview.ts`/`inlineview.ts`/`blockview.ts`/`buildview.ts`. The
`CHANGELOG.md` has **no entry** for it — cite the release boundary, not a commit.

| cited name | reality |
|---|---|
| `view/src/measure.ts`, `observer.ts`, `viewplugin.ts` | do not exist. `MeasureRequest`/`ViewUpdate`/`ViewPlugin`/`PluginValue`/`ScrollTarget` are in `extension.ts`; the read/write loop is `EditorView.measure()`; the observer is `domobserver.ts` |
| `ViewDesc`/`ContentViewDesc`/`LineView`/`BlockView`/`MarkView`/`WidgetView` | **not in any released `@codemirror/view`** (0.17.0→6.38.8 checked). The mirror was `ContentView`/`DocView`/`ChildCursor` (6.0–6.38); since 6.39 it is a **`Tile` hierarchy**: `Tile` → `CompositeTile` → `DocTile`/`BlockWrapperTile`/`LineTile`/`MarkTile`, plus `TextTile`/`WidgetTile`/`WidgetBufferTile`/`TilePointer` |
| `ChangeSet` is five parallel arrays | **one flat `sections: number[]` of `(len, ins)` pairs** + sparse `inserted: Text[]`; `fromA`/`toA`/`fromB`/`toB` are derived by cumulative sums |
| `MapMode` = Simple/TrackDel | four: `Simple`, `TrackDel`, `TrackBefore`, `TrackAfter` |
| `RangeSet` in `@codemirror/rangeset` | moved into `@codemirror/state` (`rangeset.ts`); the repo is the legacy 0.19 package |
| `Viewport{ranges: [...]}` | `Viewport` is `{from, to}`; the multi-range array is `EditorView.visibleRanges` |
| `ViewUpdate.selectionChanged` | does not exist; it is `selectionSet` ("a transaction explicitly set a selection", not "the selection differs") |
| `ParseContext.ranges`/`mounted`/`getTree`, `parseCache`, `WorkRange`, `WorkScheduler` | absent; it is `ParseContext` + a `parseWorker` `ViewPlugin` + module-local `requestIdle` + a `const enum Work` budget. "Cache by tree size" is folklore |
| `TreeFragment.of`/`set`, `IterMode.IncludeAnonymousTop`, `DecorationSpec.atomic`, a `Recovery` class, `maxStackDepth` | do not exist |

### 7.2.1 `EditorState`: what "immutable" actually costs

```ts
class EditorState {
  readonly config: Configuration      // resolved extension tree
  readonly doc: Text
  readonly selection: EditorSelection
  values: any[]                       // dynamic slot storage
  status: SlotStatus[]
  computeSlot: null | ((state, slot) => SlotStatus)
}
```

`EditorState.create` resolves the extension list once into a `Configuration`.
`Configuration.resolve` flattens extensions with a `seen: Map<Extension,
number>` for identity dedup by highest `Prec`, splits `StateField`s from
`FacetProvider`s, and builds `staticValues` (facet values with no dynamic input,
read with zero per-update work) and `dynamicSlots` (fields/dynamic facets, each
with `depDoc`/`depSel`/`depAddrs` computed once). On update a slot's getter runs
**only if a declared dependency changed**, and the result is compared
(`compareInput`/`compare`) before the slot is marked changed. `address` encodes
dynamic slot `i` as `i << 1` and static value `i` as `i << 1 | 1` — one integer
slots table. `ensureAddr` throws
`"Cyclic dependency between fields and/or facets"` on re-entry: a demand-driven
dependency graph, which is why a large extension set does not recompute
everything per keystroke.

`applyTransaction(tr)`: scan `tr.effects` for reconfiguration; if the config
changed, resolve it and use an `intermediateState` so each slot's
`reconfigure(state, oldState)` can map its old value; otherwise
**`startValues = tr.startState.values.slice()` is the only per-update copy**.
Then set `tr._state` *before* running slots (so a slot can query the new state),
force every dynamic slot, clear `computeSlot`. `Transaction` is lazy:
`_doc`/`newSelection`/`_state` are computed on first access;
`newSelection = selection ?? startState.selection.map(changes)`.
`docChanged = !changes.empty`.

`resolveTransaction` merges specs: `sequential` composes changes; otherwise
each side's changes are mapped through the other
(`mapForA = b.changes.map(a.changes)`,
`mapForB = a.changes.mapDesc(b.changes, true)`). Then `changeFilter` may veto or
*partially* filter (flat range pairs → `changes.filter`, with selection/effects
mapped back through the inverted desc), then `transactionFilter` (may return a
spec, specs or a `Transaction`), then `transactionExtender` (may only *add*
effects/annotations). **A four-stage cancellable transaction pipeline** — the
shape Niman wants for "never write zero-width spaces into a note".

**Dart translation.** `StateField<T>` → abstract class with `T create`,
`T update(T, Transaction)`, optional `T reconfigure(new, old)`. `Facet<T>` →
generic with `T combine(List<T>)`, `bool compare(a,b)`, optional declared deps.
The dependency-slot machinery is optional in Dart (a `List<StateField>` per
transaction is fine at 10–20 fields), but **immutability + pure update is not
optional**, because it is what lets the tokenizer, the decoration builder and
the tests run without `dart:ui`.

### 7.2.2 `ChangeSet` / `ChangeDesc`: the edit algebra

```
ChangeSet.of(changes, length)
ChangeDesc: sections: number[]        // flat (len, ins) pairs -- NOT fromA/toA/...
ChangeSet:  ChangeDesc + inserted: readonly Text[]   // sparse, by pair index
```

`(len, -1)` = `len` unchanged; `(len, 0)` = deletion; `(0, n)` = insertion;
`(len, n)` = replacement. `length = Σ len`; `newLength = Σ (ins < 0 ? len : ins)`.
`addSection(sections, len, ins, forceJoin = false)` drops `len == 0 && ins <= 0`
and merges only when safe (`ins <= 0 && ins == sections[last+1]`, or
`len == 0 && sections[last] == 0`). **Consecutive changed sections are
deliberately kept separate so `mapPos` can tell them apart** — hence
`iterChanges(f, individual = true)` vs the default grouping, and
`iterGaps(f(posA, posB, len))`. `inserted` is sparse: `addInsert` computes
`index = (sections.length - 2) >> 1` and **appends** to the previous `Text` when
that index exists, else pads with `Text.empty`.

**`mapPos(pos, assoc = -1, mode = Simple)` — the exact rule.** Walking sections,
an unchanged pair returns `posB + (pos - posA)`. In a changed pair:

- mode nulls first: `TrackDel` → null if `posA < pos && endA > pos`;
  `TrackBefore` → null if `posA < pos`; `TrackAfter` → null if `endA > pos`;
  `Simple` never returns null.
- then `if (endA > pos || endA == pos && assoc < 0 && !len)
  return pos == posA || assoc < 0 ? posB : posB + ins`.

In words: **`assoc < 0` (default) binds the position to the character *before*
it** — at a deletion/replacement boundary it stays at the start of the replaced
region (`posB`) and an insertion there does not push it; **`assoc >= 0` binds it
to the character *after*** — pushed past the insertion (`posB + ins`), except at
the exact section start. `RangeError` if `pos > posA` at the end. **This is the
whole answer to "the caret jumps when I type a marker inside a bold range", and
the one place an off-by-one silently corrupts selections.**

`compose`/`map`/`mapDesc` share a `SectionIter {i, len, off, ins, next(), done,
len2, forward(len), forward2(len)}`. `composeSets(A, B, mkSet)` walks both:
deletions in A emit `(a.len, 0)`; pure insertions in B emit `(0, b.ins)`;
otherwise `len = min(a.len2, b.len)`, using `b.off`/`a.off` to decide whether an
insertion still applies; the `open` flag implements `forceJoin`. `mapSet(A, B,
before, mkSet)` emits each partially-covered insertion exactly once. **OT
identity: `A.compose(B.map(A)) == B.compose(A.map(B, true))`.** `invert(doc)`
swaps each pair `(len, ins) → (ins, len)` and fills `inserted` from
`doc.slice(...)` — with `ChangeSet.empty(length)` that is undo/redo. Also
`filter(ranges)`, `toJSON`/`fromJSON`, `touchesRange(from,to)`.

Complexity: map/compose/iter are `O(#sections)`; `mapPos` is `O(#sections)`. A
10 MB document edited in 100 places has ~100+ sections, so mapping a selection
is hundreds of operations, not 10 million.

**Dart translation.** A `ChangeSet` value class with a `List<int>` of
`(len, ins)` pairs plus insertions; `mapPos(pos, {assoc = -1, mode}) -> int?`;
`MapResult(pos, deleted, deletedBefore, deletedAcross)`; `compose`; `invert`;
`iterChanges`. ~250 lines, and it replaces every ad-hoc offset arithmetic in an
editor. Niman needs it the moment the buffer, tokenizer, decoration set,
selection, find-panel matches, spell ranges and scroll map must all move
together after one edit.

### 7.2.3 `Text`: the rope

`Text.of(lines)` → `TextLeaf` (array of line strings) or `TextNode` (children +
cached `length`). **There is no height field; balance is by line count**
(`Tree.BranchShift = 5`, `Branch = 32`); `TextLeaf.split` cuts into 32-line
chunks, and `TextNode.from` regroups children into chunks of
`max(Branch, lines >> 5)` bounded by `minChunk`/`maxChunk`. `TextNode.replace`
has a fast path: if the change touches exactly one child and that child's line
count stays within `(total >> 6, total >> 4)`, only that child is copied;
otherwise full re-balance. Reads: `lineAt(pos)`/`line(n)` descend scanning at
most 32 children per level, **threading `number` down** rather than walking back
up; `Line{from, to, number, text}`. `slice`/`replace` build `parts` via
`decompose(..., Open.From|Open.To)` then `TextNode.from(parts, newLen)`.
`eq(other)` compares from both ends with `scanIdentical` (identical leaves
compared by reference) then walks the middle. Iterators: `RawTextCursor`,
`PartialTextCursor`, `LineCursor`, with `next(skip?)` and a `lineBreak` flag.
Positions are **UTF-16 code units** (Dart `String` is also UTF-16, so the port
is faithful — but astral chars cost 2).

Complexity: `length`/`lines` O(1); `lineAt`/`line` `O(log n)`;
`sliceString` `O(output + log n)`; `replace` `O(log n + edited lines)`;
`Text.of` O(n) once.

**Dart translation.** A rope with `TextLeaf(List<String>)`/`TextNode` sharing
untouched children and `lineAt` descending by accumulated length. In Dart the
rope's value is *not* memory (`String.substring` copies) but `O(log n)`
`lineAt`/`replace`. On a 934 KB string `String.replaceRange` is `O(n)` memcpy
(~0.2 ms) — fine for a *save*, not for a per-keystroke `lineAt` walk over
10 331 lines. A cheaper first step: keep the flat `String` plus a
**Fenwick/prefix-sum tree over line lengths** so line→offset and offset→line are
both `O(log n)`. `HighlightDocument._lineStarts` has the right idea but rebuilds
it `O(n)` per offset edit (§9.1).

### 7.2.4 `Tree` — the persistent syntax tree

```ts
class Tree {
  readonly type: NodeType
  readonly children: readonly (Tree | TreeBuffer)[]
  readonly positions: readonly number[]   // offsets relative to this tree's start
  readonly length: number
  props: {[id: number]: any} | null       // per-node: mounted, contextHash, lookAhead
}
```

- **`TreeBuffer`** is the memory optimisation: a `Uint16Array` of
  `(type, start, end, endIndex)` **quads**, storing small subtrees inline.
  `DefaultBufferLength = 1024`. Nodes are in **prefix order** (parents before
  children) and `endIndex` points past the node's descendants. This collapses
  millions of tiny nodes (every token) into flat typed arrays. **Dart: a
  `Uint16List`/`Uint32List` with the same quad layout** — the difference between
  a token tree of a 10 331-line document costing a few MB and hundreds.
- `NodeType{name, id, props, flags}` with `Top|Skipped|Error|Anonymous`; a
  `NodeSet` is the type table (ids must equal array indices; ids are 16-bit, so
  max 65 536 types). `IterMode`: `ExcludeBuffers`, `IncludeAnonymous`,
  `IgnoreMounts`, `IgnoreOverlays`, `EnterBracketed`.
- `TreeCursor` — a **mutable** cursor: `firstChild`, `nextSibling`, `parent`,
  `enter(pos, side)`, `moveTo(pos, side)`, `next/prev(enter)`,
  `matchContext([...names])`. Client code walks the tree without allocating a
  node per visit. **A flat-array tree needs this in Dart.**
- `resolve(pos, side)`/`resolveInner(pos, side)`: innermost node covering `pos`;
  `side = -1` enters nodes *ending* there, `1` nodes *starting* there. Both
  memoize the last node in a module-level `WeakMap`, so sequential queries (the
  caret, then caret+1) are nearly free. `Side{Before=-2 … After=2, DontCare=4}`.
- `Tree.balance()` — when a node exceeds `BranchFactor = 8` children, wrap them
  in anonymous `NodeType.none` subtrees recursively (`balanceRange`,
  `maxChild = ceil(total * 1.5 / 8)`). **Without it, a document that is one flat
  list of blocks degenerates and every lookup is linear** — a concrete trap for
  a hand-written Markdown block tree.
- `NodeWeakMap<T>` associates values with nodes so they **survive subtree
  reuse** — the mechanism behind "decorations stay valid across reparse".
- `Tree.build` reads a **postfix** flat array (parents *after* children) of
  `[typeId, start, end, size]`; negative sizes are special records
  (`SpecialRecord {Reuse = -1, ContextChange = -3, LookAhead = -4}`). It refuses
  to pack any subtree containing a `Reuse` record into a buffer, falls back to
  `takeFlatNode` past `CutOff.Depth = 2500`, and stores `lookAhead` only when
  `> 25`.
- Tree depth is `O(log n)` by construction, but child lookup inside a node is a
  linear scan (≤32 children, or `TreeBuffer` sibling records), so
  `resolve`/`enter` is `O(depth × siblings)` — about `O(log n)` in practice, not
  a guaranteed logarithmic search.

### 7.2.5 `TreeFragment` and incremental parsing

```ts
class TreeFragment {
  readonly from, to    // range in the UPDATED document
  readonly tree: Tree
  readonly offset: number   // tree pos = doc pos + offset
  openStart, openEnd: boolean
}
```

- `TreeFragment.addTree(tree, fragments = [], partial = false)` → one fragment
  `(0, tree.length, tree, 0)`, `openEnd = partial`.
- `TreeFragment.applyChanges(fragments, changes, minGap = 128)` walks
  `ChangedRange{fromA, toA, fromB, toB}` left-to-right keeping
  `off = toA - toB`, intersects each fragment with the unchanged runs, drops
  fragments inside a change, adjusts `offset`, and sets
  `openStart = cI > 0`, `openEnd = !!nextC`. **Regions shorter than `minGap`
  (128 chars) between edits are dropped** — too small to be worth reusing. That
  constant is the pragmatic heart of the scheme.
- `openStart`/`openEnd` mean "this boundary is a *change* or *partial-parse*
  boundary, not a document boundary, so a parser may not reuse a node touching
  it". **This is the algorithm-agnostic way to say "the surrounding context
  changed; don't trust the tree here."**
- `Parser.startParse(input, fragments, ranges)` → `PartialParse` with
  `advance(): Tree | null`, `parsedPos`, `stopAt(pos)` (must be monotone),
  `stoppedAt`. `Input{length, chunk(from), lineChunks, read(from,to)}` — **a
  Lezer parser never sees a string, it sees an `Input`.** Dart:
  `abstract interface class ParseInput { int get length; String chunk(int from);
  bool get lineChunks; String read(int from, int to); }`

`@codemirror/language`'s `LanguageState{tree, context: ParseContext}` wraps it.
`ParseContext` fields: `parse: PartialParse?`, `state`, `fragments`, `tree`,
`treeLen`, `viewport{from,to}`, `skipped[]`, `tempSkipped`, `scheduleOn`. On a
doc change it calls `TreeFragment.applyChanges` and returns a **new**
`ParseContext`; `isDone(upto)` requires `treeLen >= min(upto, doc.length)` **and**
`fragments[0].from == 0 && fragments[0].to >= upto`; `updateViewport` un-skips
intersecting ranges; `skipUntilInView` + `tempSkipped` implement "don't parse
what is not visible yet".

The parser drives itself through `work(until, upto?)`: convert a ms number to a
deadline predicate, lazily `startParse()`, call `parse.stopAt(upto)` when safe,
loop `parse.advance()`; on completion record
`fragments = TreeFragment.addTree(tree, fragments, parse.stoppedAt != null)`.
The worker is a `ViewPlugin` (`ParseWorker`) driven by module-local
`requestIdle` and a budget enum:
`Work {Apply=20, MinSlice=25, Slice=100, MinPause=100, MaxPause=500,
ChunkBudget=3000, ChunkTime=30000, ChangeBonus=50, MaxParseAhead=1e5,
InitViewport=3000}`. `endTime = Date.now() + min(chunkBudget, Slice,
remainingIdleTime - 5)` with the stop predicate `isInputPending?.() ||
Date.now() > endTime`; only `timeRemaining()` is read, not `didTimeout`. It
dispatches `Language.setState`. **Viewport-first scheduling:** a state change
runs the parse with `Work.Apply = 20 ms` synchronously, and the background
target is `viewport.to + (viewportFirst ? 0 : 1e5)` where
`viewportFirst = treeLen < viewport.to && doc.length > viewport.to + 1000` —
**never parse past the viewport on a keystroke.** Query API:
`syntaxTree(state)` (may be **incomplete**), `syntaxTreeAvailable`,
`ensureSyntaxTree(state, upto, timeout)` (forces the viewport to `{0, upto}` so
viewport-aware parsers cannot skip it), `forceParsing`, `syntaxParserRunning`.
**`ensureSyntaxTree(state, doc.length)` is explicitly `O(entire document)`.**

### 7.2.6 Lezer proper

**Grammar DSL** (`.grammar`, `@lezer/generator`): `@top Program`, `@tokens`,
`@skip`, `@precedence` (`@left`/`@right`; markers `!name` resolve shift/reduce,
`~name` enables reduce/reduce i.e. GLR splitting), `@specialize`, `@extend`,
`@dynamicPrecedence`, `@context`/`ContextTracker`, `@external tokens`,
`@conflict`, `@local`, `@dialects`, `@detectDelim`, `@isGroup`. Capitalized
rules become tree nodes; lowercase rules are inlined; `_`-prefixed names are
omitted. Compile with `lezer-generator lang.grammar -o lang.js`.

**Compiled tables** (`@lezer/lr`): `LRParser{states: Uint32Array, data:
Uint16Array, goto, maxTerm, minRepeatTerm, tokenizers, topRules, context,
dialects, dynamicPrecedences, specialized, specializers, termNames, nodeSet}`;
`stateSlot(state, slot) = states[state * 6 + slot]`. Actions are 32-bit values
split across two `Uint16`s: `Action {ReduceFlag = 1<<16, ValueMask = 2^16-1,
ReduceDepthShift = 19, RepeatFlag = 1<<17, GotoFlag = 1<<17, StayFlag = 1<<18}`.
Tokenizers are **generated DFA functions** (`TokenGroup`, `LocalTokenGroup`,
`ExternalTokenizer`, `readToken`), not regexes — that is why Lezer is fast.

**Parser loop and the GLR fork.** `advanceStack` tries all actions, and
`let last = i == actions.length || !split; let localStack = last ? stack :
stack.split()` — **the last action keeps the original stack, earlier ones
split**. Reachable only when the grammar opted into ambiguity (`~name`) or
during recovery. `stackToTree` closes the stack and calls `Tree.build` with
`reused` trees.

**`Stack`** holds `{p, stack: number[] /* state,inputPos,bufferIndex triples */,
state, reducePos, pos, score, buffer, bufferBase, curContext, lookAhead,
parent}`. On a reduction, `storeNode(type, start, pos, count + 4, true)` turns a
nonterminal into **one postfix buffer record whose `size` spans its children**;
a shift pushes `[type, start, end, 4]` for a leaf token. `Stack.split()` copies
`stack.slice()` and only the buffer *tail* whose offsets are after `reducePos`
(`base = parent.bufferBase + off`) — **that is why forking is cheap**.

**Limits and error recovery** (no `maxStackDepth` identifier): `Rec` constants
(`CutDepth = 2800*3`, `CutTo = 2000*3`,
`MaxLeftAssociativeReductionCount = 300`, `MaxStackCount = 12`) force-reduce an
over-deep stack. `runRecovery` per stopped stack tries `restart()`,
`forceReduce()` up to `ForceReduceLimit = 10`, then `recoverByInsert(token)`
(enumerate `nextStates`, one split each, store a `Term.Err` node,
`score -= 200`) and `recoverByDelete(token, end)` (`score -= 190`). Recovering
stacks are sorted by `score` and truncated; `advance()` sets
`recovering = Rec.Distance` when nothing advanced. **An error never aborts the
parse** — that is what makes editing-while-broken work.

**What makes a grammar incremental-friendly (verified):** only whole `Tree`
nodes are reused — `FragmentCursor.nodeAt` never returns a `TreeBuffer`, so a
node must exceed `bufferLength` (default 1024) to be reusable, and the cursor is
only created at all when `stream.end - from > bufferLength * 4`; reuse requires
a valid `getGoto(currentState, node.type.id)` **and**, for strict
`ContextTracker`s, a matching `NodeProp.contextHash`; the safe window is
`safeFrom = openStart ? cutAt(tree, fr.from + fr.offset, 1) - fr.offset :
fr.from` and `safeTo = openEnd ? cutAt(..., -1) - fr.offset : fr.to`, where
`cutAt` backs off by `Lookahead.Margin = 25`; `NodeProp.lookAhead` (stored only
when `> 25`) blocks reuse unless `end + lookAhead < fragment.to`; `*`/`+` are
stored as balanced anonymous subtrees so unchanged tails stay reusable. **A
small edit can still require far-away reparsing** (toggling a block-comment
opener) — incremental parsing promises *reuse*, not locality.

### 7.2.7 `Decoration`, `RangeSet`, `DecorationSet`

`Decoration extends RangeValue` with subclasses `MarkDecoration` (inline, wraps
a range in a style), `LineDecoration` (zero-length line decoration,
`mapMode = TrackBefore`), and `PointDecoration` (both widgets and replaces;
`get type()` → `BlockType.WidgetRange|WidgetBefore|WidgetAfter`;
`heightRelevant = block || widget && (widget.estimatedHeight >= 5 ||
widget.lineBreaks > 0)`). Spec flags that matter: `inclusive`
(`InclusiveStart`/`InclusiveEnd` — whether text typed at the boundary joins),
`startSide`/`endSide` (ordering at a shared boundary), `block` (own line), and
on `WidgetType`: `estimatedHeight` (-1 = unknown), `lineBreaks`, `ignoreEvent`.
**Atomicity is a separate facet** (`EditorView.atomicRanges`), not a decoration
field.

Ordering uses hundreds-of-millions magnitudes
(`GapStart=-5e8 … InlineIncStart=-1, InlineIncEnd=1 … GapEnd=4e8`) and the
global sort `a.from - b.from || a.value.startSide - b.value.startSide`.

`RangeSet<T>` is a linked stack of chunk arrays
(`{from: number[], to: number[], value: T[], maxPoint}`, `ChunkSize = 250`,
`Far = 1e9`) where `nextLayer` absorbs out-of-order adds. `map(changes)` is
where sharing happens: `changes.touchesRange(start, start + chunk.length)` →
`false` reuses the **same chunk object** and only remaps `chunkPos`; `true` maps
per range with `mapPos(pos, side, mapMode)` and drops deleted ranges.
`RangeSetBuilder` appends into parallel arrays and **throws** on an inversion.
`heightRelevantDecoChanges(a, b, diff)` uses `RangeSet.compare` and records a
change only when `from < to || a.heightRelevant || b.heightRelevant` — **so mark
decorations never invalidate heights, which is what keeps highlighting cheap.**

`DecorationSet` = `RangeSet<Decoration>`, living either in a `StateField`
(survives transactions, needs mapping) or produced by a `ViewPlugin`
(recomputed per update).

### 7.2.8 `ViewPlugin`, `ViewUpdate`, and the measure cycle

`ViewPlugin.fromClass(cls, {eventHandlers, eventObservers, provide,
decorations})`; `PluginValue{update?(update), docViewUpdate?, destroy?}`.
`PluginInstance.update` is try/caught into
`logException(state, e, "CodeMirror plugin crashed")` and a crashed plugin
deactivates itself. **`EditorView.plugin(p)` calls `known.update(this)`
eagerly**, which is what makes plugin-provided decoration facets safe.

**Plugin gating (verified): there is none built in.** `updatePlugins` runs under
`if (!update.empty)` where `empty = flags == 0 && transactions.length == 0` —
so a plugin sees *every* transaction, including effect-only no-ops. Each plugin
guards itself with `update.docChanged` / `selectionSet` / `viewportChanged`.
`UpdateFlag {Focus=1, Height=2, Viewport=4, ViewportMoved=8, Geometry=16}`;
`selectionSet = transactions.some(tr => tr.selection)`;
`geometryChanged = docChanged || (flags & (Geometry|Height)) > 0`. There is no
`selectionChanged`.

**The tile/diff cycle.** `EditorView.update` → `updateState` (pure) →
`updateView` → `measure`. `DocView.updateInner(changes, composition)` builds a
`TileUpdate(view, oldTile, blockWrappers, decorations, dynamicDecorationMap)`
and runs `TileBuilder.run(changes, composition)`, reusing old tiles and DOM
nodes via `Reused {Full, DOM}`; dropped tiles are destroyed; **the tile height
is temporarily pinned (`tile.dom.style.height = contentHeight/scaleY`) to stop
the browser moving the scroll position during the mutation**; then
`tile.sync(track)` fixes DOM order; then the height is restored. *That height-pin
trick is worth stealing for Flutter.*

`Tile{parent, dom, length, breakAfter, flags: TileFlag}` →
`CompositeTile` → `DocTile`/`BlockWrapperTile`/`LineTile`/`MarkTile`; leaves
`TextTile`/`WidgetTile`/`WidgetBufferTile`; `TilePointer` replaces the old
`ChildCursor`. `TileFlag {BreakAfter=1, Synced=2, AttrsDirty=4, Composition=8,
Before=16, After=32, PointWidget=48, IncStart=64, IncEnd=128, Block=256}`. Each
tile stamps `(dom as any).cmTile = this`, and `CompositeTile.nearest(dom)` walks
`parentNode` — the position-mapping index.

**Read/write split.** `requestMeasure({read, write, key})` schedules a
`MeasureRequest`; the view runs **all reads before all writes** in one
rAF-batched loop. `readMeasured()` is private and **throws**
`"Reading the editor layout isn't allowed during an update"` when
`updateState == Updating`. Requests coalesce by identity and by `key` (last wins
per key); the loop warns after 5 iterations
("Measure loop restarted more than 5 times / Viewport failed to stabilize");
exceptions in `read` become a `BadMeasure` rather than crashing. On each cycle
it establishes a scroll anchor, and **if the anchor moved more than 1 px it
adjusts `scrollTop` by the difference and loops** — CM6's scroll anchoring in
one sentence.

`DOMObserver` wraps a `MutationObserver`, a `ResizeObserver` on
`view.scrollDOM` **guarded by a 75 ms self-suppression window**
(`if (view.docView?.lastUpdate < Date.now() - 75)`) debounced 50 ms into
`requestMeasure()`, an `IntersectionObserver` (`{threshold: [0, .001]}`), and
selection listeners. Init options are exactly `{childList, characterData,
subtree, attributes, characterDataOldValue}`. `observer.ignore(f)` stops, runs
`f`, restarts and clears, so editor-initiated DOM writes are never read back.
External mutations go `readChange()` → `new DOMChange(view, from, to, typeOver)`
→ `domBoundsAround(tile, ...)` → `new DOMReader(selPoints, view).readRange(...)`
→ `applyDOMChange`. **`DOMReader` is a text *serializer*, not an
identity-preserving reader**: identity is recovered by **text diffing**
(`state.doc.sliceString(from, to, LineBreakPlaceholder)` vs `domChange.text`,
then `findDiff(a, b, preferredPos, preferredSide)` to find the minimal edit and
move it to the side the cursor prefers).

**Dart translation.** Flutter has no DOM to read back, so `DOMObserver` and
`readChange` have no equivalent — *an advantage*: no IME round-trip machinery,
no `cmTile` back-pointers. What maps is (i) the mirror-tree diff idea (Flutter's
element reconciliation already does this for `ValueKey`ed per-block widgets) and
(ii) the read/write discipline: `addPostFrameCallback` for reads of
`RenderBox.size`/`TextPainter`, `scheduleFrame` for writes, one pass doing all
reads then all writes. `requestMeasure({key})` coalescing → a `Set<Object>` of
dirty keys consumed in one post-frame pass. The 75 ms observer suppression → a
guard flag around layout-driven notifications so the scroll listener cannot
re-enter itself — `EditorPreviewScrollSync`'s guard and `_extentSyncScheduled`
already are this.

### 7.2.9 Viewport and `visibleRanges`

- `Viewport{from, to}` (two numbers) plus `ViewState.viewports[]` — the main
  viewport **plus up to two single-line viewports for the selection anchor/head
  when they fall outside it**, so the DOM selection never lands in a gap.
- `ViewState.visibleRanges` is the multi-range array (that is what the
  "viewport is not contiguous" intuition is about): `computeVisibleRanges()`
  runs `RangeSet.spans(stateDeco.concat(lineGapDeco), viewport.from,
  viewport.to, ..., minPointSize = 20)` and diffs against the previous array,
  returning `UpdateFlag.Viewport` or `ViewportMoved`.
- Sizing: `VP {Margin = 1000, MinCoverMargin = 10, MaxCoverMargin = 250,
  MaxDOMHeight = 7e6, MaxHorizGap = 2e6}`. `getViewport(bias, scrollTarget)`
  maps `visibleTop - marginTop*1000` and `visibleBottom + (1-marginTop)*1000`
  through the height map, so the viewport is never more than ~2000 px beyond
  the visible range.
- **Long lines use `LineGap`**, not layout: `LineGap{from, to, size,
  displaySize}` replaces the invisible middle of an overlong line with a widget
  sized `displaySize * scale`. `LG {Margin = 2000, MarginWrap = 10000,
  SelectionMargin = 10}`; gaps split around the selection. **Flutter needs the
  equivalent: never build a `TextPainter` for a 10 MB single line.** Niman's
  note has 90-char lines, so this is insurance, not a current need.
- `scrollIntoView(pos|{range}, {y = "nearest", yMargin = 5, x = "nearest",
  xMargin = 5})` → a `ScrollTarget` stored in `viewState.scrollTarget`;
  `view.scrollSnapshot()` builds a snapshot target from the scroll anchor;
  `DocView.scrollIntoView` honours `isSnapshot`, offers the target to
  `EditorView.scrollHandler` facets, then expands the rect by the margins and
  calls `scrollRectIntoView`.

### 7.2.10 `HeightOracle` / `HeightMap` — the scroll-anchoring core

**This is the section to re-read before writing any Flutter scroll code.**

```ts
class HeightOracle {
  doc: Text; lineHeight = 14; charWidth = 7; textHeight = 14; lineLength = 30;
  heightSamples: {[key: number]: boolean}
  constructor(public lineWrapping: boolean) {}
  heightForGap(from, to): number      // estimate for unmeasured text
  heightForLine(length): number       // wrap estimate
}
```

- **Estimation, not measurement, is the default**, and it is a
  **two-parameter arithmetic model, not a regression**: `heightForLine(length)`
  is `lineHeight` when not wrapping, else
  `(1 + max(0, ceil((length - lineLength) / max(1, lineLength - 5)))) * lineHeight`.
  `heightForGap(from, to)` counts lines and adds
  `max(0, ceil((chars - lines*lineLength*0.5) / lineLength))` extra lines.
  `mustRefreshForHeights`/`refresh` report a change when
  `|lineHeight - old| > 0.3`, wrapping flipped, or `|charWidth - old| > 0.1`;
  `heightSamples` keys measured heights rounded to 0.1 px
  (`Math.floor(h * 10)`). **Port this exactly — it is ~40 lines and it is the
  whole estimator.**
- `MeasuredHeights{from, heights: number[], index, more}` — the measured lines
  from the DOM read phase. **A negative entry means "space above the next
  line"** (`setMeasuredHeight` consumes two entries then);
  `measureVisibleLineHeights` encodes block-widget margins that way.
- **Loading a 10 MB document is O(1) heightmap nodes.** `EditorView` starts from
  `HeightMap.empty().applyChanges(stateDeco, Text.empty, oracle.setDoc(doc),
  [new ChangedRange(0, 0, 0, doc.length)])`, which collapses the whole document
  into **one `HeightMapGap(length = 10^7)`** whose height comes from
  `oracle.heightForGap` — two rope `lineAt` lookups, `O(log n)`, *not*
  `O(lines)`. Only the viewport is then measured. **The most important
  structural fact here for a 10 331-line preview: the index over the
  un-laid-out document must be one node, not one entry per block.**

`HeightMap` is a binary tree over the document:

- `HeightMapBranch(left, brk, right)` — `left.length + brk + right.length`;
  `balanced()` rebalances when `left.size > 2 * right.size` (weight-balance,
  not height-balance).
- `HeightMapText(length, height, spaceAbove)` — one line, with `collapsed`
  (amount of replaced content), `widgetHeight` (max inline widget height) and
  `breaks` (widget-introduced line breaks). `updateHeight` recomputes as
  `max(widgetHeight, oracle.heightForLine(length - collapsed)) + breaks * lineHeight`.
- `HeightMapGap(length)` — a run of **never measured** lines. `heightMetrics()`
  → `{firstLine, lastLine, perLine, perChar}` with
  `perLine = min(height, lineHeight*lines)/lines` and
  `perChar = (height - perLine*lines)/(length - lines - 1)`. `lineAt`/`blockAt`
  interpolate: a line's height is `perLine + line.length * perChar`. Partially
  measured gaps split into `HeightMapText`s plus smaller gaps.
- `HeightMap.of(nodes: (HeightMap|null)[])` builds a balanced tree from a node
  list with `null` marking line breaks, repeatedly splitting the biggest child
  until sizes are within 2×.
- `applyChanges(decorations, oldDoc, oracle, changes)` is the incremental
  update: walk changes **backwards** (so earlier ranges' offsets stay valid),
  snap to line boundaries via `QueryType.ByPosNoHeight`, rebuild only that slice
  with `NodeBuilder.build` (a `SpanIterator` over decoration sets emitting
  `HeightMapText`/`HeightMapBlock`/`null` breaks, handling `block` widgets,
  `estimatedHeight`, `lineBreaks`, `collapsed`, `spaceAbove`), splice, then
  `updateHeight(oracle, 0)`.
- `heightChangeFlag` / `clearHeightChangeFlag()` — a module-global dirty bit set
  during the cheap walk, so "did height change?" costs no second pass. It is
  also set when the *shape* of the tree changes (`replace(old, val)` compares
  constructors).
- `BlockInfo{from, length, top, height, _content}` where `_content` is a packed
  union (number = widget line breaks, array = sub-blocks, `PointDecoration` =
  the block widget); `QueryType {ByPos, ByHeight, ByPosNoHeight}`;
  `lineBlockAt(pos)` answers "which line block is here".

**Scroll anchoring, concretely.** `ViewState.update` takes an anchor *before*
the height update (`scrollAnchor = scrolledToBottom ? null :
scrollAnchorAt(scrollOffset)`, which is `lineBlockAtHeight(scrollOffset + 8)`),
maps `scrollAnchorPos` through the change with `assoc = -1`, records
`scrollAnchorHeight`, and compares `heightMap.height != prevHeight ||
heightChangeFlag` to set `UpdateFlag.Height`. In `EditorView.measure`, after each
cycle the anchor's top is recomputed and **if it moved more than 1 px,
`scrollTop` is corrected by exactly that difference and the loop re-runs**
(bounded at 5). Because the map is a tree with partial measurement, the
correction is `O(log n + measured)`, not `O(document)`.

**Dart translation, line by line:**

| CM6 | Flutter/Dart to build |
|---|---|
| `HeightOracle` | `HeightEstimator{lineHeight, charWidth, lineLength, lineWrapping}` with `heightForLine(int chars)`, `heightForGap(int from, int to)` |
| `HeightMapBranch/Text/Gap` | sealed `HeightNode` with `Branch/Text/Gap` |
| `MeasuredHeights` | `List<double>` collected during layout from each block's `RenderBox.size.height` |
| `heightChangeFlag` | a `bool` on the controller checked in the post-frame pass |
| `BlockInfo` / `lineBlockAt` | `BlockInfo{from, length, top, height, kind}` and `blockAt(int offset)` |
| `applyChanges` | `applyChangeSet(ChangeSet)` |
| `view.coordsAtPos` | per-block `TextPainter.getOffsetForCaret` |
| `view.scrollIntoView(pos, {y})` | `RenderAbstractViewport.getOffsetToReveal` / `ScrollPosition.ensureVisible` |
| scroll anchor correction | `ScrollPosition.correctBy(delta)` in a post-frame callback |

**This is the highest-value borrow in the document.** Niman's preview feeds
`SliverVariedExtentList.itemExtentBuilder` from `ScrollMap.extentFor(index)`,
freezing each block's extent the first time it is asked
(`scroll_map.dart` ~190–230). That is a *flat, eager-per-block* `HeightMap`, and
it has exactly the failure mode `HeightMap` was invented to avoid:
`totalExtent()` walks **every block** to compute the scroll extent, and a
never-laid-out block is estimated from one global `pixelsPerLine`. Generalising
`ScrollMap` into a `HeightMap`-shaped tree removes that `O(blocks)` walk.

---

## 7.3 Incremental parsing: Lezer, tree-sitter, and the *minimum* for Markdown

### 7.3.1 What a partial re-parse actually needs

Three things, and only three:

1. **A persistent tree with absolute source spans.** Nodes immutable, carrying
   `[from, to)`. Reuse is a pointer copy.
2. **A mapping of the old tree through the edit** yielding candidate reuse
   regions plus an indication of which *boundaries* are suspect.
3. **A parser that can accept a whole old subtree** at a point in its own state
   machine — and knows how far past that subtree's end it had looked when it
   built it.

Lezer spells (2) `TreeFragment` + `applyChanges(fragments, changes,
minGap = 128)` and (3) `ParseContext.fragments` + `NodeProp.lookAhead` +
`NodeProp.contextHash` + the `Reuse` record. Tree-sitter spells (2)
`ts_tree_edit` with `TSInputEdit{start_byte, old_end_byte, new_end_byte,
start_point, old_end_point, new_end_point}` and (3) the GLR stack's ability to
push a reused subtree when a state at a matching position is found.

**What fragments/edit ranges are, precisely (Lezer):**

```
before: [F0(0..L, tree=T)]
edit [fromA, toA) -> [fromB, toB)
applyChanges: walk changes left to right keeping off = toA - toB;
  intersect each fragment with the unchanged runs;
  openStart = (there was an earlier change), openEnd = (there is a later one);
  offset = offset + off; drop empty intersections;
  runs shorter than minGap are dropped entirely (not worth reusing).
```

`openStart`/`openEnd` are the *uncertainty flags*: a node touching an open
boundary may have been influenced by text outside the fragment, so the parser
must re-derive it. A node safely inside a fragment with both boundaries closed
is reusable as a unit. **That is the whole trick, and it is
algorithm-independent.**

**How a grammar gets compiled (Lezer).** `lezer-generator` reads the `.grammar`
DSL and emits a module exporting an `LRParser` subclass with packed tables.
There is no runtime grammar interpretation: the automaton is data and the
tokenizers are generated code. **Consequence:** a Lezer-style general parser in
Dart needs a build step (`tool/` codegen) — a lot of machinery for one grammar.

### 7.3.2 tree-sitter's GLR stack, error recovery, and reuse

- `ts_parser_parse` keeps a versioned stack of parse states; on an action
  conflict it **forks** versions, then condenses by error cost.
  **`allow_node_reuse = version_count == 1`** — subtree reuse is disabled the
  moment GLR forks.
- Reuse refuses subtrees that `has_changes`, `is_error`, `missing`,
  `is_fragile`, or `contains_different_included_range`, and requires the
  external-scanner state and the lex mode to match. The **included-ranges**
  optimisation (`ts_parser_set_included_ranges`) reduces the change set to
  ranges that actually affect the parse.
- `ts_tree_get_changed_ranges(old, new, &len)` is a *query*: two tree cursors in
  parallel reporting `Matches` / `MayDiffer` (descend) / `Differs`, merged into
  ranges; "characters outside these ranges have identical ancestor nodes in both
  trees."
- **Error recovery** is cost-driven and explicit:
  `ERROR_COST_PER_RECOVERY 500`, `..._MISSING_TREE 110`, `..._SKIPPED_TREE 100`,
  `..._SKIPPED_LINE 30`, `..._SKIPPED_CHAR 1`; the parser force-reduces,
  inserts, deletes or restarts, inserts `MISSING` nodes, and keeps the cheapest
  version. **It never aborts.**
- **Progressive parsing**: `ts_parser_parse_with_options(..., TSParseOptions{
  progress_callback})` with `TSParseState{payload, current_byte_offset,
  has_error}`, checked every 100 operations; returning true cancels the parse
  (NULL) and the next call **resumes**. **There is no `ts_parser_set_lookahead`**
  — `ts_lookahead_iterator_*` is for external scanners, not parser control.
- **Lexer**: modern generated parsers have **no `valid_symbols` array and no
  `ts_lex_keywords`**. Parse states with identical valid-token sets are *merged
  at generation time* into one **lex state**, dispatched by
  `ts_language_lex_mode_for_state(parse_state)`; the generated `ts_lex` is a
  hand-unrolled DFA with `ADVANCE_MAP`/`SKIP`/`ACCEPT_TOKEN`. Lexical conflicts
  are resolved when the merged DFA is generated, so longest-match falls out of
  the state machine, not out of runtime heuristics.
- **Queries**: three files — `highlights.scm` (arbitrary `@keyword`/`@function`/
  `@type` capture names), `locals.scm` (a **fixed** capture set:
  `@local.scope`, `@local.definition`, `@local.reference`, `@ignore`, which
  makes an identifier colour the same as its definition), and `injections.scm`
  (`@injection.content`/`@injection.language`). Predicates (`#eq?`, `#match?`,
  `#any-of?`, `#is?`, `#set!`, …) are **not implemented by the C library** —
  they are "exposed in a structured form" for the host to apply.
- **Does an incremental Markdown grammar exist?** Yes, but
  `tree-sitter-markdown` (split_parser) is **two grammars** — a block grammar,
  then an inline grammar over the same text restricted by
  `ts_parser_set_included_ranges` to the block tree's `inline` nodes — and its
  README says "there are still lots of inaccuracies… not recommended to use
  this parser where correctness is important. The main goal … is to provide
  syntactical information for syntax highlighting." **That is an explicit
  negative result for "just use tree-sitter for Markdown" from the grammar's own
  authors.**
- **No incremental CommonMark anywhere.** Verified negatives: pulldown-cmark
  (`into_offset_iter()` gives ranges; no incremental API), comrak (`Arena` +
  `RefCell` AST with `sourcepos`; whole document), markdown-rs (byte state
  machine), `markdown-it` (fresh `StateBlock` per `md.parse`; no cross-call
  cache — only the enabled-rule chain is cached in `Ruler.__cache__`), micromark
  (preprocesses the whole input into a flat int array; zero hits for
  "incremental"), `remark`/`mdast-util-from-markdown` (whole value, no resume),
  and the Dart `markdown` package (`BlockParser` has **no source positions
  anywhere in the AST**).
- **cmark** is the clearest block-phase reference: `check_open_blocks` walks the
  open last-child chain, `open_new_blocks` backs up via `finalize` while
  `!can_contain`, and `add_text_to_container` handles lazy continuation. It
  **is** streaming (`cmark_parser_feed(chunk, len)`, append-only) but has **no
  incremental/resume API**. Note the explicit early `return NULL` for a blank
  line inside a list — "Avoid quadratic behavior caused by iterating deeply
  nested lists for each blank line". *The O(n²) trap of naive open-block
  re-derivation is real enough that cmark special-cases it.*
- **CommonMark's own spec appendix makes the shape normative**: "In this phase we
  may match all or just some of the open blocks. But we cannot close unmatched
  blocks yet, because we may have a lazy continuation line… Once a line has been
  incorporated into the tree in this way, it can be discarded, so input can be
  read in a stream… Reference link definitions are detected when a paragraph is
  closed."

### 7.3.3 The minimum incremental machinery for Markdown

Markdown's block structure is genuinely simpler than a programming language:
blocks are line-oriented and closure is decided by the *next* line; there is no
expression grammar to re-derive; inlines cannot affect block structure (except
lazy continuation); and therefore the **parse state at a line boundary is small
and serializable**. **The design (endorsed, with sharpenings):**

> Line-indexed buffer; a per-line block-state stack; on edit, re-parse from the
> first affected block boundary downward until the block state re-converges on a
> previously-known line.

This is what `HighlightDocument.replace` does today (§9.1) with a *3-field*
state (`fence`, `inMath`, `inFrontmatter`) and convergence
`state == old.entering`. What a full block parser adds:

1. **State must be the ordered container stack, or its hash — not counts.**
   `> - x` and `- > x` have the same (quote=1, list=1) depth but obey different
   continuation and laziness rules. `@lezer/markdown` encodes exactly this as
   `hash = (parentHash + (parentHash << 8) + type + (value << 4)) | 0`, where
   `value` is list indentation or the markup character, stamped on every child
   as `NodeProp.contextHash`; reuse requires
   `tree.prop(NodeProp.contextHash) == hash`. **One int per line is enough; do
   not snapshot whole stacks as objects.**
2. **Convergence must be checked at a top-level block boundary**, not "any line
   whose entering state matches". Copy `@lezer/markdown`'s `FragmentCursor`
   rules: `moveTo` **snaps the fragment end back to a line break**;
   `matches(hash)` must hold; never stop immediately after a node in
   `NotLast = [indented CodeBlock, ListItem, OrderedList, BulletList]` unless the
   next sibling is also reused ("an indented code block can continue after any
   number of blank lines"); and `fragmentEnd = fragmentEnd - (openEnd ? 1 : 0)`
   so nothing is reused right up to an open end.
3. **Container extents are decided by forward scans**, so the re-parse unit is
   the start of the *outermost enclosing container whose extent may have
   changed*, not the edited line: a blockquote keeps consuming until a line that
   is neither `>`-prefixed nor a lazy continuation; a list until the indent
   retreats or the blank-line rule fails ("a list item can begin with at most one
   blank line"); a setext heading makes a paragraph's type depend on the
   **following** line; a table peeks one line.
4. **Line index.** Do **not** rebuild `List<int> lineStarts` per offset edit as
   `HighlightDocument.replace` does (`_lineStarts()` is `O(n)` and is called on
   every offset edit). Use a `Uint32List` of line starts plus a **Fenwick tree
   over line lengths** (`offsetOfLine`/`lineOfOffset` `O(log n)`, update
   `O(log n)`), or a rope (§2.3). For a line-based editor the line list itself is
   the index and offsets need not exist on the edit path at all — which is what
   `replaceLines` + line-object identity already does. **A gap buffer is the
   wrong shape here**: it optimises cursor-local character edits and is not
   persistent, which is not the query a Markdown parser makes.
5. **Convergence alone cannot restore correctness, because of DOCUMENT-GLOBAL
   state.** Link reference definitions (`Document.linkReferences` / cmark's
   `refmap`), footnote numbering, tight/loose list status (which a single blank
   line anywhere in a list toggles: `BlockParser.encounteredBlankLine`), and
   ordered-list start numbers all change the rendering of blocks *far away*.
   Fix: a **refmap/footnote epoch** — bump a counter whenever an edit touches a
   line matching `^\s{0,3}\[[^\]]*\]:` or `^\[\^…\]:`, and key any cached inline
   result on `(blockRange, epoch)`. Block *structure* can still be reused across
   epochs; only the inline phase is affected. This is precisely why
   `@lezer/markdown` skips link-reference validation and says so in its README.
6. **Worst cases, and they are irreducible.** Inserting ` ``` `, `---` or `$$`
   at line 1 of a 10 331-line file flips the carried state for every following
   line, convergence never happens, and the re-parse is `O(n)` *because the
   document's block structure genuinely changed for all lines*. Same for an
   unclosed fence, a closed frontmatter block, and a list-marker change
   (`-` → `*` splits one list into two). No incremental algorithm beats this.
   Bound the damage instead: (i) cut materialization at the edit and
   re-materialize only up to the viewport (Niman already does this and the
   measured open cost is `O(visible)`); (ii) run the block re-parse in the
   existing `PreviewWork` isolate, viewport-first, with the previous render kept
   on screen (CM6's `viewportFirst`, `skipUntilInView`, 20 ms sync budget /
   3000 ms per 30 s background chunk; VS Code's worker slices at 200 lines or
   20 ms); (iii) make the state transition cheap so the unconverged path is
   `O(n)` *scalar* work, not `O(n)` full tokenization (`_stateAfter` is a handful
   of char checks per line; a cold 200 KB tokenize measured 23.95 ms, so a full
   10 331-line pass is tens of ms).
7. **A paste of 5000 lines costs `O(5000)`** — the input, not a regression.

**Can a hand-written recursive-descent parser with memoized block boundaries
get O(change)? Yes — and it is the right choice for Markdown**, for four
reasons: Markdown has no ambiguity requiring GLR (CommonMark's block rules are a
deterministic forward scan); the change unit is a **line**, so a line-indexed
buffer makes the change region contiguous and re-parse is a forward scan plus a
convergence check, strictly simpler than mapping fragments; a block's *inline*
parse is independent of every other block except the global state in point 5
(which Niman already seeds from the block phase via `prepareInlines`), so
per-block inline parsing is already O(1) and needs no incremental machinery at
all; and memoizing the block containing each line (`blockAt(offset)` becomes
O(1) after the first query, invalidated from the first affected boundary) is a
*cache*, not an algorithm.

**What you do *not* need (the useful negative result):**
`TreeFragment.applyChanges`'s min-gap/offset algebra, LR tables, a grammar
compiler, GLR stack splitting, `NodeProp.lookAhead`, `contextHash`, error
recovery as a tree of `⚠` nodes. Those exist because a general parser must
handle grammars where a change at byte 10 can alter the parse of byte 1 000 000
(a brace mismatch). Markdown has no such construct: the block state is a
*forward-only contraction*.

**What you *do* need:**
- the equivalent of `NodeProp.lookAhead`: record per block how many characters
  the scanner read past the block's end (0 for a fence, one line for a setext
  heading, table or paragraph). **A change inside that window invalidates the
  block's parse even though the block's own range did not change — the subtle
  correctness rule, and the most likely bug in a naive implementation.**
- work ranges + budgets: re-parse with a deadline and a "these lines are stale"
  set.
- balancing: ~2–4 k blocks in a flat list is fine, but **`ScrollMap.totalExtent()`
  walking all of them per layout is the symptom of not having a tree** (§6).

**Prior art that does the same thing.** *Incremark* (the only widely-documented
incremental JS Markdown renderer) keeps `Block{id, node, status:
'pending'|'completed'}`; a Pending block is micro-reparsed per chunk, a
Completed block goes to an AST cache and is "no longer involved in parsing or
re-rendering", with parser context `{inFencedCode, inContainer, listStack,
blockquoteDepth}` and exactly these boundary heuristics: blank line ends a
paragraph; a heading/thematic break ends the previous non-container block;
fenced code stays Pending until its close fence; lists/quotes tracked by
indentation + quote depth. It is append-only (`append`/`finalize`/`reset`) and
does **not** model arbitrary mid-document edits — but its boundary set is
independent confirmation of the rules above. **ToastMark** (nhn/tui.editor)
"parses only changed part of the document and update the existing AST… returns
information about removed and inserted nodes". VS Code's new
`@vscode/markdown-editor` (micromark) does a **full** tokenization every change
and then re-associates nodes with the previous tree by source range
(`getOriginalRange()`, `lookupExact(range, kind)`, `equalsShallow()`) so
unchanged blocks keep object identity — "full parse + identity reuse", the
closest thing VS Code has to incremental Markdown.

---

## 7.4 ProseMirror and Lexical: the position-mapping idea

### 7.4.1 ProseMirror's persistent tree

The whole document is **one `Node`** whose `type` is `doc`. Positions are a flat
integer space over the tree where every non-leaf node contributes 2 units.
`Fragment.findDiffStart`/`findDiffEnd` (delegating to `diff.ts`) compare children
by **reference identity** and only descend where they differ — `O(size of the
diff)`, not `O(document)`. `ResolvedPos` is the position→structure map:

```ts
class ResolvedPos {
  readonly pos: number
  readonly path: readonly (Node|number|Attrs)[]   // (node, childIndex, absStart)
  readonly parentOffset: number
  depth: number
  parent: Node; node(depth); index(depth); posAtIndex(index, depth)
  start(depth); end(depth); before(depth); after(depth)
  textOffset: number   // offset into the parent *text* node, or 0
  nodeAfter / nodeBefore
  marks(); marksAcross($end)
}
```

`doc.resolve(pos)` walks down with a binary search over `Fragment` sizes
(`node.content.findIndex(parentOffset)`), pushing `(node, index, start+offset)`
and subtracting 1 for the enclosing node's open token → `O(depth)`. Results are
cached in a 12-slot WeakMap per doc. **The gotcha `textOffset` exists to paper
over:** a text node is one `Node` holding many characters, so a position inside
it is not a tree position, and there is no addressable position "between two
marks inside a run of text" — which is why any mark change must split the text
node.

### 7.4.2 `Step`, `StepMap`, `Mapping`

```ts
class StepMap {                         // ranges = flat [start, oldSize, newSize, ...]
  readonly ranges: readonly number[]
  invert(): StepMap          // new StepMap(this.ranges, !this.inverted) -- same array
  map(pos, assoc = 1): number | null
  mapResult(pos, assoc): MapResult
  forEach(f(oldStart, oldEnd, newStart, newEnd))
}
class MapResult { pos; DEL_BEFORE=1; DEL_AFTER=2; DEL_ACROSS=4; DEL_SIDE=8 }
class Mapping {
  readonly maps: readonly StepMap[]
  slice(from?, to?); map(pos, assoc = 1); mapResult(pos, assoc)
  appendMap(map); appendMapping(other); appendMappingInverted(other); invert()
  getMirror(n)/setMirror(n,m)
}
```

`_map` walks chunks: `start = ranges[i] - (inverted ? diff : 0)`; if
`pos <= end` then `side = !oldSize ? assoc : pos == start ? -1 : pos == end ? 1
: assoc` and the result is `start + diff + (side < 0 ? 0 : newSize)`; else
`diff += newSize - oldSize`. Consequences: a pure insertion exactly at `pos`
resolves by `assoc` (−1 stays before, +1 moves after); at the *start* boundary
of a deletion the position is pushed left and at the *end* boundary right;
strictly inside a deleted stretch it collapses to `start + diff`. `MapResult`
flags: `deleted = DEL_SIDE`, `deletedBefore = DEL_BEFORE|DEL_ACROSS`,
`deletedAcross = DEL_ACROSS` — "when content on only one side is deleted, the
position itself is only considered deleted when `assoc` points in the direction
of the deleted content." `recover = makeRecover(index, offset) = index + offset
* 2^16` (arithmetic, not `<<`, so a double stays exact) lets `Mapping._map` jump
across already-inverted maps and restore the exact pre-step offset, which is
what makes map∘invert lossless.

**`Transaction.selection` is
`curSelection.map(doc, mapping.slice(curSelectionFor))`** — the selection is
*lazily* mapped through only the steps appended since it was last valid. **That
one line is the collaboration payoff.** Selection mapping uses `assoc = 1` for
the head and `-1` for the anchor.

**Nomenclature corrections:** there is no `StepMap.invertedRanges` (inversion is
a boolean flag `inverted`) and no `Mapping.append` (it is
`appendMap`/`appendMapping`/`appendMappingInverted`). **Rebasing is not in
`prosemirror-transform`**: `Rebaseable` is a *private* class inside
`prosemirror-collab/src/collab.ts` (the exported symbol is `rebaseSteps`). For
Niman this is good news: **undo needs only `Mapping` + `invert`, and there is
no collab.**

`Transform` API: `replace`, `replaceWith`, `addMark`, `removeMark`,
`setNodeMarkup`, `setNodeAttribute`, `split`, `join`, `wrap`, `lift`, `delete`,
`insert`, `replaceRange`/`replaceRangeWith`/`deleteRange` (which expand to whole
covered parents while `contentMatch.validEnd`/`canReplace` allow, and step out of
textblock starts so deleting a whole line does not merge paragraphs),
`tr.doc`, `tr.docChanged`, `changedRange()`. On failure to fit a slice directly,
a `Fitter` walks a `frontier` of content matches and either `openMore()` (raise
the slice's openStart), `dropNode()` (drop a wrapper), or `findWrapping` — and
can end with a `ReplaceAroundStep` instead of a `ReplaceStep`.

### 7.4.3 The view: `ViewDesc`-tree diffing

`ViewDesc` is an abstract DOM mirror: `NodeViewDesc`, `MarkViewDesc`,
`TextViewDesc`, `WidgetViewDesc`, `CustomNodeViewDesc`, plus `NodeView`/`MarkView`
extension interfaces, and each DOM node gets a `dom.pmViewDesc` back-pointer.
Dirty levels are `NOT_DIRTY=0, CHILD_DIRTY=1, CONTENT_DIRTY=2, NODE_DIRTY=3`,
propagated by `markDirty`/`markParentsDirty`. **There is no `ViewDesc.sync()`**
— the entry point is **`NodeViewDesc.update(update)` → `updateChildren` →
`ViewTreeUpdater` + `renderDescs`**. `updateChildren` runs `iterDeco`, which
splits text nodes at decoration boundaries and feeds widgets to `placeWidget`,
then for each child tries in order `findNodeMatch` → composition case →
`updateNextNode` → `recreateWrapper` → `addNode`, then `syncToMarks([])`,
`addTextblockHacks()` (trailing `<br class="ProseMirror-trailingBreak">`,
`<img class="ProseMirror-separator">`), `destroyRest()`, and finally
`renderDescs(contentDOM, children, view)` which does only
`insertBefore`/`removeChild`.

**`preMatch(frag, parentDesc)` is the key optimisation:** walk the fragment and
the desc children **from the end** while `desc.node == frag.child(fI-1)` by
reference, producing `{index, matched: Map<desc, fragIndex>, matches}` —
unchanged suffixes are recognised in `O(suffix)` and each matched desc is
reserved so it cannot be stolen by another index. `findNodeMatch` then scans at
most 5 children ahead, and `updateNextNode` refuses a desc whose reserved index
differs.

`readDOMChange`/`parseBetween`/`readMutation` convert observed DOM mutations
back into document steps: it snaps the range out to the enclosing block, uses
`docView.parseRange` plus `DOMParser.parse(parent, {topNode, topMatch,
topOpen: true, from, to, findPositions, ruleFromNode, ...})` (where
`ruleFromNode` consults `dom.pmViewDesc.parseRule()` so custom views re-parse as
themselves), diffs the slice with `findDiff`, then **reinterprets the DOM diff
as intent**: `isMarkChange` → `addMark`/`removeMark`; a deletion inside one text
node → `delete` + `tr.ensureMarks(...marksAcross(...))`; a pure insertion →
`insertText` (after the `handleTextInput` prop); `looksLikeBackspace` → a
synthetic Backspace key. **Nomenclature: there is no `ReadOnly` class** —
read-only is `view.editable` (the `editable` prop), which gates
`registerMutation` inside `DOMObserver.flush()`. **Flutter has no such path,
which removes a whole class of bugs.**

### 7.4.4 Lexical: dirty-node-driven reconciliation

- `LexicalNode` (`__key`, `__parent`, `__type`), `ElementNode` (`__first`,
  `__last`, `__size`, `__cachedText`), `TextNode` (`__text`, `__format`,
  `__style`, `__mode`). `NodeKey` is a random string;
  `EditorState._nodeMap: Map<NodeKey, LexicalNode>`; children are a doubly-linked
  list, so `getChildAtIndex(i)` walks from whichever end is nearer; the DOM
  back-pointer is `__lexicalKey_<editorKey>`, so `$getNodeByKey(key)` is O(1).
- **Dirty state is *editor-level*, not a per-node bitmask.** Verified against
  `main` and tags v0.6.0/v0.12.0/v0.23.1: the bitmask constants in Lexical are
  *text format* flags (`IS_BOLD = 1` … `IS_CAPITALIZE = 1024`). The real
  machinery is:
  ```ts
  LexicalEditor {
    _dirtyType: 0 | 1 | 2        // NO_DIRTY_NODES | HAS_DIRTY_NODES | FULL_RECONCILE
    _dirtyLeaves: Set<NodeKey>
    _dirtyElements: Map<NodeKey, boolean>   // true = itself, false = descendant
    _cloneNotNeeded: Map<NodeKey, LexicalNode>
  }
  LexicalNode.isDirty() => editor._dirtyLeaves.has(this.__key)
  ```
  `getWritable()` performs **copy-on-write**: it clones the node out of the
  frozen previous state, registers the clone in `_nodeMap` and `_cloneNotNeeded`,
  and calls `internalMarkNodeAsDirty`, which walks ancestors up to the root
  setting each to `false` (stopping early if already present) and finally sets
  the node itself. **The transferable pair is "copy-on-write + a dirty set
  consulted by the reconciler", not a per-node flag.**
- `$reconcileRoot`/`$reconcileNode`/`$reconcileChildren`/`$reconcileNodeChildren`/
  `$createNode` live in **core, in `packages/lexical/src/LexicalReconciler.ts`**
  — there is **no `@lexical/dom` package and no `reconciler.ts` there**, and no
  `getDiff`, `isSameNode`, `ReconcilerContext` or `syncNodeSelection` anywhere.
  The algorithm: `$reconcileNode(key, parentDOM)` computes
  `isDirty = treatAllNodesAsDirty || _dirtyLeaves.has(key) ||
  _dirtyElements.has(key)`, then the **fast path**
  `if (prevNode === nextNode && !isDirty)` reuses
  `editor._keyToDOMMap.get(key)` verbatim; otherwise it calls
  `$updateDOM(nextNode, prevNode, dom, editor)` and recreates if that returns
  true. `$reconcileNodeChildren` is a **Set-based keyed diff**: `prevKey ===
  nextKey` → recurse; `prevKey` absent from the next set → `$destroyNode`;
  `nextKey` absent from the previous set → `$createNode`; otherwise **move**,
  `slot.withBefore(siblingDOM).insertChild(getElementByKeyOrThrow(nextKey))` — a
  move of an existing element, never a re-create. Two-phase update: all model
  mutation inside `editor.update`, one batched reconcile afterwards, and
  `MutationObserver` input re-enters through `updateEditorSync` as a *model*
  update, never a direct DOM edit.
- `@lexical/markdown`: `Transformer`s (`TextMatchTransformer`,
  `ElementTransformer`, `MultilineElementTransformer`) plus
  `$convertToMarkdownString`/`$convertFromMarkdownString`. **Explicitly lossy.**
- **MarkText's "muya" does *not* diff blocks with snabbdom.** snabbdom
  `patch()` is for *floating UI*; inline content is built as vnodes then
  **serialized with `snabbdom-to-html` and assigned via `innerHTML`** — not a
  diff. The real engine is **`ot-json1` + `ot-text-unicode`**: JSON block state,
  OT ops composed per animation frame, `fast-diff` for text input. A *third*
  model (OT on a JSON tree), evidence that "block list + per-frame op
  composition" is workable — not a model to copy for a disk-is-truth app.

### 7.4.5 Transferable ideas, and the lesson for Niman

1. **Keyed identity + a per-key DOM cache** turns the children diff into
   `Set.has` plus `insertChild`, so reorders never re-create DOM. Lexical:
   `$reconcileNodeChildren`; ProseMirror: `preMatch` + reference equality.
2. **Dirty propagation from the root**, so the reconciler walks the root→leaf
   spine of the change and skips every clean sibling via
   `prevNode === nextNode && !isDirty`. Cost is `O(depth + dirty)`, not
   `O(document)`.
3. **Copy-on-write `getWritable()`** gives O(1) versioned snapshots and makes
   "current vs pending state" and undo cheap.
4. **Positions as `(nodeKey, offset)`** (Lexical) versus **integers**
   (ProseMirror): keys need no tree resolution and survive sibling moves, at the
   cost of needing an explicit key→DOM lookup; integers are cheap to store and
   map but every resolution walks the tree.

> Any editor that hides syntax **must** have a position-mapping layer, and it
> must be a *value* (a `Mapping`) that composes with every other mapping, not a
> cached integer.

Concretely:

1. Build `StepMap`/`Mapping`/`MapResult` in Dart (~200 lines). Same data as
   CM6's `ChangeDesc`/`mapPos`; ProseMirror's `assoc` convention and
   `deleted`/`deletedBefore` reporting are what a selection needs.
2. Alongside the source `Text`, keep a **projection map**: `(sourceRange,
   displayRange | hidden | widget)` segments. Then `displayToSource`/
   `sourceToDisplay` are two prefix-sum walks (or a Fenwick tree); the caret is
   stored as `(sourceOffset, assoc)`; a click at display x maps display→source
   with `assoc = 1`; an arrow key moves in **source** space and is then
   **snapped** to the next visible position if it landed inside a hidden range.
   **That snapping rule is the actual fix for "arrows walk invisible
   characters".**
3. The projection map must be persistent so it maps through a `ChangeSet` in
   `O(log n)` instead of being rebuilt.
4. Pair it with **`EditorView.atomicRanges`-style atomicity** (CM6) so
   arrow-key and selection motion treat a hidden range as one unit instead of
   walking into it, and honour a `mousedown` flag so drag-select does not fight
   widget reveal (Obsidian's `livePreviewState.{mousedown}`).
5. **Never store the selection as a display offset.** That is the bug that broke
   `markdown_editor_live`, and `editor-alternatives.md` measured it as real.

---

## 7.5 Live preview in the wild

### 7.5.1 Obsidian Live Preview

Obsidian's editor is **CodeMirror 6** — its own docs say so ("Obsidian uses
CodeMirror 6 (CM6) to power the Markdown editor… an Obsidian *editor extension*
is the same thing as a *CodeMirror 6 extension*"), and the API package pins
`@codemirror/state@6.7.0` / `@codemirror/view@6.43.5`. Live Preview shipped in
0.13.0, whose release notes literally call it "Live Preview (also known as
'WYSIWYG' mode)".

| axis | values |
|---|---|
| **views** | Reading vs Editing (`MarkdownViewModeType = 'source' \| 'preview'`) |
| **modes inside Editing** | Live Preview vs Source — *both* live in `'source'`; Reading is `'preview'` |
| **public API** | `editorLivePreviewField: StateField<boolean>`, `editorInfoField: StateField<MarkdownFileInfo>`, `editorEditorField: StateField<EditorView>` (the only public route to the CM6 view), `livePreviewState: ViewPlugin<{mousedown: boolean}>`, `Plugin.registerEditorExtension(extension)` |

Documented mechanics:

- The rule is **cursor-conditional**: "When your cursor enters formatted
  content, the underlying syntax becomes visible for editing"; LP is "only
  displaying Markdown syntax around the cursor". Release notes confirm the
  model: "Live Preview will now detect whether the editor is focused to apply
  syntax hiding" (0.13.20); "Improved selection when selecting across hidden
  Markdown formatting syntax" (0.13.8); "backslash escapes hidden off-line"
  (0.14.11); "headings always show `#` on that line" (0.13.1).
- The mechanism, in CM6 terms: **replace decorations over the marker ranges +
  widget decorations for replacements**, rebuilt on
  `docChanged | viewportChanged | selectionSet`, **skipping any range that
  overlaps the selection**. The recipe comes from CM6's author: "Replacing
  widget decorations would be the way to go… Make sure you skip the line with
  the selection head in it, and update (probably a full rebuild of the widgets
  inside the viewport is fine) when the selection, document, or viewport
  changes."
- **Atomic ranges are not in Obsidian's public API but real plugins add them:**
  `provide: plugin => EditorView.atomicRanges.of(view => view.plugin(plugin)
  ?.atomicRanges ?? RangeSet.empty)`, with
  `Decoration.replace({widget, inclusiveStart, inclusiveEnd, block: false})`.
- **Block widgets** (tables, code blocks, callouts, embeds, display math) are
  `Decoration.replace` with `block: true` and a `WidgetType` with
  `contenteditable=false`. `eq()` must be implemented or the widget is
  re-created on every update. Editing a rendered block reverts it to source —
  "editing the table transforms the whole table to its source markdown format"
  — and cell-by-cell table editing is still an open request.
- Math moved from **MathJax to Temml** in 1.14.0 (2026-09-02) for LP + Reading.

Reported pain points, with sources:

1. **Caret jumps / layout shift on reveal** — "when the editor toggles between
   showing and hiding Markdown syntax, the lines shift and the cursor jumps"
   (forum 109155); headings shift rightward to make room for `#` when clicked;
   Obsidian's own release notes fix "cursor jumps back with some IMEs in Live
   Preview" (0.13.31), "indenting/unindenting sometimes moves the cursor to
   unintended spots" (0.13.10), and still in 1.14.0 "incorrect cursor placement…
   with multiple formatting markers (e.g. `**__text__**`)".
2. **Editing a rendered block reverts it to source** — callouts and tables in
   callouts un-render wholesale; the most repeated complaint (2022→2026).
3. **Hit-testing on rendered blocks** — "click position detection to misbehave"
   with many embeds/images (0.13.27); "clicking or selecting the end of the
   file selects to the beginning when there is a block at the end" (0.13.8).
4. **Atomicity/selection friction** — Shift+Up/Down and up/down over hidden
   blocks (0.13.18/0.13.22), Vim-mode block traversal (0.14.3).
5. **A reported widget ceiling** — after ~25–30 callout widgets LP stops hiding
   `**` and stops rendering callouts (forum 113449). The "CM6 widget budget"
   explanation is the reporter's inference, **not confirmed by Obsidian**.
6. **Plugin/theming fragility** — themes are warned not to change vertical
   margins in LP classes; release notes fix "some plugins CSS causes Live
   Preview's selections to break" (0.13.13).
7. `%%comments%%` stay visible in LP, inline footnotes do not work in LP, and
   Source/LP do not run PrismJS (so code highlighting differs from Reading).

Reading view is a separate, block-granular renderer: "normally, when you use
proper headings and markdown blocks (generally anything separated by a
completely empty line in between), the app can recognize each block, and only
re-render unchanged blocks" (developer statement, 2020, pre-CM6 — the engine
identity for today's Reading view is **unverified**; only a moderator's "we use
commonmark with some minor additions" exists). The editor itself is
viewport-incremental only: "supports huge documents with millions of lines… the
editor only renders what's visible (and a little bit more)".

**Lesson.** Obsidian's architecture is exactly candidate (a), and it is the
best-known proof that (a) works at scale. Its pain points are *all* in the
projection↔source mapping and in height instability — addressable with a real
`Mapping` + atomic-ranges layer (§4) and a real `HeightMap` (§2.10). **And the
escape hatch is that live preview is optional:** keeping the *source editor*
un-hidden (highlight-only, like iA Writer) and the *preview* read-only removes
the entire class of pain without changing the architecture.

**The consolidated engineering minimum for a CM6-style concealer:** syntax tree
→ marker ranges; `Decoration.replace` for markers + `Decoration.widget` for
replacements; skip and reveal any range overlapping `selection.main`, honouring
a `mousedown` flag; `EditorView.atomicRanges.of(...)` for arrow-key/selection
atomicity; rebuild on `docChanged | viewportChanged | selectionSet`; prefer a
viewport-scoped **ViewPlugin** unless vertical layout must change (then
StateField); and expect the three unavoidable costs — layout shift on reveal,
hit-testing across atomic ranges, and destroying block widgets to edit their
interior.

### 7.5.2 One line each

| app | rendering model | notable |
|---|---|---|
| **Typora** | single surface, no preview pane; inline styles appear as you type, **block tags (`###`, `- [x]`) hidden once the block is rendered**; cursor in the middle of a span expands it to source | "What You See Is What You Mean", not WYSIWYG. Source mode is **Ctrl/Cmd + / — F8 is Focus Mode.** Bundles CodeMirror, **morphdom**, rangy, MathJax. There is **no "TypeMark"** anywhere. Parser/incremental pipeline: unverified (closed source). |
| **Bear** | native macOS/iOS; Markdown **styled in place**, plus a **"Hide Markdown"** setting (off by default); no preview pane | CommonMark + `~underline~`, `==highlight==`, `[[wikilinks]]`, `#tags`; storage is a **SQLite DB**, not one file per note; CloudKit sync (notes >500 k chars not synced); math **hides caret-scoped** exactly like Obsidian LP; the editor was developed as *Panda* and spun out as *Lettera*. |
| **iA Writer** | plain text with Markdown colouring ("Auto-Markdown"); **has a Preview pane**, but the editor never hides syntax | its "**Syntax Highlight**" feature is **parts-of-speech colouring**, not Markdown. Quotes Gruber: "Don't hide the formatting characters; just style/colour them", and calls cursor-driven show/hide ("the jiggle") out as "unpleasant and distracting". Math is **KaTeX**; Android discontinued 2024-09. |
| **Zettlr** | CM6 + `@lezer/markdown` + ~13 custom Lezer extensions; **no separate preview pane** — renders in place via per-type renderers over `syntaxTree(state).iterate({from, to})` with `Decoration.replace`/`WidgetType`, skipping nodes the selection overlaps | **`markdown-it` is not a current dependency** — export goes through remark/unified/rehype. Closest desktop app to Niman's shape; CM5→CM6 was Zettlr 3.0. |
| **Logseq** | outliner: blocks are the unit (a standalone ClojureScript `outliner` lib over a DataScript graph); Markdown is the disk serialization with `id:: <uuid>` | the block *is* the incremental unit; the new DB version moved canonically to SQLite with lossy Markdown export |
| **Notion** | every block is an object with a UUID, `properties`, `type`, an ordered `content` array of child ids, and `parent` for permissions; transactions of `set`/`update`/`listBefore`/`listAfter` ops with precomputed inverses | no Markdown parse step exists. *(per-block-contenteditable and "virtualized block list" are third-party findings, unverified by Notion.)* |
| **Craft** | block-based: "every paragraph in Craft is a Block", a block with nested content becomes a Page; own components/layout, not SwiftUI | Markdown is interchange, not the editing model |
| **MarkText "muya"** | block records (JSON) + `ot-json1`/`ot-text-unicode` OT ops composed per animation frame; content serialized from vnodes to `innerHTML`; markers hidden by re-tokenizing and tagging marker spans `mu-hide` (`display:inline-block; width:0; height:0; overflow:hidden`), toggled per token so the marker shows at the caret | a worked example of "blocks + OT" for Markdown, and of its bugs; **not** a snabbdom content diff. `ScrollPage.updateState` is the blunt "recreate every block" path. |
| **Ulysses** | single-surface WYSIWYM: markup stays visible as styled tokens, formatting is applied at export; editor themes can `visibility: hidden` tag classes | Markdown XL dialect; separate Preview window (⇧⌘P) |
| **VNote** | Qt/C++ notebook manager; the editor is a **native widget** (`vtextedit`'s `MarkdownEditor` over `QTextEdit`), QtWebEngine only for preview panes | not a web editor at all; in-place preview, source-block folds, editable table preview written back to Markdown |
| **HackMD / CodiMD / HedgeDoc** | CodiMD: CM5 + `markdown-it` split pane, `scrollSync` aligned by wrapping the renderer so block tokens get `class="part"` with `data-startline`/`data-endline`; collaboration is **OT, not CRDT** (`ot.js` + `ot.CodeMirrorAdapter`) | HedgeDoc 2.0 was rebuilt on CM6 + React + **Yjs CRDT** with a hand-rolled `Y.Text`↔CM6 `ViewPlugin`; the line-marker scroll sync is exactly the bug `ScrollMap` fixed by walking block heights instead of a fraction |

**Also relevant:** VS Code's markdown preview re-parses the **whole document**
per change (`engine.parse(text, env)`, `TokenCache` keyed on
`{uri, version, …}` so any edit misses) with a 300 ms debounce, then patches the
DOM with **morphdom**; its source-line map is a markdown-it core rule that sets
`data-line = token.map[0]` and `class="code-line"` on every non-inline token.
**That is the naive design Niman already beat** — and the reason its own
`ScrollMap` walks block heights instead of a line fraction.

**Cross-cutting.** Syntax hiding in every family is *replace/atomic decoration
over a still-present range*, never deletion — which is precisely why "Live
Preview is not WYSIWYG" and why widgets become caret traps. **If Niman hides
syntax, expect to solve exactly the Obsidian/MarkText problems: atomic ranges,
click-to-position inside a hidden range, and IME/composition interaction with
widgets.**

---

## 7.6 Virtualized document rendering in other ecosystems

The three questions: **(1) lay out only the visible blocks; (2) keep scroll
stable when off-screen content changes height; (3) estimate the height of
never-laid-out blocks.**

**The invariant every system shares:** nobody lays out the whole document. Each
keeps a per-unit table with **monotone prefix sums + a measured-size override +
an "invalidate from index i forward" frontier**, and estimation is always
"exact for the known, extrapolate the tail".

### 7.6.1 VS Code / Monaco

**Model.** `ITextModel` (`TextModel`) over a `PieceTreeTextBuffer`: a **piece
table** — a red-black tree whose nodes are
`Piece{bufferIndex, start, end, lineFeedCnt, length}` over two immutable
`StringBuffer`s (the original disk content and an "additions" buffer appended to
on every edit). An insert splits a piece and references the additions; **bytes
are never moved**. Line starts live per buffer (`StringBuffer.lineStarts`)
rather than on the model — *there is no `TextModel._lineStarts` today* — and
`getLineContent(n)` *derives* the text rather than materialising a line array.
`applyEdits` sorts ascending, checks overlap, reduces ≥1000 ops to one, computes
inverse ranges, then applies **descending** so earlier offsets stay valid.
`_isTooLargeForTokenization` is decided once (`LARGE_FILE_SIZE_THRESHOLD` 20 MB,
300 000 lines, 256 M chars, model-sync limit 50 MB).

**Wrapping and `PositionAffinity`.** `ViewModelLinesFromProjectedModel` holds
one `IModelLineProjection` per model line plus a
`ConstantTimePrefixSumComputer` over *wrapped-line counts*.
`ModelLineProjectionData{injectionOffsets, injectionOptions, breakOffsets[],
breakOffsetsVisibleColumn[], wrappedTextIndentLength}` answers
`getOutputLineCount()`/`translateToInputOffset`/`translateToOutputPosition`.
**`PositionAffinity.None|Left|Right|LeftOfInjectedText|RightOfInjectedText`** is
the "which wrapped line does offset N belong to" answer: an offset exactly on a
break resolves to the previous line with `Left` and to the next with
`Right`/`None`. **Same `assoc` problem as §2.2, different costume.**

**Vertical index: heights are exact by rule, never estimated.**
`LinesLayout` binary-searches lines by `getVerticalOffsetForLineNumber(mid)`;
`getLinesViewportData` walks from the start line accumulating heights and
interleaved whitespace; `bigNumbersDelta` subtracts `floor(offset/500000)
*500000` because "IE cannot handle units above about 1,533,908 px" — the same
class of hack as react-virtualized's rescaling.

`LineHeightsManager` keeps `_orderedCustomLines: CustomLine{decorationId, index,
lineNumber, specialHeight, prefixSum, maximumSpecialHeight}`, so
`heightForLineNumber(n)` is `maximumSpecialHeight` if a `lineHeight` decoration
covers the line else `_defaultLineHeight`, and the accumulated prefix sum is
**exact** — `getLinesTotalHeight()` is `O(log n)` and **there is no estimation
layer at all**. Mutations are batched (`PendingChange` union, `_commit()` on
first read) and recompute `prefixSum`/`maximumSpecialHeight` **only from
`_invalidIndex` forward**. `ConstantTimePrefixSumComputer` is the extreme
version: `_prefixSum[]` **and** `_indexBySum[sum] = idx` for every integer pixel
in the block's range, so `getIndexOf(sum)` is a direct O(1) array lookup while
`_ensureValid()` refills forward only. **This is the structure to copy for a
per-block height table**, with a Fenwick tree as the fallback if extents must
stay floating point. Memory is one int per pixel of total extent (~1.2 MB for a
300 k-px document) — a trade VS Code and Chromium both make.

**Widgets, hidden areas, rendering.** There is **no `viewZones.ts`/`IViewZone`
today** — injected widgets are *whitespace*: `IEditorWhitespace{id,
afterLineNumber, height, prefixSum}` plus
`IWhitespaceChangeAccessor{insertWhitespace, changeOneWhitespace,
removeWhitespace}`; `ICodeEditor.changeViewZones` is the public wrapper. Hidden
ranges are `HiddenAreasModel` + `ViewModelLinesFromProjectedModel.setHiddenAreas`
setting `projection.setVisible(false)` and `projectedModelLineLineCounts
.setValue(i, 0)`, with `_ensureAtLeastOneVisibleLine()`. `ViewLineData` /
`ViewLineRenderingData` feed `renderViewLine`; `RenderLineInput.equals()` is used
to skip re-rendering unchanged lines, and `CharacterMapping` packs
`partIndex<<16 | charIndex` into a `Uint32Array` so columns/DOM positions are
recovered from a mapping table rather than recomputed. Inline injected text is a
decoration (`ModelDecorationInjectedTextOptions`), which is how a
`ReplacementSpan` equivalent works. Tokens > `Constants.LongToken = 50` chars
are split (huge spans make DOM range reads slow).

**Minimap — the *second* virtualizer**, with its own structure:
`MinimapLayout.create` decides which lines fit
(`minimapLinesFitting = floor(canvasInnerHeight / minimapLineHeight)`) with
anti-flicker hysteresis; `RenderData{_imageData, _renderedLines}` and
`MinimapLine{dy}` with `onContentChanged()` setting `dy = -1`;
`_renderUntouchedLines(imageData, ..., lastRenderData)` **byte-copies unchanged
line strips from the previous `ImageData`** (`targetData.set(subarray)`) and
returns `[dirtyY1, dirtyY2, needed[]]`, then only `needed[]` lines are
re-rendered and blitted with a partial `putImageData`; `MinimapCharRenderer`
holds pre-baked glyph bitmaps (16×10 sampled, `BASE_CHAR_WIDTH = 1`). **A minimap
is not a scaled-down `ViewLines`; it is a purpose-built, much cheaper render.**

**Monaco is literally the same code** (`monaco-editor` is "generated straight
from VS Code's sources with some shims"). The standalone model interface is
`ITextModel` (not `IModel`), and it exposes the same machinery including
`getCustomLineHeightsDecorations`. Two things worth stealing from its
*packaging*: the **worker split** (one generic `editor.worker` for diffs/links,
plus per-language workers) — Niman's analogue is `Isolate`, and
`preview/preview_work.dart` already does it, with a documented reason for not
using `Isolate.run`; and **where Monaco does *not* virtualize**: the diff is
whole-model in the worker (`hideUnchangedRegions` is presentation only). Niman's
analogue: do not run a document-wide diff on the UI isolate.

### 7.6.2 Android: `Layout`/`StaticLayout` + `RecyclerView` + Markwon

- **`android.text.Layout`** is the text layout engine. Subclasses:
  `StaticLayout` (immutable), `BoringLayout` (single-line fast path),
  **`DynamicLayout`** (editable `Spannable`). Derived and final on `Layout`:
  `getLineBottom(l) = getLineTop(l+1)`, `getLineBaseline(l) =
  getLineTop(l+1) - getLineDescent(l)`, `getHeight() = getLineTop(getLineCount())`.
  Query API: `getLineCount`, `getLineTop/Bottom/Start/End`, `getLineForOffset`,
  `getOffsetForHorizontal(line, x)`, `getPrimaryHorizontal`, `getDesiredWidth`.
  **That is the per-line height table Niman needs** — and Flutter's
  `TextPainter.computeLineMetrics()` gives it per paragraph as
  `LineMetrics{hardBreak, ascent, descent, height, width, left, baseline,
  lineNumber}`. *Correction: `mLines` is private to `StaticLayout`, and modern
  AOSP uses **columns** — `COLUMNS_NORMAL = 5`, `COLUMNS_ELLIPSIZE = 7` with
  `START=0, DIR=0, TAB=0, TOP=1, DESCENT=2, EXTRA=3, HYPHEN=4,
  ELLIPSIS_START=5, ELLIPSIS_COUNT=6` — not "two ints per line".*
- **`DynamicLayout` is the incremental-relayout story**: `ChangeWatcher
  implements TextWatcher, SpanWatcher` routes every text/span change into
  `reflow(s, where, before, after)`, which expands `[where, where+after)` to
  paragraph bounds and then over `WrapTogetherSpan`s (so `LeadingMarginSpan2`/
  `LineHeightSpan` stay atomic), builds a **partial** `StaticLayout` from a
  static pool, then splices: `mInts.deleteAt(startline, endline-startline)`,
  `mObjects.deleteAt(...)`, `mInts.adjustValuesBelow(startline, START,
  after-before)`, reinsert `n` lines, then `updateBlocks(startline, endline-1,
  n)` which shifts `mBlockEndLines[i] += deltaLines` for `i >=
  newFirstChangedBlock`. **A per-*block* dirty frontier over a per-*line*
  table.** `TextLine` (`@hide`) turns `Directions` runs + spans into drawing,
  applying `MetricAffectingSpan.updateMeasureState` per run — which is *why* any
  layout-affecting span forces a rebuild while `UpdateAppearance`-only spans
  reuse it.
- **Spans**: `Spanned` flags (`SPAN_MARK_MARK=0x11` … `SPAN_PARAGRAPH=0x33`,
  `SPAN_PRIORITY_SHIFT=16`), `SpanWatcher`, `TextWatcher`.
  `SpannableStringBuilder` is a **gap buffer** (`char[] mText`, `mGapStart`,
  `mGapLength`, parallel span arrays, `moveGapTo` rewriting spans relative to
  the gap, gap compacted when `mGapLength > 2*length()`).
  `MetricAffectingSpan extends CharacterStyle` and
  **`ReplacementSpan extends MetricAffectingSpan` with
  `getSize(Paint, CharSequence, start, end, FontMetricsInt fm)` — inline
  images/math work by mutating `fm` so the line's ascent/descent accommodate the
  replacement.** That is the Android answer to an inline math widget.
- **Off-thread measurement**: `PrecomputedText`/`PrecomputedTextCompat.create` +
  `getTextFuture(text, params, executor)` + `AppCompatTextView.setTextFuture`,
  and Markwon's `PrecomputedFutureTextSetterCompat` for RecyclerView. Flutter's
  analogue does not exist: **`dart:ui` `Paragraph`/`Canvas.drawParagraph` are
  root-isolate-only, so parsing can go to `Isolate.run` (as `PreviewWork`
  already does) but height measurement cannot** — measure on the UI isolate or
  ship a heuristic. Same constraint as Android and as TextKit.
- **Markwon** parses with `commonmark-java` using **`IncludeSourceSpans`**
  (`NONE | BLOCKS | BLOCKS_AND_INLINES`) to retain source ranges on nodes — the
  source-span idea again — then renders via `MarkwonVisitor` +
  `MarkwonSpansFactory` (`SpanFactory` per node type) + `SpannableBuilder`.
  Block spans are `LeadingMarginSpan`s; `ReplacementSpan` is used only for
  inline images (`AsyncDrawableSpan`, scheduled by `AsyncDrawableScheduler`).
  **Virtualization is `markwon-recycler`**: `MarkwonAdapter` +
  `MarkwonAdapterImpl` (a `RecyclerView.Adapter`) with exact-class-keyed
  `Entry{createHolder, bindHolder, clear, id}` and
  `MarkwonReducer.directChildren()` producing **one RecyclerView item per
  top-level `BlockNode`**.
  *Corrections: there is **no** `RecyclerPlugin`, `RecyclerMarkwonView`,
  `RecyclerPlugin.Ids`, `ViewPool`, `ScrollDirectionListener`,
  `MarkwonRecyclerViewPlugin` or `ScrollingPlugin` anywhere in the repo
  (verified master + v3.1.0 + v2.0.2). `TableRowsScheduler` does **not** chunk
  table rows — it only coalesces invalidations (`view.removeCallbacks(r);
  view.post(r)`), and `markwon-recycler-table` renders a whole table into one
  `TableLayout` in a single row. The "virtualize tables row-by-row" idea is
  therefore **not** prior art found here, though it is still the right design
  for a 500-row table.*
- **Transferable**: (i) block-level items = Flutter sliver children; (ii)
  per-block view-type pools = element reuse with `ValueKey`; (iii) a table
  should be virtualized row-by-row rather than laid out as one paragraph — a
  real risk for `preview/html_table.dart` at scale, though this note has only
  22 table lines.

### 7.6.3 iOS/macOS: TextKit

- **`NSTextStorage`** extends `NSMutableAttributedString`; an edit calls
  `edited(_ editedMask: NSTextStorageEditActions, range: NSRange,
  changeInLength: Int)` → `processEditing()`, whose order is will → delegate
  will → **fix attributes** → did → delegate did → notify **each** layout
  manager. *Correction: the public callback is
  `textStorage(_:edited:range:changeInLength:invalidatedRange:)` /
  `processEditing(for:edited:range:changeInLength:invalidatedRange:)`, not
  `invalidateLayout:`.* Apple's example: "deleting a paragraph separator
  invalidates the layout information for all characters in the paragraphs that
  precede and follow the separator."
- **`NSLayoutManager`** — `invalidateLayout(forCharacterRange:
  actualCharacterRange:)` ("only invalidates information; it performs no glyph
  generation or layout"), `invalidateDisplay`, `ensureLayout(for:)` /
  `(forCharacterRange:)`, `glyphRange(for:)`, `lineFragmentRect(forGlyphAt:
  effectiveRange:)`, `boundingRect(forGlyphRange:in:)`, `usedRect(for:)`,
  `drawBackground(forGlyphRange:at:)`. **TextKit 1's invalidation is "from the
  edited glyph to the end"** — why a paste near the top of a huge `NSTextView`
  is slow. `textContainerChangedGeometry(_:)` invalidates "the specified text
  container **and all subsequent** text container objects".
- **`allowsNonContiguousLayout`** is the switch that matters: when `true` the
  layout manager **lays out only the glyph ranges it is asked about** and leaves
  the rest as **gaps**; `ensureLayout(for:)` fills a requested range on demand.
  It is **off by default** because "direct clients … have relied on the previous
  behavior—for example, by forcing layout for a specific glyph range, and then
  assuming that previous glyphs would therefore be laid out."
  `hasNonContiguousLayout` is a live state flag, not the switch. **This is the
  closest Apple analogue to CM6's viewport-only decoration building and to
  `HeightMap`'s gaps.** *There is **no**
  `estimatedLineFragmentHeight(forGlyphAt:)` — that symbol does not exist in any
  NSLayoutManager doc feed. The real TK1 estimate tools are
  `defaultLineHeight(for:)` and the delegate's `lineSpacingAfterGlyphAt:
  withProposedLineFragmentRect:`.*
- **TextKit 2 is explicitly viewport-based** — WWDC21 10061: "for performance,
  TextKit 2 uses viewport-based layout and rendering". `NSTextLayoutManager`
  replaces `NSLayoutManager` (with a singular `textContainer`, a KVO-compliant
  `usageBoundsForTextContainer`, and rendering attributes separate from storage
  attributes). `NSTextViewportLayoutController` +
  `NSTextViewportLayoutControllerDelegate`: "a viewport is a rectangular area
  within a **flipped** coordinate system expanding along the y-axis… the area
  corresponds to the user visible area **with an additional over-scroll
  region**"; the delegate gets
  `textViewportLayoutController(_:configureRenderingSurfaceFor:)` per visible
  `NSTextLayoutFragment`, and there is a
  `cacheRenderingSurface`/`retrieveCachedRenderingSurfaceFor` recycling API.
  `NSTextLayoutFragment{layoutFragmentFrame, renderingSurfaceBounds,
  textLineFragments, state}` with `.EnumerationOptions.estimatesSize` and
  `State.estimatedUsageBounds` ("hasn't performed a full layout yet… is
  returning an estimated bounds"). **The model: the viewport controller asks for
  fragments by viewport rect; TextKit lays out only those; unmeasured fragments
  are represented by their estimated size.** That is `HeightMap` +
  `visibleRanges` + a sliver, shipped by Apple.
- **`UITableView` self-sizing** — `rowHeight = automaticDimension` +
  `estimatedRowHeight`; "if your table uses self-sizing cells, the value of this
  property must not be 0", and the scroll-stability contract is normative:
  "**the table view actively manages the `contentOffset` and `contentSize`
  properties… Don't attempt to read or modify those properties directly.**"
  This **is** `SliverVariedExtentList` + `ScrollMap`, with the same jumpiness
  when the estimate is bad. *(Corrections: `UIHostingConfiguration` is iOS 16+
  with `minSize(...)`; `preferredMaxLayoutWidth` is on `UILabel`.)*
- **Swift ports as worked examples.** **STTextView** (TK2, GPL-3.0) is the most
  instructive: `viewportBounds(for:)` = visible bounds plus a prefetch band
  (`verticalPrefetch = visibleHeight * 0.5`, `upwardPrefetch =
  min(verticalPrefetch, bounds.minY)`); `configureRenderingSurfaceFor` reuses
  views through `fragmentViewMap: NSMapTable<NSTextLayoutFragment,
  STTextLayoutFragmentView>` (`.weakToWeakObjects()`), re-framing only when
  `!frame.isAlmostEqual(to: layoutFragmentFrame.pixelAligned)`, with
  `WillLayout` snapshotting the used views and `DidLayout` removing leftovers;
  `layoutText()` runs a **convergence loop (max 5)** of `layoutViewport()` until
  `!needsRelayout`, with a re-entrancy guard; content height uses
  `usageBounds.maxX/maxY` with the honest comment that the value "is an
  estimate: TextKit refines `usageBoundsForTextContainer` as more of the
  document is laid out". Its README is also a curated TK2 bug list
  (`usageBoundsForTextContainer` observers never firing, `lineFragmentPadding`
  not affecting `usageBounds` maxX, etc.).
  **CodeEditTextView** is *not* TK2 — it lays out with CoreText, and its
  `TextLineStorage` is an **augmented red-black tree** keyed by character
  offset with per-node `length`, `height`, `leftSubtreeOffset`,
  `leftSubtreeHeight`, `leftSubtreeCount`, giving `getLine(atOffset:)`,
  `getLine(atIndex:)` and `getLine(atPosition posY:)` in `O(log n)`; it seeds
  **every** node height with `estimatedLineHeight` on build (UITableView's trick
  applied to a layout tree), and `layoutLines(in rect:)` re-lays out a line only
  if the width changed, it was off-screen, or its height disagrees with the
  cached fragment — then *moves* cached fragment views, explicitly "similar to
  the lazy loading of collection or table views".

### 7.6.4 The browser

- **`content-visibility: auto`** + **`contain-intrinsic-size: <w> <h>`** — the
  browser skips layout/paint/hit-testing of off-screen elements and substitutes
  the intrinsic size in the scroll height; when the element becomes relevant,
  real layout replaces the estimate. `auto <length>` means "use the **last
  remembered size** iff the element is currently skipping its contents", and
  that concept is specified in **CSS Sizing 4** (not css-contain). The
  `contentvisibilityautostatechange` event (`skipped`) is the hook for
  deferring work. **Why the placeholder is mandatory:** size containment lays
  the element out "as if empty", so without `contain-intrinsic-size` the
  scrollHeight collapses and the scrollbar jumps as chunks cross the viewport.
  web.dev measured a travel blog's initial render going 232 ms → 30 ms.
- **Scroll anchoring** (`overflow-anchor: auto`, not inherited): the spec picks
  a priority candidate (focused editable, find-in-page match), else recursively
  examines DOM children (skipping fully-clipped subtrees, preferring fully
  visible nodes, deeper preferred), then applies `y1 - y0` at the end of a
  **suppression window** (one event-loop iteration). Chromium's
  `blink::ScrollAnchor` carries the direct link to this section:
  **`bool anchor_is_cv_auto_without_layout_`** — "set to true if the last anchor
  we have selected is a `content-visibility: auto` element that did not yet have
  a layout after becoming visible". The anchor can be picked while still at its
  `contain-intrinsic-size` placeholder and then relayout to its real size ⇒ a
  visible jump that the adjustment may not cover. **Mitigation: set
  `overflow-anchor: none` on the scroller (and on CV-auto ancestors) when you
  compute offsets yourself**, or the UA adjustment and your `scrollTop` write
  compose and double-shift.
- **Chromium dirty bits** (`core/layout/`; LayoutNG flattened — `core/layout/ng/`
  is gone): `NeedsLayout() = self_needs_full_layout_ || child_needs_full_layout_
  || needs_simplified_layout_`; `MarkContainerChainForLayout()` bails early if an
  ancestor already needs full layout and **stops at a display-lock boundary**
  (`ChildLayoutBlockedByDisplayLock()`), which is what contains
  `content-visibility: hidden` dirtiness; roots live in
  `LocalFrameView::layout_subtree_root_list_`; guards are
  `SetLayoutNeededForbiddenScope`. Layout produces an immutable fragment tree
  whose parent `ConstraintSpace` is the cache key, replacing the old
  under/over-invalidation dance.
- **Virtual list libraries** are the clearest statement of the structure:
  - `react-window` v1 `VariableSizeList`: `InstanceProps{itemMetadataMap:
    {[i]: {offset, size}}, estimatedItemSize, lastMeasuredIndex}`,
    `DEFAULT_ESTIMATED_ITEM_SIZE = 50`; `getItemMetadata` extends the prefix sum
    forward from `lastMeasuredIndex`; `findNearestItem` binary-searches, or
    **exponential-then-binary** when searching past the measured tail;
    `getEstimatedTotalSize = measuredTail + (itemCount - lastMeasuredIndex - 1)
    * estimatedItemSize`; `resetAfterIndex` sets
    `lastMeasuredIndex = min(lastMeasuredIndex, index - 1)`.
  - `react-virtualized` `CellSizeAndPositionManager`: `_cellSizeAndPositionData`,
    `_lastMeasuredIndex`, `_lastBatchedIndex`, `_estimatedCellSize`;
    `getTotalSize` = measured prefix + estimated tail ⇒ instant scrollbar;
    `_findNearestCell` scans back exponentially then binary-searches;
    `ScalingCellSizeAndPositionManager` rescales when the total exceeds the
    browser's scroll-offset cap (Chrome ~33.5 M px, Edge ~1.5 M px) — the same
    problem as VS Code's `bigNumbersDelta`.
  - `TanStack Virtual`: `measurementsCache: VirtualItem[]`, `itemSizeCache:
    Map<Key, number>`, `pendingMeasuredCacheIndexes`; `getMeasurements` is a
    memo that slices the cache to `min(pendingMeasuredCacheIndexes)` and rebuilds
    forward; `calculateRange` binary-searches `measurements[i].start` then walks
    forward; `resizeItem` computes `delta = size - (itemSizeCache.get(key) ??
    item.size)` and, if the item starts above the fold, accumulates it into
    `scrollAdjustments` applied on the next `_scrollToOffset`. Its default
    predicate is subtle and worth copying: a *first* measurement compensates when
    `itemStart < scrollOffset + adjustments`, but a *re-measurement* compensates
    only when `itemStart + itemSize <= scrollOffset + adjustments &&
    scrollDirection !== 'backward'` — "an item that merely *spans* the fold
    changes size *below* the anchor point, so shifting scrollTop by the delta
    would drag the viewport downward on every growth" (TanStack #1218).
  - **None of the three uses `IntersectionObserver` for index math** — visible
    range is pure arithmetic over `scrollTop` and the prefix-sum array; IO is
    only the render-ahead trigger.
  - The **anchor-node trick**: `before = anchor.getBoundingClientRect().top` →
    mutate → `scrollTop += anchor.getBoundingClientRect().top - before`, before
    paint. Equivalent to the UA's own anchoring; run one or the other.

### 7.6.5 Extracted techniques

**(1) Only lay out visible blocks**

- The unit must be a **block**, not a line: a Markdown block is the smallest
  unit whose layout is independent. `block_parse.dart` already buys this (block
  phase once, inlines on first build).
- Feed the sliver **extents you own**:
  `SliverVariedExtentList(itemExtentBuilder: (i, _) => heightIndex.extentFor(i))`.
  **But know its cost:** `RenderSliverVariedExtentList` extends
  `RenderSliverFixedExtentBoxAdaptor` (verified in the local SDK:
  `packages/flutter/lib/src/rendering/sliver_fixed_extent_list.dart:538`) —
  which is good — yet it **inherits the default `indexToLayoutOffset`, which
  loops from 0 accumulating extents, and `_getChildIndexForScrollOffset`, which
  loops until `position >= scrollOffset`** ⇒ `O(index)`/`O(n)` per layout
  query. `RenderSliverFixedExtentList` is O(1) because `itemExtent * index` is
  arithmetic. **So the right move is to subclass
  `RenderSliverFixedExtentBoxAdaptor` and override `indexToLayoutOffset` +
  `getMin/MaxChildIndexForScrollOffset` with prefix-sum lookups**, keeping
  `SliverChildBuilderDelegate` for child lifecycle.
- Flutter classes to know: `SliverMultiBoxAdaptorElement` (which owns the
  `SplayTreeMap<int, Element?> _childElements` and the
  `createChild`/`removeChild`/`didStartLayout`/`didFinishLayout` protocol — *not*
  `RenderSliverList`), `RenderSliverList` (which walks up with
  `insertAndLayoutLeadingChild` and down with `advance()`, writes
  `parentData.layoutOffset`, and does "**dead reckoning**"),
  `SliverChildBuilderDelegate` (`estimateMaxScrollOffset => null`),
  `SliverConstraints{scrollOffset, remainingPaintExtent, remainingCacheExtent,
  cacheOrigin, precedingScrollExtent}`, `SliverGeometry{scrollExtent,
  paintExtent, maxPaintExtent, scrollOffsetCorrection, cacheExtent}`,
  `RenderViewportBase._attemptLayout` + `offset.correctBy(correction)` bounded
  by 10 layout cycles, and `ScrollCacheExtent.pixels(250.0)` as the default
  prefetch band.
- `SliverToBoxAdapter` per block is **not** an option: one render object per
  block, no laziness, no prefix sums.

**(2) Keep scroll stable when off-screen blocks change height**

- Adopt the **anchor rule**: remember the anchor block + intra-block delta
  before a re-layout; after extents change, `scrollOffset +=
  newTop(anchor) - oldTop(anchor)`. In Flutter: **`ScrollPosition.correctBy`**
  (which is layout-time, silent, and exactly what `RenderViewportBase` uses) —
  **not `jumpTo`/`animateTo`**, which start a ballistic activity and can fight
  the gesture. (`setPixels` asserts it is not called during
  `SchedulerPhase.persistentCallbacks`; `correctBy` is the sanctioned path.)
- Inside a sliver, the cleanest form is to **return
  `SliverGeometry(scrollOffsetCorrection: delta)` and let
  `RenderViewport.performLayout` call `offset.correctBy(delta)` in the same
  layout pass** — this replaces the post-frame `applyMeasurements` + `setState`
  second pass with one pass.
- **Never let an extent change *during* a layout pass.** Niman already does this
  and documents why: `ScrollMap.measure` stores the new height in `_pending` and
  `applyMeasurements` (post-frame from `_scheduleExtentSync`) applies it, because
  "an extent that moves under a block the sliver has already placed is what makes
  SliverVariedExtentList's offsets jump mid-pass". This is VS Code's
  `PendingChange`/`_commit()` and TanStack's `pendingMeasuredCacheIndexes`.
- **Freeze extents**: once asked for, a block's extent changes only to that
  block's *own* measurement (`ScrollMap._extents`). A shared average
  re-estimating already-placed blocks is what triggers sliver assertions.
- Also **wrap each block in `OverflowBox(minHeight: 0, maxHeight:
  double.infinity)`** when measuring it, or the sliver's tight constraint makes
  the block report its *estimate* back and freeze a wrong height — which is what
  `_BlockMeasure`/`_BlockMeasureRender` already does (`RenderProxyBox`,
  reporting `size.height` after `super.performLayout()`).

**(3) Estimate heights of never-laid-out blocks**

- Use a **per-block-type** estimator, not one global constant:
  ```
  text/heading/list : lines * lineHeight + spacing
                      (account for wrap: ceil(chars / charsPerLine))
  code fence        : lines * codeLineHeight
  display math      : max(mathLineHeightEstimate, 1) + verticalPadding
  table             : rows * rowHeight
  image             : widthFraction * aspectRatio (unknown until decode →
                      placeholder aspect, corrected on load)
  ```
  This is the direct analogue of CSS `contain-intrinsic-size: auto <len>`'s
  "last remembered size" and `CellMeasurerCache.defaultHeight/defaultWidth`:
  once *any* instance of a kind has been measured, that becomes the kind's
  default.
- Niman's estimator is one `defaultPixelsPerLine = 22` plus an average of
  measured blocks. Fine for prose, **wrong for this document: 1682 of 10 331
  lines are display math, whose height is not 22 px/line. This is the biggest
  single source of scroll-position error on `Geometria 1.md`.** A per-kind
  estimator (the block scan already knows each block's kind) removes it.
- **Do not `TextPainter.layout` a block to estimate it.** Shaping is the
  expensive part and it is UI-isolate-only. That is exactly what VS Code's
  exact-by-rule heights avoid and what TextKit 2's `.estimatesSize` does
  internally.
- The estimator should learn: CM6's `HeightOracle` keeps `lineHeight`,
  `charWidth`, `lineLength` and `heightSamples`; a Dart version can do the same
  with a small `Map<BlockKind, (perLine, perChar, padding)>` refined from
  measurements.

**(4) Invalidation and identity**

- Diff the new block list against the previous by `firstSourceLine` (which
  `ScrollMap.rebuild` already does), keep `extent`/`measuredHeight` for blocks
  whose start line is unchanged, and reset the prefix-sum validity to the first
  changed block.
- `SliverChildBuilderDelegate.shouldRebuild` returns `true` unconditionally, so
  give each child a `ValueKey((blockIndex, sourceHash))` and supply
  **`findChildIndexCallback`** so an edit that shifts blocks keeps the existing
  `Element`/`RenderObject` — state, selection, in-flight image future — attached
  to the right block. That is Flutter's equivalent of Android's
  `DynamicLayout.reflow` block deltas and of `LineHeightsManager.onLinesInserted`.

### 7.6.6 Concrete structure for Niman

```
PreviewScrollIndex                      // replaces/augments ScrollMap
  List<BlockEntry> blocks               // firstSourceLine, lineSpan, kind,
                                        // measuredHeight?, frozen extent
  _prefixSum: Float64List (or Int32List)   // monotone, lazily valid
  _indexByOffset: Int32List?               // vector: offset -> block, O(1)
  Map<BlockKind, HeightModel> models    // learned per kind
  double contentInset
  int anchorIndex; double anchorDelta   // scroll anchoring
  int refmapEpoch                       // bump on link/footnote-definition edits

  double extentFor(int i)                // frozen ?? kindEstimate(i)
  int    blockAtOffset(double y)         // O(log n) binary / O(1) vector
  double offsetOfBlock(int i)            // O(log n) prefix sum
  int    lineForOffset(double y)
  double offsetForLine(int line, {double into})
  void applyBlockDiff(prev, next)        // keep extents by firstSourceLine,
                                         // invalidate prefix from first change
  void applyMeasurements(Map<int,double>) // post-frame ONLY
  SliverGeometry? correctionFor(double delta)  // scrollOffsetCorrection
```

Invariants: (1) `applyMeasurements` runs **only** between frames; (2)
`extentFor(i)` is pure, allocation-free and non-`O(blocks)`; (3)
**`totalExtent()` is the prefix sum's total, `O(1)` — this alone removes the
`O(blocks)` walk `ScrollMap.totalExtent()` does today**; (4) folded/collapsed
blocks are excluded from the block list or contribute only their header height;
(5) on an extent change above the viewport, emit a `scrollOffsetCorrection`
rather than `setState`+`jumpTo`.

**If extents must stay floating point**, a Fenwick tree over blocks gives
`O(log n)` add/prefix/select. **If they can be integer device pixels**, copy VS
Code's `ConstantTimePrefixSumComputer` and get `O(1)` select.

**Choices compared.** `SliverList` alone — dead reckoning; it cannot know the
total, so it extrapolates from reified children (the bug this repo already hit)
and corrects with `scrollOffsetCorrection`; fine only for uniform heights.
`SliverVariedExtentList` + this repo's map — correct placement and total, but
`O(index)` scans and it *asserts* if an extent moves under an already-placed
child (hence the post-frame deferral). Custom `RenderSliver` + prefix sums —
`O(log n)` (or `O(1)` with the bucket index), one layout pass, deterministic
anchoring: **the recommended target**. `CustomScrollView` + one
`SliverToBoxAdapter` per block — `O(n)` render objects, no laziness: never.
Keep `SliverConstraints.cacheOrigin`/`remainingCacheExtent` as the prefetch band
(default 250 px; STTextView uses `viewportBounds.height * 0.5`, react-window
overscan 2 items, TanStack `overscan = 1`); finally, parse off-isolate as today,
**measure on the UI isolate**, and gate expensive per-block work (math
typesetting, image decode) on a scroll-settle timer as
`MarkdownPreview._onScrollNotification` already does (120 ms) — the Flutter
analogue of `backgroundLayoutEnabled` plus deferred work.

---

## 7.7 Math rendering: KaTeX and MathJax

The target document is wall-to-wall TeX (1682 display-math lines), so this is
where the real risk is and where the current implementation choice matters most.
Paths verified against KaTeX `v0.16.22` (last pure-JS release) and `master` =
0.18.7 (now TypeScript); `.js` paths hold for ≤ 0.16.22.

### 7.7.1 The current Niman stack (read from the repo)

| file | what it does |
|---|---|
| `preview/math_widget.dart` (429) | `MathInlineBuilder` → `WidgetSpan(alignment: baseline, baseline: alphabetic, child: InlineMathView)`; `MathBlockBuilder` → centered block; `MathDeferScope` (an `InheritedWidget`) defers typesetting while scrolling; `MathStyle{fontSize, color}` |
| `preview/math_cache.dart` (146) | `MathCache`: `LinkedHashMap` LRU keyed `'${display?1:0}\u0000$tex'`, capacity 512, `hits`/`misses`/`generation`, `_errors` (errors remembered but **never cached**), `_inflight` dedupe, sync `renderToBox` default with `renderer`/`asyncRenderer` seams |
| `preview/math_syntax.dart` (156) | `MathBlockSyntax` (`md.BlockSyntax` for `$$…$$`), `splitInlineMath` (post-parse inline replacement), `stripFrontmatter`, `frontmatterLines` |
| `editor/math_rule.dart` (65) | the **single shared rule** for what a math span is; used by the editor tokenizer *and* the preview parser |
| `pubspec.yaml` | `katex: ^1.0.0`, `katex_dart: ^0.1.1` |

What is actually underneath: **`katex_dart` 0.1.1** is *not* a wrapper — it is a
**pure-Dart port of KaTeX** whose pipeline is
`Lexer → MacroExpander → Parser → parse-node AST → builders → box tree → SVG`,
with the box tree (`BoxNode`: `GlyphNode`, `HBox`, `KernNode`,
`VList`/`VListChild`/`VListPositionType` — a direct port of `makeVList` —
`RuleNode`, `SpanNode`, `SvgPathNode`, `EncloseNode`, `ImageNode`) as the
primary public model, **dimensions verified against KaTeX 0.17.0**.
`katex` 1.0.0 is the Flutter `CustomPainter` consumer
(`GlyphNode → TextPainter` with a `_glyphCache`, `RuleNode → drawRect`,
`SvgPathNode → drawPath`, `VList` by resolved downward shifts) over bundled
permissively-licensed `KaTeX_*` fonts; no WebView, no `katex.css`. README
status: *"Covers a broad MVP of KaTeX (fractions, scripts, roots, big
operators, delimiters, accents, fonts, environments, …). Full command/macro
coverage and stretchy-glyph stacking are incremental."*

**So "replacing it with Niman's own TeX layout" means replacing a working
pure-Dart TeX layout engine with another one.** That framing drives the
recommendation.

Given the note uses `\begin{pmatrix}` 1121 times, `cases` 114, `aligned` 103,
`vmatrix` 45, `array` 7, plus `\frac`, `\sqrt`, `\operatorname`, `\mathbf`,
`\mathbb`, `\mathcal`, `\dots`-family, `\langle/\rangle`, `\quad`, `\ker`,
`\dim`, `\det`, `\text`, the risk is entirely in **environment coverage and
stretchy-delimiter assembly** — the two things the README flags. A 6×6
`pmatrix` is exactly the worst case for `makeStackedDelim`.
**Test that before committing to the current stack; it is more important than
any architecture question in this document.**

Niman's scroll-time mitigation is already good: `MathDeferScope` holds
placeholders during a gesture and typesets on settle, because "the preview spent
5–6 ms per block, most of a frame's budget". That 5–6 ms **per block** (not per
formula) is the number to beat, and it means one 6×6 `pmatrix` block can cost
more than a frame.

### 7.7.2 KaTeX, phase by phase

**Lexer** (`src/Lexer.ts`, 5 081 B). `tokenRegex` is built from string fragments
and stored as a **stateful `/g` regex with `lastIndex`**, so the parser can lex
from any position (backtracking). Fragments: whitespace runs, `controlSpace`
(`\` + whitespace), a single codepoint class excluding control chars/backslash/
PUA/bare surrogates **with trailing combining marks `[\u0300-\u036f]`**,
surrogate pairs, `\verb*<c>…<c>` and `\verb<c>…<c>`, control words
(`\\[a-zA-Z@]+` with trailing spaces) and control symbols
(`\\[^\uD800-\uDFFF]`). Capture groups: [1] whitespace, [2] backslash+space,
[3] everything else, [4]/[5] verb delimiters, [6] control word; token text is
`match[6] || match[3] || (match[2] ? "\\ " : " ")`. `catcodes = {"%": 14
comment, "~": 13 active}`. `\u` is a control *symbol*, defined as a text-mode
breve accent in `accent.ts`. `Token{text, loc, noexpand?, treatAsRelax?}`;
`SourceLocation{lexer, start, end}` keeps the input reachable so errors can
render context.

**MacroExpander** (`src/MacroExpander.ts`, 16 533 B) — the "gullet".
`stack: Token[]` holds tokens **in reverse order**; `future()` lexes-and-pushes
if empty then peeks. `expandOnce` pops, looks up `Namespace` (builtins
`macros.ts` → `settings.macros`), lexes a string body into tokens, counts
`numArgs` by scanning for `#n` after deleting `##`, then `countExpansion(1)` —
**throws past `settings.maxExpand` (default 1000)** — then `consumeArgs` and
`#1` substitution (scan backwards; `##` → `#`). `expandNextToken()` loops until
no expansion remains (this is `Parser.fetch()`); `expandTokens()` is full
expansion for `\edef`/`\xdef`. `consumeArg(delims?)` implements TeX's delimited
vs undelimited parameter rules with a brace-depth counter.
**`\newcommand`/`\renewcommand`/`\providecommand` are JS-function macros** in
`macros.ts`; `\def/\gdef/\edef/\xdef/\let/\global/\long/\futurelet` are
functions in `functions/def.ts` returning `{type:"internal"}` nodes that never
reach the tree. `implicitCommands = {^, _, \limits, \nolimits}` are handled by
the Parser directly. `Namespace{current, builtins, undefStack}`:
`beginGroup()`/`endGroup()`; a **global** `set` deletes scheduled undos at every
nesting level and re-arms at the deepest; builtins are never destructively
shadowed.

**Parser** (`src/Parser.ts`, 38 732 B). `mode ∈ {math, text}`; `fetch()` memoizes
`gullet.expandNextToken()`; `parse()` → `beginGroup()` unless
`settings.globalGroup` → `parseExpression(false)` → `expect("EOF")` →
`finally endGroups()`. `endOfExpression = ["}", "\\endgroup", "\\end",
"\\right", "&"]`. `parseExpression(breakOnInfix, breakOnTokenText?)` skips
spaces in math, calls `parseAtom`, drops `"internal"` nodes, forms text-mode
ligatures (`--`, `---`, ` `` `, `''`), then `handleInfixNodes`.
**`handleInfixNodes` splits the group at the single `type:"infix"` node and
calls `genfrac` — `\over` never reaches a build phase.** `parseAtom` loops on
`\limits`/`\nolimits`, `^`, `_`, `'` (primes into an `ordgroup` of `\prime`
textords, absorbing a following `^`) and Unicode sub/superscripts, returning
`{type:"supsub", base, sup, sub}`. `parseFunction` enforces
`allowedInArgument`/`allowedInText`/`allowedInMath` and calls `parseArguments`
(arg types `color | size | url | math | text | hbox | raw | original |
primitive | null`). `parseGroup` returns `{type:"ordgroup", body, semisimple?}`
for `{`/`\begingroup`, else `parseFunction || parseSymbol`; **on failure with a
`\`-token and `throwOnError: false` it calls `formatUnsupportedCmd(text)`** — a
`color` node in `settings.errorColor` wrapping per-character textords.
`parseSymbol` strips combining marks (`i`→`\u0131`, `j`→`\u0237`), looks up
`symbols[mode][text]`, and builds `{type:"atom", family}` when the group is in
`ATOMS`, else `{type: group, mode, text}`; unknown ≥0x80 chars become text-mode
textords.

**`ParseNode` is a union of shapes discriminated by `type`**, not one class with
optional fields. Real per-type keys:

```
atom          {type, family: Atom, mode, loc?, text}
mathord/textord/spacing {type, mode, loc?, text}
op            {type, mode, limits, alwaysHandleSupSub?, suppressBaseShift?,
               parentIsSupSub, symbol: bool, name}
              | {… same, symbol: false, body: AnyParseNode[]}
supsub        {type, mode, base: ?AnyParseNode, sup?, sub?}
genfrac       {type, mode, continued, numer, denom, hasBarLine,
               leftDelim?, rightDelim?, size: StyleStr|"auto",
               barSize: Measurement|null}
sqrt          {type, mode, body, index?}
leftright     {type, mode, body: AnyParseNode[], left, right, rightColor?}
mclass        {type, mode, mclass, body: AnyParseNode[], isCharacterBox}
infix         {type, mode, replaceWith, size?, token}
accent        {type, mode, label, isStretchy?, isShifty?, base}
styling       {type, mode, style, body}
kern          {type, mode, dimension: Measurement}
array         {type, mode, colSeparationType?, hskipBeforeAndAfter?, addJot?,
               cols?: AlignSpec[], arraystretch, body: AnyParseNode[][],
               rowGaps, hLinesBeforeRow, tags?, leqno?, isCD?}
```

`defineFunction({type, names, props, handler, htmlBuilder, mathmlBuilder})` with
`props = {numArgs, argTypes?, numOptionalArgs?, allowedInArgument?,
allowedInText?, allowedInMath?, infix?, primitive?}`; 46 files in 0.16.22
(47 on master). **File-name corrections that matter if you port file by file:**

| cited | actual |
|---|---|
| `functions/leftright.ts`, `middle.ts` | both in **`functions/delimsizing.ts`** (22 names: `\bigl`…`\Bigg`, `\bigm`, `\big`, `\left`, `\right`, `\middle`) |
| `functions/delimiter.ts` | the engine is **`src/delimiter.ts`** (not a function file) |
| `functions/infix.ts` | `\over`/`\atop`/`\above`/`\choose`/`\brace`/`\brack`/`\genfrac` are all in **`functions/genfrac.ts`** (`type: "infix"`) |
| `src/spacing.ts` | **`src/spacingData.ts`**; the spacing *commands* are macros in `macros.ts` (`\,` → `\tmspace+{3mu}{.1667em}`) plus `functions/symbolsSpacing.ts` |
| `array` as a function | a `defineEnvironment` in `environments/array.ts` (`array darray matrix pmatrix bmatrix Bmatrix vmatrix Vmatrix smallmatrix subarray cases dcases rcases align align* aligned split gathered gather* alignat alignedat equation CD` …) |

**Atom classes.** The authoritative list is **`ATOMS` in `src/symbols.ts`**
(not `src/units.ts`, which holds `ptPerUnit`/`validUnit`/`calculateSize`/
`makeEm`; a small separate `src/atoms.ts` exports `isAtom`):

```
ATOMS     = { bin, close, inner, open, punct, rel }
NON_ATOMS = { accent-token, mathord, op-token, spacing, textord }
```

So the eight spacing classes are **mord/mathord (Ord), mop/op-token (Op), mbin
(Bin), mrel (Rel), mopen (Open), mclose (Close), mpunct (Punct), minner
(Inner)**. Class assignment is *not* in the Parser: `symbolsOp.ts`'s `atom`
builder emits `["m"+family]`, `mathord`/`textord` go through `makeOrd` →
`["mord"]`, `op-token` → `["mop", "op-symbol", "large-op"|"small-op"]`,
`mclass.ts` wraps in `[group.mclass]`, and delimiters set
`["mopen"]`/`["mclose"]` themselves.

**Contextual Bin→Ord happens in `buildHTML.ts`, not the Parser:**
`binLeftCanceller = ["leftmost","mbin","mopen","mrel","mop","mpunct"]`,
`binRightCanceller = ["rightmost","mrel","mclose","mpunct"]`;
`traverseNonSpaceNodes` flips `classes[0]` to `"mord"` when a `mbin` has a
canceller on the correct side. Dummy `leftmost`/`rightmost` spans bracket the
expression, and `checkPartialGroup` (DocumentFragment / Anchor / `.enclosing`
span) recurses transparently so spacing is computed *across* partial groups.

**Critical simplification: the `m*` classes have ZERO CSS rules.**
`src/styles/katex.scss` defines `.mspace`, `.vlist*`, `.base`, `.strut`,
`.frac-line`, `.delimsizing`, `.op-limits`, `.accent`, `.mtable` and almost
nothing else. `.mord`/`.mbin`/`.mrel`/`.mopen`/`.mclose`/`.mpunct`/`.minner`/
`.mop`/`.mtight` are **pure JS-side semantic markers** used for three things:
bin cancellation, the spacing-table lookup, and choosing tight-vs-loose spacing
(`mtight`). **A Dart port must carry the atom class as metadata on the box,
never as styling:** `Box{atomClass, height, depth, width}` where `atomClass` is
an enum used only by the spacing and break passes.

**Inter-atom spacing — `src/spacingData.ts` verbatim:**

```js
const thinspace   = {number: 3, unit: "mu"};
const mediumspace = {number: 4, unit: "mu"};
const thickspace  = {number: 5, unit: "mu"};

const spacings = {                    // display & text styles
  mord:   {mop: thin, mbin: medium, mrel: thick, minner: thin},
  mop:    {mord: thin, mop: thin,  mrel: thick, minner: thin},
  mbin:   {mord: medium, mop: medium, mopen: medium, minner: medium},
  mrel:   {mord: thick,  mop: thick,  mopen: thick,  minner: thick},
  mopen:  {},
  mclose: {mop: thin, mbin: medium, mrel: thick, minner: thin},
  mpunct: {mord: thin, mop: thin, mrel: thick, mopen: thin,
           mclose: thin, mpunct: thin, minner: thin},
  minner: {mord: thin, mop: thin, mbin: medium, mrel: thick,
           mopen: thin, mpunct: thin, minner: thin},
};
const tightSpacings = {               // script & scriptscript styles
  mord:   {mop: thin},
  mop:    {mord: thin, mop: thin},
  mbin:   {}, mrel: {}, mopen: {}, mpunct: {},
  mclose: {mop: thin},
  minner: {mop: thin},
};
```

**8×8, absent key = no space, and NOT symmetric** (`mbin→mopen` = medium but
`mopen→mbin` = absent). Contrast MathJax, which encodes no-space as `-1` in a
dense matrix (§7.3) — comparing the two tables is a good port correctness check.
Unit values: `\,`/`\thinspace` = 3mu; `\:`/`\medspace`/`\>` = 4mu;
`\;`/`\thickspace` = 5mu; `\!` = −3mu; `\negmedspace` = −4mu;
`\negthickspace` = −5mu; `\enspace` = 0.5em; `\quad` = 1em; `\qquad` = 2em;
`nulldelimiterspace` = 0.12em.

**1 mu = 1/18 em of the *current* style**: `cssEmPerMu = quad[sizeIndex]/18`
with `quad = [1.000, 1.171, 1.472]` → **0.055556 / 0.065056 / 0.081778 em**.
`em`/`ex` resolve against the **textstyle** options and do *not* shrink in
scripts. `calculateSize(measurement, options)`: absolute →
`pt / ptPerEm / sizeMultiplier`; `mu` → `cssEmPerMu`; `ex` → textstyle
`xHeight`; `em` → textstyle `quad` (with a `sizeMultiplier` ratio correction in
tight styles), clamped by `options.maxSize`. `makeEm(n) = (+n.toFixed(4)) +
"em"` — **every emitted length is rounded to 4 decimals**, useful when matching
KaTeX output exactly.

**Where spacing is applied.** Not in the Parser — in `buildHTML.ts`'s
`buildExpression`, as a second pass over the *built* nodes:

```js
traverseNonSpaceNodes(groups, (node, prev) => {
  const prevType = getTypeOfDomTree(prev);   // classes[0] of outermost node
  const type     = getTypeOfDomTree(node);
  const space = prevType && type
    ? (node.hasClass("mtight") ? tightSpacings[prevType]?.[type]
                               : spacings[prevType]?.[type])
    : null;
  if (space) return makeGlue(space, glueOptions);   // inserts a span after prev
}, {node: dummyPrev}, dummyNext, isRoot);
```

`makeGlue` = `makeSpan(["mspace"])` with `style.marginRight = makeEm(size)`.
`traverseNonSpaceNodes` **skips `.mspace` nodes when choosing `prev`** (so
explicit `\,`/`\;` do not count as atoms), recurses into partial groups, and at
root level resets `prev` to a `leftmost` span at a `.newline`. `buildExpression`
returns early for a non-real group so the parent owns spacing.
**One pass, one 8×8 table, one glue span per pair.**

**The box model** (`buildCommon.ts`, 26 399 B).

- `makeSymbol(value, fontName, mode, options, classes)` looks the char up in
  `fontMetricsData`, applies `symbols[mode][value].replace`, and builds a
  `SymbolNode` with `height/depth/italic/skew/width` **in em**. Italic is zeroed
  when `mode === "text"` or `options.font === "mathit"`; `maxFontSize =
  options.sizeMultiplier`; `"mtight"` when `options.style.isTight()`.
- `makeOrd(group, options)` picks a font: `boldsymbol` → `Math-BoldItalic` if
  the glyph exists else `Main-Bold`; `options.font` → `fontMap[font].fontName`;
  else `fontFamily`/`fontWeight`/`fontShape` →
  `retrieveTextFontName(...)` (`AMS|Main|SansSerif|Typewriter|Caligraphic|
  Script|Fraktur` + `Regular|Bold|Italic|BoldItalic`); else `Math-Italic` for
  `mathord` (+ class `mathnormal`) and Main/AMS for `textord`. Classes start
  `["mord"]`. `fontMap`: `mathbf`→`Main-Bold`, `mathrm`→`Main-Regular`,
  `textit`/`mathit`→`Main-Italic`, `mathnormal`→`Math-Italic`,
  `mathsfit`→`SansSerif-Italic`, `mathbb`→`AMS-Regular`,
  `mathcal`→`Caligraphic-Regular`, `mathfrak`→`Fraktur-Regular`,
  `mathscr`→`Script-Regular`, `mathsf`→`SansSerif-Regular`,
  `mathtt`→`Typewriter-Regular`.
- `makeSpan(classes, children, options, style)` calls
  `sizeElementFromChildren`: `height = max(child.height)`,
  `depth = max(child.depth)`, `maxFontSize = max(...)`. **A box is
  `(height, depth, width, maxFontSize, classes, style, children)`; there is no
  y coordinate until `makeVList`.**
- `tryCombineChars` merges adjacent `SymbolNode`s with identical
  classes/skew/maxFontSize/style, keeping the last char's italic correction —
  **but never two bare `mbin`/`mord`**, which would destroy spacing.
- `makeLineSpan(className, options, thickness?)`:
  `height = max(thickness || defaultRuleThickness, minRuleThickness)` plus
  `borderBottomWidth` — the node used for fraction bars, `\overline`, array
  rules.

**`makeVList` — the vertical stacking algorithm, verbatim structure.**
`VListParam` is one of `{positionType: "individualShift", children:
[{elem, shift}]}`, `{positionType: "top"|"bottom"|"shift", positionData,
children: (elem | kern)[]}`, `{positionType: "firstBaseline", children}`.

`getVListChildrenAndDepth` computes the **depth** and synthesises kerns:

```
individualShift:
  children = [c0]; depth = -c0.shift - c0.elem.depth; currPos = depth
  for i in 1..n-1:
     diff = -c_i.shift - currPos - c_i.elem.depth
     size = diff - (c_{i-1}.elem.height + c_{i-1}.elem.depth)
     currPos += diff; children += [Kern(size), c_i]
top:            bottom = positionData; per child bottom -= (kern? size : h+d); depth = bottom
bottom:         depth = -positionData
shift:          depth = -firstChild.elem.depth - positionData
firstBaseline:  depth = -firstChild.elem.depth
```

Then the layout:

```
pstrutSize = max over elems of max(elem.maxFontSize, elem.height) + 2
currPos = minPos = maxPos = depth
for each child:
  if kern: currPos += child.size
  else:
     wrap = span(wrapperClasses||[], [pstrut, elem], wrapperStyle||{})
     wrap.style.top = em(-pstrutSize - currPos - elem.depth)     // CSS top grows down
     push wrap; currPos += elem.height + elem.depth
  minPos = min(minPos, currPos); maxPos = max(maxPos, currPos)
vlist.style.height = em(maxPos)
if minPos < 0: depthStrut = span("vlist") with height em(-minPos);
               topStrut = span("vlist-s", [SymbolNode("\u200b")]);
               rows = [vlist+topStrut, depthStrut]
vtable.height = maxPos; vtable.depth = -minPos
```

**The `pstrut` is the trick to port.** HTML cannot say "put this box's baseline
at y", so KaTeX inserts a zero-width `overflow:hidden` strut of known height
into each child and sets `top` so the strut's **bottom edge lands on the
baseline**. In Dart there is no such limitation — `RenderBox` children position
arbitrarily — so `makeVList` degenerates to: **compute `(depth, maxPos, minPos)`
exactly as above, then position each child at `y = -(currPos + elem.depth)`
relative to the baseline.** The `pstrut`/`vlist-t`/`vlist-r`/`vlist-s`/
`vlist-t2` scaffolding is pure CSS workaround and can be dropped (`.vlist-s` is
a Safari baseline fix, `.vlist-t2` a `margin-right:-2px` hack). `katex_dart`
still carries these boxes because it also serialises to SVG/HTML; a
Flutter-only engine needs only the arithmetic.

**`makeStack` does not exist.** (Verified: no such function anywhere in `src/`.)
`\over`/`\atop`/`\above`/`\choose` are realised by `functions/genfrac.ts`,
which emits a `genfrac` node built from **two
`makeVList({positionType:"individualShift"})` calls** — one for the
rule-present case, one for rule-absent — implementing TeXbook Rule 15 directly:
`u = (display ? num1 : num2) - axis - t`,
`v = (display ? denom1 : denom2) + axis - t`, with the 3×/7× rule-thickness
clearance variants and the clearance corrections against `axisHeight`.
`\above` with an explicit `barSize` creates the rule via
`makeLineSpan("frac-line", options, calculateSize(barSize))` and uses
`midShift = -(axisHeight - 0.5*ruleWidth)`. `makeNullDelimiter(options, classes)`
appends the `nulldelimiter` class (a 0.12 em span) for an empty side.
**Port Rule 15's arithmetic, not a function.**

**Delimiters** (`src/delimiter.ts`, 30 009 B — the largest module after
`symbols.ts`/`macros.ts`, which tells you where the complexity lives). Three
regimes:

| regime | when | how |
|---|---|---|
| `makeSmallDelim` | fits a text-style glyph | a `Main-Regular` symbol restyled by `options.havingStyle` |
| `makeLargeDelim` | fits one of four display sizes | a `Size1..4-Regular` glyph via `sizeToMaxHeight = [0, 1.2, 1.8, 2.4, 3.0]` and `traverseSequence(delim, height, sequence, options)` with `start = min(2, 3 - options.style.size)` |
| `makeStackedDelim` | taller than all | a **top piece + repeated extension pieces + a bottom piece**, overlapped with `lap = {type:"kern", size:-0.008}`, combined with `makeVList({positionType:"bottom", positionData: depth})`, wrapped in `["delimsizing","mult"]` |

Classification arrays: `stackLargeDelimiters` (parens/brackets/braces/floors/
ceils/surd), `stackAlwaysDelimiters` (arrows, bars, groups, moustaches),
`stackNeverDelimiters` (`< > \langle \rangle / \backslash`).
`\left…\right` uses TeX's `make_left_right`: `delimiterFactor = 901`,
`delimiterExtend = 5/ptPerEm`,
`totalHeight = max(maxDist/500*901, 2*maxDist - delimiterExtend)` with
`maxDist = max(h - axis, d + axis)`. **There is no `stretchy.ts` (0.16 only)
and no `leftright.ts` in current KaTeX.** `\sqrt` is `makeSqrtImage` (same file)
with the `sqrtMain`/`sqrtSize1..4`/`sqrtTall` tables and `sqrtRuleThickness`,
then `functions/sqrt.ts` applies Rule 11
(`inner.style.paddingLeft = makeEm(advanceWidth)`,
`makeVList({positionType:"firstBaseline", children:[inner,
kern(-(inner.height+imgShift)), img, kern(ruleWidth)]})`). **This is exactly
what a note with 1121 `pmatrix` occurrences needs, and exactly what
`katex_dart`'s README calls incremental.**

**Font metrics** (`src/fontMetrics.ts` + `src/fontMetricsData.js`, 95 879 B):

```js
metricMap[fontName][charCode] = [depth, height, italic, skew, width]  // em
```

`getCharacterMetrics` throws if the *font* is unknown, indexes by
`charCodeAt(0)`, falls back through `extraCharacterMap` (Latin-1/Cyrillic
proxies), and in text mode to `'M'` (77) for supported scripts.
**Extraction (`src/metrics/extract_ttfs.py`):** `height = glyph.yMax/upm`,
`depth = -glyph.yMin/upm`, `width = glyphSet[name].width/upm`. **`italic` and
`skew` are NOT in the TTF** — they come from a hand-maintained base-character
map (`metrics_to_extract`). The global parameters are `sigmasAndXis` (three size
indexes, from `tftopl cmsy10/7/5` and `cmex10.tfm`):

```
slant [0.250,0.250,0.250]  xHeight [0.431,...]  quad [1.000,1.171,1.472]
num1 [0.677,0.732,0.925]   num2 [0.394,0.384,0.387]   num3 [0.444,0.471,0.504]
denom1[0.686,0.752,1.025]  denom2[0.345,0.344,0.532]
sup1 [0.413,0.503,0.504]   sup2 [0.363,0.431,0.404]   sup3 [0.289,0.286,0.294]
sub1 [0.150,0.143,0.200]   sub2 [0.247,0.286,0.400]
supDrop[0.386,0.353,0.494] subDrop[0.050,0.071,0.100]
delim1[2.390,1.700,1.980]  delim2[1.010,1.157,1.420]  axisHeight[0.250,...]
defaultRuleThickness[0.04,0.049,0.049]  sqrtRuleThickness[0.04,...]
bigOpSpacing1..5 = 0.111 / 0.166 / 0.2 / 0.6 / 0.1 (text)
ptPerEm = 10               doubleRuleSep 0.2   arrayRuleWidth 0.04
fboxsep 0.3                fboxrule 0.04
```

`getGlobalMetrics(size)` picks the size index (`>= 5` text, `>= 3` script, else
scriptscript) and caches `cssEmPerMu = quad/18`. Two more constant tables:

```
sizeMultipliers = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.2, 1.44, 1.728, 2.074, 2.488]
Style: D=0 Dc=1 T=2 Tc=3 S=4 Sc=5 SS=6 SSc=7, each with size 0..3 and cramped
  sup=[S,Sc,S,Sc,SS,SSc,SS,SSc]        sub=[Sc,Sc,Sc,Sc,SSc,SSc,SSc,SSc]
  fracNum=[T,Tc,S,Sc,SS,SSc,SS,SSc]    fracDen=[Tc,Tc,Sc,Sc,SSc,SSc,SSc,SSc]
  cramp=[Dc,Dc,Tc,Tc,Sc,Sc,SSc,SSc]    text=[D,Dc,T,Tc,T,Tc,T,Tc]
  isTight() = size >= 2
```

**These constants are the entire physical model of TeX** and, in Dart, a
~60-entry `const Map<String, List<double>>` copied verbatim (KaTeX is MIT; keep
the notice). `ptPerEm = 10` is shared with `katex.scss` — in Flutter it is
"10 pt per em" in your sizing maths.

**Output.** `buildTree.ts` → `buildHTML` + `buildMathML`. `buildHTML` takes the
built expression, wraps runs in `katex-base` chunks **split after every
`mbin`/`mrel`/`allowbreak`** (TeXbook p.173: a formula breaks only after a
relation or binary operator at the outer level, absorbing following `.mspace`
unless `nobreak`), each chunk prefixed with a `katex-strut` span of
`height = body.height + body.depth` and `verticalAlign = -body.depth`;
everything goes into a `katex-html` span with `aria-hidden="true"`.
`buildMathML` emits `<math><semantics><mrow>…</mrow><annotation
encoding="application/x-tex">src</annotation></semantics></math>`. `Settings`
defaults: `displayMode:false`, `output:"htmlAndMathml"`, `throwOnError:true`,
`errorColor:"#cc0000"`, `macros:{}`, `strict:false`, `trust:false`,
`maxSize:Infinity`, `maxExpand:1000`, `globalGroup:false`.

**`ParseError`** is a hand-rolled Error-prototype hack, not `class extends
Error`: `"KaTeX parse error: " + msg + (" at position N: " | " at end of
input: ")` plus ±15 chars of context with the offending slice underlined by
U+0332. **Error recovery:** `throwOnError:false` renders `formatUnsupportedCmd`
(red raw text), and `buildHTML` wraps *any* thrown error by re-rendering the
**raw source** as text in `errorColor` — **errors degrade to visible source,
never to a blank box.** Niman's `MathCache` mirrors this by never caching an
error.

**CSS realisation** (`src/styles/katex.scss`) — the ONLY rules carrying real
geometry are `.vlist-t`/`.vlist-r`/`.vlist` (an `inline-table` with
`vertical-align:bottom`, `position:relative` children whose inline `top` is the
computed offset), `.pstrut` (`overflow:hidden; width:0`), `.vlist-s` (Safari
fix), `.frac-line`, `.delimsizing.sizeN`, `.op-limits > .vlist-t`,
`.accent > .vlist-t`, `.nulldelimiter {width: calc(1.2em/10)}`,
`.mspace {display:inline-block}`, `.base {position:relative;
display:inline-block; white-space:nowrap; width:min-content}` (a Chrome
negative-space workaround), and `.svg-align`. **Everything else is realised by
inline `top`, inline `height` and inline `margin-left`/`margin-right`.**

### 7.7.3 MathJax, the contrast

MathJax is a *framework*, KaTeX a *library*.

- **Core**: `MathDocument` drives a state machine on `MathItem`
  (`UNPROCESSED → FINDMATH → COMPILED → CONVERT → METRICS → TYPESET →
  INSERTED`); `MathList` is a `LinkedList<MathItem>`; `InputJax.compile(math,
  document) -> MmlNode`; `OutputJax.typeset/styleSheet/getMetricsFor`;
  `DOMAdaptor` abstracts the DOM (browser vs `liteDOM`).
- **TeX input** (`ts/input/tex/`, ~60 package dirs): `FindTeX` builds one
  `RegExp` from the sorted start delimiters plus `\\begin\s*\{([^}]*)\}`;
  default `inlineMath: [['\\(','\\)']]`,
  `displayMath: [['$$','$$'],['\\[','\\]']]` (v4 **removes `$…$`** by default).
  `TexParser.Parse()` loops `getCodePoint()` →
  `parse(HandlerType.CHARACTER, [this, c])` →
  `configuration.handlers.get(kind).parse(input)`.
- **Stack automaton**: `Stack` starts with a `'start'` item; `Push()` wraps
  MmlNodes in an `'mml'` item, calls `this.Top().checkItem(item)`, and either
  pops+re-pushes the returned items or pushes; `BaseItem.checkItem` auto-handles
  `over`→`num` and rejects a misplaced `cell`. Concrete kinds live in
  `base/BaseItems.ts` (`StartItem, StopItem, MmlItem, FnItem, BeginItem,
  EndItem, BeginEnvItem, EndEnvItem, StyleItem, CellItem, OverItem, SubsupItem,
  PrimeItem, …`).
- **Plugin architecture**: `Configuration.create(name, {handler, fallback,
  items, tags, options, nodes, preprocessors, postprocessors, init, config,
  priority, parser})`; `ConfigurationType {HANDLER, FALLBACK, ITEMS, TAGS,
  OPTIONS, NODES, PREPROCESSORS, POSTPROCESSORS, INIT, CONFIG, PRIORITY,
  PARSER}` and `HandlerType {DELIMITER, MACRO, CHARACTER, ENVIRONMENT}`;
  `TokenMap` supplies `CharacterMap/RegExpMap/DelimiterMap/MacroMap/CommandMap/
  EnvironmentMap`. Packages: `base, ams, amscd, bbox, boldsymbol, braket,
  bussproofs, cancel, cases, centernot, color, colortbl, configmacros, enclose,
  extpfeil, gensymb, html, mathtools, mhchem, newcommand, noerrors,
  noundefined, physics, require, setoptions, textmacros, unicode, units,
  upgreek, verb, …`. **A plugin registry, the opposite of KaTeX's monolithic
  `functions.ts` + `macros.ts` tables** — MathJax pays more per formula and
  supports a much larger surface.
- **Box model**: `BBox` lives in **`ts/util/BBox.ts`** (v4) / `js/util/BBox.js`
  (v3): `{w, h, d, L, R, pwidth, ic, oc, sk, dx, scale, rscale}` — note the
  **horizontal** extents (`L`, `R`) KaTeX does not model and the italic
  corrections. `combine(cbox, x, y)` max-merges with offsets; `append(cbox)` is
  the left-to-right row case. Construct arithmetic worth copying, all in
  `ts/output/common/Wrappers/*` as **mixins shared by CHTML and SVG**:
  - `mfrac.getTUV/getUVQ`: `T = (display ? 3.5 : 1.5) * t`,
    `u = (display ? num1 : num2) - axis - T`,
    `v = (display ? denom1 : denom2) + axis - T`; `p = (display ? 7 : 3) *
    rule_thickness`, and if the actual separation `q < p` split the difference;
    then `w = bbox.w - 2*pad (-0.2 if a rule)`.
  - `msqrt`: `H = basebox.h + q + t`, `bbox.h = H + surd_height`, then
    `combine(surdbox, x, H - surdbox.h)` and
    `combine(basebox, x + surdbox.w, 0)`.
  - `munderover`: `getOverKU`/`getUnderKV` + `getDeltaW` for
    italic-correction-aware alignment, then `bbox.h += big_op_spacing5` (over) /
    `bbox.d += …` (under).
  - `mo.getSpace()` → `getTeXSpacing()` → `node.texSpacing()`, reading
    `lspace`/`rspace`/`OPTABLE` for MathML spacing and taking
    `max(0, L - prev.bbox.R)` for adjacent `<mo>`s.
- **`TEXSPACE`, MathJax's own 8×8 atom-spacing table**
  (`ts/core/MmlTree/MmlNode.ts`), TeXbook p.170, with
  `TEXCLASS = {ORD:0, OP:1, BIN:2, REL:3, OPEN:4, CLOSE:5, PUNCT:6, INNER:7,
  NONE:-1}` and `TEXSPACELENGTH = ['', thin, medium, thick]`:

  ```
  TEXSPACE = [                    // rows = prev class, cols = this class; -1 = none
    [ 0,-1, 2, 3, 0, 0, 0, 1],    // ORD
    [-1,-1, 0, 3, 0, 0, 0, 1],    // OP
    [ 2, 2, 0, 0, 2, 0, 0, 2],    // BIN
    [ 3, 3, 0, 0, 3, 0, 0, 3],    // REL
    [ 0, 0, 0, 0, 0, 0, 0, 0],    // OPEN
    [ 0,-1, 2, 3, 0, 0, 0, 1],    // CLOSE
    [ 1, 1, 0, 1, 1, 1, 1, 1],    // PUNCT
    [ 1,-1, 2, 3, 1, 0, 1, 1],    // INNER
  ]
  ```

  `AbstractMmlNode.texSpacing()` returns `''` when
  `(prevLevel > 0 || scriptlevel > 0) && space >= 0` — **in script styles only
  the negative ("no space") entries survive.** Same table as KaTeX's
  `spacingData.ts` in a different encoding; comparing the two is a good port
  correctness check.
- **Font data**: `CharDataArray = [height, depth, width, CharOptions?]` with
  `CharOptions = {ic?, oc?, sk?, dx?, …}` — the h/d/w triple plus italic
  corrections, versus KaTeX's `[depth, height, italic, skew, width]`.
  Delimiter data: `{c, dir: V|H, sizes, stretch: [ext, mid, end…], schar,
  variants, HDW, min}` with `VSIZES = [1, 1.2, 1.8, 2.4, 3]`. **v4 moved the
  tables out of `output/chtml/fonts/`** into
  `ts/output/chtml/{FontData,DefaultFont,DynamicFonts,Usage}.ts` with the fonts
  as a separate asset package.
- **`LinebreakVisitor`** (`ts/output/common/LinebreakVisitor.ts`, 955 lines) is
  a real line-breaking pass over the box tree, with
  `PENALTY {newline: 0, nobreak: 1_000_000, goodbreak: p - 200*depth,
  badbreak: p + 200*depth, auto: p}` and per-wrapper `getLineBBox`/
  `computeLineBBox`/`breakToWidth`. **MathJax does automatic line breaking;
  KaTeX does not** — KaTeX only splits into `.base` chunks after
  `mbin`/`mrel`/`allowbreak`.

**Where MathJax wins for a notes app**: `\newcommand`/`\def` scope handling,
complete AMS environments, line breaking. **Where KaTeX wins**: an order of
magnitude less code, synchronous, no font-file dependency beyond its own,
documented vocabulary. **Niman's note is `\begin{pmatrix}`-heavy with
`\operatorname`/`\ker`/`\det` — fully inside KaTeX's vocabulary.**

### 7.7.4 The practical subset, and the real difficulty

| must have | where it lives |
|---|---|
| `\frac`, `\dfrac`, `\tfrac`, `\binom`, `\cfrac`, `\over`/`\atop`/`\above`, `\genfrac` | `genfrac.ts` Rule 15 + `makeVList` |
| `^`/`_`/`'` with `\limits`/`\nolimits` (`\sum`, `\int`, `\lim`) | `supsub` + `op.ts` movablelimits + `bigOpSpacing1..5` |
| `\sqrt`, `\sqrt[n]{}` | `makeSqrtImage` + `sqrtMain`/`Size1..4`/`sqrtTall` + Rule 11 |
| `\left…\right`, `\middle`, `\bigl…\Bigg`, `\{`, `|`, `\|` | `delimiter.ts` + `delimsizing.ts` (**the expensive one**) |
| Greek, arrows, `\to`, big operators, relations | `symbols.ts` + `fontMetricsData` |
| accents `\hat \bar \vec \tilde \dot \ddot \overline \underline \widehat` | `accent.ts` + `makeVList` |
| `\text{…}`, `\textbf`, `\textit`, `\operatorname{…}` | `text.ts` + Main-Regular |
| `\mathbb \mathcal \mathfrak \mathbf \mathrm \mathit \mathsf \mathtt \boldsymbol` | `fontMap` |
| `matrix pmatrix bmatrix Bmatrix vmatrix Vmatrix cases dcases aligned gathered array` with `&` and `\\` | `environments/array.ts` + delimiters |
| `\, \: \; \! \quad \qquad \hspace \kern` | `spacingData` + `calculateSize` |
| `\color`/`\textcolor`, `\boxed`, `\\` line breaks | `color.ts`, `enclose.ts`, `cr.ts` |

**Safely dropped at first:** `\html*`, `\href`/`\url` (trust gate),
`\includegraphics`, `\raisebox`, `\enclose`/`\cancel`/`\angl`, `\class`,
`\mathchoice`, `\smash`, `\pmb`, CD/amscd, `mhchem`/`physics`/`bussproofs`,
MathML output (unless accessibility demands it), deep `\def`/`\edef` recursion
(keep `\newcommand`/`\def` with a small `maxExpand`), Fraktur/Script variants,
and the `Size1..4` fonts if you accept slightly different stretching. `\tag` is
cheap to keep.

**Code size, from the actual KaTeX source (MIT), calibrated against the two
Dart ports.** Hand-written Dart for the whole engine is **~18 000–23 000 lines**,
plus **~6 000–8 000 lines of generated data**, i.e. **20 000–30 000 lines plus
the fonts** (`katex_dart` + `katex` ≈ 29 000 lines over 59 files;
`flutter_math_fork` ≈ 29 000 over 155). **An MVP for just the 95 % subset above,
without MathML, selection or automatic line breaking, is ~8 000–12 000 lines of
hand-written Dart plus the tables**; the long tail (`\enclose`, `\cd`, `\angl`,
the `\xrightarrow` family, full stretchy geometry) is another ~10 000.
**The genuinely hard parts are (a) the per-character font metrics and (b)
stretchy delimiter geometry — not parsing, and not the box model.**

**Where the metrics come from — and the one part that cannot be regenerated.**

- `depth`, `height`, `width` **are** derivable from the TTF
  (`yMax/upm`, `-yMin/upm`, `advanceWidth/upm`).
- **`italic` and `skew` are NOT in the TTF.** So either (a) **transcribe
  `fontMetricsData.js`** (2 077 lines, ~150–200 KB, MIT data) — what
  `katex_dart` does (`tool/gen_font_metrics.dart` shells out to Node and
  JSON-stringifies the ES module) — or (b) regenerate h/d/w and hand-maintain an
  italic/skew base-character map. **(a) is strictly less work.**
- The 22 sigma + 6 xi font parameters (`sigmasAndXis`) are **not in the TTF at
  all** (they come from `tftopl` + `cmex10.tfm`) — copy them.
- Glyph **outlines** for the stretchy/SVG path: `katex_dart`'s
  `tool/gen_glyph_paths.py` uses `fontTools.ttLib` + `SVGPathPen`. **On Flutter
  you can use `TextPainter` (what `katex` does) and keep paths only for stretchy
  delimiters/accents/surd.**

**Fonts: 20 faces** — `KaTeX_AMS-Regular`,
`KaTeX_Caligraphic-{Regular,Bold}`, `KaTeX_Fraktur-{Regular,Bold}`,
`KaTeX_Main-{Regular,Bold,Italic,BoldItalic}`,
`KaTeX_Math-{Italic,BoldItalic}`, `KaTeX_SansSerif-{Regular,Bold,Italic}`,
`KaTeX_Script-Regular`, `KaTeX_Size1-Regular`…`KaTeX_Size4-Regular`,
`KaTeX_Typewriter-Regular`, each `.ttf`/`.woff`/`.woff2`. They are generated
from **METAFONT sources (Computer Modern / AMS compatible), NOT Latin Modern or
New Computer Modern**, and their metrics are cmsy10/cmsy7/cmsy5/cmex10-compatible.
**Licensing: the KaTeX *code* is MIT (Khan Academy); the font files live in the
separate `KaTeX/katex-fonts` repo, whose `LICENSE` is MIT (Copyright (c) 2018
Khan Academy).** Note `katex_dart`'s README labels them "SIL OFL" while its own
generated header says "SIL OFL fonts; MIT data" — the authoritative
`katex-fonts/LICENSE` says MIT. Either way it is permissive to vendor with
attribution, and **the 3–5 MB asset cost is unavoidable for real TeX quality.**

**Flutter font pitfalls already documented in the wild:**

- Declare **each TTF under its own family** (`KaTeX_Math-Italic`, **no**
  `weight`/`style` descriptors), because Skia synthesises oblique/bold over
  KaTeX's already-slanted/bold outlines → **double slant**. This is what the
  `katex` package does; `flutter_math_fork` chose grouped families with
  `style: italic`/`weight: 700` and pays with synthetic slant.
- Set `height: 1` on the `TextStyle` and **pin the baseline from
  `CharacterMetrics.height`/`depth`**, not from `TextPainter`'s metrics — the
  glyphs' `italicAngle` is 0 and the Bold/Italic OS/2 bits are unset.
- **Who owns the advance is the main architectural fork between the two Dart
  ports, and it decides how faithfully you match KaTeX's line breaking:**
  `flutter_math_fork` lets Flutter measure each glyph's advance and takes only
  h/d/italic/skew from the table; `katex` owns advances via `TextPainter` with a
  `_glyphCache`.

### 7.7.5 Dart ports: what exists and what it means

| package | what it is | implication |
|---|---|---|
| **`katex_dart` 0.1.1** (`roszkowski.dev` — GitHub `orestesgaolin`, MIT, ~3.1k downloads/30d, published 2026-07) | a **fresh hand port of the whole pipeline** (`Lexer → MacroExpander → Parser → parse-node AST → builders → box tree → SVG`) targeting **KaTeX 0.17.0**; 53 Dart files. Sealed `BoxNode`: `GlyphNode, HBox, KernNode, VList/VListChild/VListPositionType` (a direct `makeVList` port), `RuleNode, SpanNode, SvgPathNode, EncloseNode, ImageNode`. `KatexOptions(displayMode, fontSize, color, macros, throwOnError, strict, minRuleThickness, maxSize)`; no `MathStyle` enum (internal `Style.{DISPLAY,TEXT,SCRIPT,SCRIPTSCRIPT}`). Data generated from KaTeX (`tool/gen_{font_metrics,glyph_paths,spacing,symbols,svg_geometry,font_bytes}`; the last emits **511 KB of base64 `@font-face`** so SVG output is self-contained). Verified against a Node/puppeteer oracle (`reference/pin.json` = 0.17.0, "dimension gate 26/26"). `tickets/BOARD.md` marks "port full `macros.ts` (~245 builtin)" and "final coverage 100 %" **done**. Gaps: **stretchy geometry beyond Size4, no MathML, no selection/copy, no line breaking, no async** | this is the engine Niman already uses, indirectly. The 511 KB base64 font payload is dead weight for a Flutter app |
| **`katex` 1.0.0** (same publisher, MIT) | the Flutter widget: `Math(tex, {displayMode, fontSize, color, onError, throwOnError})`, `mathSpan(...) -> InlineSpan` (baseline-aligned `WidgetSpan` for `Text.rich`), `AnimatedMath`, and `KatexBoxPainter extends CustomPainter` (`GlyphNode → TextPainter` with a `_glyphCache`, `RuleNode → drawRect`, `SvgPathNode → drawPath`). **Paints the box tree; no WebView, no `katex.css`.** Ships the 20 TTFs as package fonts under per-file families with the double-slant note in its pubspec. Fully synchronous | Niman's `math_widget.dart` uses this |
| previous `katex` (`motorcityadam/katex.dart`) | deprecated **WebView/JS wrapper** | rejected by upgrade; Niman already moved off it |
| **`flutter_math_fork` 0.7.4** (`simpleclub.com`, Apache-2.0, 172 likes, ~272k downloads/30d, active to 2026-06; repo `simpleclub/flutter_math`; the original is `znjameswu/flutter_math`) | the *other* architecture: a KaTeX **parser port** + a **red-green AST** (`SyntaxTree(greenRoot:)`, stateless `GreenNode`, `SyntaxNode.buildWidget(MathOptions) -> BuildResult`), where **`BuildResult = {Widget widget, MathOptions options, double italic, double skew, List<BuildResult>? results}` carries NO width/height/depth** — layout is delegated to Flutter (`RenderCustomLayout`, `RenderVList` with `VListParentData{hShift, trailingMargin, customCrossSize}`). **Metrics are hybrid**: `font_metrics.dart` ports `fontMetricsData.js` but only for **height/depth/italic/skew**; advance is measured by Flutter's text layout. Stretchy delimiters/surd use `flutter_svg`. Their `doc/design.md` is candid: *"Tex's height and depth calculations are performed implicitly by the layout process of RenderObjects… Breakable RenderObjects are made subclasses of RenderBox, which caused huge amount of boilerplate code and exception spots."* API: `Math.tex(...)`, `Math.texBreak() -> BreakResult<SyntaxTree>{parts, penalties}` (relPenalty 500, binOpPenalty 700, assembled in a `Wrap`), `SelectableMath.tex` (experimental). **Inline line breaking IS implemented; nested/display breaking is only planned.** Gaps (`doc/unsupported.md`): `\href`, `\includegraphics`, `\lap`, `\mathchoice`, `\smash`, `\pmb`; planned `gather`, `Vmatrix`. Open issues are overwhelmingly Flutter-version breakage (`RenderObjectWithLayoutCallbackMixin not found`, `RenderConstrainedLayoutBuilder can't be mixed in`, infinite constraints with `\frac`+`\sqrt`) — **the concrete cost of bolting layout onto `RenderObject`s** | proof a full TeX→Flutter layout is solved in Dart, and the architectural alternative to `katex`/`katex_dart`. Its `unsupported.md` is an honest gap list to read before choosing |
| `flutter_math` 0.2.1 (`znjameswu`) | the original; Apache-2.0, Dart-3-incompatible, dead since 2020-12 | superseded by the fork |
| `flutter_tex` 5.2.7 | MathJax via `webview_flutter_plus`; broadest input surface, **no Dart layout** | disqualified for a native app |
| `markdown_widget` 2.3.2+8 | no LaTeX dependency; ships a *recipe* implementing a `markdown` `InlineSyntax` for `$…$`/`$$…$$` calling `Math.tex` | a pattern reference for the syntax layer, not an engine |
| `flutter_html_math`, `flutter_markdown_latex`, `flutter_markdown_plus_latex` | integrations, all on `flutter_math_fork` | confirms it is the de-facto Dart TeX engine for markdown stacks |
| `latex` (pub.dev) | **404 — does not exist** | lookalikes: `latext`, `tex_text` (wrappers over `flutter_math_fork`), `smart_latex`, `flutter_math_katex` |

**Conclusion for §7.** A Dart TeX layout engine is not a research problem: it has
been done twice, with two *different* answers to "who owns layout". Building
"Niman's own" means re-typing 8–12 k lines for an MVP (20–30 k for parity) plus
a 3–5 MB font bundle plus the metrics table, in exchange for (i) dropping the
`katex_dart` dependency, (ii) controlling the box model directly (no
`domTree`/SVG indirection, no `pstrut` workarounds, no base64 font payload), and
(iii) fixing exactly the gaps the README admits. **The honest recommendation is
not "write your own" but "measure the current one against the target document
first, then decide":** render the 1121 `pmatrix` occurrences and the 1682 display
blocks through `katex_dart` (or `flutter_math_fork`), count errors, and time the
worst block. The `pmatrix`/`vmatrix` cases exercise `makeStackedDelim` at its
worst — exactly the module `katex_dart` flags as incremental. **If it passes,
keep `katex_dart` behind Niman's own `TeXLayout` interface** (a value type
`TeXBox{height, depth, width, children}` with no `domTree`, no SVG node, no
base64 payload), so the widget layer and the cache never depend on the package's
internals and a future engine swap is one file. If it fails on `pmatrix`, the
work is bounded: port `delimiter.ts`'s `makeStackedDelim`/`traverseSequence` and
`genfrac.ts`'s Rule-15 arithmetic, not the whole engine.

**What to steal regardless of the engine choice:** the atom-class spacing table
(8×8, §7.2) and the `makeVList` arithmetic are ~150 lines of Dart that make an
inline formula look right *while typing* without a full TeX pass (spacing `a+b`
vs `a=b`). And **copy the font-metric tables + `sigmasAndXis` verbatim** — MIT
data over permissively licensed fonts; never regenerate them.

---

## 7.8 Syntax highlighting prior art

The requirement is modest: fenced code blocks, plus Markdown's own tokens, which
`highlighting.dart` already handles. **The target document makes this cheap to
get right**: 0 fences, 40 wikilinks, 1 Markdown link — so Markdown's own
tokenization is the whole game and a code fence is an optimisation for *other*
notes, never a hot path here.

| approach | model | incremental? | Dart feasibility |
|---|---|---|---|
| **CM6 `StreamLanguage`** | a state-machine tokenizer: `token(stream, state) -> style`, plus `startState`, `blankLine`, `copyState`, `indent`, and an **`inner` mode stack** | **yes, inherently.** CM6's own `Parse` tokenizes line by line in chunks of `ChunkSize = 512` and **stores the tokenizer state as a per-node prop** (`[[lang.stateAfter, streamParser.copyState(state)]]`), then restarts from the nearest node before the target carrying that prop — **shrinking the reuse region by 25 chars on each open side.** A stream language is *restartable from a state snapshot*, never token-incremental | **excellent** — one small value per line (or per 512-char chunk) plus a per-line function, exactly what Niman already built in `highlighting.dart`. The `inner` stack is the piece to add for nested modes |
| **TextMate grammars** | declarative `patterns` with `begin`/`end`/`while` regexes, `captures`, `include`, `repository`; state is a **rule stack** (`StateStackImpl{parent, ruleId, endRule, nameScopesList, contentNameScopesList}` + line-local `enterPos`/`anchorPos` which reset per line, which is why states compare cleanly across lines) | yes in principle, but the stack is a full linked structure and `while`-condition failure cuts the whole stack above it | **bad** — needs Oniguruma/Onigmo. This is why VS Code ships **`vscode-oniguruma` compiled to WASM** (`onig.wasm`): JS `RegExp` cannot express TextMate's patterns (`\G`, `\K`, POSIX classes `[[:alpha:]]`, `\R`/`\h`/`\X`, scoped inline flags, atomic groups), and its binding keeps **one global match buffer**, so it is not re-entrant. **Dart `RegExp` is ECMAScript** ([api.dart.dev](https://api.dart.dev/dart-core/RegExp-class.html)), verified empirically on Dart 3.13.2: lookbehind, named groups, `\p{L}` with `unicode: true`, `dotAll` and backreferences all work; possessive quantifiers, atomic groups and inline flags `(?i)` are **rejected** with `FormatException`. No `\G`/`\K`/`\R`/`\h`/`\X`/POSIX classes. So a faithful TextMate engine means porting Oniguruma or accepting a different dialect — not worth it for notes |
| **tree-sitter queries** | `(node) @capture` over the tree, plus predicates and the **locals query** (`@local.scope`/`@local.definition`/`@local.reference`/`@ignore`) and injections | yes (tree is incremental; ranges recomputed per visible range) | **medium** — needs a tree-sitter runtime in Dart (FFI to the C runtime, or a pure-Dart GLR port) **plus** a compiled `parser.c`/`.so` per language **plus** the query engine **plus** per-language `highlights.scm`/`locals.scm`. And the Markdown grammar's own README says it is "not recommended … where correctness is important" |
| **Prism** | `Prism.languages[lang]` is a grammar object; `tokenize(text, grammar)` builds a `LinkedList` and runs `matchGrammar` over the grammar's keys **in insertion order**, recursing into `inside`; `lookbehind: true` is *faked* by slicing the matched group off | no (whole string) | **good** — one flat regex per grammar is portable. **Correction: Prism is NOT a longest-match tokenizer** — it is "first token key/pattern in grammar order wins at the leftmost position", which is why grammar authoring order matters |
| **highlight.js** | `hljs.highlight(code, {language})`: `Mode`s compiled to `beginRe`/`endRe`, all joined into **one `ResumableMultiRegex`** with `matchIndexes[groupIndex]` recording which rule matched; `modeStack` + `top` + `endsWithParent`/`excludeBegin`/`returnBegin`; `subLanguage` threads a sub-mode stack across calls via `continuations`; `illegal` throws and is caught into `{illegal: true, value: escape(code)}` | no (whole string), but resumable per chunk via `continuations` | **good** — `highlight` 0.7.0 (the Dart port) is *already a Niman dependency*, used by the preview's code highlighter (`preview/code_highlight.dart`, 67 lines). The port is semantically faithful but re-tests each candidate mode's regex instead of using upstream's `matchIndexes`, so it has a worse constant factor |

**Recommendation: `StreamLanguage`-style state machines — extend what Niman
already has.** Reasons, in order:

1. **The convergence machinery already exists and is measured.**
   `HighlightDocument` is a per-line state machine with a convergence check;
   0.507 ms/keystroke, 44.7 µs/laid-out line. A `StreamLanguage` port is *the
   same object* with a richer state, not a new architecture. **And the mature
   architectures converge on exactly this mechanism:** VS Code's incremental
   tokenization is *line-state convergence, not tree reuse* —
   `TokenizationStateStore.setEndState` returns false when the recomputed state
   `equals` the remembered one, and invalidation stops there. That is the same
   rule as `HighlightDocument.replace`'s `if (state == old.entering)`.
2. **The workload is Markdown, not C++.** Markdown's own tokenizer plus a
   handful of fence languages (Dart, Python, JS/TS, JSON, YAML, Bash, SQL,
   LaTeX, C-family, HTML/XML) is 50–150 lines each.
3. **TextMate is not portable** (Oniguruma). Shipping `onig.wasm` in a Flutter
   app is not an option; porting Oniguruma is not worth it for notes.
4. **tree-sitter is the "right" answer and the wrong cost.** FFI to
   `libtree-sitter` means a per-platform `.so`/`.dll`/`.a` for Android (4 ABIs),
   Linux and Windows, plus one grammar library per language plus the query
   engine — for a feature whose current cost is 44.7 µs/line. Revisit only if
   Niman needs semantic code features (folding, structural selection, symbol
   outline) across many languages.
5. **Niman already ships `highlight` 0.7.0** — the right place for it is the
   *preview* (a block renders once and can afford a whole-string pass). **The
   editor must stay on the incremental stream tokenizer.**

**Concrete plan.** Keep `HighlightDocument` as the *Markdown* stream language.
Add a `CodeFenceLanguage` registry: `(fenceInfo) -> LineStateMachine?`. The
fence's opening line selects the machine and the fence state becomes part of
`_State`, so a fence's interior is tokenized by the *inner* machine while the
fence is open, and the convergence walk is unchanged. For an unknown language,
fall back to "no inner highlighting" rather than to a whole-string engine — a
missing colour is not a bug, a 400 ms keystroke is. Whole-string engines stay
off the hot path: the preview's code blocks (cache the result per
`(language, fenceTextHash)` so a large fence is not re-highlighted per frame),
export/print, and `MarkdownChunkAnalyzer` (already off-isolate and capped at
20 000 lines). If Niman ever needs a WYSIWYG surface, the AST-diff precedents to
copy are VS Code's "full re-parse + node identity reuse by source range" and
ToastMark's "re-parse only the changed part, return inserted/removed nodes".

---

## 7.9 What Niman already does that must be carried over

### 7.9.1 `HighlightDocument` (`editor/highlighting.dart`) — **keep as-is, then extend**

`List<_Line>` where each `_Line` caches `entering`/`exit` `_State` and
`tokens`; `_State{fence, inMath, inFrontmatter}` is a 3-field immutable value
with value equality. `_tokenizeAt` reads `lines[i-1].exit`, computes `exit` via
`_stateAfter`, produces `tokens` via `_lineTokens` (fence content → fence open →
math → frontmatter → HR → heading → blockquote → list item →
`_InlineScanner.scan`). 20 token kinds; inline scanning uses precompiled
`RegExp`s, a manual backtick-run matcher, and hand-rolled guards because "Dart
regex has no lookbehind" (line 879) — a comment that is now **out of date**
(modern Dart has lookbehind), though the manual code is correct and fast.

**Why it is O(change) — two mechanisms:**

1. `replaceLines(first, removed, replacement)` splices the line list and then
   does **only** `if (_materializedUntil > first) _materializedUntil = first;` —
   it does *not* walk the tail. Stale tokens from `first` onward are simply
   never read, because `_materialize(upTo)` re-tokenizes forward from
   `_materializedUntil` whenever `lineAt(line)` is called. **This is the
   cleverest thing in the file**: invalidation is O(1) and the cost is paid
   lazily by the viewport, in order, so the carried state is always exact.
2. `replace(start, end, replacement)` (the offset path) re-tokenizes the rebuilt
   region then **extends with unchanged old lines until `state ==
   old.entering`** — the convergence walk — with the unchanged tail
   `addAll`ed by reference.

Laziness: `_materializedUntil` means opening a 1 M-char note tokenizes only the
visible lines (`empty()` starts at 0; `lineAt` materializes up to the asked
line). `lines` (the eager getter) is documented O(lineCount). Also in this file:
`mathSpansIn` (whole-document span collector, used by the WYSIWYG codec) and
`forEachHeading` — a **block-state-only** walk that finds headings without
running the inline scanner, taking the outline of the 931 K note from ~1 s to a
few ms; `_headingIn` "mirrors the order of `_lineTokens`'s early returns", and
`outline_test` holds the two to the same answer.

**What it needs:** a richer `_State` (the ordered CommonMark container stack, or
its hash — §3.3) if a real block tree is wanted, with the *same* convergence
logic and lezer-markdown's boundary rules; a `ChangeSet`-based `replace` instead
of the line-identity path (see 9.2); an O(log n) line index instead of
`_lineStarts()` (which is `O(n)` and is called on *every offset edit*); and the
work-budget/`WorkRange` idea (§2.5, §3.3) for the unconverged fence-at-line-1
case, with the previous render kept on screen meanwhile.

### 7.9.2 `EditorHighlightSync` (`editor/highlight_sync.dart`) — **port** (keep the span cache, drop the diff scan)

`onBufferChanged(CodeLines current)` returns early if
`identical(current, _lastCodeLines)` (selection-only changes reuse the same
instance — a nice `re_editor` property); otherwise it finds
`first = _firstChangedLine(previous, current)` and
`suffix = _commonSuffix(previous, current, first)` and calls
`_doc.replaceLines(first, removed, replacement)`. Both helpers are
**segment-aware**: `re_editor` groups lines into `CodeLineSegment`s, untouched
segments are shared by reference (`identical(oldLines, currentLines)`), so a
single-line edit at any file size is `O(segments + 256)` and only the differing
segment is walked line-by-line. `spanFor(index, text, base, syntax, dark,
spellRanges, spellStyle)` builds a `TextSpan` **cached per line index** in
`_spans`, invalidated from the edit's first changed line
(`_spans.removeWhere((index, _) => index >= first)`) and cleared entirely on a
palette/dark change. The span is built from a `Set<int>` of token boundaries
(plus the heading-body start plus spell-range boundaries) so each maximal run
gets one style — **the "one `TextSpan` per style run" trick that lets Flutter's
paragraph cache keep hitting.** `tokensOf(index)` is the Ctrl+click link-lookup
entry point.

**Verdict:** the *idea* (segment-aware first-difference detection, per-line span
caching, an invalidation frontier) is exactly right and should survive a move
off `re_editor`. The *implementation* is coupled to `re_editor`'s
`CodeLines`/`CodeLineSegment` sharing semantics. **With an explicit `ChangeSet`,
`_firstChangedLine`/`_commonSuffix` become unnecessary — the `ChangeSet` *is*
the answer and is O(1) to obtain instead of a scan. Keep the span cache; delete
the diffing scan.** One caveat the research surfaced: `re_editor`'s `CodeLines`
is a COW list of 256-line segments with **no prefix sums**, so offset↔line is
`O(#segments)`; add per-segment line/char prefix sums if the new editor needs
offsets at all.

### 7.9.3 `MarkdownChunkAnalyzer` (`editor/markdown_chunks.dart`) — **port, and fix the input**

Heading-based fold chunks, computed by
`HighlightDocument.fromText(...).lines` → `outlineOf` → for each heading, the
terminus is the next same-or-higher heading; a section needs ≥2 body lines to
fold. Runs in `re_editor`'s isolate per change, **no-op above
`lineLimit = 20000`** because "the whole-document tokenize (~80 ms at 931 K, per
keystroke, background) is not worth it for fold markers on monster notes".

**Verdict:** the chunk model (heading sections, level-based terminus) is right
and cheap. What is wrong is a **full eager tokenize per buffer change** to find
headings — when `forEachHeading` exists in the same file's dependency and walks
the block state machine only. Use it (or the incremental block index) and the
cap becomes unnecessary: finding 84 headings in 10 331 lines is a per-line char
scan, ~1 ms. The fold *state* (collapsed sections) belongs in the height index
(§6.6), because folding changes extent.

### 7.9.4 `MarkdownPreview` (`preview/markdown_preview.dart`) — **port the windowing; replace the package**

- **Two-phase parse:** `_parse()` runs `PreviewWork.run('parse', source)`
  (isolate) above `_syncParseLimit = 64 * 1024`, synchronously below, obtaining
  a `BlockPhase{nodes, linkReferences}`; each block's inlines are computed on
  **first build** via `_builder!.build(withInlines(_doc, block))` (~0.1 ms/block
  vs the old 378 ms whole-document inline pass).
- **Rendering:** `CustomScrollView` → `SliverPadding` → `SliverList` (plain) or
  **`SliverVariedExtentList(itemExtentBuilder: (i, _) => map.extentFor(i))`**
  when a `ScrollMap` is present. **Grouping:** one sliver child per *top-level
  node*, not per built widget, because `flutter_markdown_plus` appends a
  `SizedBox` after every block and "its flat list has more entries than the
  source has blocks and the scroll map's per-block measurements drifted by one
  every block (T-PP-22)".
- **Extent sync:** `_onBlockMeasured` → `map.measure(index, height)` → schedule a
  post-frame `applyMeasurements()`; if it moved anything, `setState` for one more
  pass. Doc: "It settles in one extra frame — a block measured with the same
  width measures the same."
- **Scroll deferral:** `_onScrollNotification` sets `_scrolling` + a
  `_settleTimer` and hosts a `MathDeferScope`, so math holds placeholders during
  a gesture.
- `MediaQuery` text scaling is replaced at this boundary so the note renders at
  the *note* text size, not the interface size.
- **Math wiring:** `MathInlineBuilder`/`MathBlockBuilder`, a shared `MathCache`,
  `MathBlockSyntax`/`splitInlineMath`. The inline builder returns a `Text.rich`
  with a `WidgetSpan` deliberately, because the package keeps non-text widgets as
  separate `Wrap` children and a bare view "would strand the formula (and its
  neighbours) alone on a line (device report, 2026-09-11)".

**Verdict: PORT the windowing, the two-phase parse, the grouping rule and the
post-frame extent sync — that is architecture and it is correct. REPLACE the
`flutter_markdown_plus` dependency**, because the codec/window boundary is the
thing being rebuilt: `MarkdownPreview` currently *is* the package's builder plus
Niman's windowing wrapped around it, so the new surface should own the
block→widget mapping directly and drop `MarkdownBuilder`,
`MarkdownElementBuilder`, `MarkdownStyleSheet`, `SyntaxHighlighter` and the
`Wrap`-merge quirk. Keep the *contracts*: per-block build, measured height out,
`imageDirectory` resolution, `onWikiLink`/`onTapLink`, `embedResolver`.

### 7.9.5 `ScrollMap` (`preview/scroll_map.dart`) — **keep now, generalise**

`blockStartLines: List<int>`, `blockHeights: List<double>`,
`_measuredPixels`/`_measuredLines` running sums, `_extents: List<double>` (the
frozen per-block extent handed to the sliver), `_pending: Map<int, double>`
(measurements waiting for the frame end), `contentInset`, `lineOffset`
(frontmatter). `BlockLocator` is a structural top-level block scanner whose
count the locator tests assert matches the parser's AST.

- `measure(index, height)` moves a block from estimate to measured, subtracting
  its old contribution from the running sums; if the new height differs from the
  **frozen extent** by more than `_extentEpsilon = 0.5`, it goes to `_pending`.
  `applyMeasurements()` freezes them.
- `extentFor(index)` → `_heightOf(index)` → `measured > 0 ? measured :
  span * perLine`, where `perLine = _measuredPixels / _measuredLines` (or
  `defaultPixelsPerLine = 22`).
- `previewOffsetForLine(line, into:)` walks blocks above and adds a fraction of
  the line's own block — **because "the fraction put the preview behind the
  editor next to" a tall image/math block (T-PP-22)**.
- `totalExtent()` **walks every block** to settle extents, because "a lazy list
  extrapolates from the handful of children it has laid out, which put the end
  of a 10 000-line note some 30 000 px away when its blocks add up to twelve
  times that: every jump past the guess was clamped, and the two panes came
  apart (device report, 2026-09-10)".
- `rebuild(source, lineOffset:)` carries measured heights over for blocks that
  keep the same start line — **"without that, every debounced edit (one parse
  per typing pause) wiped the whole map, and the preview re-measured every block
  on screen"**.
- `_spanOf(index)` is the line span; unmeasured blocks use the **global**
  pixels-per-line average; `blockForLine` binary-searches.
- `_BlockMeasure`/`_BlockMeasureRender extends RenderProxyBox` reports
  `size.height` after `super.performLayout()`, wrapped in
  `OverflowBox(minHeight: 0, maxHeight: double.infinity)` because the sliver's
  tight constraint would otherwise make a block report its *estimate* back and
  freeze a wrong height.

**Verdict: keep as-is now, then generalise** — every documented behaviour is a
hard-won fix and must not be lost, and the *shape* (freeze-on-first-ask,
post-frame commit, one sliver child per block, carry-over by start line) is the
right one. The generalisation (§2.10/§6.6): (1) replace
`_measuredPixels/_measuredLines` + one `perLine` with a **per-block-kind
estimator**, because on `Geometria 1.md` a single 22 px/line is wrong for 1682
of 10 331 lines; (2) replace the flat `_extents` walk in `totalExtent()` with a
**prefix-sum index** so it is O(1)/O(log n), and give the sliver an
`indexToLayoutOffset` that reads it instead of scanning; (3) add **explicit
scroll anchoring** (anchor block + delta, `ScrollPosition.correctBy` or a
`SliverGeometry.scrollOffsetCorrection`) instead of relying on the sliver to
absorb changes; (4) drive invalidation from the `ChangeSet` (which blocks' line
ranges overlap the change) rather than the "same start line" carry-over, which
is a good heuristic but breaks when a block above the viewport grows while start
lines shift.

### 7.9.6 `preview_work.dart` — **keep as-is; add a first-scroll task**

`PreviewWork.run(task, source)` spawns an `Isolate.spawn` with a **top-level**
entry and a message of nothing but strings, replying on a `SendPort`.
`Isolate.run` is deliberately **not** used: "its wrapper closes over the calling
zone, and a closure created inside a widget State carries the State's element
with it — the isolate rejects that (`Illegal argument in isolate message: object
is unsendable`)". Tasks: `parse` (block phase), `stats` (word count + outline),
`read` (file decode, distinguishing "not UTF-8" via
`PreviewWorkFailure.notText` — issue #156). Stats deliberately do not ride with
`read`, because stats cost ~1.1 s on the 931 K note while reading is 44 ms, and
"carrying them here only bought a 1.2 s spinner in front of a note whose first
frame paints in 0.4 ms". `statsFor` returns
`(countWords(text), outlineOfText(text))`, and the comment is the money quote:
"the outline used to come from `HighlightDocument.fromText(text).lines`, which
on a 931 K maths-dense note spent ~1.07 s of a ~1.16 s total inline-scanning
10 406 lines to find 84 headings. `outlineOfText` walks the block state machine
alone for the same answer."

**Verdict: keep as-is.** Correct isolate protocol for this app: top-level entry,
strings only, typed failure values, split the cheap thing from the expensive
thing. **Two additions:** (i) a **`blocks`/first-scroll task** returning the
block index for a large file on open, so the first scroll into an unparsed
region does not pay a synchronous block scan on the UI isolate; (ii) **batch the
parse.** The current message copies the whole buffer string (~1 MB per parse)
across the isolate boundary, and the per-keystroke cost that matters more than
the tree shape is message copying. Debounce/coalesce. If parsing becomes
frequent, a **long-lived isolate with a `SendPort`/`ReceivePort` command loop**
avoids repeated spawn (~1–3 ms plus warmup) — which the existing
top-level-entry discipline already permits.

### 7.9.7 `MathCache` + `math_widget.dart` — **keep as-is; add a `TeXLayout` seam**

`MathCache` is an LRU over `BoxNode` keyed `'${display?1:0}\u0000$tex'`, capacity
512, with `hits`/`misses`/`generation` counters (used as test assertions),
`_errors` as a **never-cached** negative cache, and `_inflight` dedupe so
concurrent requests for the same tex share one render. The default render is
`renderToBox(tex, options: KatexOptions(displayMode: displayMode))` —
**synchronous, ~0.1 ms per span** — and the doc explains why there is no
isolate: "the isolate route proved un-sendable for the closure on AOT devices
(the message carried the calling zone and every span rendered its red error
fallback)". `renderer`/`asyncRenderer` remain as timing seams.

`math_widget.dart` adds `MathDeferScope` (an `InheritedWidget` carrying
`deferring`), and each `InlineMathView`/`BlockMathView` **listens to nothing**: it
calls `_request()` in `didChangeDependencies`, hands a `then` that `setState`s
only itself, and bumps `_revision` so a stale completion cannot rebuild a
recycled view. The comment names the exact failure it avoids: "A listener on the
shared cache would rebuild every mounted formula on every other formula's render
— the scroll-time storm on math-heavy notes (T-PP-22); the cache's own dedupe
still shares one render between views of the same tex."

**Verdict: keep as-is** (both files) — a well-engineered cache and widget. Add
only a **`TeXLayout` seam** (§7.5) so `BoxNode` does not leak into the widget
API, and a **priority hint** so blocks approaching the viewport are typeset at
idle priority rather than only on first build, removing the "placeholder →
pop-in" the deferral currently produces.

### 7.9.8 `block_parse.dart` + `math_syntax.dart` — **port the rules, replace the mechanism**

`makeDocument()` builds one `md.Document` (GFM extension set + `MathBlockSyntax`
+ `EmbedInlineSyntax` + `WikilinkInlineSyntax`, `encodeHtml: false`), shared by
the preview and the WYSIWYG codec "so the two cannot drift apart".
`parseBlockPhase` runs only `md.BlockParser(...).parseLines()` and returns
`(nodes, linkReferences)` with `md.UnparsedContent` leaves. `prepareInlines`
seeds `linkReferences` and, crucially, **seeds footnote numbering from document
order** so "a footnote's number never depends on which block scrolled into view
first" — the fix for running inlines out of order. `withInlines` inlines one
block then applies `splitHtmlTables(splitInlineMath(...))`.
`hoistTaskCheckboxes` fixes a loose/tight-list `p`-wrapping discrepancy that
made checkboxes vanish (device report, 2026-09-18). `_gatherFootnotes`
reimplements the package's footnote filtering at block level.

`math_syntax.dart` implements `MathBlockSyntax` (indent-agnostic, and it works
inside list items/blockquotes because the package re-parses item content with
the document's syntaxes), `splitInlineMath` (post-parse, because "parser-side
inline syntaxes fight the `markdown` package's inline flow"), and
`stripFrontmatter`/`frontmatterLines` (whose count is what lets
`ScrollMap.lineOffset` keep editor and preview line numbers aligned after a
"device report, 2026-09-10" bug left the preview eight lines ahead all the way
down).

**Verdict: PORT the *rules*, REPLACE the *mechanism*.**

- Keep `math_rule.dart`'s single shared predicate (`findInlineMath`,
  `isSingleLineDisplay`, `displayMarkerStart`, `isDisplayClose`) — that the
  editor highlight and the preview parse cannot drift is a design asset and is
  why `parseLinks`/Ctrl+click/the preview all agree.
- Keep the block-phase/inline-phase split and `prepareInlines`' seeding (the
  scheduling contract for out-of-order inline parsing), plus the frontmatter
  offset discipline.
- **Replace** the `markdown` package's `md.Document`/`md.Node`/`BlockParser`
  with Niman's own block scanner + inline scanner, because (i) the package's AST
  has **no source offsets anywhere** — verified in the package source: `Line` is
  `{content, tabRemaining, isBlankLine}` and `Node` is `abstract {accept,
  textContent}` — which is the reason `BlockLocator` exists as a *parallel*
  scanner whose agreement is only asserted in tests; and (ii) the package is the
  source of the loose/tight-list and inline-flow constraints that
  `hoistTaskCheckboxes` and `splitInlineMath` work around. The package's
  cross-block state (`Document.linkReferences`,
  `Document.footnoteReferences`, `parser.encounteredBlankLine`,
  `BlockquoteSyntax._lazyContinuation` — a **static** mutable flag, and there is
  **no document-level open-block stack** at all: containers recurse over
  rewritten child lines) also shows why a hand-written scanner with explicit
  state is cleaner. A Niman block tree with `[from, to)` spans deletes both
  workarounds and makes `BlockLocator`'s agreement structural. **This is the
  strongest argument in the repo for building the new parser.**

### 7.9.9 `links/parser.dart` — **keep as-is, exactly**

`parseLinks(text)` → `linksInDocument(HighlightDocument.fromText(text))`: it
*reads the tokenizer's tokens* rather than re-scanning, so
`TokenKind.wikilink`/`TokenKind.link` are exactly the link ranges the editor
paints, and "links inside code fences, math blocks, inline code or the
frontmatter are never links, everywhere". `parseWikiRef(inner)` is **the single
parse rule** — "the indexer, the editor Ctrl+click and the preview all call it"
— splitting on the first `|` for the alias and the first `#` before it for the
heading. Images (`![alt](src)`) are excluded from links; `![[…]]` embeds are
excluded from wikilinks; empty refs are skipped.

**Verdict: keep as-is.** This is the model to extend: one tokenizer, one rule,
three consumers. If a new surface re-tokenizes links differently, the SQLite
index and Ctrl+click will disagree with what is painted — a silent
data-quality bug from the user's point of view. Expose the same `parseWikiRef`/
`ParsedLink` shapes, or rewrite the resolver in lockstep.

### 7.9.10 `scroll_sync.dart` + `editor_preview_split.dart` — **port**

`EditorPreviewScrollSync` wraps the two-pane `Row`; on a user scroll in either
pane it maps through `ScrollMap` and moves the other, suppressing programmatic
jumps with a guard flag and ignoring moves below `deadzone = 8` px "the other
pane's own native scroll feedback would otherwise fight the mapping".
Critically, the editor's side of the mapping is its **top visible line**, read
from `EditorLineView` — not a pixel fraction — because "`re_editor` sizes the
scroll extent by counting every line below the viewport as a single row, so the
extent grows as wrapped lines come into view and the same fraction means a
different line at every position". Without `lines` it falls back to the
fraction, "which is right only while no line wraps".
`EditorPreviewSplit` is a draggable fraction with a 1 px visual divider and a
12 px hit box, persisting `onFractionChanged`.

**Verdict: port.** The `deadzone` + guard-flag + top-visible-line design is
correct and directly reusable. The `lines` dependency disappears if the new
editor owns its line/wrap model (which it must, for per-line heights). The split
widget is untouched. For editor→preview jumps, prefer
`RenderAbstractViewport.getOffsetToReveal` / `ScrollPosition.ensureVisible` over
hand-walking blocks.

### 7.9.11 Carry-over summary

| mechanism | verdict | why |
|---|---|---|
| `HighlightDocument` incremental tokenizer | **keep as-is**, extend state + line index | the 0.507 ms asset; lazy materialization + convergence is the right architecture, and matches VS Code's line-state convergence |
| `EditorHighlightSync` | **port** (keep span cache, drop the diff scan) | a `ChangeSet` replaces `_firstChangedLine`/`_commonSuffix` |
| `MarkdownChunkAnalyzer` | **port**, feed it `forEachHeading` | same answer for a fraction of the cost; fold state belongs in the height index |
| `MarkdownPreview` windowing + extent sync | **port** | correct architecture; drop the `flutter_markdown_plus` builder layer |
| `ScrollMap` | **keep now, generalise** | per-kind estimator, prefix-sum index, real anchoring, `ChangeSet` invalidation |
| `PreviewWork` isolate protocol | **keep as-is**, add a blocks task + debounce | correct sendability discipline and failure typing; message copying is the real cost |
| `MathCache` + `math_widget.dart` | **keep as-is**, add a `TeXLayout` seam | LRU + never-cache-errors + no-listener rebuild is right |
| `math_rule.dart` shared predicate | **keep as-is** | prevents editor/preview drift |
| `block_parse.dart` two-phase + footnote seeding | **port the contract, replace the AST** | package AST has no source spans; a Niman block tree deletes `BlockLocator` and the list/inline workarounds |
| `links/parser.dart` single wikilink rule | **keep as-is, exactly** | one rule, three consumers |
| `scroll_sync.dart` | **port** | deadzone + guard + top-visible-line is right |

---

## 7.10 Ideas worth stealing

1. **`ChangeSet` + `mapPos(pos, assoc)`** — normalized `(len, ins)` sections and
   a left/right bias for "where did this offset go". Flutter: a
   `List<int>`-backed immutable value class; it replaces every ad-hoc offset
   fix-up in the editor, tokenizer, find panel, spell ranges and scroll map.
2. **`Mapping` with `MapResult.deleted`/`deletedBefore`/`deletedAcross`** — the
   ProseMirror refinement that also reports *whether* a position survived and
   how much was deleted around it. Flutter: the same class, used by the
   selection mapper so typing at a hidden-marker boundary does the intuitive
   thing.
3. **`RangeSet<Decoration>` / `DecorationSet`** — an immutable, chunked (250),
   persistent sorted range set with `between(from,to,f)` and a `compare` that
   diffs through an edit and invalidates heights only for `heightRelevant`
   changes. Flutter: the projection layer should be exactly this, not a
   `List<InlineSpan>` rebuilt from scratch.
4. **Hide by `Decoration.replace` + `atomicRanges`, never by removing text** —
   the source stays whole, only the projection elides, and arrow-key/selection
   motion treats the hidden range as one unit. Flutter: a projection segment of
   kind `hidden` plus the caret-snapping rule and an atomicity set.
5. **Gate the rebuild on `viewportChanged | docChanged | selectionSet`, skip the
   selection range, and honour a `mousedown` flag** — the exact CM6+Obsidian
   recipe. Flutter: build per-block widgets only for the sliver's current window
   and never iterate the whole document to build a decoration set.
6. **`TreeFragment` + `applyChanges(minGap = 128)` + `openStart`/`openEnd`** —
   the algorithm-independent way to say "this region is reusable; this boundary
   is suspect". Flutter: a persistent block index with explicit open boundaries
   and a reuse-size threshold.
7. **A per-block `lookAhead` (the equivalent of `NodeProp.lookAhead`)** — how
   far past a block's end the scanner looked, so a change in that window
   invalidates reuse. Flutter: 0 for a fence, one line for a setext
   heading/table/paragraph — **the most likely correctness bug if omitted.**
8. **A container-stack *hash*, not stack counts** (`hash = (parentHash +
   (parentHash << 8) + type + (value << 4)) | 0`, from `@lezer/markdown`) plus
   its reuse rules: snap the fragment end to a line break, never stop right
   after an indented code block / list item / list, and subtract one from an
   open end. Flutter: one int per line, checked at top-level block boundaries.
9. **A refmap/footnote epoch** — bump a counter when an edit touches a link
   reference definition or footnote definition, and key cached inline results on
   `(blockRange, epoch)`, because document-global state can change a block far
   away. Flutter: one int on the block index.
10. **Work ranges with a time budget, visible first, rest at idle** — parse what
    is on screen now, schedule the rest, mark unparsed regions stale
    (`viewportFirst`, `skipUntilInView`, 20 ms sync / 3000 ms per 30 s
    background). Flutter: a post-frame budget from `SchedulerBinding` plus a
    `Set<int> staleLines`; never a synchronous full pass on the UI isolate.
11. **`HeightMap` as a balanced tree of measured/estimated/gap nodes** —
    `HeightMapText` (`collapsed`, `widgetHeight`, `breaks`), `HeightMapGap`
    (interpolated `perLine + chars*perChar`), `HeightMapBranch`
    (weight-balanced), `applyChanges` walked backwards. Flutter: replace the
    flat `ScrollMap` extents with this shape; `totalExtent` becomes O(1), and
    **loading a 10 MB document costs one gap node, not one node per line.**
12. **`HeightOracle` as an estimator, not a measurement** —
    `heightForLine(length)`/`heightForGap(from,to)` from `lineHeight`,
    `charWidth`, `lineLength`, `lineWrapping`. Flutter: a per-block-kind model
    learned from measurements; the current single `pixelsPerLine = 22` is wrong
    for a math-dense note.
13. **`heightChangeFlag` as a global dirty bit set during the cheap walk** —
    answer "did height change?" without a second pass. Flutter: a `bool` on the
    height index checked once in the post-frame pass.
14. **Freeze extents; adopt measurements only between frames** — an extent that
    moves under an already-placed child breaks the sliver. Flutter: `_pending` +
    `applyMeasurements()` post-frame (already done — keep it).
15. **Correct by returning `SliverGeometry(scrollOffsetCorrection: delta)`** and
    let `RenderViewport.performLayout` call `offset.correctBy(delta)` in the same
    layout pass — one pass instead of the current post-frame `setState`; and use
    `ScrollPosition.correctBy` (never `jumpTo`/`animateTo`) for anchor
    correction outside a sliver.
16. **A prefix-sum height index with O(1) select** — VS Code's
    `ConstantTimePrefixSumComputer` keeps `_prefixSum[]` **and**
    `_indexBySum[sum] = block` for every integer pixel, so `getIndexOf(sum)` is a
    direct array lookup and only forward refills are needed. Flutter: this, or a
    Fenwick tree if extents stay floating point. **Do not settle for
    `SliverVariedExtentList`'s default `indexToLayoutOffset`, which is
    `O(index)`.**
17. **`ResolvedPos` / `$pos.textOffset`** — the position→structure map and the
    explicit escape hatch for "a position inside a text node". Flutter: a
    `ResolvedPos{blockIndex, offsetInBlock, inlineSpanIndex?}` for the caret and
    the toolbar.
18. **`Step`/`Transform` for structural edits raw text makes painful** — list
    renumbering, table row insert, heading level change, block move all have a
    clean `Step` form, and `Transaction.selection`'s lazy
    `map(doc, mapping.slice(from))` is the pattern. Flutter: a small
    `EditorCommand` layer with `apply(state) -> state` and `invert()`,
    generalising `editor/list_tally_edit.dart`; do *not* build a full document
    tree.
19. **Flat typed-array node storage (`TreeBuffer` quads)** — tokens/nodes as
    `(type, start, end, endIndex)` in a `Uint16List` instead of objects. Dart:
    the difference between a token tree of a 10 331-line document costing a few
    MB and hundreds.
20. **Weight-balanced child grouping (`BranchFactor = 8`)** — never let a node
    hold 10 000 children. Flutter: group blocks into anonymous branch nodes (or
    a prefix-sum index) so `resolve`/`blockAt` stay `O(log n)`.
21. **`NodeWeakMap` / reuse-keyed side tables** — attach computed values
    (decorations, measured heights, rendered math) to a node so they survive
    subtree reuse. Flutter: an `Expando`/keyed map from block identity, not from
    an integer index that shifts.
22. **Keyed, dirty-driven reconciliation** — copy-on-write (`getWritable`), an
    **editor-level** dirty set (not a per-node bitmask), and a fast path on
    `prevNode === nextNode && !isDirty`; then a Set-based children diff where a
    move is an `insertChild` of an existing element. Flutter: `ValueKey`s plus
    `findChildIndexCallback` so an edit that shifts blocks keeps the existing
    `Element`/`RenderObject`.
23. **KaTeX's 8×8 atom-spacing table applied in one build pass** — thin 3 mu,
    medium 4 mu, thick 5 mu, with `tightSpacings` for script styles and bin
    cancellation by `binLeft`/`binRightCanceller`. Flutter: ~150 lines of Dart
    that make an inline formula look right *while typing* without a full TeX
    pass.
24. **`makeVList`'s `(depth, minPos, maxPos)` arithmetic** — the vertical stack
    loop with `currPos` and `y = -(currPos + elem.depth)`. Flutter: implement the
    arithmetic and **drop the `pstrut`/`vlist-t`/`vlist-r` scaffolding** —
    `RenderBox` positioning has no need for the CSS workaround.
25. **KaTeX's per-character metrics `[depth, height, italic, skew, width]` in em
    + `sigmasAndXis`** — the entire physical model, ~60 global constants plus a
    table. Flutter: ship the KaTeX math fonts as assets (permissive) and
    transcribe the table; **`italic`/`skew` cannot be regenerated from the TTF,
    so this is the part that cannot be shortcut.**
26. **Errors degrade to visible source, never to a blank box** — KaTeX's
    `throwOnError: false` renders the raw TeX in `errorColor`. Flutter:
    `MathCache._errors` already never caches a failure; render the source.
27. **Stream-language state machines, not TextMate** — per-line state +
    convergence, which is also exactly what VS Code does with a far heavier
    per-line state. Flutter: a `LineStateMachine` registry per fence language;
    never Oniguruma, never a whole-string engine on the editor's hot path.
28. **Whole-string highlighting only off the hot path** — the preview's code
    blocks (cached per `(language, textHash)`), export, and the capped chunk
    analyzer can afford `highlight` 0.7.0. Flutter: keep the two engines
    separate and never call the whole-string one from `spanFor`.
29. **Table virtualization row-by-row** — never lay out a 500-row table as one
    paragraph. *(Not prior art in Markwon: its `TableRowsScheduler` only
    coalesces invalidations and its Recycler table renders the whole table in
    one row — so this is a design Niman would be inventing, and
    `preview/html_table.dart` will need it once a note has a big table.)*
30. **Isolate protocol: top-level entry, strings only, typed failures, split the
    cheap read from the expensive stats, and debounce** — `Isolate.run`'s closure
    is unsendable from a widget State. Flutter: keep `PreviewWork`'s shape; the
    per-keystroke cost that matters is message copying, not tree shape.
31. **A viewport controller that lays out a rect and estimates elsewhere**
    (TextKit 2's `NSTextViewportLayoutController` + `.estimatesSize`/
    `.estimatedUsageBounds`, `UITextView`'s framework-managed `contentOffset`,
    `content-visibility: auto` + `contain-intrinsic-size: auto <len>` +
    `overflow-anchor: none` when you own the offsets) — the OS/browser-level
    prior art for `visibleRanges` + `HeightMap`. Flutter: the design target for
    the height index's API, and the reason to own the anchoring yourself.
32. **One shared parse rule per concept, read by every consumer** — Niman's
    `math_rule.dart` and `links/parser.dart`'s `parseWikiRef` are the repo's best
    idea: the editor highlight, the indexer, Ctrl+click and the preview cannot
    disagree because they call the same function. Flutter: make this a hard rule
    for the new surface — one `wikiRef`, one `mathSpan`, one `blockSpan`, no
    re-derivation.

---

### Closing note on the target document

The single most decision-relevant fact about `Geometria 1.md` is its shape:
**1682 display-math lines and 1394 `\begin`/`\end` pairs against 0 code fences
and 40 wikilinks.** That inverts the usual priorities. Prose windowing, link
parsing, syntax highlighting and even the block tree are cheap at this scale;
the two things that will decide whether the editor feels fast are

1. **TeX typesetting cost per block** — currently 5–6 ms/block on math-heavy
   blocks with `katex_dart` + `katex`, mitigated by `MathDeferScope`. **Measure
   the 1121 `pmatrix` cases before changing anything** (§7.5).
2. **Height estimation for math blocks** — a single 22 px/line underestimates a
   display formula by an order of magnitude, and `ScrollMap`'s flat array makes
   `totalExtent()` O(blocks) on every layout. **The cheapest large win
   available** (§6.6, §9.5).

Everything else here is architecture insurance: build the `ChangeSet`, the
decoration `RangeSet`, the prefix-sum height index, the position-mapping layer
and the shared parse rules, and both the source editor and the preview stay
`O(visible)` at 1 MB — the property the incumbent already has and the one thing
that must not regress.


---

# 8. The proposal: one surface, three modes

## 8.1 The shape of the answer

One widget, `MarkdownSurface`, with a mode. The modes are *presentation
policies* over a single pipeline, not three engines:

```
                 ┌──────────────────────────────────────────────┐
  source text ──▶│ SourceBuffer   (lines + prefix sums, O(log n))│
  (the document) │        │                                       │
                 │        ▼                                       │
                 │ BlockScanner   line state machine, O(change)   │
                 │        │                                       │
                 │        ▼                                       │
                 │ BlockIndex     immutable, revision-stamped     │
                 │        │                                       │
                 │        ├──▶ InlineParser  (lazy, per block)    │
                 │        │        │                              │
                 │        │        ▼                              │
                 │        │    RenderedBlock ── source text +     │
                 │        │                     style runs +     │
                 │        │                     decorations       │
                 │        ▼                                       │
                 │ HeightMap      Fenwick prefix sums, O(log n)   │
                 └────────┬───────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
   mode: source      mode: live        mode: read
   all markers       markers hidden    markers hidden
   shown, mono       except at the     always; no caret,
                     caret (revealed)  no IME
```

The three modes differ in exactly three things: **which characters are
rendered**, **whether there is a caret/IME**, and **which font family the
prose uses**. Everything else — parsing, inline spans, math, code
highlighting, block metrics, the viewport, the height map, the theme, the
find state, folding, the outline, the toolbar's active-format computation,
the context menu, the tools, the spellcheck ranges, the clipboard, the undo
stack — is one implementation.

That is what makes R2, R3 and R4 fall out by construction rather than by
discipline.

## 8.2 The document model: the source text *is* the document

The repo's first rule is "disk is source of truth", so the in-memory document
is the Markdown text and nothing else. This is the architectural fork in the
road and it is worth stating plainly:

| Model | Where it is used | Verdict here |
|---|---|---|
| Delta / rich-text document, serialized on save | `flutter_quill` today | **Rejected.** A Delta is not Markdown; the codec is 648 lines and still loses information. |
| Node tree authoritative, serialized on save | ProseMirror, Lexical, appflowy_editor | **Rejected as the document.** The tree is a *derived* structure here, never written back. |
| **Source text authoritative, tree derived** | Obsidian live preview, CodeMirror 6, VS Code, Typora | **Adopted.** Matches "disk is source of truth" exactly: nothing can drift, saving is the identity function. |

### 8.2.1 `SourceBuffer`: a line array with a prefix-sum index

Markdown is line-structured, so the buffer is a **line array** rather than a
rope or piece table:

```dart
final class SourceBuffer {
  final List<String> _lines;        // no trailing '\n' stored
  final String _eol;                // '\n' or '\r\n', detected once
  int _length;                      // total chars incl. separators
  // Fenwick tree over line lengths → O(log n) lineOf(offset) / offsetOf(line)
  final Int32List _fenwick;
}
```

Why a line array beats a rope here:

- **Editing is a line splice.** A keystroke inside a line replaces one
  `String` (O(line length), not O(document)). A newline splits one line into
  two (O(log n) Fenwick updates). Nothing else in the document moves.
- **The parser is line-oriented anyway.** Every block construct in
  CommonMark except fenced code, HTML blocks and indented code is a
  per-line decision; those three are still decided per line, with a carried
  state. Handing the parser a `List<String>` is handing it its natural input;
  a rope would force an `offsetToLine` on every access.
- **`lineOf`/`offsetOf` are O(log n)** through the Fenwick tree, which matters
  because the caret, selection, spellcheck ranges, link resolution and the
  scroll map all speak in *absolute source offsets*, while parsing speaks in
  lines.
- **It cannot diverge from the file.** `buffer.text` is
  `_lines.join(_eol)`; writing is byte-identical to what was read unless the
  user changed something. CRLF is preserved as a document-level property (a
  mixed-EOL file keeps its mixed EOLs by storing the separator per line — a
  decision to take deliberately and test).

**Built, and measured** (`lib/src/markdown/{fenwick_tree,source_buffer}.dart`,
`dart run tool/source_buffer_bench.dart`, debug mode, best of many batches —
the numbers are read as ratios, not absolutes):

| fixture | lines | load | **content edit** | **structural edit** | line delete | `lineOf` | `lineAt` | `text` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `fixture-10kb.md` | 400 | 0.02 ms | 0.60 µs | 6.2 µs | 5.7 µs | 0.019 µs | 0.005 µs | 0.01 ms |
| `fixture-200kb.md` | 6 289 | 0.45 ms | 0.38 µs | 83 µs | 83 µs | 0.024 µs | 0.004 µs | 0.17 ms |
| `fixture-1mb.md` | 32 101 | 3.09 ms | 0.75 µs | 843 µs | 842 µs | 0.031 µs | 0.004 µs | 2.16 ms |
| `Geometria 1.md` | 10 332 | 1.97 ms | 0.41 µs | 151 µs | 145 µs | 0.025 µs | 0.004 µs | 1.19 ms |

What that says, and what it does not:

- **A content edit is flat**, 0.38–0.75 µs from 400 to 32 101 lines — O(log n)
  as designed, and 0.1 % of the 0.5 ms keystroke budget. This is the common
  case and it is free.
- **A line-count change is O(lines), and at 32 101 lines it costs 843 µs** —
  above the keystroke budget, though still inside a 60 Hz frame. On the app's
  own worst note (10 332 lines) it is 151 µs. So Enter and paste are fine at
  the sizes this app actually has, and the *synthetic* 1 MB fixture is where
  the rebuild starts to be the dominant cost of the keystroke.
- **The fix, if it is ever needed, is block decomposition** — sums per block of
  256 lines over a second tree — which turns the rebuild into
  O(256 + log blocks). It was not built because the measurement says it is not
  needed yet, and this table is what makes that a decision rather than a habit.
- `lineOf` and `lineAt` are 20–30 ns and 4 ns: the queries the parser and the
  caret make thousands of times are not a cost at all.
- `text` is O(n) — 1.2 ms on the geometry note — which is why it is the
  *save* path and never the keystroke path.

Memory: a 10 331-line note is a `List<String>` of 10 331 entries plus 41 KB of
Fenwick index, against ~1.9 MB for the text itself as UTF-16.

**Where this sits in the survey's classification.** The prior-art survey
([§7.1](#71-the-three-candidate-architectures)) lays out three architectures and
recommends the hybrid — source text authoritative, an incremental parse, and a
*real span tree* projection rather than a flat decoration set. This design is
that recommendation with one deliberate substitution: **a line array instead of
a rope or piece table.** The survey's own comparison notes that VS Code's piece
table exists so that a 10 000-line file needs no line array; Markdown needs
exactly the opposite, because every block decision is a *per-line* decision, so
the line array is the parser's natural input rather than a convenience. The
Fenwick prefix sums restore the one thing the rope gave for free — O(log n)
`offset ↔ line` — and the parser gets O(1) line access without an
`offsetToLine` on every access. If a future requirement needs character-level
edits inside very long lines (a minified JSON blob pasted into a note, say),
the buffer is the one component to revisit; nothing above it assumes a line
array.

### 8.2.2 Revisions, not mutation

The buffer is mutated in place for speed, but it carries a monotonically
increasing `revision` counter. Every derived structure (`BlockIndex`,
`InlineSpans`, height entries, highlighted lines, math boxes) is stamped with
the revision it was computed from and is invalidated by comparison, not by
notification. This is what makes the whole system cheap to reason about:

- No observer graph, no `ChangeNotifier` fan-out storm on every keystroke.
- A block's rendered form is cached under `(blockId, revisionOfBlockText)`;
  unchanged blocks keep their layout across a revision bump.
- The background isolate can be given a (revision, splice) pair and knows
  exactly what it has already parsed.

## 8.3 One typography, one block metric set

Today the same note is styled by three authorities: `re_editor`'s
`CodeTheme`, Quill's `DefaultStyles` + the Markdown codec's attributes, and
`flutter_markdown_plus`'s `MarkdownStyleSheet`. They disagree about heading
sizes, paragraph spacing, list indents, code background, blockquote bars and
table borders — which is precisely why switching modes moves the text.

The replacement is one immutable `MarkdownTheme`:

```dart
final class MarkdownTheme {
  final TextStyle body, h1, h2, h3, h4, h5, h6;
  final TextStyle code, codeInline, quote, tableCell, tableHeader, math;
  final TextStyle mono;                  // source mode's prose font
  final Color codeBackground, quoteBar, rule, tableBorder, tableStripe;
  final Color markerDim, link, wikilink, tag, taskBox, syntaxMarker;
  final double quoteBarWidth, ruleThickness, listIndentPerLevel,
      blockSpacing, paragraphSpacing, codePadding, tableCellPadding;
  final double columnWidth;              // the readable-line-length setting
  final TextDecoration squiggle;         // spellcheck
  final TextHeightBehavior heightBehavior;
}
```

Rules that make it *uniform* rather than merely shared:

1. **One metric per construct, used by all three modes.** `listIndentPerLevel`
   is the same number that indents a source line and a rendered list item, so
   toggling modes does not move text sideways.
2. **`columnWidth` is applied by the surface's own padding**, not by three
   different `padding` parameters — so the toolbar, find bar and status row
   keep to the column as `docs/user/editing.md` promises.
3. **Block spacing is a property of the block, not of the widget that renders
   it**, so a paragraph followed by a list is spaced identically in live and
   read.
4. Source mode is *not* a different theme: it is the same theme with
   `prose: mono` and `markers: visible`. Even the marker dimming colour is a
   theme token, so source mode's syntax colouring and live mode's revealed
   markers are the same colour by construction.

## 8.4 Layout: only the blocks the viewport shows

The preview already proves this design (`SliverVariedExtentList` +
`ScrollMap`), and the numbers in [§2.2](#22-what-the-code-already-measured-and-what-it-says-to-keep)
say why: eager layout of a 934 KB note is thousands of `TextPainter.layout`
calls at ~45 µs, i.e. hundreds of milliseconds and a guaranteed frame drop.

The corpus profile puts exact figures on it
([§5.6](#56-scrolllayout-sizing-model)), and they change one design decision:

| Strategy | Cost on `Geometria 1.md` | Frames @ 60 Hz | Frames @ 120 Hz |
|---|---|---|---|
| Eager: every block laid out | **552 ms** (range 371–988) | 33.1 | 66.2 — **not viable** |
| Viewport only | **5.23 ms** | 0.31 | 0.63 |
| Viewport + one viewport of cache on each side | **15.70 ms** | 0.94 | **1.88** |

**A hard constraint first, because it decides the whole split:** text layout
cannot leave the root isolate. `dart:ui`'s `ParagraphBuilder`, `Paragraph`,
`Canvas` and `PictureRecorder` throw `UI actions are only available on root
isolate` off it (the engine's `UIDartState::ThrowIfUIOperationsProhibited()`;
[flutter#41707](https://github.com/flutter/flutter/issues/41707) is closed as
not planned). So the parse, the lexers and the **math parse** go off-thread,
and the **layout and paint stay** — see
[§6.0](#60-executive-summary-of-the-cost-model) and
[§6.7](#67-isolates-and-parsing-off-the-ui-thread). This is why the design's
isolate work is about *what crosses the port*, not about moving layout.

Three consequences, all load-bearing:

1. **Eager layout is off the table by a factor of 33**, which is the quantitative
   version of "never hand the document to an eager `Column`".
2. **At 120 Hz, filling the cache is itself more than one frame's work.** The
   cache extent must therefore be filled *incrementally across frames* — a
   background "lay out one more block" step per frame, seeded in the direction
   of travel — rather than in a single synchronous pass after a jump. A design
   that lays out viewport + cache in one go passes at 60 Hz and misses every
   other frame at 120 Hz.
3. **A "40-block viewport" is really about 117 visual lines**, because the real
   note averages 2.93 visual lines per block (89.5 bytes per line against the
   1 MB fixture's 31.7, i.e. per-line work is ~3× worse on the real note than
   on the synthetic benchmarks the repo has been tuning against). Any budget
   expressed in "blocks" must be converted through that factor before it means
   anything.

What the replacement adds over today's `ScrollMap`:

### 8.4.1 A Fenwick-tree height map

Today `ScrollMap._heightOf` walks blocks to sum extents (`O(blocks)` per
lookup) and `previewOffsetForLine` walks the blocks above the line. On a
10 331-line note with a few thousand blocks that is fine for a jump but bad
inside a scroll frame. The replacement keeps measured heights in a Fenwick
tree so:

- `extentFor(block)` — O(1)
- `totalExtent()` — O(1)
- `blockAtPixel(y)` — O(log blocks)
- `pixelOfBlock(i)` — O(log blocks)
- `heightMeasured(block, h)` — O(log blocks) update

### 8.4.2 Estimates that freeze

The lesson from `scroll_map.dart` is preserved verbatim: an unmeasured block's
extent is **frozen on first use** and replaced only by that block's own
measurement, because re-estimating already-placed blocks moves offsets under
the scroll position and makes `SliverVariedExtentList` assert. The new height
map keeps that rule and adds per-kind estimators instead of one global
"pixels per line":

| Block kind | Estimate before measurement |
|---|---|
| Paragraph | `ceil(chars / charsPerLine) * lineHeight`, `charsPerLine` measured from the pane width and the theme |
| Heading | same, at the heading's own style |
| List item | same, plus `listIndentPerLevel * depth` |
| Fenced code | `lines * monoLineHeight + codePadding * 2` |
| Table | `rows * rowHeight(style)` |
| Math block | `measuredCache[tex] ?? lines * mathLineHeight` |
| Image | aspect ratio from the header if known, else a fixed placeholder ratio |
| Rule / frontmatter | fixed |

Per-kind estimates cut the error the scrollbar has to absorb, which is what
makes a 10 000-line note's scrollbar thumb stop jumping.

### 8.4.3 Scroll anchoring

When a revision changes a block **above** the viewport, every pixel offset
below it shifts. The surface keeps an anchor — `(blockIndex, fractionIntoBlock)`
— across layout and re-establishes the scroll offset after the frame, so the
line the reader was looking at stays put. This is what today's `ScrollMap`
does *between two widgets*; inside one widget it is simply the layout's own
invariant.

### 8.4.4 Sliver, or custom `RenderSliver`?

Two options, to be decided by measurement:

- **`SliverVariedExtentList` with the frozen-extent map.** Proven in this
  codebase; no new render code; `estimateMaxScrollOffset` is overridden so
  long jumps are not clamped (the `_MappedChildDelegate` trick).
- **A custom `RenderSliverMarkdownBlocks`.** Needed only if the frozen-extent
  trick stops being enough (e.g. because measured heights legitimately change
  on reflow when the pane is resized). A custom sliver owns its own
  `childManager`, can rebuild its own `SliverGeometry`, and would remove the
  "extents must not change" constraint. **Recommendation: start with the
  proven one, keep the custom sliver as the escape hatch, and make
  `HeightMap` the seam that both satisfy** so the swap is local.

**Found on a device, 2026-09-21 — this is the escape hatch.** The first real read
of the geometry note on an Android phone, with the engine set to `unified` (the
debug log records the switch at 17:46 and the way back at 17:52:46, eight
seconds after the screenshot), shows both halves of one failure at once: long
wrapped paragraphs and display maths **cut off** — a paragraph of Geometria is
one source line and thirty visual ones — and generous empty **gaps** where a
block's estimate exceeds what it draws.

The cause is the first bullet, and `SliverVariedExtentList`'s own documentation
says so: "Each child is **forced** to have the returned extent of
`itemExtentBuilder`", and the class is "appropriate for sliver lists ... whose
extent is **already determined**". Three consequences, in the order they bite:

- the estimate is a **constraint, not a guess**: a block taller than its estimate
  is clipped rather than overflowing, which is the cut-off text;
- `_RenderMeasured.performLayout` reports the size the sliver *imposed*, so
  `BlockHeightMap.measured` writes the estimate back, `applyMeasurements` finds
  the difference below `epsilon` and does nothing. The estimate → measure →
  correct loop is **dead code**, which is why the gaps never close;
- the estimate is in *source* lines (`block.lineCount * lineHeight`), and that is
  exactly wrong for the two kinds that matter here: a paragraph wrapping to
  thirty visual lines is estimated at one, and a multi-line `$$…$$` block at 1.6
  lines each while its typeset height has nothing to do with its line count.

So the recommendation above rested on a false premise — that a forced extent
could be corrected — and the escape hatch is now the plan: the read view needs a
sliver that **measures** its children (`SliverList` does; a custom
`RenderSliverMarkdownBlocks` does, laying each child out with unbounded
main-axis constraints), with the height map demoted from "the extents" to "the
estimator `estimateMaxScrollOffset` uses for the part of the note no frame has
laid out" — which is what §8.4.1's Fenwick tree was for.

**Two gates missed it, and both are named rather than mended quietly.** The
engine comparison reads `toPlainText()`, and clipped content is still in the
widget tree, so the words matched; and this phase's own exit criteria asked for a
**golden-image test per fixture** (§10.4, phase 2), which was never built. A
device, not a test, is what found this — and the fix wants the test first.

**Fixed, the same day: `SliverList` measures, and the jump pays for it.** The read
view now lays its blocks out through `SliverList` — every child measured with
unbounded main-axis constraints — and `BlockHeightMap` is demoted to what its
name always said: an estimator whose `estimateAfter` feeds
`estimateMaxScrollOffset` with the height of the part of the note no frame has
reached. `test/widget/markdown_read_view_test.dart` holds the property a device
found missing: a paragraph that wraps is drawn at its own height (31.5 px before
the fix, against the ~300 it needs), and the block after it starts below it.

The trade is measured rather than hidden. First content *improved* — 60 ms on the
geometry note against the 88 that forcing extents cost, because the first frame
no longer lays anything out to a guess — but a **far jump now walks the list**: a
`SliverList` cannot place a child it has not laid out, so jumping to the middle of
the geometry note reads 2 604 ms and builds 3 156 of its 7 530 blocks (386 ms and
470 of 1 092 on the 50 KB fixture). Cheap jumps were the forcing sliver's, and it
bought them with the clipping. Having both is the custom
`RenderSliverMarkdownBlocks` above — positions from the map, heights from
measurement — and that is now the next piece of work rather than a hypothesis.

Data to build while measuring: per-3-second rolling average of
`build + layout` time per block kind, blocks laid out per frame, and the
p90 of `editsPerSecond`. These become the regression tests of [§9](#9-the-performance-budget).

## 8.5 The parser: incremental, two-phase, line-oriented

**Who does what, after D2.** The CommonMark/GFM *grammar* is `markdown`
7.3.1's — the package stays, and none of this section replaces it. What this
section describes is the machinery the package does **not** have and cannot
give: it has no incremental API, no source spans on its nodes, and no notion of
"re-parse only what moved". So the package is called **per block, on
already-bounded input**, with the block boundaries, the source spans, the
extensions and the caching all Niman's. The extension zone the package cannot
know — wikilinks, `$…$` / `$$…$$` delimiters, YAML frontmatter, tags — sits in
front of it and masks those ranges before the package ever sees them
([§8.5.0](#850-what-the-corpus-does-and-does-not-exercise)). Conformance
becomes a measurement against the spec suite with the failures pinned
([§4.8](#48-recommended-conformance-strategy)), not a parser to write.

The parse is split exactly where the measurements say, and the split is the
same split the preview already uses — generalized to all modes:

| Phase | Input | Output | Cost on `Geometria 1.md` | When it runs |
|---|---|---|---|---|
| **Block scan** | the line array + the per-line state array | `BlockIndex`: top-level blocks `[startLine, endLine)` with kind, indent and container chain | 14 ms *(measured today)* | Off-thread, per edit, incremental |
| **Inline parse** | one block's text | `InlineSpans`: flat emphasised spans, links, wikilinks, math spans, code spans, tags, entities, escapes | 378 ms for the whole document *(measured today)* → **only for blocks laid out** | On demand, memoized per block revision |
| **Render** | one block's spans + theme | the block's source text + style runs + decorations (1:1 offsets) | ~45 µs/line for prose | For visible blocks only |

### 8.5.0 What the corpus does and does not exercise

The corpus profile ([§5](#5-the-corpus-reality)) contains the single most
important scoping fact in this document, and it cuts both ways.

**`Geometria 1.md` is 37.75 % math by bytes and almost nothing else.** It has
13 845 math expressions, 7 769 blocks, 2 392 paragraph lines (73.83 % of bytes),
852 list items, 84 headings, 22 blockquotes (all depth 1), 17 footnote
definitions, 2 GFM tables, 40 wikilinks (38 of them image embeds) — and
**zero** code spans, **zero** fenced or indented code blocks, **zero** links,
**zero** images, **zero** character entities, **zero** backslash escapes,
**zero** hard line breaks, **zero** link reference definitions.

So the app's real worst note:

- proves the *math* and *layout* requirements decisively (and tells us the
  required TeX subset precisely: **58 commands and 5 environments cover 95 %**
  of its expressions, 86 commands cover 99 %, `pmatrix` alone appearing 1 120
  times);
- tells us nothing about code highlighting, links, images, entities, escapes or
  reference definitions, all of which the spec suite and the synthetic fixtures
  must cover instead;
- and contains a trap worth naming: `Geometria 1.md` has **7 530 `_` delimiter
  runs, of which only 15 are left once the extensions are masked** — 7 530 →
  15, a 500× over-read of the emphasis algorithm for any inline pass that
  scans delimiters before masking. And it gets the emphasis *wrong* inside
  formulas, not merely slowly. **Masking (code, math, wikilinks, tags) before
  the inline pass is a correctness requirement, not an optimisation.**

  **Built, and measured** (`lib/src/markdown/extension_masker.dart`,
  `dart run tool/extension_masker_bench.dart`) — and the numbers land on the
  corpus profile's independently, which is the best evidence either is right:

  | fixture | blocks | spans | inline math | wikilink | embed | tag | code | `_` runs before | after |
  |---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
  | `fixture-200kb.md` | 4 301 | 308 | 62 | 28 | 0 | 49 | 109 | 310 | **0** |
  | `fixture-1mb.md` | 22 326 | 1 744 | 375 | 161 | 0 | 271 | 579 | 1 636 | **0** |
  | `Geometria 1.md` | 7 530 | **13 044** | **13 004** | 2 | **38** | 0 | 0 | **7 530** | **15** |

  The geometry note's row reproduces the corpus profile exactly where the two
  overlap — 13 004 inline math spans, 38 embeds, 2 wikilinks, no code spans and
  no tags — which is a cross-check neither measurement was built to pass. The
  masker runs over a whole document in 19–31 ms (≈4 µs per block), once, and
  only over the blocks that have inline content at all.

The practical consequence for the plan: the spec suite in
[§4.8](#48-recommended-conformance-strategy) and the adversarial fixture
([§5.7](#57-a-synthetic-worst-note-spec-and-fixture), 1 482 533 bytes / 11 773
lines, depth-7 lists, depth-4 quotes, a 12×41 table, a 2 000-line fence and a
2 000-line paragraph, 5 real reference definitions, 120 CRLF lines) are **both
mandatory and neither is sufficient**: the real note proves performance and
math, the spec suite proves correctness, and the fixture proves the union of
what the other two miss.

### 8.5.1 The block scan is already half-written

`highlighting.dart`'s `_State` (`fence`, `inMath`, `inFrontmatter`) *is* a
block-state machine, and `HighlightDocument._stateAfter` *is* the transition
function. What it does not carry yet is the container stack — list nesting
depth, blockquote depth, table continuation, HTML-block state, indented-code
state — and container state is what makes a line a `blockquote > list item >
paragraph` rather than a flat line. The replacement generalizes `_State` to:

```dart
final class LineState {
  final _Fence? fence;         // fence char + length + indent
  final bool inFrontmatter;    // only line 0..end of the leading --- block
  final MathRun? math;         // a $$ block, with its indent
  final bool inHtmlBlock;      // one of GFM's 7 HTML block types, with its end condition
  final bool inIndentedCode;
  final List<Container> containers; // (kind, indent, marker) innermost last
  final TableRun? table;       // GFM table continuation
}
```

### 8.5.2 Incrementality: reparse until the state converges

Markdown block parsing is almost a pure state machine over lines, with three
bounded lookahead cases (setext heading underline, GFM table delimiter row,
lazy blockquote/list continuation). So:

1. On an edit, take the lowest dirty line `L`.
2. Reparse from `L` forward, recomputing `LineState[i]` and the block
   boundaries it implies.
3. **Stop** at the first line `i` where the recomputed `LineState[i]` equals
   the previously stored state **and** every line from `i` to `i + K` is
   unchanged (`K` = the maximum lookahead, 2–3). The rest of the block index
   is correct by induction.
4. Splice the affected region of the block list; bump the affected blocks'
   text revisions.

The pattern already exists in this repo and should be the shape of the
implementation: `highlighting.dart:341`'s `if (state == old.entering)`, the
convergence check the current tokenizer uses to stop re-tokenizing.

**Built, and measured** (`lib/src/markdown/block_scanner.dart`,
`dart run tool/block_scanner_bench.dart`, debug mode):

| fixture | lines | blocks | cold scan | keystroke | **lines re-scanned** | Enter | lines re-scanned |
|---|---:|---:|---:|---:|---:|---:|---:|
| `fixture-200kb.md` | 6 339 | 4 301 | 3.81 ms | 86 µs | **5** | 114 µs | 51 |
| `fixture-1mb.md` | 32 151 | 22 326 | 12.27 ms | **85 µs** | **3** | 545 µs | 52 |
| `Geometria 1.md` | 10 382 | 7 530 | 6.79 ms | **29 µs** | **7** | 144 µs | 51 |

Three things that table says:

- **The convergence rule works as designed.** A keystroke in a 10 382-line note
  recomputes the state of **7 lines**. That is the O(change) property, and it is
  not a projection — it is the count, printed by the scanner itself.
- **Enter costs 51 lines, not 1**, and that is correct rather than a leak: the
  convergence point has to be a block boundary, so joining or splitting inside a
  paragraph re-parses the rest of that paragraph. The bound is the paragraph,
  which is the unit a caller already thinks in.
- **The wall clock is O(change) too, and it took a second pass to get there.**
  The first version of `edited` filtered and rebuilt a `List<Block>` of 22 326
  entries in three passes, which made the cost per *block* rather than per
  changed line: 290 µs → 1.23 ms as the document grew from 6 339 to 32 151
  lines. It now finds the head, the tail and the convergence boundary by binary
  search and splices the survivors back with one `replaceRange`, and the
  keystroke is **flat at 29–86 µs from 6 339 lines to 32 151** — a 14×
  improvement on the largest fixture and the property the design claimed.
  What stays document-shaped is Enter (545 µs on the 32 151-line fixture),
  because 51 lines are genuinely re-parsed: the bound there is the paragraph,
  not the bookkeeping.
- Cold scan is 6.77 ms on the geometry note, against the design's 20 ms budget,
  and it is the one-off cost of opening a note.

### 8.5.5 The inline phase, measured

The bridge (`lib/src/markdown/block_parser.dart`) masks a block, parses it with
the package, and walks the syntax tree alongside the masked text to give every
construct a source range. `dart run tool/bench.dart` runs every measurement in
this document's tables in one go — the buffer, the block scan, the masking and
the inline phase — and each also stands alone (`tool/block_parser_bench.dart`
below, `tool/source_buffer_bench.dart`, `tool/block_scanner_bench.dart`,
`tool/extension_masker_bench.dart`):

| fixture | blocks | with inline content | **all** | a viewport (40) | cache (120) |
|---|---:|---:|---:|---:|---:|
| `worst-note.md` | 2 435 | 983 | 484.50 ms | 64.09 ms | 67.60 ms |
| `fixture-200kb.md` | 4 301 | 2 256 | 97.49 ms | 1.56 ms | 4.06 ms |
| `Geometria 1.md` | 7 530 | 3 100 | **378.00 ms** | **5.13 ms** | 12.52 ms |

The geometry note's whole-document inline phase is **378.00 ms** — the same
figure this document has quoted all along from the *old* preview's split ("14 ms
of blocks and 378 ms of inlines on the 931K note"), reproduced to the
millisecond by code that shares nothing with it. That is the best evidence
available that the split is a property of Markdown rather than of one
implementation, and it is why the inline phase is done per visible block:

- **a viewport's worth is 5.13 ms** — inside a frame, once, and only on a miss;
- **the adversarial fixture's viewport is 64 ms**, because its blocks are
  enormous (a 2 000-line paragraph, 4 209-byte lines). The bound is the block's
  size, not the document's, which is what the cache and the viewport are for;
- the two columns together are the whole argument for windowing: a
  document-shaped cost of 378 ms against a screen-shaped one of 5 ms.

Measured expectation: a keystroke in the middle of prose dirties one line and
converges immediately — O(change), matching the 0.507 ms the tokenizer already
achieves. Pasting 500 lines dirties 500 lines and converges at the end of the
paste. Typing a backtick fence converges at the *next* fence close, which is
the worst case and is bounded by the fence's length, not the document's.
Inserting a blank line at the very top of the document is the pathological
case: it changes nothing about states (blank lines are neutral), so it also
converges immediately — the block list shifts but no line is re-tokenized.

### 8.5.3 Structural sharing

`BlockIndex` is immutable and shares unchanged blocks with the previous
revision. That gives the view a cheap diff (identity comparison per block),
which is what lets the surface rebuild only the visible blocks whose objects
actually changed — instead of the current pipeline, where a keystroke in the
WYSIWYG re-encodes the whole document into a fresh Delta.

### 8.5.4 The isolate protocol

Today `PreviewWork.run('parse', source)` sends the **whole source string** per
change. On `Geometria 1.md` that is a 934 KB copy per edit. The replacement
holds a mirror of the buffer inside a long-lived worker isolate and sends only
splices:

```dart
sealed class ParseCommand {}
final class ParseSplice extends ParseCommand {   // one edit
  final int revision, startLine, removedLines;
  final List<String> insertedLines;
}
final class ParseInvalidate extends ParseCommand { /* unused block ranges */ }
final class ParseRequest extends ParseCommand { /* blocks [a, b) inline-parsed */ }
```

and the worker answers with a **flat typed-array** payload
(`Int32List offsets`, `Uint8List kinds`, `Int32List parentChild`), so nothing
crosses the port but numbers. This is the design constraint worth fixing now,
because changing it later means rewriting both sides.

Lifetime and cost, from the isolate measurements in
[§6.7](#67-isolates-and-parsing-off-the-ui-thread):

- **A warm pool, not a fresh spawn per call.** A spawn costs 0.134–0.162 ms
  (not the 1–10 ms of folklore), but `Isolate.run` adds ~2.1 ms per call
  against a warm pool's ~0.5 ms — and a keystroke's whole budget is ~0.5 ms,
  so `Isolate.run` on the hot path would cost more than the work.
- **Return with `Isolate.exit`.** For a 32 MB payload built inside the worker,
  `Isolate.exit` costs 498 µs against 5 563 µs for a captured send — **11×**.
  The return path, not the send path, is where isolates are usually lost: a
  small `String` send is flat (12–24 µs from 1 KB to 32 MB) and `TypedData`
  copies at ~5.4 GB/s, while `TransferableTypedData` is *not* faster
  end-to-end (its win is peak memory).
- **One worker per open note, capped at 2** (the split pane's two panes),
  because each worker mirrors ~2 MB of text.
- **Fall back to the UI isolate below 64 KB** (today's `_syncParseLimit`), so a
  short note never pays a round trip that would dominate it.
- **The flat buffer is the point**: a typed-array parse result is ~4.4 MB for
  `Geometria 1.md` where the equivalent object graph is 20–40 MB — which is
  what makes the round trip cheap at all.

## 8.6 Inline rendering: change styles, not characters

This is the crux of doing WYSIWYG correctly on top of source truth, and the
place where the rejected `live_markdown_editor` and `markdown_editor_live`
both failed. It is also where the prior-art survey
([§7.10](#710-ideas-worth-stealing), idea 4) and this design initially
disagreed, so the fork is set out explicitly.

### 8.6.0 The two ways to hide a marker

| | **A — omit the marker from the text** | **B — keep the text, collapse the marker** |
|---|---|---|
| What the paragraph contains | the visible characters only, as a concatenation of source slices | the block's *entire* source text, every character |
| What hiding is | removal: the marker is not in the string | a **style**: a hidden run at zero size and transparent colour |
| Offsets | need a `toSource` map per block, visual↔source, plus a rule for insertions at a boundary | **1:1 — text offset == source offset, always** |
| The IME's text | the *visual* text; every delta must be mapped back | **the source text**; no mapping, deltas apply directly |
| Copy/paste | needs the map applied | free and byte-faithful |
| Selection, spellcheck, find, `getBoxesForSelection` | each needs the map | work on real offsets |
| Caret can rest inside a marker | no (it is not in the text) | **yes** — must be handled by the reveal policy |
| Prior art | — | CodeMirror's `Decoration.replace`, Obsidian live preview |

**Approach B is the design.** It is what every mature implementation actually
does, it makes the editing path *simpler* rather than harder, and it removes
the single most dangerous component of the original sketch (the `toSource`
map, risk K7, where a wrong entry silently writes the wrong bytes to disk).

The mechanism, in Flutter terms: the block's source text is built into a
`TextSpan` tree whose **content is always the source string**, and whose
*styles* carry the meaning:

```dart
// source: "some **bold** text"   with the caret away from this block
TextSpan(children: [
  TextSpan(text: 'some '),
  TextSpan(text: '**',   style: theme.hidden),   // fontSize: 0, transparent
  TextSpan(text: 'bold', style: theme.strong),
  TextSpan(text: '**',   style: theme.hidden),
  TextSpan(text: ' text'),
])
```

`theme.hidden` is a `TextStyle` with **exactly zero** font size and a
transparent colour — and "exactly" is measured, not assumed:
`test/unit/zero_size_run_test.dart` lays the paragraph out both ways and shows
that a run at 0 contributes no width, leaves the kerning either side untouched
and keeps the paragraph's height, while a run at **0.01 adds 0.04 px** and is
therefore not an option. Flutter does not document this, which is why it was
the design's first spike; the test is the settled half of it (the test font),
and the device pass is still owed ([§10.4](#104-what-to-spike-first-before-committing-to-the-plan),
spike 2).

Given a zero advance the markers occupy no width and the text visually closes
up — the whole point of WYSIWYG — while `TextPainter.text.toPlainText()` still
equals the block's source. The line height must come from the block's
`StrutStyle`, not from the hidden runs, or the zero-size metrics would collapse
the line box.

**What this buys, concretely:**

- **Typing at the end of a bold word does the right thing with no special
  rule.** `**bold|**` + `X` is `**boldX**`, because `|` is the real source
  offset between `d` and `*`. The boundary-insertion rule that approach A
  needs ([§8.6.1](#861-the-boundary-rule-that-approach-a-would-have-needed))
  does not exist here.
- **Backspace at the same place deletes the visible character**, not the
  marker, for the same reason.
- **The IME, the clipboard, find, spellcheck and selection all speak source
  offsets**, so nothing has to be translated, and the surface can report the
  source text as its `TextEditingValue` without shipping a lie to the
  platform.
- **Nothing can drift on save**, because the rendered string *is* the buffer.

**What it costs, and what must be spiked:**

1. **The caret can rest inside a hidden marker.** Two arrow presses walk
   through `**` invisibly. Two mechanisms fix it together, and both are
   needed:
   - **Atomic ranges for motion.** CodeMirror's answer — `atomicRanges` — is
     that a set of ranges behaves as **one unit** for cursor motion, so the
     caret cannot land inside; it moves across. In Flutter the same effect
     comes from intercepting the arrow/intent handlers and snapping a
     destination offset that falls inside a hidden run to that run's nearer
     edge. Outside the caret's block, a hidden marker is therefore skipped by
     one key press, which is what a writer expects from `**bold**` that reads
     as *bold*.
     Implemented: `SelectionModel.snap`
     (`lib/src/markdown/edit/selection_model.dart`) takes the runs
     `hiddenRangesOf` already reports for painting and snaps a destination in
     the direction of travel. Worth knowing before the keys are wired: only a
     marker **with an interior** can trap a caret. `**` and `~~` have one; a
     single backtick or `$` does not, so nothing ever snaps inside a code span —
     its text is walked one character at a time and its two markers occupy no
     width at all (`test/unit/selection_model_test.dart`).
   - **The reveal policy for editing** ([§8.6.2](#862-the-marker-reveal-policy)),
     because a marker the user *cannot* see is a marker the user cannot
     correct. Inside the caret's block the markers are visible — and
     therefore not hidden, hence not atomic — so editing them is ordinary
     text editing; everywhere else they are hidden and atomic.

   The two are complementary rather than alternatives: atomicity makes hidden
   text *navigable*, revealing makes it *editable*. `markdown_editor_live` was
   rejected precisely because it hid the markers and did neither.
2. **A zero-size run must really have zero advance — settled for the test
   font, owed for the platform fonts.** `test/unit/zero_size_run_test.dart`
   shows that at exactly 0 there is no width, no kerning disturbance and no
   height change, and that 0.01 is *not* zero (it adds 0.04 px over two
   16 px markers). What remains is the device pass — the same three checks
   against the real fonts of Android, Linux and Windows, including a fallback
   font and a bidi run ([§10.4](#104-what-to-spike-first-before-committing-to-the-plan),
   spike 2). If a platform fails it, the fallback is approach A for the
   *string* while keeping approach B's *policy*, and the `toSource` map comes
   back for emphasized spans only — which is why §8.6.1 is still in this
   document.
3. **Inline widgets cannot be collapsed by a style.** An image, a checkbox, an
   inline math box and a footnote marker are `WidgetSpan`/placeholder
   children; a placeholder has a size regardless of `fontSize`. So for those
   the source characters (`$x^2$`, `![alt](src)`, `[ ]`) must stay hidden at
   zero size **and** the widget placed immediately after them, which puts the
   box exactly where the source is. Two consequences to record honestly:
   - a block containing inline widgets needs a small **correction table**
     (the placeholder's width and text offset) so hit-testing and
     `getBoxesForSelection` are right around it — the residual of Flutter's
     limitation that a `WidgetSpan` is one code unit in the paragraph
     ([§6.9](#69-traps-and-known-flutter-pitfalls)). Measured, that correction
     turns out to be **arithmetic rather than geometric**: with the placeholder's
     dimensions supplied, `getOffsetForCaret` steps exactly the placeholder's
     width across it, so what the table carries is "this text offset is that
     source range", and what stays the surface's own job is measuring the child
     so those dimensions are right (`test/unit/caret_rectangle_test.dart`);
   - the correction table is *only* needed for blocks with inline widgets,
     which on `Geometria 1.md` means the math-heavy ones — so the widget path
     must be measured, not assumed.

### 8.6.1 The boundary rule that approach A would have needed

Kept here because it is the fallback if a platform's fonts fail spike 2, and
because it is the
subtlety that makes approach A expensive: with markers omitted from the
string, a collapsed caret at a visual boundary is ambiguous. Typing at the end
of `bold` in `some **bold** text` must produce `**boldX**`, not `**bold**X`.
The rule is: **a collapsed insertion at a span boundary resolves to the inside
of the span** — at `visualEnd` of an emphasis/link/code span, map the
insertion to `sourceEnd - markerLength`; at `visualStart`, to
`sourceStart + markerLength`. One rule, per span kind, table-tested. Under
approach B the rule simply does not exist.

### 8.6.2 The marker-reveal policy

Markers are hidden *except* where the writer is working. Three candidate
policies, to be validated with the user (this is a UX decision, not a technical
one):

| Policy | Reveals | Rebuilds per keystroke | Feel |
|---|---|---|---|
| **A — visual line** | the markers on the *row* the caret is on (computed from layout, so it follows wrapping) | the one block, once per row crossing | Closest to Obsidian/Typora: you always see the syntax you are editing, and nothing else. |
| B — block | the whole block's markers | the one block, once per block entry | Cheapest and most stable; but a long wrapped paragraph shows all its syntax while you are anywhere in it. |
| C — character | the marker the caret touches | up to one block per keystroke | Most "accurate", worst thrash and most distracting. |

**A is the decision (D9), with per-word as the refinement the user asked
for**: only the caret's line — or, where it reads better, only the word the
caret is in — temporarily becomes source. B stays as the fallback if
measurement shows the per-row work is visible. Note the cost either way: rebuilding one block is
one `InlineParser` pass over a few hundred characters plus one
`TextPainter.layout` — tens of microseconds — so even C is technically
affordable; the objection to C is human, not computational.

Two details that matter:

- **Revealing is a style change, not a content change.** Under approach B,
  changing the policy does not change the paragraph's string at all — it
  changes `theme.hidden` to a visible style on a run. That means the layout
  cache key is stable across caret movement, and there is no risk of the
  content and the caret's offsets disagreeing mid-edit. This is the practical
  payoff of approach B and the reason to prefer it beyond the IME story.
- **Order of operations.** An edit is applied to the source buffer first, then
  the block is re-styled and re-laid out. Never re-lay-out before applying the
  edit. This ordering bug is the classic way these designs break, and it should
  be stated in the code, not just here.

### 8.6.3 Source mode is the degenerate case

In `source` mode nothing is hidden: every run gets its visible style and the
whole machinery of blocks, height map, viewport, find, folding and spellcheck
runs unchanged. Source mode is therefore *faster* rather than *different*, and
it inherits every fix the other modes get. It is also, for the same reason,
the cheapest first milestone: it is `live` mode with `theme.hidden` unused.

## 8.7 Editing mechanics

### 8.7.1 IME and `DeltaTextInputClient`

The surface opens a `TextInputConnection` with `TextInputConfiguration(
enableDeltaModel: true, inputType: TextInputType.multiline, inputAction:
TextInputAction.newline)`. It then receives `TextEditingDelta`s
(`Insertion`/`Deletion`/`Replacement`/`NonTextUpdate`) instead of whole
`TextEditingValue`s, which is what keeps a keystroke O(change) at the platform
boundary too.

**The mapping problem does not exist under approach B**
([§8.6.0](#860-the-two-ways-to-hide-a-marker)): the rendered text *is* the
source text, so the `TextEditingValue` the surface reports is the buffer
itself and an incoming delta's range is already a source range. That is the
main reason the design hides markers with a *style* rather than by omitting
them — it removes the single most error-prone translation in the whole
surface, and with it the class of bug where a mapped range writes the wrong
bytes to disk.

**The API, as it actually is in Flutter 3.47.2** (read from the SDK at
`packages/flutter/lib/src/services/text_input.dart` and `text_editing_delta.dart`;
the framework source, not the docs, because the details decide the design):

- `mixin DeltaTextInputClient implements TextInputClient` exists
  (`text_input.dart:1518`) with `updateEditingValueWithDeltas(List<TextEditingDelta>)`.
- `TextEditingDeltaInsertion` / `Deletion` / `Replacement` / `NonTextUpdate`
  exist (`text_editing_delta.dart:299/359/412/476`).
- `TextInputConnection` exposes `setEditingState`, `setEditableSizeAndTransform`,
  `setComposingRect`, `setCaretRect`, `setSelectionRects`, `updateStyle`,
  `updateConfig`, `show`/`hide`. **There is no `setComposingRegion`** — the
  composing range travels inside `TextEditingValue`, so it can only be sent
  through `setEditingState`.
- With `enableDeltaModel: false` but `DeltaTextInputClient` implemented, updates
  arrive through the whole-`TextEditingValue` channel instead. That is a
  graceful fallback, and the client must handle both paths.

Practically:

- **The echo must be suppressed deliberately.** `EditableText` calls
  `_updateRemoteEditingValueIfNeeded()` on *every* value change, and that calls
  `setEditingState(localValue)` with the **entire text** whenever the local value
  differs from `_lastKnownRemoteTextEditingValue` (`editable_text.dart:4016`).
  So the framework's own text field sends the whole document back to the platform
  on every keystroke. On a 934 KB note that is untenable, and the surface must
  therefore track what it has already told the platform and send
  `setEditingState` only when the platform's copy is genuinely stale — the
  composing range and the selection being the two things that legitimately need
  it.
- **Composition** (`TextRange.composing`) is preserved and mapped like any other
  range. Note the consequence of the point above: a composing-only change still
  requires a full `setEditingState`, so it should be coalesced to at most one per
  frame rather than one per character.
- **The delta model is scarcely exercised by the framework.** Grepping this SDK:
  nothing under `packages/flutter/lib/` sets `enableDeltaModel: true`, and
  `EditableText` does not implement `DeltaTextInputClient` — only the two
  `services` files reference it. The API is therefore not on the path that
  Flutter's own widgets test in anger, and its platform-side behaviour
  (especially Android's `InputConnection` deltas and OEM IMEs) must be
  established by device testing, not by reading. **This is a reason to spike it
  first (spike 2, §10.4), and a reason to keep the whole-value fallback working
  as a first-class path rather than as an afterthought.**
- **Android specifics to verify on a device**: Gboard's word-composing
  behaviour, `getTextBeforeCursor` limits, autocorrect replacements arriving as
  full-value updates, and the keyboard dismissing when the connection closes
  because the pane became read-only (`_dismissKeyboardForPreview`).

### 8.7.2 Caret and selection are document-global

`SelectionModel` holds `TextSelection(baseOffset, extentOffset)` in **source
offsets**. Moving by character/word/line is executed in *visual* space of the
block that holds the caret and translated back, so the caret never lands
inside a hidden marker. A selection spanning blocks is just a wider source
range; each visible block paints the intersection of its own source span with
the selection, via `TextPainter.getBoxesForSelection` on the block's visual
text — 1:1 with the source under approach B, with a small correction table for
blocks that contain inline widgets (§8.6.0, point 3).

Painting order per frame: text → selection rects → search-match rects →
spellcheck squiggles → decorations (bullets, checkboxes, bars, rules) → caret →
IME composing underline. All of it inside the block's `RepaintBoundary`, so
a caret blink repaints one block, not the viewport.

The caret's own geometry comes from the same laid-out `TextPainter` that painted
the line — `getOffsetForCaret(position, prototype)` for where it starts and
`getFullHeightForCaret` for how tall it is (§6.3,
`painting/text_painter.dart:1447`, `:1496`) — never from line metrics the
surface computes for itself. That is the distinction a first attempt at this
surface got wrong: it had its own `row_text_metrics.dart`, and the caret's
*rendered* position is what it was replaced over (`12d9f4a`; Phase 3's exit
criteria and §10.4's spike 2 carry it as a criterion now).

`test/unit/caret_rectangle_test.dart` measures the three things the call leaves
to the caller, and two of them are not what they look like. (An earlier draft of
this section guessed at the first and got it backwards; the measurement is the
correction.)

- **The prototype's height is inert.** `getFullHeightForCaret` answers with the
  line's own full height — 19.2 px for a 16 px strut at height 1.2 — for a
  zero-height prototype, a 20 px one and a 100 px one alike, and
  `getOffsetForCaret` does not move either. The parameter is documented as
  supplying the caret's height; deriving the caret's height from a box the
  surface keeps is therefore wrong in both directions.
- **The prototype's width is not inert, and only on the right-to-left side.** A
  caret before an RTL character is drawn on that character's right, so the
  returned top-left is the character's edge minus the caret's own width: 48 →
  46.5 → 45 → 38 for prototype widths 0, 1.5, 3 and 10, while an LTR run answers
  the same x for all four. The returned `Offset` does **not** say which side to
  draw on — that is the caller's problem, which is §6.9's warning measured
  instead of cited.
- **An empty block has no line metrics.** `computeLineMetrics()` is empty on an
  empty paragraph, and the caret still has its full height: nothing may index
  the first line metric, and every note ends with an empty paragraph.

A block holding an inline widget no longer looks like a geometric problem. With
the placeholder's dimensions supplied, `getOffsetForCaret` steps exactly the
placeholder's width across it (`see $x^2$ here` is 14 source units and 10 in the
paragraph, and the caret moves the 40 px box). What the correction table below
has to carry is the **arithmetic** — one code unit stands for a source range —
while measuring the child so those dimensions are right stays the surface's job.

The model is `lib/src/markdown/edit/selection_model.dart`: source offsets, the
two ends and how they normalize, and the atomic motion above. The arithmetic
around a drawn span is `lib/src/markdown/edit/placeholder_map.dart` — the
identity for every block of `source` mode, and the table only for blocks with a
formula, an image or a checkbox drawn in them. The seam itself is
`lib/src/markdown/edit/caret_geometry.dart`: given a block's laid-out painter and
the document's selection, it answers the caret's rectangle, a selection's boxes
and the offset a tap lands on — every one of them asked of the painter, none
computed from metrics it keeps.

Two things its tests hold it to, both measured rather than reasoned:

- **Which mode hides what decides whether anything snaps.** `source` mode's
  render map is the identity, so its markers are ordinary characters, every
  offset has its own place on screen, and no tap is ever moved. It is the modes
  that hide a marker *by style* whose interior positions collapse to one place,
  and there a tap leaves through the same rule the arrow keys use
  (`test/unit/caret_geometry_test.dart`);
- **the advance a caret steps by and the height it is drawn at are two different
  numbers** — 19 and 19.2 for a 16 px strut at height 1.2. A surface that treats
  them as one drifts by the difference on every line.

### 8.7.3 Undo is a stack of source splices

Today undo lives inside `re_editor` and inside `flutter_quill`, which is why
"undo moves with a tab" is a thing the shell has to arrange. The replacement
owns it:

```dart
final class EditRecord {
  final int offset, removedLength, insertedLength;
  final String removed, inserted;
  final TextSelection selectionBefore, selectionAfter;
  final int revisionBefore, revisionAfter;
}
```

Grouping: consecutive typing within a pause (the same 500 ms the save path
already uses) and consecutive single-character deletions coalesce into one
record. A formatting command, a find-replace-all, a tidy or a list-tally edit
is its own record (and may itself be a *batch* of records applied
atomically). The stack is plain data, so it travels with a tab between panes,
survives a rebuild, and is trivially unit-testable — none of which is true of
the two current stacks.

### 8.7.4 Clipboard

With source-as-document, **copy is `buffer.substring(selection)`** — the same
Markdown from every mode, which is exactly what `docs/user/editing.md`
promises and what took `wysiwyg_clipboard.dart` (190 lines) + Quill's Delta
conversion to approximate. Pasting:

- `text/plain` containing Markdown → a source splice (the parse catches up).
- `text/html` → an **own minimal HTML→Markdown converter** (headings,
  paragraphs, emphasis, links, images, lists, blockquotes, code, tables),
  because the app promises that pasting a styled page arrives formatted.
  Today this rides `flutter_quill_delta_from_html`; it must be written
  ([§10](#10-effort-and-phasing)).
- An image file on the clipboard → the existing library image-import path.

`guarded_clipboard_service.dart`'s existing rule — the clipboard is never
trusted to be cheap and the app must not crash when it is not — is kept.

### 8.7.5 Find, replace, folding, outline, spellcheck, tally: document-level

Because the buffer and block index are mode-independent, these stop being
per-surface features:

- **Find/replace** walks the block index for matches (with the same
  case-sensitivity option), paints matches as decorations, and applies
  replace-one/replace-all as ordinary undoable splices. One implementation
  replaces `find_panel.dart` + `CodeFindController` + `wysiwyg_find_controller.dart`
  + `wysiwyg_find_panel.dart`.
- **Folding** stays what it already is — "the layout skips these line ranges"
  — and now applies in read mode too, which the preview cannot do today.
- **Outline and word count** come from the block scan. Today they are O(bytes)
  because the outline rides a *full-document highlight*: measured at 38–40 ms
  off-thread on a desktop, and recorded at ~1.1 s on a phone (`preview_work.dart`).
  With the line-state machine the heading scan is a by-product of the block
  scan and the word count a by-product of the inline phase for blocks that
  have been rendered, with a lazy background pass for the exact total. **The
  change is from O(bytes) to O(changed) — ~40 ms to ~1 ms on desktop, and the
  ~1.1 s device stall to well under a frame.**
- **Spellcheck**: `EditorSpellCheck.rangesFor(line)` is already line-based and
  returns `TextRange`s in line coordinates, which under approach B are the
  same coordinates the paragraph uses — so the underline rects come straight
  out of `getBoxesForSelection` with no mapping at all. Android's system spellcheck comes from
  the IME reporting to the platform, and the underlines are drawn by us either
  way — the same `rangesFor` path.
- **List tally**: one implementation over the block index (replacing
  `list_tally*` + `quill_tally.dart`), with the "keeps its place / greyed with
  the reason" rule intact.

### 8.7.6 Everything the shell already relies on

| Today | Replacement |
|---|---|
| `onIndicator: CodeIndicatorValueNotifier` (which rows are laid out) | `MarkdownSurfaceController.visibleRows` / a `ValueListenable<List<VisibleRow>>` with the same meaning |
| `scrollController`/`scrollOffset` per surface | one `ScrollController` owned by the controller |
| two-way scroll sync between editor and preview | **Deleted (D4).** With the split preview rejected the sync has no counterpart to talk to; `ScrollMap` survives only *inside* the surface as `HeightMap`, and `scroll_sync.dart`, `editor_lines.dart` and the `onIndicator` contract go with it |
| `activeItems` (toolbar pressed state) | `MarkdownSurfaceController.activeFormats`, computed from the inline spans at the caret |
| `formatMenu`, `editor_context_menu` | one context-menu builder over `activeFormats` + the same toolbar item list |
| `md_editing` / `quill_editor_commands` | one `MarkdownCommand` set operating on source splices |
| `initialCaretOffset` (template `{{cursor}}`) | `MarkdownSurfaceController.revealOffset(offset)` then focus |
| Zen mode's caret width, line numbers, column, typewriter | presentation parameters of the same widget |

### 8.7.7 The export seam

Export will be required (D12), and it is the one requirement that a
viewport-shaped renderer cannot grow later: a print or PDF pass needs the
**whole** note laid out at an arbitrary width, off-screen, with no scroll
position and no laziness. Three consequences, all cheap now and expensive
afterwards:

1. **Layout is a pure function of (block, width, theme)** — no dependence on
   the viewport, the scroll offset or the widget tree. That is already how the
   block layer is described ([§8.4](#84-layout-only-the-blocks-the-viewport-shows));
   export is what makes it non-negotiable, and it is what a test can assert.
2. **The painter takes a target**, not a `Canvas` it found in a
   `BuildContext`: `paintBlock(Canvas, Offset, width)` and a driver that walks
   the `HeightMap` in order, so the same code serves the viewport and a
   `PictureRecorder`.
3. **A "layout everything" path exists and is allowed to be slow** — the
   eager mode measured at 552 ms for the geometry note
   ([§8.4](#84-layout-only-the-blocks-the-viewport-shows)) is a perfectly good
   export cost, and having it as an explicit mode is what stops the viewport's
   laziness from becoming an accidental API.

Page breaking, headers and margins are *not* designed here — only the seam
that makes them possible without rewriting the renderer.

## 8.8 The two specialised renderers

### 8.8.1 Math: own TeX layout

Geometry is the app's worst real note (13 845 math spans; §5.4) and the
current pipeline costs 5–6 ms per block, mitigated only by *not rendering during a
scroll* (`MathDeferScope`) — a workaround that trades a stutter for a pop-in.

The measurement sharpens the diagnosis, and it is worth stating precisely
because it changes what has to be built: **the incumbent's per-expression math
render is already fast** — 0.077–0.109 ms warm, 0.007 ms on a cache hit
(§9.3) — and the 5–6 ms per block is simply *tens of inline formulas in one
paragraph*, each correctly rendered. So the problem is not the typesetter's
constant factor; it is that a geometry note has 13 845 spans and the design
lays out every block it does not defer, re-typesetting on every revision
instead of trusting the cache. **The fix is the cache plus the viewport, not a
faster formula.** A new typesetter that is 2× faster but still re-renders
everything would reproduce the stutter exactly. The typesetter is being
replaced for the package-dependency reason (R6), and it must not regress the
per-expression numbers while the viewport discipline is added around it.

The replacement is an own TeX layout engine, in four stages, all pure Dart:

1. **Tokenize + expand** (small macro set: `\newcommand`, `\renewcommand`,
   `\def` with a small parameter form, `\text`, `\operatorname`, `\color`).
2. **Parse to a math list** of atoms carrying their class — `Ord`, `Op`,
   `Bin`, `Rel`, `Punct`, `Inner`, `Open`, `Close`, `Over`, `Under`, `Accent` —
   which is what decides the whitespace around them.
3. **Lay out boxes.** A box is `(width, height, depth, children)`; the
   essential constructors are `makeOrd`/`makeAtom` (glyph run + class),
   `makeVList` (fractions, limits, scripts, stacks, roots, accents) and
   `makeStack` for `\over`. Inter-atom spacing is a **table by atom-class
   pair** (`thinspace` 3/18 em, `mediumspace` 4/18, `thickspace` 5/18,
   `negthinspace`), which is the single detail that makes hand-rolled math look
   wrong when it is omitted.
4. **Draw.** Each glyph run is a `TextPainter` positioned by a
   `CustomPainter`, rules are `drawRect`, and stretchy delimiters are built by
   hand. **That last part is not optional and not a detail**: Flutter cannot do
   OpenType MATH glyph assembly. A grep of the engine's text stack for
   `MATH`/`GlyphAssembly` returns nothing, and `Paragraph` exposes no glyph
   coverage or size-variant API
   ([§6.5](#65-math-rendering-without-a-package)). So `\left( … \right)`,
   radicals, `\overbrace` and friends must be assembled from discrete
   size-variant fonts (Size1–4, ~41 KB measured), from the U+239B..U+23AD
   bracket-piece range, or from authored `ui.Path`s. Related and also verified:
   **math layout is provably two-pass** (TeX's `make_left_right`,
   `tex.web:15016-15030`), so the measure-then-place API in
   [§6.5.6](#656-is-a-two-pass-measure-then-place-layout-required) is required, not a
   convenience.

   Two premises worth correcting while here, because they would otherwise
   mislead an implementer: `katex`/`katex_dart` are **not** WebView-based (that
   is `flutter_tex` and friends) — `katex` 1.0.0 is a `CustomPainter` +
   `TextPainter` glyph cache + `drawRect`/`drawPath`, which is exactly the
   shape this design wants; and **`flutter_math_fork` — a transitive
   dependency today — must not be adopted**: it emits one `RichText` per
   character plus a `SvgPicture` per stretched radical, bundles 20 KaTeX fonts
   (660 KB) none of which has a MATH table, and its open issue #120 throws on
   infinite constraints with `\frac`/`\sqrt` inside a `ListView`, which is
   precisely the long-note configuration.

Caching is two-level and is what takes 5–6 ms/block to near zero on re-render:
a **parse cache** keyed by the TeX string (produces the atom list) and a
**layout cache** keyed by `(tex, fontSize, textScaler, color, availableWidth)`
(produces the box). Only visible blocks ever compute a miss. `math_cache.dart`
already has the right idea (a per-preview cache, a synchronous renderer for
tests) and should be ported rather than rewritten.

**Fonts: bundle them, never name them.** This was resolved with evidence in
[§6.5.7](#657-math-fonts-availability-licensing-bundling), and the answer is
not the intuitive one:

- **Android ships no math font at any API level.** Verified against AOSP
  8/9/11/12/13/14 and `main`: zero `math` matches in `fonts.xml`, no
  `notosansmath` directory, nothing in `Android.bp`/`fonts.mk`. Only ten
  name-addressable families exist there, so `fontFamily: 'NotoSansMath'` is a
  **silent no-op**, not a fallback. Windows has Cambria Math only (the math
  face is index 1 of `Cambria.ttc`) and no STIX; Linux depends on the distro
  — a Debian desktop pulls in no math font at all.
- **Keep the 20 KaTeX TTFs (544 KB, OFL) that `katex`/`katex_dart` already
  vendor-bundle.** Dropping the packages must not drop the fonts, or the same
  note changes appearance on first launch. Add **STIX Two Math** (818.9 KB,
  OFL) for coverage rather than a ~1 MB TTF or Noto Sans Math (991.6 KB).
- **`dart:ui` has no glyph-outline API**, so surds, arrows and other built
  deliverables must be authored `ui.Path`s — you cannot extract outlines from
  a font at runtime. This is why `\sqrt` and stretchy delimiters are hand-built
  ([§6.5.4](#654-stretchy-delimiters-and-fraction-bars--the-concrete-recipe)).
- **Missing glyphs are not reliably observable**: Skia *has*
  `Paragraph::unresolvedGlyphs()`, but no native embedder surfaces it, so in
  `flutter test` tofu is deterministic while on a device it may be silently
  rescued by another font — meaning **a green widget test proves nothing about
  device coverage**. The answer is a build-time `fontTools` coverage manifest
  asserted in CI, plus a zero-width terminal fallback so uncovered text
  vanishes rather than showing a box.

The **highest-leverage idea in the math design** comes from the same section:
a **glyph-metrics cache** keyed `(rune, family, variant, quantizedPx) →
(advance, height, depth, italic, skew)` in em. Measure each *distinct* glyph
once and the whole layout becomes double arithmetic — `O(distinct glyphs)`
shaping calls for the entire geometry note regardless of expression count.
Two details that decide whether it works: **quantize the em size to a 1/64-px
grid** (double equality destroys caches) and **never put the colour in the
layout key** (colour belongs to paint, not layout). The parse cache has a
matching trap: its key must include a macro-environment id bumped by
`\newcommand`, or it serves formulas parsed under stale macro meanings.

Conformance: the current `katex`/`katex_dart` pair is a KaTeX port with a
`BoxNode` model. Their removal is a *behavioural* cliff, not just a
dependency one: whatever the geometry note uses today must keep rendering.
[§5.4](#54-math-deep-dive) turns that into an explicit, measured acceptance
criterion, and it is unusually cheap to state because the corpus is so
concentrated: **95 % of `Geometria 1.md`'s 13 845 expressions need 58 TeX
commands and 5 environments; 99 % need 86 commands.** The five environments are
`pmatrix` (1 120 uses), `cases` (114), `aligned` (103), `vmatrix` (45) and
`array` (7). Other measured requirements: brace depth never exceeds 3; 882
expressions use `\\` and 507 use `&`, so row/column layout is not optional; the
largest single expression is 1 094 bytes (an `aligned` + `vmatrix` block); 135
commands are used in total, 129 of them alphabetic. KaTeX upstream defines
648 symbols and 336 macros (~985 entries), so the symbol table is a lookup
table to port, not a language to write; the real cost is glyph coverage and the
per-symbol metrics. **One command to refuse explicitly: `\mathchoice`**, which
needs all four styles resolved at layout time; `flutter_math_fork` refuses it
too. **The golden-file test is the gate**: render every distinct expression in
the corpus with `katex_dart` today, freeze the boxes, render them again with
the new typesetter, and diff — which also produces the exact command list to
implement instead of a guess at it.

Two constants that a spec would otherwise copy wrongly, both corrected by
measurement ([§6.5.5](#655-tex-constants-to-hardcode-katex-tables-cross-checked-against-tftopl-and-texweb)):
**`1mu` is not `1/18 em`** — it is `quad(style)/18`, where `quad` is
1.000/1.171/1.472 for text/script/scriptscript, so a hardcoded `/18` makes
script-level spacing about 17 % too wide; and the `sup1/sup2/sup3` shifts are
0.412892/0.362892/0.288889 (tftopl-measured), not the round 0.413/0.363/0.289.
KaTeX also uses *thick* (5mu) spacing for punct→rel where real TeX uses *thin*
(3mu) — a divergence to match or not, deliberately.

**What the read view draws for a display formula, measured against the preview
(#252).** A device report — the formulas of `Geometria 1.md`, "me li aspetterei
centrati orizzontalmente" — is a rendering bug no gate in this phase could see:
the comparison reads `toPlainText()` (§8.4.4), and a formula's position is not a
word. A probe that rendered one `$$…$$` block in a 600-pixel pane and printed the
geometry of its `BlockMathView` found the box was **568 px wide** — the whole
column — with the formula painted at x = 16, the left page margin. Two constants
explain it, and both are load-bearing. A sliver lays a block out on the cross axis
with a *tight* width, so `BlockMathView`'s `SizedBox.fromSize` (77.3 × 17.1 for
`x^2 + y^2 = z^2` at 15 px) is `constrain`ed to the column instead of keeping its
own size; and `KatexBoxPainter` always starts its ink at the canvas origin whatever
size it is handed, so the extra width is empty space to the right of the formula
rather than a centred one. The preview has wrapped its display box in `Center`
since the package path (`MathBlockBuilder`, "centered, as its own block widget");
the read view passed its constraints straight through. One `Center` in
`BlockView._blockMath` gives the view its own width back — the box measures 77.3 px
and sits centred at 300 — and `MarkdownExportView`, which stretches its column the
same way, inherits the fix.

The test states the property rather than the number: the box is **typeset**
(`cache.boxFor(tex, displayMode: true) != null` — the pending placeholder is
centred too, and a weaker assertion would have passed on the ellipsis, which is
exactly how `display math renders inside a list` passed while asserting only that
the tex was nowhere on screen), narrower than the column, and centred
(`test/widget/markdown_read_view_test.dart`).

### 8.8.2 Code: a line-state lexer, not a whole-block regex

`preview/code_highlight.dart` uses the pure-Dart `highlight` package, which
runs a regex grammar over the **entire** block on every render, and
`re_highlight` (its Flutter sibling) comes in with Quill. Neither supports
incremental re-lexing, so a 500-line code block re-highlights in full on any
change near it.

The measurements in [§6.6](#66-syntax-highlighting-without-a-package) make
this worse than "not incremental", and one of them is a robustness bug rather
than a performance one:

| Finding | Number |
|---|---|
| `highlight` 0.7.0 lexing a 200 KB block | 57.9 ms (dart), 128 ms (python) |
| … a 934 KB block | 415 ms, **+29.5 MB RSS** |
| `Result.toHtml()` on a 100 KB block | **6 868.8 ms** — super-quadratic (`str +=` and three `replaceAll(RegExp)` *per node*) |
| The `cpp` grammar on `'a' * n + '!'` | **O(n²)**: 8 KB → 1 854 ms |
| Regex timeouts in Dart | **none** — `dart-lang/sdk#61284` closed as intended |
| `autoDetection` | ~39 ms/KB (≈ 188 full passes) |

The last two rows are the ones to keep: **a user can paste a note that hangs
the app, and there is no timeout to save it.** Two defences, both required:
the own line-state lexer bound by the visible/changed lines, and a **guard on
the input**: a single line beyond a length threshold, or a token run beyond a
threshold, is rendered plain rather than lexed. The same guard should cover
the Markdown parser's own pathological cases (the spec suite's
`pathological_tests.py` is the list to adopt). The performance argument for
replacing the lexer is strong; the robustness argument is decisive.

**The decision, since the user deferred it (D14): keep `highlight`
entirely as the lexer; replace only how it is used, and let a number decide
whether it is enough.** The package's language modules are declarative `Mode`
trees (190 of them, zero raw `RegExp`, compiled centrally) — weeks of grunt
work to reproduce for no user-visible gain, and the geometry note has *zero*
code fences, so code colouring is not the hot path on the real worst note. What
must not survive is the usage: `parse()` over a whole block and then
`toHtml()` is super-quadratic (100 KB → 6 869 ms), `autoDetection` is
~39 ms/KB, and the grammars have **no regex timeout**, so a pasted note can
hang the app (K13).

So the rules are:

1. **Lex the visible or changed block only**, cached by
   `(block revision, language)`. Never the document.
2. **Build spans from the token stream**; `toHtml()` is never called.
3. **Never `autoDetection`**: the fence's info string names the language, or
   the block is plain.
4. **Cap the input, unconditionally.** A block past N bytes or N lines, or a
   line past M chars, renders plain. The cap exists because there is no
   timeout to fall back on, so the cap *is* the timeout.
5. **The decision point is a number, not a preference**: the keystroke budget
   inside the adversarial fixture's 2 000-line fence — **≤ 1 ms**
   ([§9.2](#92-the-budget-by-operation)). If `highlight` meets it, there is
   nothing left to write. If it does not, the fallback is line-state lexers
   for the top ~15 languages with `highlight` demoted to the long tail — a
   swap confined to the one interface below, which is why that interface is
   specified even though its second implementation may never exist.

The interface that both satisfy — a CodeMirror-style stream lexer — is:

```dart
abstract class CodeLexer {
  CodeState startState();
  CodeState blankLine(CodeState state);
  String? token(CodeStringStream stream, CodeState state);
  CodeState copyState(CodeState state);   // states are immutable snapshots
}
```

One `CodeState` per line, stored in the same per-line cache as the block
state, so only changed lines re-lex and only visible lines are converted into
styled spans. Unknown languages get the fence's info string and no colour —
never an error. A language with no lexer is a *value*, so the set can grow
without touching the renderer.

## 8.9 What replaces what

| Deleted | Lines | Replaced by |
|---|---|---|
| `editor/note_editor.dart` + `re_editor` | 518 | `MarkdownSurface` (source mode) |
| `editor/wysiwyg/*` + `flutter_quill` | 2 521 | `MarkdownSurface` (live mode) |
| `preview/*` + `flutter_markdown_plus` + `markdown` | 3 374 | `MarkdownSurface` (read mode) + own parser/renderer |
| `editor/highlighting.dart`, `highlight_sync.dart` | 1 217 | **ported** into `BlockScanner` + `InlineParser` + `MarkdownTheme` |
| `editor/find_panel.dart` + the WYSIWYG find pair | 664 | one find bar over the block index |
| `editor/list_tally*` + `quill_tally.dart` | 719 | one tally over the block index |
| `editor/editor_context_menu.dart` + Quill's menu | 241 | one context menu |
| `editor/md_editing.dart` + `quill_editor_commands.dart` | 539 | one `MarkdownCommand` set |
| `preview/scroll_map.dart` + `scroll_sync.dart` + `editor_lines.dart` | 966 | `scroll_map.dart` **ported** into `HeightMap`; `scroll_sync.dart` and `editor_lines.dart` (429 of the 966 lines) **deleted**, because D4 rejects the split preview they existed to keep in step |
| `preview/math_*` + `katex` + `katex_dart` | 731 | own `TexParser` + `TexBox` layout + `TexPainter` |
| New code | ~ | `SourceBuffer`, `BlockScanner`, `BlockIndex`, `InlineParser`, `RenderedBlock`, `HeightMap`, `MarkdownSurface`, `MarkdownSurfaceController`, `MarkdownTheme`, `Tex*`, `CodeLexer` |

Net effect on the dependency graph: the seven surface packages and the 55
packages reachable only through them leave the tree — including
`quill_native_bridge_*`, `sqflite*`, `flutter_svg`/`vector_graphics*`,
`cached_network_image`/`flutter_cache_manager`, `provider`,
`flutter_colorpicker`, `html`/`csslib`, `isolate_manager`/`isolate_contactor`,
`rxdart`, `flutter_math_fork` and `diff_match_patch`.

## 8.10 How each requirement is met, concretely

| Requirement | Mechanism |
|---|---|
| R1 one widget | `MarkdownSurface` + `MarkdownSurfaceMode`; the preview is the same widget in `read` **mode**, not a pane (D4). |
| R2 uniform functionality | Every capability reads the buffer and the block index, which are mode-independent; `MarkdownSurfaceController` is the single API the shell talks to. |
| R3 uniform performance | One viewport/height-map/inline-cache path; no mode has a size cap; source mode is a strict simplification of it. |
| R4 uniform visual rendering | `MarkdownTheme` + `MarkdownMetrics`, one per construct, applied by the surface itself. |
| R5 syntax | Own CommonMark+GFM parser + the app's extensions, developed against `spec.json`. |
| R6 no UI packages | Own renderer, editor, viewport, typesetter. `markdown` and `highlight` stay as pure-Dart engines behind Niman's incremental driver (D2). |
| R7 pure Flutter/Dart | `dart:ui`, `flutter/widgets|rendering`, `dart:isolate`, `dart:typed_data`, asset fonts. No plugin, no FFI, no native code. |
| R8 speed on `Geometria 1.md` | Incremental block scan + lazy inline phase + viewport-only layout + Fenwick height map + two-level math cache + line-state code lexer, against the budget in [§9](#9-the-performance-budget). |

## 8.11 A sketch of the public API

```dart
enum MarkdownSurfaceMode { source, live, read }

final class MarkdownSurface extends StatefulWidget {
  const MarkdownSurface({
    required this.controller,
    this.mode = MarkdownSurfaceMode.live,
    this.focusNode,
    this.showLineNumbers = false,
    this.column = NoteColumn.off,
    this.spellCheck,
    this.formatMenu,
    this.typewriter = false,
    this.caretWidth,
    this.imageDirectory,
    this.linkSource,
    this.onChanged,
    this.onFollowLink,
    this.theme,
    super.key,
  });
}

final class MarkdownSurfaceController extends ChangeNotifier {
  SourceBuffer get buffer;
  MarkdownSurfaceMode get mode;

  // selection, all in source offsets
  TextSelection get selection;
  void setSelection(TextSelection selection);
  void replaceRange(TextRange range, String replacement, {bool user = true});

  // what the shell asks for today
  Set<ToolbarItem> get activeFormats;
  List<String> get plainTextLines;
  int get lineCount;
  int lineOfOffset(int offset);
  int offsetOfLine(int line);
  List<VisibleRow> get visibleRows;       // the onIndicator contract

  // navigation and geometry
  Future<void> revealOffset(int offset);
  double? pixelOfOffset(int offset);
  int? offsetOfPixel(double y);
  ScrollController get scroll;

  // document operations
  void undo(); void redo();
  MarkdownFindController get find;
  FoldState get folds;
  Outline get outline;
  // stats are incremental, so this is O(changed) where it used to be O(bytes)
  ValueListenable<NoteStats> get stats;
}
```

Engine types behind it, one per file, none over ~300 lines (the repo's
"no god classes" rule):

`SourceBuffer` · `SourceEdit` · `LineState` · `BlockScanner` · `BlockNode` ·
`BlockIndex` · `ParseWorker` · `ParseCommand` · `InlineParser` ·
`DelimiterStack` · `InlineSpan` · `RenderedBlock` · `BlockStyleRuns` ·
`BlockDecoration` · `HeightMap` · `VisibleRow` · `MarkdownTheme` ·
`MarkdownMetrics` · `MarkdownCommand` · `MarkdownFindController` ·
`TexTokenizer` · `TexParser` · `TexAtom` · `TexBox` · `TexLayout` ·
`TexCache` · `CodeLexer` · `CodeState` · `HtmlToMarkdown` ·
`MarkdownSurface` · `MarkdownSurfaceController` · `MarkdownContextMenu`.

Roughly 30 files of 150–300 lines each: ~6 000–8 000 lines of new code, of
which the parser is the largest single block ([§10](#10-effort-and-phasing)).


---

# 9. The performance budget

## 9.1 How to read a number in this project

The repo has been burned by absolute timings before:
[`editor-alternatives.md`](../../docs/dev/editor-alternatives.md) says so
explicitly — the M2 numbers are debug-mode, in the test harness, on one
Windows machine, inflated in absolute terms, and **only the ratios carry**.
The budget below therefore has two layers:

- **Targets** — absolute, expressed against the frame budget, to be asserted
  only on a dedicated measurement machine (or a device) in release/profile
  mode.
- **Gates** — ratios against the recorded baseline, which is what CI can
  enforce on machines nobody controls.

And it has two baselines to beat:

- **Legacy, per mode** — what the surface being replaced does today (measured
  for this document; the full report is
  [§13](#13-annex-the-incumbent-baseline-measured-in-full), summarised in
  [§9.3](#93-the-legacy-baseline-to-beat-measured)).
- **Legacy, per operation** — the numbers the app's own comments record:
  0.507 ms per mid-buffer keystroke at 200 KB, 44.7 µs per line of layout,
  14 ms / 378 ms block-vs-inline split on `Geometria 1.md`, 44 ms to read the
  note, ~0.4 ms to first frame, 5–6 ms per math block, and 38–40 ms (desktop)
  / ~1.1 s (device) for stats.

## 9.2 The budget, by operation

Frame budgets: **16.7 ms** at 60 Hz, **8.3 ms** at 120 Hz. A scroll or typing
interaction must stay inside one frame; anything that cannot must move to an
isolate or be deferred to a gesture boundary (the pattern `MathDeferScope`
already uses).

| Operation | Fixture | Target (release, desktop) | Hard ceiling | Where the work goes |
|---|---|---|---|---|
| Read the note from disk | `Geometria 1.md` | ≤ 50 ms | 100 ms | isolate (already 44 ms today) |
| Text → first visible frame content | `Geometria 1.md` | ≤ 60 ms | 120 ms | block scan off-thread; only viewport blocks laid out |
| First frame after mount | any | ≤ 16.7 ms | 16.7 ms | viewport only; no eager parse |
| Block scan, cold | `Geometria 1.md` | ≤ 20 ms | 40 ms | isolate (today 14 ms) |
| Block scan, incremental (1 line changed) | `Geometria 1.md` | ≤ 0.2 ms | 0.5 ms | UI isolate, O(change) |
| Inline parse, one visible block | any | ≤ 60 µs | 150 µs | lazy, memoized per block revision |
| **Keystroke, mid-buffer, total** | `fixture-200kb.md` | **≤ 0.5 ms** parse + ≤ 2 ms layout/paint | 8 ms | O(change): one line, one block |
| **Keystroke, mid-buffer, total** | `Geometria 1.md` | ≤ 2 ms | 8 ms | as above; math block cached |
| Keystroke inside a fenced code block | 2 000-line fence | ≤ 1 ms | 8 ms | **D14's decision point**: `highlight` driven per visible/changed block, or line-state lexers if this row fails |
| Scroll frame (60 Hz) | `Geometria 1.md` | ≤ 6 ms | 16.7 ms | paint visible blocks; no parse, no math miss |
| Scroll frame (120 Hz) | `Geometria 1.md` | ≤ 4 ms | 8.3 ms | as above, plus aggressive deferral |
| Jump to an arbitrary line (10 000th) | `Geometria 1.md` | ≤ 25 ms to content | 60 ms | `HeightMap` prefix sums; only landed blocks laid out |
| Scroll anchoring after an off-screen edit | any | 0 px drift | 0 px | anchor re-established post-layout |
| Layout of one visible block | any | ≤ 45 µs/line | 100 µs/line | one `TextPainter` per block (today's number) |
| Math: one expression, cache miss | any | ≤ 0.11 ms | 0.25 ms | the incumbent is 0.077–0.109 ms and **must not regress** — this is the row that stops "our typesetter is slower" from hiding behind the viewport win |
| Math: one expression, cache hit | any | ≤ 0.02 ms | 0.05 ms | the incumbent is 0.007 ms; two-level cache |
| Math: a visible block's first layout | `Geometria 1.md` | ≤ 3 ms | 8 ms | bounded by that block's own span count — the incumbent's 5–6 ms per block *is* this, and the fix is the viewport, not the formula |
| Math: during a scroll gesture | `Geometria 1.md` | 0 new typesets | ≤ 0.5 ms | deferred as today, but with the cache warm so the pop-in disappears |
| Stats (word count + outline) | `Geometria 1.md` | ≤ 10 ms incremental | 30 ms | block-scan by-product; today 38–40 ms off-thread and O(bytes) |
| Live mode open | `Geometria 1.md` | ≤ legacy preview open | ≤ 2× | **No size cap.** Today live mode refuses above 204 800 chars. |
| Search/find across the note | `Geometria 1.md` | ≤ 30 ms | 80 ms | block index walk, off-thread above a threshold |

The bar itself is D10, and it is deliberately asymmetric: **`source` must be
very fast — at least the legacy numbers, in every row — and `live`/`read` are
judged as close to `source` as they can get, not against each other.** Source
mode is the floor because it does no math layout and carries no hidden runs;
since it shares the whole pipeline, any win in the shared layers shows up there
first. Where a row below has no separate `live` figure, the `source` figure is
the target for both.

## 9.3 The legacy baseline to beat (measured)

The incumbent numbers were re-measured for this document, because
`editor-alternatives.md` records that the incumbent (`flutter_quill`) had
never been benched and that doing so "is the first thing the next evaluation
should do". Method: the repo's own harness shape — the fixture-loading and
`_firstFrame` helpers from
[`test/unit/m2_spike_benchmark_test.dart`](../../test/unit/m2_spike_benchmark_test.dart),
the same fixtures in `test/fixtures/markdown/`, and `Geometria 1.md` as the
real worst case; debug mode inside the test harness, best-of-N and median
reported.

Machine: Linux (CachyOS) x86_64, Intel i5-13400F (6c/12t), 32 GB RAM,
Flutter 3.47.2 / Dart 3.13.2, debug in `flutter test`. Best / median in ms;
n = 5 for keystrokes, n = 3 otherwise. Nothing timed out, crashed or OOM'd at
934 KB — "did not complete" is empty everywhere, which is itself a finding:
the incumbent's problem is not failure, it is *class*.

| Component | Fixture | First frame | Keystroke (best / median) | Class |
|---|---|---|---|---|
| Source editor (`re_editor` + tokenizer) | 206 241 chars | 15.9 ms | **0.296 / 0.319** | O(1) |
| Source editor | 513 423 chars | 12.6 ms | **0.277 / 0.357** | O(1) |
| Source editor | `Geometria 1.md` (931 042 ch) | 9.3 ms | **0.372 / 0.458** | O(1) |
| Source editor, keystroke + one paint frame | 200 KB | — | 3.712 / 5.500 | O(visible) |
| WYSIWYG codec decode only (Markdown→Delta) | 206 241 ch | — | 357.2 / 388.2 | O(blocks+nodes) |
| WYSIWYG codec decode only | 513 423 ch | — | **2 407.7 / 2 459.3** | O(blocks+nodes) |
| WYSIWYG codec decode only | `Geometria 1.md` | — | 1 024.6 / 1 047.9 | O(blocks+nodes) |
| WYSIWYG full first frame (the largest note it opens) | 204 800 ch | **2 214.9 ms** | 47.3 / 57.5 | O(bytes) |
| WYSIWYG mount over cap (decode paid, then refuses) | 513 423 ch | 2 741.2 ms | — | O(blocks+nodes) |
| WYSIWYG mount over cap (decode paid, then refuses) | `Geometria 1.md` | 1 178.4 ms | — | O(blocks+nodes) |
| WYSIWYG keystroke | 102 400 ch | — | 14.6 / 17.7 | O(bytes) |
| WYSIWYG emit after edit (encode fast-path) | 513 423 ch | — | 25.5 / 26.6 | O(bytes) |
| Preview first frame (skeletons) | any | 14.6–29.0 ms | — | O(visible) |
| Preview first visible content (the "blank wait", #58) | 200 KB / 500 KB / geo | **161 / 182 / 137 ms** | — | isolate round trip |
| Preview off-thread block parse (wall) | 500 KB | — | 64.0 / 72.7 | O(lines) |
| Preview scroll-to-middle landing frame | any | — | 34.2–70.8 | O(visible blocks) |
| Preview stats (word count + outline, off-thread) | `Geometria 1.md` | — | 38.0 / 40.4 | O(bytes) |
| Math render, cache miss | per expression | — | 0.077 / 0.109 | O(1)/expr |
| Math render, cache hit | per expression | — | **0.007** | O(1) |
| Math paint (`KatexBoxPainter`) | per expression | — | 0.192 | O(1)/expr |

Two corrections to the brief's own premises that the measurement produced, and
that the rest of this document uses:

1. **The WYSIWYG does not open any of the three fixtures.** The cap is
   `_maxWysiwygBytes = 200 * 1024 = 204 800` *chars* (`wysiwyg_editor.dart:93`),
   enforced only in `build()` at line 525 — so `initState` → `_open()` →
   `_codec.decode()` runs anyway, and the "too large" message costs 2 741 ms at
   500 KB and 1 178 ms at 934 KB. `fixture-200kb.md` is itself 206 241 chars,
   i.e. over the cap by 1 441. The cap protects Quill, not the codec. There is
   also no size guard in `NoteView._editorPane` (`note_view.dart:1137`).
2. **`Geometria 1.md` has 13 845 math spans, not 1 683.** The 1 682 `$$`
   lines are 841 display blocks; the rest are 13 004 inline `$…$` spans. The
   math cost that matters is therefore the *inline* one, and the tokenizer's
   cold cost on this note (455.2 ms, 0.489 µs/char) is **5.7× the per-byte cost
   of the 500 KB fixture** because of that density — a density term, not a size
   term.

The **complexity classification** is the part that matters most, and it is
what the new implementation must change:

| Component | Today's complexity (evidence) | Required |
|---|---|---|
| Source editor keystroke | **O(1)**: 0.296 → 0.277 → 0.372 ms while the document grows 4.5× | **keep O(1)** — this is the number to defend |
| Source editor cold tokenize | O(bytes × inline density): 21.3 → 43.8 → 455.2 ms | O(bytes) with the same density constant, *lazily*, so it never runs in one go |
| WYSIWYG keystroke | **O(bytes)**: 14.6 ms at 102 KB → 47.3 ms at 205 KB, ~50–160× the source editor | **O(visible)** |
| WYSIWYG open | O(blocks + inline nodes) through a lossy codec, 0.36 s → 2.46 s | **no codec exists at all** |
| Preview open | O(visible) for layout, O(lines) for the block phase, plus a 137–182 ms isolate wait | keep the window, make the block phase incremental and the wait shorter than a gesture |
| Preview scroll jump | 34–71 ms landing frame — **above one 16.7 ms budget** despite windowing | ≤ 25 ms, ideally inside a frame |
| Preview stats | O(bytes) off-thread, 38–40 ms desktop | **O(changed)** |
| Math | 0.077–0.109 ms per miss, 0.007 ms per hit — already fast; the problem is 13 845 spans and re-rendering | **O(visible misses)**, no regression per expression |

The contract in one line, taken from the benchmark: **edit at ≤ 0.5 ms per
keystroke on a 931 KB note, open every fixture with no codec round trip, and
make live-mode editing O(visible) — the incumbent's 14.6 ms at 102 KB, 47.3 ms
at 205 KB and 2.4 s decode at 500 KB are the numbers to beat.**

## 9.4 The benchmark harness the implementation must ship with

One file, following the repo's existing convention (prints, does not assert,
so it stays green on any machine):
`test/unit/markdown_surface_bench_test.dart`.

| Bench | What it does | What it prints |
|---|---|---|
| `coldOpen` | mount the surface on each fixture, time to first frame and to first *content* | ms, per fixture, per mode |
| `keystrokeMid` | one character inserted mid-document, best of 5 + median, per fixture, per mode | µs |
| `keystrokeTyping` | 60 consecutive characters at 8 char/s equivalent, report p50/p95 | µs |
| `scrollFrames` | synthetic 3-second scroll, report per-frame build+layout+paint | p50/p95/p99 ms, dropped-frame count |
| `jump` | jump to 10 %, 50 %, 90 % of the document | ms to content |
| `mathCold` | first render of every distinct expression in a corpus | µs/expression, total |
| `mathWarm` | re-layout of the same expressions at a different font size | µs/expression |
| `stats` | word count + outline over `Geometria 1.md` | ms |
| `memory` | RSS before/after open + 200 keystrokes + a full scroll | MB, and cache occupancy |

The bench fixtures are three, and all three are committable:

- the repo's own `test/fixtures/markdown/` set (1 KB → 1 MB), for comparability
  with every number already on record;
- a generated **math corpus** built from `Geometria 1.md`'s distinct
  expressions, so the math benches are stable without committing the note;
- the generated **adversarial fixture** ([§5.7](#57-a-synthetic-worst-note-spec-and-fixture)):
  1 482 533 bytes, 11 773 lines, 19 700 inline + 902 display math, list depth 7,
  quote depth 4, display math inside lists and quotes, a 12×41 table, a
  2 000-line fence and a 2 000-line paragraph, 5 real link reference
  definitions, 120 CRLF lines, a 5 372-byte line and a 351-character
  unbreakable token. Its generator is a deterministic, re-runnable script that
  belongs in the repo — `tool/gen_worst_note.dart` — so the fixture is
  reproducible rather than a 1.5 MB binary in git.

The adversarial fixture is the one that matters most, because the real note
exercises almost none of the spec ([§8.5.0](#850-what-the-corpus-does-and-does-not-exercise)):
without it, a 934 KB note proves only that math and layout are fast, and every
regression in code blocks, tables, links, entities, escapes and reference
definitions would be invisible.

## 9.5 Memory budget

| Item | Ceiling | Note |
|---|---|---|
| Source text (UTF-16) | 2 × file bytes | unavoidable |
| `SourceBuffer` index (Fenwick + line list) | ~8 bytes/line | 82 KB for 10 331 lines |
| `BlockIndex` | ~48 bytes/block | shares unchanged blocks across revisions |
| Per-line state + code states | ~24 bytes/line | 248 KB on the geometry note |
| Rendered-block cache | **bounded, LRU, ~200 blocks** | the viewport plus a cache extent; never "all blocks" |
| Math parse cache | bounded by distinct expressions, capped | geometry has 13 845 spans / far fewer distinct |
| Math layout cache | LRU by `(tex, size, width)`, ~200 entries | the incumbent's LRU is capacity 512 (`math_cache.dart:36`) |
| Isolate mirrors (max 2 workers) | 1 × source text each | so a 934 KB note costs ~2 MB extra while split |

Ceiling for the whole surface on `Geometria 1.md`: **≤ 6 × the source text
size**, i.e. ~6 MB for the note, with the caches bounded rather than growing
with the document. That bound is the reason the caches are LRU and keyed by
block: an unbounded "rendered document" cache is exactly how a 934 KB note
becomes a 300 MB process.

## 9.6 Regression gates

- **In CI**, on the benchmark's ratio form: the same bench is run on the same
  class of machine each time, and a change that makes the 200 KB keystroke
  more than **1.25×** slower than the recorded baseline fails. Absolute times
  are recorded in the log, never asserted.
- **At 120 Hz, filling the layout cache is more than one frame** (15.70 ms
  measured for viewport + one viewport of cache on each side, [§8.4](#84-layout-only-the-blocks-the-viewport-shows)).
  The cache must therefore be filled incrementally across frames, in the
  direction of travel; a gate that only runs at 60 Hz would not catch the
  difference.
- **On the branch**, the phase exit criteria in [§10.3](#103-the-stages) are
  the gate: a mode is not migrated until its numbers are at least as good as
  the legacy surface's on the same fixture, in the same harness.
- **Complexity gates** (these are the ones that matter): the keystroke cost
  must be *flat* from 200 KB to 934 KB; the scroll frame cost must be
  *independent of document length*; the stats cost must be independent of
  document length. A gate that only measures absolute time on one fixture
  would pass a design that is secretly O(n).
- **A published benchmark artifact**: the numbers table is committed into this
  document (§9.3) after each phase, with the machine and the command, so the
  next proposal starts from numbers rather than from an opinion — the same
  discipline `editor-alternatives.md` established.


---

# 10. Effort and phasing

## 10.1 The rule that shapes the plan

The app is at 0.0.8 and shipping on three platforms. The rewrite is therefore
planned as a **sequence of independently shippable stages**, each of which
leaves `main` green and the app usable, with the old surface kept behind a
switch until the new one is measurably better on the same fixture:

- **A mode is migrated only when its mode of the new widget beats the surface
  it replaces, on the same commands, in the same harness.** No mode is
  migrated on the strength of a design document.
- **The three old surfaces are deleted only after all three modes are
  migrated** — until then `re_editor`, `flutter_quill` and
  `flutter_markdown_plus` stay in the tree and the app stays shippable.
- **The dependency diet happens at the end**, in one commit per package
  family, only once nothing imports them.

## 10.2 What the decisions do to the effort

**D2 removed the largest workstream.** The parser is `markdown` 7.3.1's, so the
CommonMark/GFM grammar is no longer written here; Phase 1 becomes *measure and
close the gap* against the spec suite. That removes the parser rows — 29–54
days — and replaces them with 9–18 days of integration, harness and
gap-closing. The code-lexer row shrinks too, because `highlight` supplies the
language rules. Two rows are added by the other decisions: the export seam
(D12) and the removal of the split preview and its scroll sync (D4).

Sizes in developer-days, for one experienced Flutter/Dart engineer:

| Workstream | Days | Notes |
|---|---|---|
| `SourceBuffer` + `SourceEdit` + Fenwick index | 4–7 | Small, self-contained, fully testable. |
| `BlockScanner` + `BlockIndex` + incremental convergence | 6–10 | The "reparse until the state converges" rule needs careful tests (lazy continuation, fences, tables, HTML blocks). |
| **Parser integration into the engine + the 8 measured fixes** (`markdown` 7.3.1) | **3–6** | *Was 29–54 as "write CommonMark + GFM"; 6–12 before the measurement.* The harness is built and the gap is enumerated — [§4.9](#49-the-markdown-package-measured) — so what is left is wiring the package into the block scanner and fixing eight examples. |
| App extensions: masking + parsing (wikilink, math delimiters, frontmatter, tags, embeds) | 3–6 | Mask the ranges the package must not see, then parse them with `links/parser.dart`'s rule. |
| Isolate protocol + flat typed-array payloads | 4–6 | Warm pool, `Isolate.exit`, worker-mirror splices. |
| `RenderedBlock` + style runs + the inline-widget correction table | 8–12 | No offset map to get wrong (D9/§8.6.0); the risky part is the `WidgetSpan` geometry. |
| **Editing core: IME, caret, selection, hit-testing, handles** | **15–25** | **Highest-risk item in the project.** Device work on Android is mandatory. |
| Undo/redo over splices | 3–5 | Simple by construction. |
| Viewport / `HeightMap` / sliver | 6–10 | Includes the custom-`RenderSliver` escape hatch if needed. |
| `MarkdownTheme` + block rendering (headings, paragraphs, lists, quotes, code, tables, images, rules, checkboxes, callouts) | 15–25 | Where the visual quality actually comes from. |
| Math typesetter (tokenizer → atoms → box model → painter) + fonts | 15–30 | D8 fixes the target as today's rendering; the golden diff is the gate. |
| **Code-lexer driver over `highlight`'s grammars + input guards** | **4–8** | *Was 5–10 for writing the lexers.* D14: the grammars stay; the driver, the line cache and the guards are ours, and the 2 000-line fence decides whether that is enough. **If it is not, add 5–10** for line-state lexers on the top ~15 languages. |
| HTML→Markdown (clipboard) | 3–5 | Keeps a documented behaviour (D7). |
| Shell integration: find/replace, folding, outline, stats, tally, context menu, toolbar, per-tab state | 10–15 | Also where the duplicated per-surface code disappears. |
| Spellcheck underlines + dictionary integration | 2–3 | `EditorSpellCheck.rangesFor` is already line-based. |
| Accessibility (`Semantics` for a custom text surface) | 3–5 | Non-optional on Android and for desktop screen readers. |
| **Export seam: offscreen whole-note layout + painting** | **3–5** | New, D12. The seam only — page breaking and margins are not designed here. |
| **Removing the split preview: settings, UI, scroll sync, docs** | **2–4** | New, D4. Deletes 429 lines rather than generalizing them. |
| Migration glue, dual-path feature flag, test porting | 10–20 | 38 test files / 8 651 lines touch the old surfaces. |
| Docs (`docs/user/editing.md`, `docs/dev/architecture.md`, this document) | 2–3 | Required by `AGENTS.md` in the same PR. |
| **Total** | **~121–210** | ≈ **6–10 months** of one engineer's focused time (down from ~140–245, and now anchored by a measurement rather than an assumption). |

The arithmetic, stated plainly so it can be checked: the parser workstreams
were 29–54 days and are now 6–12, the lexers were 5–10 and are now 4–8, and the
two new rows add 5–9. So **D2 removed 23–42 days** — the largest single lever,
and smaller than it first looked because the two new requirements eat part of
it. The row-by-row low and high sums are 121 and 210.

**The levers that remain**, in order:

1. **Reducing `live` mode's reveal fidelity** from per-word (D9) to per-block:
   −10 to −20 days. It costs the thing the user actually asked for — an
   interactive preview that turns the caret's line back into source — so it is
   the lever of last resort, not the first.
2. **Keeping `highlight`'s grammars without the incremental driver**, i.e.
   lexing the visible block only and accepting a full re-lex on edit inside it:
   −4 to −8 days, and K13's guards become load-bearing rather than
   belt-and-braces.
3. **Dropping HTML paste**: −3 to −5 days. Contradicts D7.
4. **A narrower math subset**: −8 to −15 days. Contradicts D8, which fixes the
   target as what the app renders today.
5. **Deferring export**: −3 to −5 days now, and much more later — a
   viewport-shaped renderer cannot print. Contradicts D12.

## 10.3 The stages

Each stage ends in a commit series that leaves `main` green, and per
`AGENTS.md` each is followed by an APK and a Linux rebuild with the artifact
path reported.

### Phase 0 — Research and decision (this document)

**Deliverable:** this file, plus the decisions D1–D9 answered.

**Exit criteria:** the user has answered D1–D9; a GitHub issue exists for the
epic (there is none today — the closest open issues are #228 "WYSIWYG: tables
as tables", #45 "Performance & jank", #62 "Desktop performance & animation
audit", #72 "Markdown linter"), with this document linked.

### Phase 1 — The engine, no UI

**Who parses.** `markdown` 7.3.1 (D2). This phase does **not** write a
CommonMark parser; it *measures* the one that is already a dependency, closes
the gap the app actually needs, and builds the incremental machinery the
package does not have.

**Deliverable:** `lib/src/markdown/` — `SourceBuffer`, `BlockScanner`,
`BlockIndex`, the per-block bridge to `markdown`, the extension masking
(wikilinks, math, frontmatter, tags), `BlockStyleRuns`, plus the spec harness
(`tool/markdown_spec.dart`) that runs the suites through the package and
reports pass/fail per section. No widget, no shell change; the old surfaces
keep running.

**First task, before anything else:** run the harness against `markdown`
7.3.1 as it ships and **publish the number**. Until that exists, "conformance"
is an assumption; after it, it is a list.

**Exit criteria:**

- **CommonMark 0.31.2: 652/652 examples**, run from
  `https://spec.commonmark.org/0.31.2/spec.json`, asserted on normalized HTML
  and — for a subset — on raw HTML.
- **GFM: 677/677 examples from the published spec HTML**
  (`https://github.github.com/gfm/`), pinned by commit SHA. Note that
  cmark-gfm's `test/spec.txt` is *not* the same suite (672 examples, 12
  vs 7 divergent examples) and that **GFM serves no `spec.json`** (404); the
  examples must be extracted from the HTML once and checked in as a fixture.
- Any failure that is *accepted* goes in a checked-in allowlist of
  `spec/example-number` + a one-line reason, and **CI fails if an allowlisted
  example starts passing**, so the list cannot rot. Failures are triaged in
  three buckets, and each is a decision rather than a bug report: *fix*
  (the app needs it), *pin* (the package's documented or measured divergence,
  recorded with its reason), or *mask* (the extension zone — wikilinks, math,
  frontmatter — which the package never sees). The three GFM oddities already
  known are decided up front, not discovered: the GFM HTML comment rule (which
  keeps CommonMark 0.29's grammar while CommonMark 0.31.2 moved to WHATWG),
  GFM's strikethrough prose contradicting its own example (single `~there~`
  renders as `<del>`), and GFM's 8-vs-9 digit entity case.
- **Gaps are closed bottom-up**, in the order of [§4.8.1](#481-order-of-attack)
  (preliminaries → leaf blocks → HTML blocks → reference definitions →
  containers → inline scaffolding → **emphasis** → links/images → breaks →
  GFM extensions → Niman extensions), because an emphasis fix on top of a
  wrong character class is wasted work. Where the package is already correct —
  which the first task's number will show — nothing is touched.
- Test names are `spec/version/example @section` (e.g.
  `gfm/0.29-gfm/257 @4.6 HTML blocks`), so a failure names its `spec.txt`
  line range directly, whichever bucket it lands in.
- The app's own extensions have tests ported from `links/parser.dart`,
  `highlighting.dart` and `math_syntax.dart`, so the new parser is provably a
  superset of today's behaviour for this app. The extension zone is outside
  the conformance gate and has its own suite (frontmatter recognition range,
  math delimiters including the `$$`-before-`$` ordering trap, wikilink
  precedence and ambiguity rules).
- Incrementality is proven: a mid-buffer single-character edit re-tokenizes
  O(1) lines and O(1) blocks on `Geometria 1.md`; pasting 500 lines touches
  500.
- A `--bench` mode prints cold parse, incremental edit and inline-phase
  timings for each fixture, and the numbers are recorded in this document.
- The adversarial fixture generator (`tool/gen_worst_note.dart`) and its
  output are committed, and the parser is run against it — because the real
  note exercises none of code spans, code blocks, links, images, entities,
  escapes, hard breaks or link reference definitions
  ([§8.5.0](#850-what-the-corpus-does-and-does-not-exercise)), and neither does
  the spec suite test them *at 11 773 lines with depth-7 nesting*.

### Phase 2 — `read` mode replaces the preview

**Deliverable:** `MarkdownSurface(mode: read)` behind a flag
(`markdownSurfaceEngine: legacy|new` in the debug settings), used by
`_buildPreview`.

**Exit criteria:**

- A byte-identical render of every fixture (1 KB → 1 MB), of the adversarial
  fixture and of `Geometria 1.md` against the current preview, verified by a
  **golden-image test** per fixture and a structural diff of the rendered
  block tree.
- Time-to-first-frame, time-to-first-*content*, scroll-to-middle and jump
  timings all at least as good as
  [§9](#9-the-performance-budget)'s incumbent row; the O(bytes) stats pass is
  O(changed).
- **The export seam works** (D12): the same block painter renders the whole
  note into an offscreen `PictureRecorder` at an arbitrary width, and a test
  asserts it. This is the phase where it is cheap ([§8.7.7](#877-the-export-seam)).
- Code highlighting, tables, task lists, footnotes, images, embeds and
  wikilinks all render, with the existing widget tests for the preview ported.
- There is **no scroll sync to keep**, because D4 removes the split preview in
  this phase rather than generalizing it: `scroll_sync.dart`,
  `editor_lines.dart`, the `onIndicator` contract, the `previewEnabled` and
  split-ratio settings and their UI all go, and `docs/user/editing.md` is
  updated in the same commit.

### Phase 3 — `source` mode replaces `re_editor`

**Deliverable:** `MarkdownSurface(mode: source)` with the identity render map.
This is the phase where the **editing core** is built and de-risked.

**Exit criteria:**

- The 0.507 ms incremental-edit number is met or beaten on the same fixture
  and command; the tokenizer's 23.95 ms cold tokenize is met or beaten.
- IME works on: Android (Gboard and at least one other IME, including
  composition and autocorrect), Linux (fcitx/ibus is acceptable to mark as
  out-of-scope but must be recorded), Windows.
- **The caret is painted where the character is — and this is the criterion a
  previous attempt at this surface failed on.** The rectangle has to come from
  this surface's own layout, because `EditableText` will not compute it: it has
  to be right at the start and the end of a line, over a hidden zero-width run,
  after a wrap, on a line whose height just changed, in a bidi run, and under
  the phone's selection handles. It is a criterion of its own because a clean
  IME pass says nothing about where the caret was drawn — see the evidence
  under spike 2 in [§10.4](#104-what-to-spike-first-before-committing-to-the-plan).
- Selection, mouse drag, double/triple click, shift+arrows, word-wise motion,
  Home/End, PageUp/Down and the existing remappable shortcuts all work; the
  `shortcuts.md` list is the test plan.
- Undo/redo, clipboard and the modified-dot behaviour work, and the shell's
  tab-move-keeps-undo promise holds.
- The 38 surface test files that are not Quill-specific are ported and green.

### Phase 4 — `live` mode replaces `flutter_quill`

**Deliverable:** `MarkdownSurface(mode: live)` — approach B's style-based
hiding ([§8.6.0](#860-the-two-ways-to-hide-a-marker)), the inline-widget
correction table, and the reveal policy chosen in
[§8.6.2](#862-the-marker-reveal-policy).

**Exit criteria:**

- Typing at the end of bold/italic/code/link spans produces what a writer
  expects, per a table-driven test over every span kind — under approach B
  this is expected to pass *by construction*, and the test exists to prove the
  zero-size runs really do not shift the offsets.
- **The reveal is D9's**: on entry to a line — or to a word, the refinement
  the user asked for — that run's style flips from hidden to visible, and back
  when the caret leaves. Because the flip is a *style* change and not a text
  change, the block's text, its offsets and the layout cache stay valid; the
  measurable risk is only how often the block is re-laid out, so the criterion
  is a budget: the flip costs one block re-layout (≤ 3 ms, [§9.2](#92-the-budget-by-operation))
  and never fires more than once per caret row change.
- The revealed-marker policy is validated on a device at 200 KB and on
  `Geometria 1.md`, with no visible thrash, at per-line and at per-word
  granularity, so the refinement is a setting or a constant and not a rewrite.
- **The 200 KB cap is gone**: the geometry note opens and edits in live mode,
  which today it cannot.
- Formatting toolbar, context menu, `activeFormats`, tools, spells and the
  find bar behave identically to source mode — verified by running *the same*
  widget tests against both modes.

### Phase 5 — Delete the old world

**Deliverable:** `re_editor`, `flutter_quill`, `flutter_markdown_plus`,
`flutter_highlight`, `katex`, `katex_dart` and `flutter_smooth_markdown`
removed from `pubspec.yaml` (**`markdown` and `highlight` stay**, D2);
`lib/src/editor/`, `lib/src/preview/` and their tests deleted;
`docs/dev/editor-alternatives.md` superseded; `docs/user/editing.md`
(including the split preview's removal, D4) and `docs/dev/architecture.md`
rewritten; `CHANGELOG.md` entry; the 55 orphaned packages confirmed gone from
`pubspec.lock`; and the **KaTeX fonts kept** — they must move from the
package's assets into Niman's, or the same note changes appearance on first
launch (D8, [§6.5.7](#657-math-fonts-availability-licensing-bundling)).

**Exit criteria:** `flutter analyze --fatal-infos` clean, `flutter test` green,
the three headless integration tests green, APK + Linux + Windows builds
green, and the dependency graph smaller by 55 packages.

## 10.4 What to spike first, before committing to the plan

Six unknowns can invalidate the design. Each should be answered by a
throwaway branch (the repo has done this before — the `spike/*` branches in
`editor-alternatives.md`), not by argument:

1. ~~Zero-size runs really have zero advance.~~ — **answered for the test
   font 2026-09-21, owed for the platform fonts.** `test/unit/zero_size_run_test.dart`:
   at exactly 0 the marker adds no width, disturbs no kerning and changes no
   height, and **0.01 is not zero** (0.04 px over two 16 px markers), so the
   constant is exactly 0. What is left is the same three checks with Android,
   Linux and Windows fonts, a fallback font and a bidi run — the device half
   of the spike, which is spike 2's trip.
   ([§8.6.0](#860-the-two-ways-to-hide-a-marker))
2. **Android IME with a custom `TextInputClient`.** The single highest
   risk in the editing path. Test: a minimal widget rendering a paragraph with
   markers collapsed to zero size, and typing across a span boundary on a real
   device with Gboard. Success = no lost characters, no caret jumps, no
   duplicated text, composition preserved, and the whole-value fallback
   (`enableDeltaModel: false`) also working. **This repo has been here before,
   and the lesson is unwritten.** The hand-built
   caret/selection/IME/gesture/view stack that `12d9f4a` (2026-09-06) replaced
   was sixteen files — `caret_geometry.dart`, `caret_painter.dart`,
   `row_text_metrics.dart`, `hit_test.dart`, `virtualized_text_view.dart`,
   `ime_bridge.dart` among them — and the author's account of why it went is the
   caret's *rendered* position: the one quantity `EditableText` computes for you
   and a surface that paints its own text has to compute from its own metrics.
   Its commit message records the switch as a plan completed and verified, so
   the reason survives only in the author's memory. That is what this spike is
   for: to turn it into a test. Two questions, and the second is the harder —
   does the IME survive, and **is the caret rectangle right?**
   **The second is answered for the test font, 2026-09-21.**
   `test/unit/caret_rectangle_test.dart`: the caret's height over a hidden run
   is the line's at every offset, including the end of the text; a prototype's
   height changes nothing while its width moves the caret on the RTL side only;
   an empty block has no line metrics and still has a caret; a placeholder costs
   one code unit and the caret steps its width; and a wrapped line moves the
   caret by the strut's advance, not by `LineMetrics.height`. What the device
   pass still owes is the platform fonts, the IME, and a real bidi paragraph.
3. ~~How conformant is `markdown` 7.3.1, really?~~ — **answered 2026-09-21:
   645/652 and 662/677, 22 examples, 8 to fix.** The gap is small and
   enumerable, so writing a parser is off the table for good
   ([§4.9](#49-the-markdown-package-measured)). The successor question is
   narrower and belongs to Phase 1: the number measures the package's *HTML*,
   while the engine will consume its *AST*, so the eight fixes need
   re-triaging against the AST path.
4. **`SliverVariedExtentList` vs a custom `RenderSliver`** when heights above
   the viewport change. Test: 5 000 blocks, edit one near the top, scroll far
   down, measure scroll jumps and assertions.
   **Answered the hard way, on a device, 2026-09-21: the first option cannot work
   at all.** `SliverVariedExtentList` *forces* each child to its extent, so the
   estimate is a constraint rather than a guess, no measurement can correct it,
   and the read view clips every block taller than its estimate. The measurement
   is in §8.4.4, with the screenshot and the log's engine switch behind it.
5. **Math golden files.** Test: render every distinct math expression in a
   corpus with `katex_dart` today, save the boxes as goldens, then render with
   the new typesetter and diff. This tells you the real required subset before
   you write the typesetter, not after — and D8 makes the *current* rendering
   the target, so this is an acceptance test and not just a survey.
6. **Per-keystroke `TextPainter` cost for one block** with a realistic span
   tree (bold inside a link inside a paragraph, 300 chars) to confirm the
   tens-of-microseconds assumption that the whole reveal policy rests on.
7. **Typing latency measured end-to-end** (key event → painted frame) on
   Android, since that is where the desktop keystroke number is least
   predictive.
8. **Offscreen whole-note layout** (D12): lay out `Geometria 1.md` into a
   `PictureRecorder` at 700 px and at a phone width, and check the eager cost
   against the reader's expectation of an export (seconds are fine; minutes
   are not).

## 10.5 How this lands in the repo's workflow

- **One issue for the epic**, with a child issue per phase, so the work is
  tracked the way the rest of the project is (GitHub Issues).
- **One logical commit per change**; a phase is many commits, never one.
- **`dart fix --apply` + `dart format lib test tool`** before analyze and
  tests, as `AGENTS.md` requires.
- **New tests must be portable** (`p.join`, no `chmod`), and the new parser's
  spec harness must run in CI on every PR — otherwise it rots, which is
  exactly what happened to the integration tests (#241).
- **Docs land with the code**: `docs/user/editing.md` changes the moment a
  mode's behaviour changes for a user, not at the end.


---

# 11. Risks, alternatives and open questions

## 11.1 The risks, ranked by what they would cost

| # | Risk | Why it is real | Mitigation | Residual |
|---|---|---|---|---|
| K1 | **The parser never fully conforms** — *closed by measurement* | This was the largest technical risk in the document, with weeks of grind assumed behind it. It is not: the package scores **645/652 and 662/677**, and the whole gap is **22 enumerated examples**, two of which are whitespace ([§4.9](#49-the-markdown-package-measured)). | Done: the harness exists, the allowlist names every accepted example with a bucket and a reason, and `flutter test` fails if one outside it fails or one inside it starts passing. | **Closed.** What remains is a different risk — whether the engine's *AST* path is as conformant as the HTML path, which the number does not measure. |
| K2 | **IME/editing on a custom text surface is harder than it looks** | `DeltaTextInputClient`, composition ranges, autocorrect full-value fallbacks, Android OEM IMEs, dead keys, CJK, RTL. The framework itself is no guide: **nothing in `packages/flutter/lib/` sets `enableDeltaModel: true`, and `EditableText` does not implement `DeltaTextInputClient`** — the delta path is not what Flutter's own text field exercises. Worse, `EditableText` echoes the whole text back to the platform on every keystroke (`editable_text.dart:4016`), which is untenable at 934 KB and must be engineered around by hand. This is where a "weeks" estimate becomes "quarters". It has already cost this repo one editor: `12d9f4a` replaced a hand-built sixteen-file stack — `caret_geometry.dart`, `caret_painter.dart`, `row_text_metrics.dart`, `hit_test.dart` — whose author names the caret's painted position as the sticking point, and whose commit message does not. | Spike 1 (§10.4) before committing. Keep the whole-`TextEditingValue` path working as a first-class fallback, not an afterthought. Keep the legacy source editor behind the flag until the new one survives a device round-trip with at least two IMEs. | **High.** The single biggest schedule risk. |
| K3 | **Visual quality regresses** | The app currently renders tables, math, images and code through packages with years of polish. A new renderer's first version will look worse in a hundred small ways. | Golden-image tests from Phase 2 onward; a written style checklist; the `MarkdownTheme` as the single place to fix all of them. | Medium. Recoverable, but only with an explicit visual QA round. |
| K4 | **Performance is not actually better** | `re_editor` is a tuned large-text editor and the windowed preview is already good. The honest possibility is that the new surface matches rather than beats them. | Measure before/after on the same fixture with the same command in both harnesses; the baseline in [§2.2](#22-what-the-code-already-measured-and-what-it-says-to-keep) is the contract. Where it cannot beat, it must at least not regress — and the *uniformity* (no 200 KB cap, no blank wait, no 5–6 ms math block) is itself the win. | Medium. |
| K5 | **Scope**: this is a 6–10 month project on an app at 0.0.8 | The app has a release cadence and a backlog of user-visible issues (#228, #45, #62, #72 …). A ground-up surface competes with all of them. | Phase-by-phase shipping: `read` mode alone removes the preview's blank wait and the math stutter and is useful even if the project stops there. | Medium. |
| K6 | **The 8 651 lines of surface tests are the real specification** | They encode hundreds of small decisions (the caret-landing retry, the `_isPlainLine` rule, the tally's tick preservation, the paste-Markdown contract) that this document does not list. | Port tests *per phase*, keeping the same test names where possible; treat a deleted test as a deleted requirement and say so in the commit. | Medium. |
| K7 | **Hidden-marker mapping bugs** | A wrong offset translation silently writes the wrong bytes to disk: data loss, not a glitch. Approach B ([§8.6.0](#860-the-two-ways-to-hide-a-marker)) removes the map entirely by keeping the rendered text identical to the source, which is why it was chosen over the cheaper-looking "omit the marker" design. The residual is the `WidgetSpan` correction table for blocks with inline widgets. | Property-based tests: for random documents and random edit sequences, assert `buffer.text` is exactly the expected string. Never let a computed offset be the only thing between a keystroke and a write. | **Reduced to low** by approach B; the residual is the inline-widget geometry, which is testable in isolation. |
| K8 | **Math fonts, stretchy delimiters, no MATH table, and no coverage signal** | Four verified facts make this harder than "ship a font": Flutter cannot do OpenType MATH glyph assembly at all (the engine's text stack has no `MATH`/`GlyphAssembly` path); `dart:ui` exposes **no glyph-outline API**, so surds and arrows must be authored `ui.Path`s; **Android ships no math font at any API level**, so a `fontFamily` name is a silent no-op rather than a fallback; and missing glyphs are **not reliably observable** — Skia has `Paragraph::unresolvedGlyphs()` but no native embedder surfaces it, so a widget test's tofu is deterministic while a device may silently substitute another font, and **a green test proves nothing about device coverage**. | Bundle the fonts (keep the 20 KaTeX TTFs the packages already vendor, 544 KB OFL; add STIX Two Math, 819 KB OFL) and never name a system font; build the stretchy-delimiter recipe as its own tested unit ([§6.5.4](#654-stretchy-delimiters-and-fraction-bars--the-concrete-recipe)); assert coverage with a build-time `fontTools` manifest in CI plus a zero-width terminal fallback. | Medium — bounded, but it is real work that a "just render the font" plan would miss. |
| K9 | **Accessibility silently lost** | A custom surface can end up with no semantics at all, which on Android is a serious regression from `EditableText`-backed surfaces. | Per-visible-block `Semantics` from Phase 3; test with TalkBack and with a screen reader on Linux/Windows. | Low probability if scheduled, high if not. |
| K10 | **The isolate work is subtly wrong on Android** | No platform channels off the root isolate; `RootIsolateToken` needed for anything that touches the engine; large messages copied, not shared. | Keep the worker payload numeric (typed arrays) and the entry a top-level function, as `preview_work.dart` already does and documents. | Low. |
| K11 | **Two engines alive at once during migration** | The feature flag means both the legacy surfaces and the new one are compiled and tested, doubling the surface area for regressions in the interim. | Keep the flag's scope to the pane that is migrated, and delete each legacy surface the moment its mode is migrated instead of waiting for Phase 5. | Low. |
| K12 | **CRLF, BOM, tabs and trailing whitespace** | "Disk is source of truth" means a note that is CRLF must stay CRLF, a BOM must stay a BOM, and a hard break's two trailing spaces must survive a round trip. | Store the separators per line in `SourceBuffer`; make round-trip byte-equality a property test over real files. | Low. |
| K13 | **A pasted note that hangs the app** | Measured in the incumbent stack: the `highlight` package has no regex timeout (Dart has none — `dart-lang/sdk#61284` closed as intended), its `cpp` grammar is O(n²) on `'a' * n + '!'` (8 KB → 1 854 ms), and `Result.toHtml()` is super-quadratic (100 KB → 6 869 ms). A user can paste this. | Replace the lexer with the line-state one, **and** guard the input: lines or token runs beyond a threshold render plain. Adopt the CommonMark spec's own `pathological_tests.py` as a regression suite for the parser, and add the equivalent for the lexer. | Medium probability, **high severity** — it is a hang, not a slowdown. |
| K14 | **Math text silently renders wrong, everywhere** | The failure mode of the two rows above is not a crash: it is a formula that looks plausible and is not. A wrong `1mu` makes script spacing 17 % too wide ([§6.5.5](#655-tex-constants-to-hardcode-katex-tables-cross-checked-against-tftopl-and-texweb)); a missing glyph is replaced by another font's shape; and neither shows up in a widget test. | Golden boxes from `katex_dart` for every distinct corpus expression, compared numerically and not by eye; tftopl-precision constants; the CI coverage manifest; and a rendering pass on a real Android device, not only in `flutter test`. | Medium probability, **high severity** — wrong math is worse than missing math. |

## 11.2 Alternatives considered, and why they lose

| Alternative | Why it is rejected |
|---|---|
| **Do nothing** | The three surfaces are three implementations of the same features, they disagree visually, one has a 200 KB cap it enforces by refusing to open any of the repo's own fixtures, and the preview takes 137–182 ms to show first content and 35–71 ms to land a scroll jump. The uniformity requirement cannot be met by leaving them. |
| **Fix the three in place** | Deduplicating find, tally, context menu, formatting and scroll-sync across three engines is a large refactor whose end state is *still* three engines with three models. It costs a large fraction of the rewrite without removing the cap, the stalls or the packages. |
| **Adopt one package for all three** (the `editor-alternatives.md` candidates) | Already measured: every candidate is slower than the plain source editor at the keystroke, and the best model (appflowy_editor) fails this toolchain's analysis and brings an AGPL/MPL choice and 21 direct dependencies. `docs/dev/editor-alternatives.md` is the record. |
| **Keep source-of-truth but reuse `markdown` for the parse** | **Adopted (D2).** Was listed here as the pragmatic variant; the user took it. −20 to −36 days and CommonMark conformance becomes a measurement rather than a rewrite. `highlight` stays for the same reason, with its hazards contained (K13). |
| **A Delta/rich-text document with a Markdown codec** | Contradicts "disk is source of truth"; the codec is exactly the 648 lines and the fidelity bugs the app already has (#139, #165). |
| **Render to HTML and use a web view / `flutter_html`** | Not pure Flutter, a plugin on every platform, and no chance of the keystroke numbers. |
| **Only build live mode, drop source mode** | Source mode is the power-user surface and the one that never hits the size cap; it is also the cheapest mode to build (identity map). Dropping it saves little and removes the fallback that makes the migration safe. |
| **Build `read` mode only** | A legitimate reduced scope that solves the visible problems (blank wait, math stutter, no size cap) in a fraction of the time. Worth keeping as the explicit stop point if K5 bites. |

## 11.3 The open questions, and what was answered

Answered 2026-09-20; the decisions themselves and their consequences are in
[§1.5](#15-the-decisions-and-what-each-one-changes). Recorded here as the
conversation they came from, so the reasoning is not lost.

| # | Question | Answer |
|---|---|---|
| 1 | May the pure-Dart `markdown` and `highlight` stay? | **Yes.** The scope lever: −20 to −36 days (the parser workstreams). |
| 2 | One widget with three modes, or three widgets over one engine? | **One widget, three modes.** |
| 3 | Acceptance bar for "uniform performance"? | **`source` must be very fast; the other modes as close as they can get.** Not "equal timings" — source mode is the floor, and it inherits every optimisation, so the gap should be small and is allowed to exist. |
| 4 | How much of the WYSIWYG's visual ambition? | **All of it: `live` is literally an interactive preview**, Obsidian-style — only the caret's line, or even just the word, temporarily becomes source. That settles the reveal policy as policy A with a per-word refinement, and it is the reason markers are hidden by *style* rather than by removal: a style change re-reveals a run without touching the text, the offsets or the layout cache. |
| 5 | Which platforms, in what order? | **Both desktop and Android.** Order ours: desktop first for measurement (the harness and the comparable numbers live there), with the Android IME spike in parallel from day one. |
| 7 | Export/print/PDF? | **Will be required.** The renderer must paint offscreen at an arbitrary width from the start — a seam, not a feature. |
| 8 | One widget for every note kind? | **No: Markdown only.** List notes and audio notes keep their own UI, separate from this widget, and `ui/kinds/` is untouched. |
| 6 | Target release? | **None — build it first, then decide when to integrate** (D15). The plan can stop at any phase boundary; the only gate is that each one leaves the app shippable. |

## 11.4 What would make this project fail, in one sentence each

- Writing a Markdown parser anyway, out of a habit formed before D2 was
  answered.
- Building the renderer before deciding how markers are hidden, then
  discovering that the reveal policy (D9) cannot be retrofitted onto it.
- Migrating `live` mode before the IME has survived a real Android device.
- Deleting the legacy surfaces before the new one has beaten them on the same
  benchmark, in the same harness, on the same machine.
- Treating the 38 surface test files as obsolete instead of as the
  specification they are.
- Letting `highlight` keep rendering: its `toHtml()` is super-quadratic and its
  grammars have no timeout, so "we kept the package" becomes a hang.
- Retrofitting export: a viewport-shaped renderer cannot print a whole note.


---

# 12. Appendix

## 12.1 Source inventory of the surfaces being replaced

`wc -l` on this checkout (`main` @ `16691f7`), for the modules
`lib/src/{editor,preview,links,frontmatter}` — 11 814 lines total.

| Lines | File | Fate |
|---:|---|---|
| 915 | `editor/highlighting.dart` | **Port** — becomes `BlockScanner` + the inline token source |
| 723 | `editor/wysiwyg/wysiwyg_editor.dart` | Delete |
| 630 | `preview/markdown_preview.dart` | Replace with the surface's viewport |
| 535 | `preview/scroll_map.dart` | **Port** into `HeightMap` (+ Fenwick, + per-kind estimators) |
| 518 | `editor/note_editor.dart` | Delete (the widget) |
| 496 | `editor/wysiwyg/markdown_document_codec.dart` | Delete (no Delta) |
| 429 | `preview/math_widget.dart` | Replace with the own TeX renderer |
| 371 | `frontmatter/parser.dart` | Keep (YAML handling is orthogonal) |
| 364 | `editor/md_editing.dart` | Replace with `MarkdownCommand` |
| 305 | `editor/find_panel.dart` | Replace with one find bar |
| 302 | `editor/highlight_sync.dart` | Port (becomes the render map's active-format pass) |
| 299 | `preview/scroll_sync.dart` | **Delete** — D4 rejects the split preview it existed for |
| 294 | `preview/block_parse.dart` | Replace with the own parser |
| 276 | `editor/list_tally.dart` | Port to the block index |
| 270 | `links/resolver.dart` | Keep |
| 241 | `editor/editor_context_menu.dart` | Replace with one context menu |
| 238 | `editor/wysiwyg/quill_tally.dart` | Delete (duplicate of the tally) |
| 216 | `preview/wikilink.dart` | Delete (wikilinks become inline spans) |
| 205 | `editor/list_tally_edit.dart` | Port |
| 193 | `links/missing_note_handler.dart` | Keep |
| 193 | `editor/wysiwyg/wysiwyg_find_panel.dart` | Delete |
| 190 | `editor/wysiwyg/wysiwyg_clipboard.dart` | Delete (copy is `buffer.substring`) |
| 178 | `editor/folding.dart` | Keep — now applies in every mode |
| 175 | `editor/wysiwyg/quill_editor_commands.dart` | Delete |
| 166 | `editor/wysiwyg/wysiwyg_find_controller.dart` | Delete |
| 159 | `preview/html_table.dart` | Delete (own table parsing) |
| 156 | `preview/math_syntax.dart` | Port into the TeX tokenizer |
| 156 | `links/parser.dart` | **Port** — the single-link-rule invariant |
| 154 | `preview/aspect_image.dart` | Port into the image block |
| 152 | `editor/wysiwyg/markdown_blocks.dart` | Delete |
| 146 | `preview/math_cache.dart` | **Port** into `TexCache` (two-level) |
| 143 | `editor/toolbar_item.dart` | Keep (the 14 items are the command set) |
| 140 | `editor/markdown_format.dart` | Port into `MarkdownCommand` |
| 133 | `editor/editor_shortcuts.dart` | Keep (remappable, `shortcuts.md` is the spec) |
| 132 | `preview/editor_lines.dart` | **Delete** (D4); `visibleRows` on the controller replaces it for typewriter and outline |
| 129 | `preview/preview_work.dart` | **Port** the isolate design, change the payload |
| 123 | `frontmatter/edit.dart` | Keep |
| 120 | `editor/toolbar.dart` | Keep, dispatch through the controller |
| 110 | `frontmatter/fields.dart` | Keep |
| 105 | `editor/wysiwyg/guarded_clipboard_service.dart` | Port the guard |
| 95 | `editor/note_column.dart` | Keep (becomes `MarkdownTheme.columnWidth`) |
| 90 | `editor/toolbar_layout.dart` | Keep |
| 85 | `editor/typewriter_scroll.dart` | Port into the viewport |
| 76 | `editor/outline.dart` | Keep, fed by the block scan |
| 75 | `editor/highlight_style.dart` | Port into `MarkdownTheme` |
| 73 | `editor/markdown_editing_controller.dart` | Delete (own controller) |
| 67 | `preview/code_highlight.dart` | Replace with `CodeLexer` |
| 65 | `editor/math_rule.dart` | Port into the TeX tokenizer's delimiter rules |
| 63 | `editor/wysiwyg/opaque_embed.dart` | Delete |
| 58 | `editor/editor_commands.dart`, `editor/editor_only.dart`, `editor/word_count.dart`, `editor/markdown_chunks.dart` | Mixed: port / delete |
| 46 | `editor/wysiwyg/markdown_parse.dart` | Delete |

Tests: **38 files / 8 651 lines** touch these surfaces, of 48 970 test lines
in the repo.

## 12.2 The dependency ledger

`flutter pub deps --json` on this checkout: **235 packages** in the graph.
Removing the seven surface packages removes the following **55** packages,
which are reachable *only* through them:

`cached_network_image`, `cached_network_image_platform_interface`,
`cached_network_image_web`, `charcode`, `csslib`, `dart_quill_delta`,
`diff_match_patch`, `file_selector_linux`, `file_selector_platform_interface`,
`file_selector_windows`, `flutter_cache_manager`, `flutter_colorpicker`,
`flutter_highlight`, `flutter_keyboard_visibility_linux`,
`flutter_keyboard_visibility_macos`,
`flutter_keyboard_visibility_platform_interface`,
`flutter_keyboard_visibility_temp_fork`, `flutter_keyboard_visibility_windows`,
`flutter_markdown_plus`, `flutter_math_fork`, `flutter_quill`,
`flutter_quill_delta_from_html`, `flutter_smooth_markdown`, `flutter_svg`,
`html`, `is_ios_simulator`, `isolate_contactor`, `isolate_manager`, `katex`,
`katex_dart`, `nested`, `octo_image`, `path_parsing`, `provider`,
`quill_native_bridge`, `quill_native_bridge_android`, `quill_native_bridge_ios`,
`quill_native_bridge_linux`, `quill_native_bridge_macos`,
`quill_native_bridge_platform_interface`, `quill_native_bridge_web`,
`quill_native_bridge_windows`, `quiver`, `re_editor`, `re_highlight`, `rxdart`,
`sqflite`, `sqflite_android`, `sqflite_common`, `sqflite_darwin`,
`sqflite_platform_interface`, `tuple`, `vector_graphics`,
`vector_graphics_codec`, `vector_graphics_compiler`.

Two of those deserve naming explicitly:

- **`quill_native_bridge_*`** compiles native code into every one of the seven
  platform targets for a surface that is being replaced. Removing it removes
  native build surface from the Windows and Android builds.
- **`sqflite*`** is a *second* SQLite in the app, on top of the `sqlite3`
  package the index already bundles (and whose comment in `pubspec.yaml`
  explains why Windows needs it). Removing `flutter_quill` removes it.

Reproduce with:

```bash
flutter pub deps --json > /tmp/niman/pubdeps.json
# then compute the closure of the surface roots minus the closure of the
# remaining direct dependencies (the script is in §12.5)
```

## 12.3 Canonical references

**Specifications**

- CommonMark spec, current version: <https://spec.commonmark.org/>
- CommonMark spec JSON (the test corpus): <https://spec.commonmark.org/0.31.2/spec.json>
- GitHub Flavored Markdown spec: <https://github.github.com/gfm/>
- GFM spec examples JSON: <https://github.github.com/gfm/spec.json>
- GitHub's own math documentation: <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/writing-mathematical-expressions>
- YAML 1.2 (frontmatter): <https://yaml.org/spec/1.2.2/>

**Prior art whose architecture is mined above**

- CodeMirror 6 system guide: <https://codemirror.net/docs/guide/>
- CodeMirror 6 reference (`ChangeSet`, `Tree`, `Decoration`, `Text`): <https://codemirror.net/docs/ref/>
- Lezer (incremental parser): <https://lezer.codemirror.net/docs/ref/>
- tree-sitter (incremental parsing, error recovery): <https://tree-sitter.github.io/tree-sitter/>
- ProseMirror guide (positions, steps, mapping, view descs): <https://prosemirror.net/docs/guide/>
- Lexical (reconciliation, dirty nodes): <https://lexical.dev/docs/concepts/architecture>
- VS Code's editor rendering (view lines, view zones, heights): <https://code.visualstudio.com/api/extension-guides/custom-editors>
- KaTeX (the math layout reference): <https://katex.org/docs/supported>
- MathJax's TeX atom/box model: <https://docs.mathjax.org/en/latest/advanced/>

**The framework itself**

- `TextPainter` / `TextSpan` / `InlineSpan`: <https://api.flutter.dev/flutter/painting/TextPainter-class.html>
- `dart:ui` `ParagraphBuilder` / `Paragraph`: <https://api.flutter.dev/flutter/dart-ui/ParagraphBuilder-class.html>
- `TextInputClient` / `DeltaTextInputClient`: <https://api.flutter.dev/flutter/services/TextInputClient-class.html>, <https://api.flutter.dev/flutter/services/DeltaTextInputClient-class.html>
- `RenderSliver` / `RenderBox`: <https://api.flutter.dev/flutter/rendering/RenderSliver-class.html>
- `SliverVariedExtentList`: <https://api.flutter.dev/flutter/widgets/SliverVariedExtentList-class.html>

**This repo**

- [`docs/dev/editor-alternatives.md`](../../docs/dev/editor-alternatives.md) — the six measured and rejected packages.
- [`docs/dev/architecture.md`](../../docs/dev/architecture.md) — the module map and the key flows.
- [`docs/user/editing.md`](../../docs/user/editing.md) — the user-visible behaviour contract.
- [`docs/user/shortcuts.md`](../../docs/user/shortcuts.md) — the remappable keys a custom surface must honour.
- [`docs/user/links.md`](../../docs/user/links.md) — wikilinks, aliases, embeds, dead-link creation.
- [`docs/dev/conventions.md`](../../docs/dev/conventions.md) — the code and interface rules.
- `lib/src/editor/highlighting.dart` — the incremental tokenizer being ported.
- `lib/src/preview/scroll_map.dart` — the height map being generalized.
- `lib/src/preview/preview_work.dart` — the isolate design being ported.
- `lib/src/links/parser.dart` — the single-parse-rule invariant.

## 12.4 Glossary

| Term | Meaning in this document |
|---|---|
| **Source text** | The note's Markdown, as bytes on disk. The only document. |
| **Buffer** | `SourceBuffer`: the in-memory line array + prefix-sum index over the source text. |
| **Block** | A top-level Markdown construct occupying a line range: paragraph, heading, list (with its items), blockquote, fence, table, math block, HTML block, frontmatter, rule. |
| **Container** | A block that contains other blocks (blockquote, list item), carrying an indent and a marker. |
| **Block scan** | The phase that decides each line's state and therefore the block boundaries. |
| **Inline phase** | The per-block phase turning raw text into emphasised spans, links, wikilinks, math, code spans and tags. |
| **Style runs** | The per-block list of styled source ranges — including the *hidden* runs that make a marker occupy no width. Under approach B there is no offset map: text offset == source offset. |
| **Reveal policy** | Which Markdown markers are shown rather than hidden in `live` mode, as a function of the caret. |
| **Height map** | The per-block pixel extent structure (measured + frozen estimate) behind the viewport. |
| **Visual text** | What the user reads in a block: a concatenation of source slices with markers omitted (or included, in `source` mode). |
| **Mode** | `source`, `live` or `read` — a presentation policy over the one pipeline. |
| **Surface** | The one widget, `MarkdownSurface`. |
| **Legacy surface** | Any of `NoteEditor` / `WysiwygEditor` / `MarkdownPreview`, during migration. |

## 12.5 How this document was produced, and how to reproduce it

**Method.** Three kinds of statement appear here and are labelled as such:

- **Measured** — produced by running a command on this checkout; the command
  or the source of the number is named inline.
- **Read** — taken from the repo's own documentation, code comments or the
  specifications, with a link.
- **Inferred / proposed** — the design in §8 and the estimates in §10. These
  are the author's judgement and are marked by their wording ("should",
  "target", "estimate", "~").

**The numbers measured for this document.**

| Measurement | Command |
|---|---|
| Surface source inventory | `find lib/src/{editor,preview,links,frontmatter} -name '*.dart' \| xargs wc -l` |
| Surface test inventory | `grep -rln "NoteEditor\|WysiwygEditor\|MarkdownPreview" test \| xargs wc -l` |
| Dependency closure | `flutter pub deps --json` + the closure script below |
| `Geometria 1.md` structure | `wc -l -c`, `grep -o '\$\$' \| wc -l`, `grep -o '\[\[[^]]*\]\]' \| wc -l`, … |

The dependency-closure script:

```python
import json, re
d = json.load(open('/tmp/niman/pubdeps.json'))
pkgs = {p['name']: set(p.get('dependencies') or []) for p in d['packages']}

def closure(roots):
    seen, stack = set(), list(roots)
    while stack:
        n = stack.pop()
        if n in seen:
            continue
        seen.add(n)
        stack.extend(pkgs.get(n, set()) - seen)
    return seen

surface = {'flutter_quill', 're_editor', 'flutter_markdown_plus', 'katex',
           'katex_dart', 'flutter_highlight', 'flutter_smooth_markdown'}
main = open('pubspec.yaml').read().split('dev_dependencies:')[0].split('dependencies:')[1]
direct = set(re.findall(r'^  ([a-z_0-9]+):', main, re.M)) - surface

only = sorted(closure(surface) - closure(direct))
print(len(only), 'packages exist only for the surface stack')
print(', '.join(only))
```

**The research inputs.** Five parallel research streams fed this document, and
their reports are §4 (the CommonMark/GFM specification inventory), §5 (the
corpus profile of `Geometria 1.md` and the fixtures), §6 (the Flutter/Dart
primitive survey), §7 (the prior-art survey) and §13 (the benchmark of the
incumbent stack, in full, with the harness). They were commissioned against a
fixed brief, independently of the design in §8, and their findings were then
carried into it — including the ones that contradicted the brief, of which
there were three worth naming: the WYSIWYG does not open *any* of the repo's
own fixtures, `Geometria 1.md` has 13 845 math spans rather than the 1 683 the
brief assumed, and the incumbent's per-expression math render is already fast
enough that the geometry note's cost is a viewport problem, not a typesetter
problem.

## 12.6 First-day checklist

The decisions are taken ([§1.5](#15-the-decisions-and-what-each-one-changes))
and there is no target release (D15), so this is simply the order the work
starts in. No step below waits on an answer.

1. **Open the epic issue** and link this document. Child issues per phase,
   with the exit criteria from [§10.3](#103-the-stages) copied into them, and
   the decisions recorded in the epic so they are not re-litigated in the PRs.
2. ~~Measure `markdown` 7.3.1 before writing anything~~ — **done, 2026-09-21**:
   **645/652 CommonMark and 662/677 GFM**, 22 examples triaged (8 *fix*, 14
   *pin*, none needing *mask*), the harness in `tool/markdown_spec.dart` and
   the gate in `test/unit/markdown_conformance_test.dart`. The number and its
   consequences are [§4.9](#49-the-markdown-package-measured).
3. **Start the Android IME spike in parallel** (spike 2) — it is the risk that
   can cancel the plan, and it does not depend on step 2. Desktop is the
   measurement platform, Android is the risk platform; run them together
   rather than in sequence (D11).
4. **Then Phase 1 proper**, in this commit order: `SourceBuffer` + its unit
   tests (small, complete, everything sits on it), then `BlockScanner` and the
   per-line state machine, then the extension masking, then the per-block
   bridge to the package.
5. **Record the incumbent's numbers** ([§9.3](#93-the-legacy-baseline-to-beat-measured))
   in the issue as the baseline to beat, with the machine and the exact
   commands, before any new code is measured — the discipline
   `editor-alternatives.md` established and this document's own benchmark
   follows.
6. **Keep this branch as the research branch**: it holds the dossier and the
   benchmark, and one working branch per phase comes off `main`.


---

# 13. Annex: the incumbent baseline, measured in full

**Deliverable:** the numbers a planned ground-up replacement must beat, measured
on the code that ships today. Repo `Nihmar/Niman`, commit
`16691f727edeb1663fe52ff4c3bbc5718c7f0da4`, working tree clean apart from a
pre-existing untracked `checklist-0.0.8.md` (not touched). `lib/` was not
modified; the one scratch test file used was deleted before this report was
finished (its full content is in §13.5 so it can be recreated byte for byte).

This is the measurement
`docs/dev/editor-alternatives.md` (repo path)
asked for: that document establishes that six *candidates* are slower than the
source editor, and states that **`flutter_quill` itself was never benched** —
"measuring the incumbent … is the first thing the next evaluation should do".
It is done here. Nothing in that document is contradicted by these numbers; the
source-editor figures it quotes (tokenize 23.95 ms, incremental edit 0.507 ms
at 200 KB, 44.7 µs/line layout+paint) are reproduced within noise (§13.2.2).

---

## 13.1 Environment and method

### 13.1.1 Machine and toolchain

| | |
|---|---|
| OS | Linux `cachyos-fisso` 7.2.6-1-cachyos, `#1 SMP PREEMPT_DYNAMIC x86_64` |
| CPU | 13th Gen Intel Core i5-13400F — 6 cores / 12 threads, 800–4600 MHz, L3 20 MiB |
| RAM | 32 691 396 kB total (≈31.2 GiB), ≈22.8 GiB available during the runs |
| `nproc` | 12 |
| Flutter | 3.47.2 stable, framework `d3b14c8769` (2026-08-26) |
| Dart | 3.13.2 (devtools 2.60.0) |
| Engine | `1cf1c4773fb941c4c74a7f8bb144a8837596c0f4` |
| Mode | **debug**, inside `flutter test` (kernel VM, asserts on, no AOT) |

Relevant package versions from `pubspec.yaml`: `flutter_quill ^11.5.1`,
`re_editor ^0.10.0`, `flutter_markdown_plus ^1.0.12`, `markdown ^7.3.1`,
`katex ^1.0.0`, `katex_dart ^0.1.1`.

**Only ratios between rows carry.** Absolute values are debug-mode,
JIT-warmed, on one desktop CPU; a release AOT build on a phone will differ by
constants (both directions) and this report does not claim otherwise. Every
number below is the same harness, same machine, same day.

### 13.1.2 Fixtures

| key | path | bytes | chars (decoded) | lines | `mathSpansIn` total | display | inline |
|---|---|---|---|---|---|---|---|
| `200kb` | `test/fixtures/markdown/fixture-200kb.md` | 206 241 | 206 241 | 6 289 | 203 | 141 | 62 |
| `500kb` | `test/fixtures/markdown/fixture-500kb.md` | 513 423 | 513 423 | 15 304 | 519 | 308 | 211 |
| `geo934kb` | `Geometria 1.md` | 934 769 | **931 042** | 10 332 | **13 845** | 841 | 13 004 |

The brief's "934 769 bytes, 10 331 lines, 1 683 math expressions" reconciles as
follows: 934 769 is the **byte** count, 931 042 the **character** count (the
note has ~3.7 kB of multi-byte characters). The file has exactly **1 682 lines
beginning with `$$`**, which is the brief's 1 683 (off by one / one line
counted twice). Those are `$$` *lines*; `mathSpansIn` pairs them into **841
display blocks**, and additionally finds **13 004 inline `$…$` spans** — so the
preview math path sees **13 845** render sites in this note, ~8× the brief's
figure. That distinction matters for §13.2.4: 841 display expressions, not 1 683.

### 13.1.3 How each metric is defined

* **Time to first frame** — a monotonic `Stopwatch` around
  `await tester.pumpWidget(<surface>…)`, i.e. build + layout + paint of the
  first frame the surface produces. A warm-up mount of a *tiny* document is
  pumped and unmounted immediately before the measured mount, so one-time
  font/theme/`Expando`/parser-class-load setup is not charged to the document
  (without it the first fixture measured in a process was inflated ~6×; see
  §13.2.2). A first frame is measured **once** (best-of-1) — it is not repeatable
  in place; the warm-up is what makes it comparable across fixtures. Where a
  second first-frame number exists it comes from an independent test and is
  quoted alongside.
* **Mid-document keystroke** — collapsed caret in the middle of the middle
  line, one character inserted. Source editor:
  `CodeLineEditingController.replaceSelection('X')` with the app's real
  synchronous listener wired (`EditorHighlightSync.onBufferChanged` from
  `highlight_sync.dart`), timed around the synchronous call. WYSIWYG:
  `QuillController.replaceText(at, 0, 'X', TextSelection.collapsed(offset: at+1))`
  with the caret moved to `at` first, timed around the call. **5 repetitions**;
  between repetitions the inserted character is removed *outside* the timed
  window, so the buffer is byte-identical at the start of each rep. Reported:
  **best** and **nearest-rank median** (sorted[⌊n/2⌋]) of the 5.
* **Tokenize-from-cold** — `HighlightDocument.fromText(raw)`, best and median
  of **3**.
* **`highlightSyncCold`** — `EditorHighlightSync.onBufferChanged` on a fresh
  sync over a freshly built controller, best/median of 3. This is the app's
  *open* path; it is lazy (no tokenization — see §13.3.1).
* **Off-thread parse** — wall time of `await PreviewWork.run('parse', source)`,
  best/median of 3; this is a fresh `Isolate.spawn` **plus** the block phase,
  which is what the preview actually pays. Also `PreviewWork.run('stats', raw)`.
* **Blank wait / first visible content** — wall time from `pumpWidget` until the
  `ValueKey('previewSkeleton')` sliver is gone. Polled at a 5 ms real delay
  inside `tester.runAsync`, bounded at 30 s; a `tester.pump()` drives each
  frame. This is the only way to let the preview's real isolate answer inside a
  widget test (fake-clock `pumpAndSettle` cannot). Adds up to one poll interval.
* **Scroll-to-middle** — after content is visible, `ScrollController.jumpTo(
  maxScrollExtent/2)` then one `pump()` (landing frame) and a second `pump()`
  (settle frame), timed separately.
* **Math** — N texes taken in document order from the first N usable
  `mathSpansIn` spans of `Geometria 1.md` (markers stripped). A fresh
  `MathCache` per repetition, `await cache.ensure(tex, displayMode: false)` per
  expression (the real `math_widget.dart` path over `katex_dart.renderToBox`).
  **3 repetitions**, best/median. A separate pass measures
  `katex_dart.renderToBox` directly and `KatexBoxPainter.paint` into a
  `PictureRecorder`.
* **Timeout** — every test carries `Timeout(Duration(seconds: 180))` and each
  `flutter test` invocation is additionally wrapped in the shell command
  `timeout -k 5 <N>`. **No test hit 180 s; nothing was killed; no OOM; no
  exception.** Where the brief asks for a "did not complete" cell, the answer
  is "nothing did not complete" — recorded explicitly in §13.2.

### 13.1.4 The cap discovered in `wysiwyg_editor.dart`

* Constant: `WysiwygEditorState._maxWysiwygBytes = 200 * 1024` = **204 800
  chars** (`lib/src/editor/wysiwyg/wysiwyg_editor.dart:93`).
* Enforced **only in `build()`**, line 525:
  `if (widget.data.length > _maxWysiwygBytes)` → returns a centred
  `Text(AppStrings.wysiwygTooLarge)`; no `QuillEditor` is built.
* **Not** enforced in `initState()` → `_open(source)` (line 188 → line 200),
  which calls `_codec.decode(source)` unconditionally **before** `build()` ever
  runs. `NoteView._editorPane()` (`lib/src/ui/note_view.dart:1137`) constructs
  `WysiwygEditor(data: _currentText, …)` whenever `showWysiwyg` is true, with no
  size guard of its own. The measured consequence is in §13.2.2.
* Boundary pinned by experiment: 204 800 chars **opens** (204 800 is not
  `> 204 800`); 204 801 chars **refuses**. `fixture-200kb.md` is 206 241 chars,
  i.e. **1 441 chars over the cap** — so the project's own "200 KB" fixture does
  **not** open in WYSIWYG at all.

---

## 13.2 Results

All values in **ms**, debug harness. `b` = best, `m` = median (n=5 for
keystrokes, n=3 otherwise). "—" = not measured for that fixture.

### 13.2.1 Source editor (`re_editor` + Niman tokenizer)

| fixture | tokenizeCold b / m | highlightSyncCold b / m | tokenizerEdit b / m | **keystrokeFullChain b / m** | firstFrame | keystroke+paint b / m |
|---|---|---|---|---|---|---|
| `200kb` (206 241 ch) | 21.274 / 22.003 | 0.865 / 0.886 | 0.462 / 1.026 | **0.296 / 0.319** | 15.894 | 3.712 / 5.500 |
| `500kb` (513 423 ch) | 43.835 / 48.279 | 3.402 / 5.455 | 1.281 / 1.360 | **0.277 / 0.357** | 12.578 | — |
| `geo934kb` (931 042 ch) | 455.168 / 459.845 | 1.659 / 1.860 | 1.039 / 1.173 | **0.372 / 0.458** | 9.264 | — |

`tokenizeCold` = `HighlightDocument.fromText` (full, eager). `tokenizerEdit` =
`HighlightDocument.replace` at mid-buffer (the offset-edit API, **not** the app
keystroke path). `keystrokeFullChain` = controller edit + the app's synchronous
`EditorHighlightSync` listener. `keystroke+paint` adds one `pump()` of the
warmed editor. Reproduces the `editor-alternatives.md` figures: tokenize 21.3 ms
vs the quoted 23.95 ms, tokenizer edit 0.462 ms vs the quoted 0.507 ms.

**`did not complete`: none.** All three fixtures mounted and edited.

### 13.2.2 WYSIWYG (`flutter_quill` + Niman codec)

Codec alone, callable without a widget (`MarkdownDocumentCodec`):

| fixture | **decode (Markdown→Delta) b / m** | encode canonical b / m | encode fast-path b / m | Delta ops | opaque embeds |
|---|---|---|---|---|---|
| `200kb` | **357.169 / 388.222** | 5.083 / 6.908 | 7.890 / 10.207 | 6 608 | 518 |
| `500kb` | **2 407.714 / 2 459.340** | 6.263 / 7.966 | 25.493 / 26.551 | 16 496 | 1 191 |
| `geo934kb` | **1 024.597 / 1 047.918** | 5.285 / 7.333 | 28.641 / 33.716 | 7 036 | 2 934 |

* `decode` = `codec.decode(source)` (block split + full `markdown` parse +
  `_blockOps` + `Document.fromJson` + `toDelta().toJson()` snapshot). This is
  the exact call `WysiwygEditorState._open` makes on open.
* `encode canonical` = `codec.encode(document)` with no `decoded:` argument —
  every edited emit.
* `encode fast-path` = `codec.encode(document, decoded: decoded)` on an
  unchanged document: `toDelta().toJson()` + `jsonEncode`/-compare (`_sameJson`).
  Runs on every debounced emit (500 ms after a typing pause, `_emit`) **and** in
  `didUpdateWidget` (line 337) on every parent rebuild whose `data` changed.

Widget, on newline-free slices of `fixture-200kb.md` (so lengths are exact):

| target | chars | opens? (`QuillEditor` built) | **firstFrame** | **keystroke b / m** | emitAfterEdit (encode after 1 edit) |
|---|---|---|---|---|---|
| `slice204800` | 204 800 (= cap) | **yes** | **2 214.908** | **47.334 / 57.455** | 18.930 |
| `slice102400` | 102 400 | yes | 675.905 | 14.552 / 17.693 | 8.007 |
| `slice204801` | 204 801 (= cap+1) | **no** | 399.655 | — | — |
| `fixture-200kb.md` | 206 241 | **no** (> cap) | (implied by cap+1) | — | — |
| `fixture-500kb.md` | 513 423 | **no** | **2 741.169** | — | — |
| `Geometria 1.md` | 931 042 | **no** | **1 178.380** | — | — |

Answers to "does it even open at 200 KB / 500 KB / 934 KB": **no at all three.**
`fixture-200kb.md` itself is over the cap by 1 441 chars. At 500 KB and 934 KB
the surface paints the "note too large" message — but only after
`initState`→`_open`→`decode` has already run: the 2 741 ms and 1 178 ms
`firstFrame` rows above contain **no Quill editor build at all**, they are
Niman's own Markdown→Delta decode plus the refusal frame. The cap protects
Quill, not the codec.

**`did not complete`: none.** The 500 KB decode (2.46 s median) and the 934 KB
one (1.05 s) both finished well inside 180 s.

### 13.2.3 Preview (`flutter_markdown_plus` + `markdown` AST, windowed)

| fixture | blockPhase b / m | off-thread parse wall b / m | stats wall b / m | firstFrame (skeleton) | **first visible content / blank wait** | scroll-middle landing | settle | maxScrollExtent (px) |
|---|---|---|---|---|---|---|---|---|
| `200kb` | 24.364 / 28.049 | 26.167 / 26.826 | 7.993 / 10.144 | 29.037 | **161.318** | 70.755 | 33.205 | 158 349.8 |
| `500kb` | 54.778 / 59.891 | 63.988 / 72.651 | 21.953 / 22.731 | 14.600 | **182.479** | 34.196 | 18.507 | 410 886.0 |
| `geo934kb` | 42.807 / 45.869 | 49.885 / 53.393 | 37.951 / 40.425 | 18.168 | **136.574** | 66.951 | 44.449 | 217 952.9 |

* `blockPhase` = `parseBlockPhase(stripFrontmatter(source))` on the UI isolate
  (only used directly below the 64 KB `_syncParseLimit`; above it the same work
  runs in `PreviewWork`).
* `off-thread parse wall` = `PreviewWork.run('parse', …)`, isolate spawn
  included. `stats wall` = `PreviewWork.run('stats', …)` (word count + outline).
* **Issue #58 ("big note appears all at once, after a blank wait"): still
  reproducible as a *wait*, no longer as a *blank*.** The pane paints
  `_SkeletonBlock` bars on the first frame (`markdown_preview.dart:448`), and
  real content replaces them after **137–182 ms** wall in the harness — polled
  in 4 / 13 / 9 pumps. There is no unbounded blank pane; the residual wait is
  the isolate round trip (26–64 ms) plus first-content-frame layout/paint. The
  500 KB fixture is again the slowest (182 ms), consistent with it having the
  most blocks.

**`did not complete`: none.**

### 13.2.4 Math (`math_widget.dart` / `math_syntax.dart` / `math_cache.dart` / `katex_dart`)

| N | render cold total b / m | per expression b / m | cache-hit total b / m | hit per expr (best) | misses / hits | miss ratio |
|---|---|---|---|---|---|---|
| 1 | 0.142 / 0.214 | 0.142 / 0.214 | 0.016 / 0.020 | 0.016 | 1 / 1 | 1.000 |
| 10 | 0.380 / 0.434 | 0.038 / 0.043 | 0.082 / 0.082 | 0.008 | 7 / 13 | 0.700 |
| 50 | 4.139 / 4.694 | 0.083 / 0.094 | 0.416 / 0.432 | 0.008 | 33 / 67 | 0.660 |
| 200 | 15.338 / 21.729 | 0.077 / 0.109 | 1.419 / 1.494 | 0.007 | 115 / 285 | 0.575 |

Supporting passes: raw `katex_dart.renderToBox` on the first tex — best 0.013 /
median 0.020 ms. Full current path for **200 inline formulas** generated through
the real parser (`makeDocument` + `parseBlockPhase` + `withInlines` +
`splitInlineMath`): parse-to-`math`-elements **31.596 ms**, then
`MathCache.ensure` render of those 200 elements **19.144 ms**
(200 elements found). `KatexBoxPainter.paint` of 200 cached boxes into a
`PictureRecorder`: **38.216 ms** (0.19 ms/formula).

The very first render of an expression that pulls a new font table is an
outlier: in a single-repetition run before the engine warm-up,
`\mathbb{R}` cost **2.577 ms** against **0.142 ms** for the same expression
warm. That is katex's one-time font-metric load, not a per-formula cost;
it is why every N row above is preceded by one `renderToBox('x')` warm-up.

**`did not complete`: none.**

---

## 13.3 Complexity analysis (from the numbers)

### 13.3.1 Source editor

* **Keystroke: O(change) = O(1) in document size.** Best keystroke times
  0.296 / 0.277 / 0.372 ms at 206 k / 513 k / 931 k chars — flat within 1.35×
  while the document grows 4.5×; per-char cost *falls* from 0.0014 to
  0.0004 µs. Mechanism: `EditorHighlightSync.onBufferChanged`
  (`highlight_sync.dart`) locates the first changed line by segment identity
  (O(segments+256), not O(lines)) and calls `HighlightDocument.replaceLines`,
  which drops the lazy materialization to the edit point
  (`_materializedUntil = first`, `highlighting.dart:381`) and shares the
  unchanged tail by state convergence. Keystroke + one paint frame is
  3.7–5.5 ms at 200 KB — **O(visible)**, one wrapped row.
* **But `HighlightDocument.replace` (the offset path) is O(lines).** It calls
  `_materialize(_lines.length - 1)` and rebuilds a `_lineStarts` list over the
  whole buffer (`highlighting.dart:298–299`): 0.462 / 1.281 / 1.039 ms, which
  tracks line count (6 289 / 15 304 / 10 332), not the app's path. Keep it in
  mind only if a replacement keeps an offset-based edit model.
* **Tokenize-from-cold: O(bytes) with a large density factor.** 21.3 ms
  (0.103 µs/char) / 43.8 ms (0.085) / **455.2 ms (0.489 µs/char)**. Geometry
  costs **5.7× more per byte** than the 500 KB fixture because its 13 845 math
  spans drive `_InlineScanner.scan`'s per-line regex battery far harder. So:
  linear in bytes asymptotically, but the constant is set by per-line inline
  structure — a density-dependent, not a size-dependent, term.
* **`highlightSyncCold` is O(lines), not O(bytes), and does not tokenize.**
  0.865 / 3.402 / 1.659 ms tracks lines (6 289 / 15 304 / 10 332), and the
  931 k-char note is *cheaper* than the 513 k one because it has fewer lines.
  This is the lazy open path: it builds the `_Line` list and defers all
  tokenization to `lineAt`, which is why first frame is O(visible).
* **First frame: O(visible).** 15.9 / 12.6 / 9.3 ms — independent of size.

### 13.3.2 WYSIWYG

* **Codec decode: O(blocks + inline nodes), byte count is *not* the driver —
  and the 500 KB fixture is the worst case, worse than the 934 KB note.**
  Per-char cost 1.732 µs/char at 206 KB, **4.689 µs/char at 513 KB** (2.7×
  worse), 1.100 µs/char at 931 KB. The 931 k-char geometry note decodes in
  1 025 ms while the 513 k-char fixture takes 2 408 ms. The 500 KB fixture
  produces **16 496 delta ops** from 15 304 lines of ordinary prose/lists; the
  geometry note produces only **7 036 ops but 2 934 opaque embeds** — its large
  `$$` blocks travel verbatim as one embed each, which is cheap. Decode cost
  is per-block/per-inline-node: `splitMarkdownBlocks` + a full `markdown` parse
  + `_blockOps`/`_inlineOps` per node. Worst measured: **2.41 s for 513 KB**.
* **Encode canonical: O(ops), cheap** — 5.1 / 6.3 / 5.3 ms for 6.6 k / 16.5 k /
  7.0 k ops. The edited-emit path is not the problem.
* **Encode fast-path: O(document)** — 7.9 / 25.5 / 28.6 ms. Paid on every
  debounced emit and on every `didUpdateWidget` with changed `data` (line 337),
  i.e. potentially once per parent rebuild while the note is open.
* **Widget keystroke: O(bytes), not O(visible).** 14.552 ms at 102 400 chars →
  47.334 ms at 204 800 chars: **3.25× the time for 2× the bytes**, per-char cost
  rising 0.142 → 0.231 µs. Quill has no windowing (the code says so itself,
  `wysiwyg_editor.dart:91–92`); `replaceText` re-lays out the document. Against
  the source editor's 0.3 ms this is **~50× slower at 102 KB and ~160× at
  205 KB**, and a different complexity class — the single most important
  finding for the replacement.
* **The cap is not an open-cost guard.** 2 741 ms to mount at 513 423 chars and
  1 178 ms at 931 042 chars, both producing **no Quill editor** — pure codec
  decode discarded after the fact. Over-cap open cost is the decode curve above.

### 13.3.3 Preview

* **Block phase: O(lines), ~3.6–4.1 µs/line.** 24.4 ms / 6 289 lines,
  54.8 / 15 304, 42.8 / 10 332. It runs off the UI isolate; the wall round trip
  including a fresh `Isolate.spawn` is 26.2 / 64.0 / 49.9 ms, so the UI thread
  pays none of it.
* **First frame: O(visible)** — 14.6–29.0 ms, no growth with size (skeleton
  sliver, 12 bars, lazily laid out).
* **First visible content: bounded async**, 137–182 ms wall, dominated by the
  isolate round trip plus the content frame; the 500 KB fixture again slowest.
* **Scroll-to-middle: O(blocks laid out).** 34–71 ms landing, 18–44 ms settle,
  roughly size-independent because the scroll map + `SliverVariedExtentList`
  lay out only the blocks the jump lands on. Note the landing frame (35–71 ms)
  is above one 16.7 ms frame — pre-existing, and not addressed by windowing.
* **Stats: O(bytes)** — word count + outline, off-thread: 8.0 / 22.0 / 38.0 ms.
  Deliberately not charged to the first frame (`preview_work.dart`).

### 13.3.4 Math

* **Render: O(N) with ~0.04–0.11 ms per expression (warm)**, and O(1) engine
  warm-up after the first font table load. N10 0.038, N50 0.083, N200 0.077
  best ms/expr; totals scale linearly (0.38 → 4.14 → 15.34 ms).
* **Cache hit: O(1), ~0.007–0.016 ms** vs a 0.077–0.214 ms miss — a **5–20×**
  gap at the N used, and the cache is what makes a math note tractable:
  geometry repeats formulas, so at N=200 only 115 of 200 spans are real misses
  (miss ratio 0.575). The LRU is capacity 512 (`math_cache.dart:36`).
* **Paint: O(1)/formula** — 0.19 ms.
* Nothing here is a scalability wall even for 13 845 spans: with the cache, the
  whole note is on the order of a second of typesetting *spread across the
  viewport*, and that is already deferred during scroll (`MathDeferScope`).

---

## 13.4 Headline table the new implementation must beat

Same units, same fixtures, debug harness — **best** and **median** where a
distribution exists.

| Metric | Fixture | Incumbent best | Incumbent median | Class |
|---|---|---|---|---|
| Source keystroke, mid-doc 1 char, incl. tokenizer sync | `200kb` | **0.296 ms** | 0.319 ms | O(1) |
| Source keystroke | `500kb` | **0.277 ms** | 0.357 ms | O(1) |
| Source keystroke | `geo934kb` | **0.372 ms** | 0.458 ms | O(1) |
| Source keystroke + one paint frame | `200kb` | 3.712 ms | 5.500 ms | O(visible) |
| Source first frame | any | 9.3–15.9 ms | — | O(visible) |
| Source tokenize from cold | `500kb` | 43.835 ms | 48.279 ms | O(bytes) |
| Source tokenize from cold | `geo934kb` | 455.168 ms | 459.845 ms | O(bytes·density) |
| WYSIWYG open — codec decode only | `200kb` | 357.169 ms | 388.222 ms | O(blocks+nodes) |
| WYSIWYG open — codec decode only | `500kb` | **2 407.714 ms** | 2 459.340 ms | O(blocks+nodes) |
| WYSIWYG open — codec decode only | `geo934kb` | 1 024.597 ms | 1 047.918 ms | O(blocks+nodes) |
| WYSIWYG full first frame (opens) | 204 800 ch | **2 214.908 ms** | — | O(bytes) |
| WYSIWYG refuse frame (decode still paid) | 513 423 ch | 2 741.169 ms | — | O(blocks+nodes) |
| WYSIWYG keystroke | 102 400 ch | **14.552 ms** | 17.693 ms | O(bytes) |
| WYSIWYG keystroke | 204 800 ch | **47.334 ms** | 57.455 ms | O(bytes) |
| WYSIWYG emit after edit (encode fast-path) | 513 423 ch | 25.493 ms | 26.551 ms | O(bytes) |
| Preview first frame (skeleton) | any | 14.6–29.0 ms | — | O(visible) |
| Preview first visible content (blank wait) | any | **136.6–182.5 ms** | — | async isolate |
| Preview off-thread block parse (wall) | `500kb` | 63.988 ms | 72.651 ms | O(lines) |
| Preview scroll-to-middle landing frame | any | 34.196–70.755 ms | — | O(visible blocks) |
| Preview stats, off-thread | `500kb` | 21.953 ms | 22.731 ms | O(bytes) |
| Math render, cache miss | per expr | 0.077–0.109 ms | 0.109 ms | O(1)/expr |
| Math render, cache hit | per expr | 0.007 ms | — | O(1) |
| Math paint | per expr | 0.192 ms | — | O(1)/expr |

One-line contract: **any new surface must edit at ≤0.5 ms/keystroke on a
931 KB note, open all three fixtures with no codec round trip, and make
WYSIWYG-grade editing O(visible) — the incumbent's 14.6 ms/keystroke at 102 KB
and 47.3 ms at 205 KB, plus its 2.4 s 500 KB decode, are the numbers to beat.**

---

## 13.5 Reproducibility

### 13.5.1 Exact commands

Run from the repo root, on Linux, with Flutter 3.47.2 on `PATH`.

```sh
mkdir -p /tmp/niman-research/logs
cd /home/alessandro/Projects/Niman

# analysis (scratch file must be in test/unit/)
dart analyze test/unit/_bench_incumbent_scratch_test.dart

# one group at a time; --plain-name matches the group name in the test name
timeout -k 5 400 flutter test test/unit/_bench_incumbent_scratch_test.dart \
  --plain-name "fixtures"        -r expanded > /tmp/niman-research/logs/source-fixtures.log 2>&1
timeout -k 5 600 flutter test test/unit/_bench_incumbent_scratch_test.dart \
  --plain-name "source"          -r expanded > /tmp/niman-research/logs/source.log 2>&1
timeout -k 5 700 flutter test test/unit/_bench_incumbent_scratch_test.dart \
  --plain-name "wysiwyg-codec"   -r expanded > /tmp/niman-research/logs/wysiwyg-codec.log 2>&1
timeout -k 5 900 flutter test test/unit/_bench_incumbent_scratch_test.dart \
  --plain-name "wysiwyg-widget"  -r expanded > /tmp/niman-research/logs/wysiwyg-widget.log 2>&1
timeout -k 5 800 flutter test test/unit/_bench_incumbent_scratch_test.dart \
  --plain-name "preview"         -r expanded > /tmp/niman-research/logs/preview.log 2>&1
timeout -k 5 700 flutter test test/unit/_bench_incumbent_scratch_test.dart \
  --plain-name "math"            -r expanded > /tmp/niman-research/logs/math.log 2>&1

# read the numbers without dumping the log
grep -hE '^(BENCH|NOTE)\|' /tmp/niman-research/logs/*.log | sort -u
```

The existing `test/unit/m2_spike_benchmark_test.dart` was **not** modified and
still runs green (`flutter test test/unit/m2_spike_benchmark_test.dart`); its
200 KB tokenize/edit numbers are the cross-check quoted in §13.2.1. Note that it
imports `flutter_smooth_markdown`, which is a declared-but-dead dependency; it
was left exactly as found.

### 13.5.2 The scratch test file, quoted in full

This file was created at `test/unit/_bench_incumbent_scratch_test.dart`, run as
above, and **deleted** before this report was finished. It never touched `lib/`
and was never committed. Recreate it exactly at that path to reproduce every
number in §13.2.

```dart
// SCRATCH BENCH for the incumbent Markdown surface. DELETE BEFORE FINISHING.
//
// Prints timings only; never asserts on a duration, so it stays green on any
// machine. Every metric is one pipe-separated line:
//
//   BENCH|<component>|<fixture>|<metric>|<stat>|<value>|<unit>
//
// Run: flutter test test/unit/_bench_incumbent_scratch_test.dart
//      [--plain-name "<group>"] -r expanded
//
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' show Canvas, PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:katex/katex.dart';
import 'package:katex_dart/katex_dart.dart' show BoxNode, KatexOptions, renderToBox;
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/editor/highlight_sync.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:niman/src/preview/block_parse.dart';
import 'package:niman/src/preview/markdown_preview.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_syntax.dart';
import 'package:niman/src/preview/preview_work.dart';
import 'package:niman/src/preview/scroll_map.dart';
import 'package:re_editor/re_editor.dart';

/// Every measurement gets 180 s; a timeout is reported as a finding.
const Timeout _limit = Timeout(Duration(seconds: 180));

const Map<String, String> _fixtures = <String, String>{
  '200kb': 'test/fixtures/markdown/fixture-200kb.md',
  '500kb': 'test/fixtures/markdown/fixture-500kb.md',
  'geo934kb': 'Geometria 1.md',
};

/// WYSIWYG refuses above this; kept in sync with the constant by hand.
const int kCapBytes = 200 * 1024;

void row(
  String component,
  String fixture,
  String metric,
  String stat,
  num value,
  String unit,
) => print(
  'BENCH|$component|$fixture|$metric|$stat|'
  '${value.toStringAsFixed(3)}|$unit',
);

void note(String component, String fixture, String text) =>
    print('NOTE|$component|$fixture|$text');

String load(String key) => File(_fixtures[key]!).readAsStringSync();

/// Best and nearest-rank median of [times].
({Duration best, Duration median}) stats(List<Duration> times) {
  final sorted = List<Duration>.of(times)..sort();
  return (best: sorted.first, median: sorted[sorted.length ~/ 2]);
}

void report(String component, String fixture, String metric, List<Duration> t) {
  final s = stats(t);
  row(component, fixture, metric, 'best', s.best.inMicroseconds / 1000.0, 'ms');
  row(
    component,
    fixture,
    metric,
    'median',
    s.median.inMicroseconds / 1000.0,
    'ms',
  );
}

/// A collapsed caret in the middle of [text]'s middle line.
({int line, int offset}) midCaret(CodeLineEditingController c) {
  final line = c.codeLines.length ~/ 2;
  return (line: line, offset: c.codeLines[line].text.length ~/ 2);
}

/// One typed character at [at], then an undo outside the timed window.
Duration typeOnce(CodeLineEditingController c, ({int line, int offset}) at) {
  c.selection = CodeLineSelection.collapsed(index: at.line, offset: at.offset);
  final sw = Stopwatch()..start();
  c.replaceSelection('X');
  sw.stop();
  c.selection = CodeLineSelection(
    baseIndex: at.line,
    baseOffset: at.offset,
    extentIndex: at.line,
    extentOffset: at.offset + 1,
  );
  c.replaceSelection('');
  return sw.elapsed;
}

Widget _preview(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(height: 800, child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Warm the text engine: the very first TextPainter load is not a measurement.
  final warm = Stopwatch()..start();
  {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = const TextSpan(text: 'warmup', style: TextStyle(fontSize: 13))
      ..layout()
      ..paint(canvas, Offset.zero);
    painter.dispose();
    recorder.endRecording();
  }
  note('env', 'all', 'text-engine warmup ${warm.elapsedMilliseconds} ms');

  // ---------------------------------------------------------------- fixtures
  group('fixtures', () {
    test('sizes', () {
      for (final entry in _fixtures.entries) {
        final raw = load(entry.key);
        final lines = '\n'.allMatches(raw).length + 1;
        row('fixture', entry.key, 'chars', '-', raw.length, 'chars');
        row('fixture', entry.key, 'lines', '-', lines, 'lines');
        row(
          'fixture',
          entry.key,
          'mathSpans',
          '-',
          mathSpansIn(raw).length,
          'spans',
        );
        final spans = mathSpansIn(raw);
        row(
          'fixture',
          entry.key,
          'mathBlockSpans',
          '-',
          spans.where((s) => s.block).length,
          'spans',
        );
        row(
          'fixture',
          entry.key,
          'mathInlineSpans',
          '-',
          spans.where((s) => !s.block).length,
          'spans',
        );
      }
      row('fixture', 'cap', 'maxWysiwygBytes', '-', kCapBytes, 'chars');
    });
  });

  // ------------------------------------------------------ 1. SOURCE EDITOR
  group('source', () {
    for (final key in _fixtures.keys) {
      test('tokenize-cold $key', timeout: _limit, () {
        final raw = load(key);
        final times = <Duration>[];
        for (var i = 0; i < 3; i++) {
          final sw = Stopwatch()..start();
          final doc = HighlightDocument.fromText(raw);
          sw.stop();
          times.add(sw.elapsed);
          if (doc.lineCount < 0) throw StateError('unreachable');
        }
        report('source', key, 'tokenizeCold', times);
      });

      test('sync-cold $key', timeout: _limit, () {
        final raw = load(key);
        final times = <Duration>[];
        for (var i = 0; i < 3; i++) {
          final c = CodeLineEditingController.fromText(raw);
          final sync = EditorHighlightSync();
          final sw = Stopwatch()..start();
          sync.onBufferChanged(c.value.codeLines);
          sw.stop();
          times.add(sw.elapsed);
          c.dispose();
        }
        report('source', key, 'highlightSyncCold', times);
      });

      test('tokenizer-edit $key', timeout: _limit, () {
        final raw = load(key);
        final doc = HighlightDocument.fromText(raw);
        final at = raw.length ~/ 2;
        final lineStart = raw.substring(0, at).lastIndexOf('\n') + 1;
        final times = <Duration>[];
        for (var i = 0; i < 5; i++) {
          final sw = Stopwatch()..start();
          doc.replace(lineStart, lineStart + 1, 'X');
          sw.stop();
          times.add(sw.elapsed);
          doc.replace(lineStart, lineStart + 1, raw.substring(lineStart, lineStart + 1));
        }
        report('source', key, 'tokenizerEdit', times);
      });

      test('keystroke $key', timeout: _limit, () {
        final raw = load(key);
        final c = CodeLineEditingController.fromText(raw);
        final sync = EditorHighlightSync();
        c.addListener(() => sync.onBufferChanged(c.value.codeLines));
        sync.onBufferChanged(c.value.codeLines);
        final at = midCaret(c);
        final times = <Duration>[
          for (var i = 0; i < 5; i++) typeOnce(c, at),
        ];
        report('source', key, 'keystrokeFullChain', times);
        c.dispose();
      });
    }

    for (final key in <String>['200kb', '500kb', 'geo934kb']) {
      testWidgets('first-frame $key', timeout: _limit, (tester) async {
        final raw = load(key);
        // Warm the editor path with a tiny note first: the very first mount
        // pays one-time font/theme/expando setup that is not a document cost.
        final warmC = CodeLineEditingController.fromText('warm');
        final warmF = FocusNode();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: NoteEditor(controller: warmC, focusNode: warmF)),
          ),
        );
        await tester.pump();
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
        warmC.dispose();
        warmF.dispose();
        final c = CodeLineEditingController.fromText(raw);
        final sync = EditorHighlightSync();
        sync.onBufferChanged(c.value.codeLines);
        final focus = FocusNode();
        final sw = Stopwatch()..start();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NoteEditor(controller: c, focusNode: focus),
            ),
          ),
        );
        sw.stop();
        row(
          'source',
          key,
          'firstFrame',
          'best',
          sw.elapsed.inMicroseconds / 1000.0,
          'ms',
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
        c.dispose();
        focus.dispose();
      });
    }

    testWidgets('first-frame-keystroke-paint 200kb', timeout: _limit, (
      tester,
    ) async {
      final raw = load('200kb');
      final c = CodeLineEditingController.fromText(raw);
      final sync = EditorHighlightSync();
      c.addListener(() => sync.onBufferChanged(c.value.codeLines));
      sync.onBufferChanged(c.value.codeLines);
      final focus = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: NoteEditor(controller: c, focusNode: focus)),
        ),
      );
      await tester.pump();
      final at = midCaret(c);
      final times = <Duration>[];
      for (var i = 0; i < 5; i++) {
        c.selection = CodeLineSelection.collapsed(
          index: at.line,
          offset: at.offset,
        );
        final sw = Stopwatch()..start();
        c.replaceSelection('X');
        await tester.pump();
        sw.stop();
        times.add(sw.elapsed);
        c.selection = CodeLineSelection(
          baseIndex: at.line,
          baseOffset: at.offset,
          extentIndex: at.line,
          extentOffset: at.offset + 1,
        );
        c.replaceSelection('');
        await tester.pump();
      }
      report('source', '200kb', 'keystrokePlusPaint', times);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump();
      c.dispose();
      focus.dispose();
    });
  });

  // ---------------------------------------------------------- 2. WYSIWYG
  group('wysiwyg-codec', () {
    for (final key in _fixtures.keys) {
      test('decode $key', timeout: _limit, () {
        final raw = load(key);
        const codec = MarkdownDocumentCodec();
        final times = <Duration>[];
        DecodedNote? last;
        for (var i = 0; i < 3; i++) {
          final sw = Stopwatch()..start();
          last = codec.decode(raw);
          sw.stop();
          times.add(sw.elapsed);
        }
        report('wysiwyg', key, 'codecDecode', times);
        note(
          'wysiwyg',
          key,
          'deltaOps=${last!.snapshot.length} '
          'embeds=${last.snapshot.where((o) => o['insert'] is Map).length}',
        );
      });

      test('encode-canonical $key', timeout: _limit, () {
        final raw = load(key);
        const codec = MarkdownDocumentCodec();
        final decoded = codec.decode(raw);
        final times = <Duration>[];
        for (var i = 0; i < 3; i++) {
          final sw = Stopwatch()..start();
          codec.encode(decoded.document);
          sw.stop();
          times.add(sw.elapsed);
        }
        report('wysiwyg', key, 'codecEncodeCanonical', times);
      });

      test('encode-fastpath $key', timeout: _limit, () {
        final raw = load(key);
        const codec = MarkdownDocumentCodec();
        final decoded = codec.decode(raw);
        final times = <Duration>[];
        for (var i = 0; i < 3; i++) {
          final sw = Stopwatch()..start();
          final out = codec.encode(decoded.document, decoded: decoded);
          sw.stop();
          times.add(sw.elapsed);
          if (!identical(out, raw) && out != raw) {
            note('wysiwyg', key, 'WARNING fast path did not return source');
          }
        }
        report('wysiwyg', key, 'codecEncodeFastPath', times);
      });
    }
  });

  group('wysiwyg-widget', () {
    // The largest source the widget will actually open, and the boundary.
    const underCap = 204800; // == _maxWysiwygBytes, opens
    const overCap = 204801; // one past, refuses in build()

    String slice(String raw, int n) =>
        raw.length <= n ? raw : raw.substring(0, n);

    testWidgets('cap-boundary', timeout: _limit, (tester) async {
      final raw = load('200kb');
      note('wysiwyg', 'cap', 'fixture-200kb.length=${raw.length} '
          'cap=$kCapBytes over=${raw.length > kCapBytes}');
      for (final n in <int>[underCap, overCap]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WysiwygEditor(data: slice(raw, n), onChanged: (_) {}),
            ),
          ),
        );
        await tester.pump();
        final opens = find.byType(quill.QuillEditor).evaluate().isNotEmpty;
        row('wysiwyg', 'cap$n', 'opens', '-', opens ? 1 : 0, 'bool');
        note(
          'wysiwyg',
          'cap$n',
          'slice=${slice(raw, n).length} QuillEditor=${opens ? 'yes' : 'no'}',
        );
      }
    });

    for (final n in <int>[underCap, 100 * 1024, overCap]) {
      testWidgets('mount-$n', timeout: _limit, (tester) async {
        final raw = load('200kb');
        final data = slice(raw, n);
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
        final sw = Stopwatch()..start();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WysiwygEditor(data: data, onChanged: (_) {}),
            ),
          ),
        );
        sw.stop();
        row(
          'wysiwyg',
          'slice$n',
          'firstFrame',
          'best',
          sw.elapsed.inMicroseconds / 1000.0,
          'ms',
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
      });
    }

    for (final key in <String>['500kb', 'geo934kb']) {
      testWidgets('mount-overcap-$key', timeout: _limit, (tester) async {
        final raw = load(key);
        // Warm the widget path first so the one-time load is not measured.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WysiwygEditor(data: '# warm\n', onChanged: (_) {}),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
        final sw = Stopwatch()..start();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WysiwygEditor(data: raw, onChanged: (_) {}),
            ),
          ),
        );
        sw.stop();
        final opens = find.byType(quill.QuillEditor).evaluate().isNotEmpty;
        row(
          'wysiwyg',
          'overcap-$key',
          'firstFrame',
          'best',
          sw.elapsed.inMicroseconds / 1000.0,
          'ms',
        );
        row('wysiwyg', 'overcap-$key', 'opens', '-', opens ? 1 : 0, 'bool');
        note(
          'wysiwyg',
          'overcap-$key',
          'chars=${raw.length} overCap=${raw.length > kCapBytes} '
          'QuillEditor=${opens ? 'yes' : 'no'} '
          '(decode still runs in initState)',
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
      });
    }

    for (final n in <int>[underCap, 100 * 1024]) {
      testWidgets('keystroke-$n', timeout: _limit, (tester) async {
        final raw = load('200kb');
        final data = slice(raw, n);
        final key = GlobalKey<WysiwygEditorState>();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WysiwygEditor(
                key: key,
                data: data,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();
        final controller = key.currentState!.controller;
        final at = controller.document.length ~/ 2;
        final times = <Duration>[];
        for (var i = 0; i < 5; i++) {
          controller.updateSelection(
            TextSelection.collapsed(offset: at),
            quill.ChangeSource.local,
          );
          final sw = Stopwatch()..start();
          controller.replaceText(
            at,
            0,
            'X',
            TextSelection.collapsed(offset: at + 1),
          );
          sw.stop();
          times.add(sw.elapsed);
          controller.replaceText(
            at,
            1,
            '',
            TextSelection.collapsed(offset: at),
          );
        }
        report('wysiwyg', 'slice$n', 'keystroke', times);
        // The debounced emit: the codec writes the edited document back.
        final decoded = MarkdownDocumentCodec().decode(data);
        controller.replaceText(
          at,
          0,
          'X',
          TextSelection.collapsed(offset: at + 1),
        );
        const codec = MarkdownDocumentCodec();
        final sw = Stopwatch()..start();
        codec.encode(controller.document, decoded: decoded);
        sw.stop();
        row(
          'wysiwyg',
          'slice$n',
          'emitAfterEdit',
          'best',
          sw.elapsed.inMicroseconds / 1000.0,
          'ms',
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
      });
    }
  });

  // ------------------------------------------------------------ 3. PREVIEW
  group('preview', () {
    for (final key in _fixtures.keys) {
      test('block-parse $key', timeout: _limit, () {
        final raw = load(key);
        final src = stripFrontmatter(raw);
        final times = <Duration>[];
        for (var i = 0; i < 3; i++) {
          final sw = Stopwatch()..start();
          parseBlockPhase(src);
          sw.stop();
          times.add(sw.elapsed);
        }
        report('preview', key, 'parseBlockPhase', times);
      });

      test('offthread-parse $key', timeout: _limit, () async {
        final raw = load(key);
        final src = stripFrontmatter(raw);
        final times = <Duration>[];
        for (var i = 0; i < 3; i++) {
          final sw = Stopwatch()..start();
          final result = await PreviewWork.run('parse', src);
          sw.stop();
          times.add(sw.elapsed);
          if (result is! BlockPhase) {
            note('preview', key, 'offthread parse FAILED: $result');
          }
        }
        report('preview', key, 'offthreadParseWall', times);
      });

      test('stats-offthread $key', timeout: _limit, () async {
        final raw = load(key);
        final times = <Duration>[];
        for (var i = 0; i < 3; i++) {
          final sw = Stopwatch()..start();
          await PreviewWork.run('stats', raw);
          sw.stop();
          times.add(sw.elapsed);
        }
        report('preview', key, 'statsWall', times);
      });

      testWidgets('first-frame $key', timeout: _limit, (tester) async {
        final raw = load(key);
        // Warm the preview path with a tiny note first.
        await tester.pumpWidget(
          _preview(const MarkdownPreview(data: '# warm\n\nA paragraph.\n')),
        );
        await tester.pump();
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
        final sw = Stopwatch()..start();
        await tester.pumpWidget(
          _preview(
            MarkdownPreview(
              key: ValueKey<String>(key),
              data: raw,
              scrollMap: ScrollMap(),
            ),
          ),
        );
        sw.stop();
        row(
          'preview',
          key,
          'firstFrameSkeleton',
          'best',
          sw.elapsed.inMicroseconds / 1000.0,
          'ms',
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
      });

      testWidgets('blank-wait $key', timeout: _limit, (tester) async {
        final raw = load(key);
        final sw = Stopwatch()..start();
        await tester.pumpWidget(
          _preview(MarkdownPreview(data: raw, scrollMap: ScrollMap())),
        );
        await tester.pump();
        final firstFrame = sw.elapsed;
        var frames = 1;
        var settled = false;
        try {
          await tester.runAsync(() async {
            for (var i = 0; i < 6000; i++) {
              if (find
                  .byKey(const ValueKey<String>('previewSkeleton'))
                  .evaluate()
                  .isEmpty) {
                settled = true;
                break;
              }
              await Future<void>.delayed(const Duration(milliseconds: 5));
              await tester.pump();
              frames++;
            }
          });
        } on Object catch (error) {
          note('preview', key, 'blank-wait loop failed: $error');
        }
        final total = sw.elapsed;
        row(
          'preview',
          key,
          'firstFrameSkeleton',
          'best',
          firstFrame.inMicroseconds / 1000.0,
          'ms',
        );
        if (settled) {
          row(
            'preview',
            key,
            'firstVisibleContentWall',
            'best',
            total.inMicroseconds / 1000.0,
            'ms',
          );
          row('preview', key, 'blankWait', 'best', total.inMicroseconds / 1000.0, 'ms');
          note('preview', key, 'blank wait polled in $frames pumps');
        } else {
          note('preview', key, 'DID NOT reach visible content within 30 s poll');
        }
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump();
      });

      testWidgets('scroll-middle $key', timeout: _limit, (tester) async {
        final raw = load(key);
        final map = ScrollMap();
        final scroll = ScrollController();
        await tester.pumpWidget(
          _preview(
            MarkdownPreview(data: raw, scrollMap: map, controller: scroll),
          ),
        );
        await tester.pump();
        var settled = false;
        await tester.runAsync(() async {
          for (var i = 0; i < 6000; i++) {
            if (find
                .byKey(const ValueKey<String>('previewSkeleton'))
                .evaluate()
                .isEmpty) {
              settled = true;
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 5));
            await tester.pump();
          }
        });
        if (!settled) {
          note('preview', key, 'scroll: no content, skipped');
          return;
        }
        await tester.pump();
        await tester.pump();
        if (!scroll.hasClients) {
          note('preview', key, 'scroll: no clients, skipped');
          return;
        }
        final max = scroll.position.maxScrollExtent;
        row('preview', key, 'maxScrollExtent', '-', max, 'px');
        final sw = Stopwatch()..start();
        scroll.jumpTo(max / 2);
        await tester.pump();
        sw.stop();
        row(
          'preview',
          key,
          'scrollToMiddleFrame',
          'best',
          sw.elapsed.inMicroseconds / 1000.0,
          'ms',
        );
        final sw2 = Stopwatch()..start();
        await tester.pump();
        sw2.stop();
        row(
          'preview',
          key,
          'scrollToMiddleSecondFrame',
          'best',
          sw2.elapsed.inMicroseconds / 1000.0,
          'ms',
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        await tester.pump(const Duration(milliseconds: 200));
        scroll.dispose();
      });
    }
  });

  // --------------------------------------------------------------- 4. MATH
  group('math', () {
    const sizes = <int>[1, 10, 50, 200];

    List<String> texes(int n) {
      final raw = load('geo934kb');
      final spans = mathSpansIn(raw);
      final out = <String>[];
      for (final span in spans) {
        var body = raw.substring(span.start, span.end).trim();
        if (body.startsWith(r'$$')) body = body.substring(2);
        if (body.endsWith(r'$$')) body = body.substring(0, body.length - 2);
        if (body.startsWith(r'$')) body = body.substring(1);
        if (body.endsWith(r'$')) body = body.substring(0, body.length - 1);
        body = body.trim();
        if (body.isEmpty) continue;
        out.add(body);
        if (out.length >= n) break;
      }
      return out;
    }

    test('expression-count', timeout: _limit, () {
      final raw = load('geo934kb');
      row('math', 'geo934kb', 'mathSpans', '-', mathSpansIn(raw).length, 'spans');
      row('math', 'geo934kb', 'usableTex200', '-', texes(200).length, 'tex');
      note('math', 'geo934kb', 'first tex: ${texes(1).first}');
    });

    for (final n in sizes) {
      test('render-N$n', timeout: _limit, () async {
        final tex = texes(n);
        // Warm katex's engine/font tables once; the N1 run otherwise pays
        // ~25 ms of one-time setup that is not a per-expression cost.
        renderToBox('x', options: const KatexOptions(displayMode: false));
        final coldTimes = <Duration>[];
        final hitTimes = <Duration>[];
        var misses = 0;
        var hits = 0;
        for (var rep = 0; rep < 3; rep++) {
          final cache = MathCache();
          var sw = Stopwatch()..start();
          for (final t in tex) {
            await cache.ensure(t, displayMode: false);
          }
          sw.stop();
          coldTimes.add(sw.elapsed);
          misses = cache.misses;
          sw = Stopwatch()..start();
          for (final t in tex) {
            await cache.ensure(t, displayMode: false);
          }
          sw.stop();
          hitTimes.add(sw.elapsed);
          hits = cache.hits;
          cache.dispose();
        }
        final per = tex.isEmpty ? 1 : tex.length;
        report('math', 'N$n', 'renderColdTotal', coldTimes);
        row(
          'math',
          'N$n',
          'renderColdPerExpr',
          'best',
          stats(coldTimes).best.inMicroseconds / 1000.0 / per,
          'ms',
        );
        row(
          'math',
          'N$n',
          'renderColdPerExpr',
          'median',
          stats(coldTimes).median.inMicroseconds / 1000.0 / per,
          'ms',
        );
        report('math', 'N$n', 'cacheHitTotal', hitTimes);
        row(
          'math',
          'N$n',
          'cacheHitPerExpr',
          'best',
          stats(hitTimes).best.inMicroseconds / 1000.0 / per,
          'ms',
        );
        row('math', 'N$n', 'cacheMisses', '-', misses, 'count');
        row('math', 'N$n', 'cacheHits', '-', hits, 'count');
        row(
          'math',
          'N$n',
          'missRatio',
          '-',
          per == 0 ? 0 : misses / per,
          'ratio',
        );
      });
    }

    test('render-via-math-syntax-200', timeout: _limit, () async {
      final tex = texes(200);
      final source = tex.map((t) => 'math \$$t\$ here\n\n').join();
      final sw = Stopwatch()..start();
      final phase = parseBlockPhase(source);
      final doc = makeDocument();
      prepareInlines(doc, phase);
      final elements = <String>[];
      void collect(md.Node n) {
        if (n is! md.Element) return;
        if (n.tag == 'math' || n.tag == 'mathblock') {
          final latex = n.attributes['latex'];
          if (latex != null) elements.add(latex);
        }
        for (final child in n.children ?? const <md.Node>[]) {
          collect(child);
        }
      }

      for (final node in phase.nodes) {
        for (final n in withInlines(doc, node)) {
          collect(n);
        }
      }
      sw.stop();
      row(
        'math',
        'viaSyntax200',
        'parseToMathElements',
        'best',
        sw.elapsed.inMicroseconds / 1000.0,
        'ms',
      );
      row('math', 'viaSyntax200', 'mathElements', '-', elements.length, 'count');
      final cache = MathCache();
      final sw2 = Stopwatch()..start();
      for (final t in elements) {
        await cache.ensure(t, displayMode: false);
      }
      sw2.stop();
      row(
        'math',
        'viaSyntax200',
        'renderElementsTotal',
        'best',
        sw2.elapsed.inMicroseconds / 1000.0,
        'ms',
      );
      cache.dispose();
    });

    test('paint-200', timeout: _limit, () {
      final tex = texes(200);
      final boxes = <BoxNode>[
        for (final t in tex)
          renderToBox(t, options: const KatexOptions(displayMode: false)),
      ];
      final sw = Stopwatch()..start();
      for (final box in boxes) {
        final size = boxSizePxPadded(box, 15);
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        KatexBoxPainter(box, fontSize: 15, color: const Color(0xFF000000))
            .paint(canvas, size);
        recorder.endRecording();
      }
      sw.stop();
      row(
        'math',
        'paint200',
        'paintTotal',
        'best',
        sw.elapsed.inMicroseconds / 1000.0,
        'ms',
      );
    });

    test('cold-vs-warm-katex-1', timeout: _limit, () {
      final t = texes(1).first;
      final cold = <Duration>[];
      for (var i = 0; i < 5; i++) {
        final sw = Stopwatch()..start();
        renderToBox(t, options: const KatexOptions(displayMode: false));
        sw.stop();
        cold.add(sw.elapsed);
      }
      report('math', 'render1', 'renderToBox', cold);
    });
  });
}
```

### 13.5.3 Raw logs

Kept at `/tmp/niman-research/logs/`: `source-fixtures.log`, `source.log`,
`wysiwyg-codec.log`, `wysiwyg-widget.log`, `preview.log`, `math.log`,
`analyze-scratch.log`, and `ALL.txt` (all 182 `BENCH|`/`NOTE|` rows merged and
sorted). Every measurement in §13.2 appears there verbatim.

---

## 13.6 Caveats — why these numbers are not device reality

1. **Debug mode, kernel VM, no AOT.** `flutter test` runs the Dart VM with JIT
   and assertions; `flutter_quill`, `markdown` and `katex_dart` are all much
   faster AOT-compiled in a release/profile build. Absolute values here are
   inflated (the quill and markdown package code especially); only ratios
   between rows should be trusted. A release AOT run could change the *constant*
   by several × and it is not claimed otherwise.
2. **No GPU / raster measurements.** All times are wall-clock work on the
   platform thread inside the test binding: build + layout + paint *recording*.
   Rasterisation (Skia/Impeller on a real device) is not measured, so these
   numbers cannot show frame drops; a 47 ms quill `replaceText` is CPU work
   before any raster.
3. **Test-binding viewport, not a phone screen.** Widget tests use the default
   headless surface (800×600 logical, DPR 1; the preview wrapper pins height
   800). Text wrapping, line counts per block and "visible lines" all differ on
   a 1080×2400 phone, so the O(visible) terms scale with the device's viewport.
   The O(document) terms do not.
4. **First frame is best-of-1 by nature, with a tiny-document warm-up.** It
   cannot be repeated in place (the widget is already mounted). The pre-warm
   mount removes one-time font/theme/class-load cost but is a judgement call:
   without it the first fixture in a process read ~6× high. Read the first-frame
   column as "the document-attributable part", not "cold app start".
5. **The 5-rep keystroke includes JIT warm-up in rep 1**, and only the *best*
   and *median* are reported; the median is the honest "typical" figure in
   debug, the best is the JIT-optimised figure. Neither is a p99, and no
   keystroke was measured under contention.
6. **The blank-wait polling adds a quantisation of one 5 ms poll per frame**,
   and each `tester.pump()` inside `runAsync` is a real frame; the 137–182 ms
   figures are therefore upper bounds by up to ~10–15 ms. Real-device blank wait
   also includes file I/O (`PreviewWork` `read` task, ~44 ms for a 931 KB note
   per the source comment), which the widget test does not pay because the
   source string is already in memory.
7. **Math texes are the first N in document order**, which are systematically
   simpler than the tail (starts at `\mathbb{R}`, trivial fractions); the
   per-expression cost at the far end of `Geometria 1.md` is likely higher. The
   N=1 cold 2.6 ms font-table outlier is documented but excluded from the table
   by the one-time engine warm-up.
8. **`mathSpansIn` counts render sites, not unique formulas**: 13 845 spans
   collapse to far fewer unique texes (measured miss ratio 0.575 at N=200), so
   "math cost per note" is dominated by cache hits and is not 13 845 misses.
9. **Desktop x86_64 only.** Nothing here ran on Android (the primary target) or
   Windows; a mid-range phone's CPU is several × slower than this i5-13400F, and
   `flutter_quill`'s `replaceText` cost is CPU-bound, so the 47 ms debug figure
   at 205 KB is the row most likely to be worse, not better, on device.
10. **`Geometria 1.md` lives at the repo root and is not a test fixture**; it is
    read from a fixed path, so replaying this bench requires that file to exist
    with the same content.
11. **No OOM, crash, or timeout occurred.** All three fixtures completed every
    test; the 180 s per-test limit was never reached and no process was killed.
    The brief's "a crash at 934 KB is the headline number this project needs" is
    answered negatively: the incumbent does not crash at 934 KB, it *slowly
    refuses* in WYSIWYG (1.18 s decode) and runs cleanly in the source editor
    (0.37 ms keystroke) and preview (137 ms to visible content).

### What release numbers would take

* Build and run on real hardware: `flutter run --profile` (or `--release`) on a
  mid-range Android phone, Linux desktop and Windows, with the same three
  fixtures.
* Capture frame timings from `SchedulerBinding.instance.addTimingsCallback`
  (`FrameTiming.buildDuration` / `rasterDuration` / `totalSpan`), not
  `Stopwatch` around `pump` — this separates build from raster and gives real
  jank (`FrameTiming.totalSpan` > budget) instead of CPU work.
* Use `integration_test/` with the real app shell (`NoteView`, file I/O,
  spellcheck) rather than the isolated widgets benched here; the per-keystroke
  path in the app also runs save debouncing and stat timers that the isolated
  harness omits.
* Repeat each measurement ≥30× and report p50/p95/p99, and run on at least one
  low-end and one high-end Android device, since the quill decode/keystroke and
  the preview block phase are the rows most sensitive to device class.

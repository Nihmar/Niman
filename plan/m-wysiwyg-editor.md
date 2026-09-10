# WYSIWYG editor — a third writing surface

**Status:** Planned (not started) · **Depends on:** M2 (editor + preview), M6
(theming, text size) · **Branch:** `feat/wysiwyg-editor` · **Spec:**
*Requirements* (editor), [design.md](design.md)

A slice outside the M0→M7 chain (see [README](README.md)): it grows out of
writing comfort, not out of a milestone, and it depends on what M2 built
rather than on the next milestone.

## Purpose

Add a WYSIWYG writing surface that sits **between** the source editor
(`re_editor`) and the read-only preview, and make the three surfaces
independently configurable: pick which editor is active (source or WYSIWYG)
and whether the preview exists at all. The WYSIWYG editor is **never shown
side by side with the preview** — it already is a rendering, so the two
editing surfaces and the preview do not share the window as they do today.

Disk stays the source of truth: the note is a `.md` file, the WYSIWYG editor
reads and writes that same file through the existing save pipeline, and
nothing about the file format changes.

## Evaluation

### The problem in one line

The note on disk is **Markdown**; the candidate editors speak **Delta**. The
whole risk of this feature is the conversion in both directions, and the plan
is built around keeping it lossless rather than around the editor widget.

### Options

| Option | Markdown I/O | Fit with Copist | Verdict |
| --- | --- | --- | --- |
| **`flutter_quill` 11.5.1 + `markdown_quill` 4.3.0** | Converter does md→Delta and Delta→md, with custom syntaxes and custom embeds | Mature WYSIWYG on Android/desktop; Delta + embed API matches the opaque-block envelope below | **Recommended** |
| `super_editor` + `super_editor_markdown` | Markdown-native document model, both directions | Cleaner serialization, but a different world of widgets and a heavier adoption for the toolbar/find/spell surfaces; keep as the swap if the adapter shows Quill's fidelity is not enough | Fallback |
| `appflowy_editor` | Own document model, Markdown plugin | Rich, but a large dependency tree and less control over the exact block model | Rejected for now |
| `fleather` 1.28 | Delta like Quill, **no Markdown** | Cleaner core, smaller ecosystem, no migration path for the disk format | Rejected |
| Custom WYSIWYG on the existing `markdown` AST + `re_editor` | Perfect by construction | Month-scale, and it re-implements caret, selection, IME, embeds and tables | Rejected |

### Package facts (checked against pub.dev)

- **`flutter_quill` 11.5.1** — `sdk ^3.12.0`, `flutter >=3.44.0`. The project
  is on `sdk ^3.13.2` and Flutter 3.47.2, so it resolves. It already depends
  on `markdown ^7.1.0` (the project has `^7.3.1`) and on
  `flutter_quill_delta_from_html`.
- **`markdown_quill` 4.3.0** — `sdk >=3.1.6 <4.0.0`, `flutter >=3.16.0`,
  depends on `flutter_quill` + `markdown`. Exposes `MarkdownToDelta` and
  `DeltaToMarkdown`, both configurable (custom element→attribute maps and
  custom embeds). Documented limits: image alt text is dropped, block
  attributes are exclusive. Those limits are inputs to the envelope, not
  blockers.
- **`flutter_quill_extensions` 11.0.0** (optional) — image/video embeds; pulls
  `image_picker`/`video_player`/`quill_native_bridge`. Copist draws its own
  library-relative images, so this is only needed for the video case and can
  start out of the dependency set.
- Upstream's own warning (flutter_quill README): Delta/Markdown/HTML
  round-trips are **not** standard and storing Delta is preferred. Copist
  cannot store Delta — the file must stay Markdown — so the conversion is
  retired to a narrow, tested adapter instead of being trusted end to end.

### Verdict

Use **flutter_quill** as the editing widget, behind a Copist-owned
**Markdown adapter** with a **lossless envelope**:

1. The adapter parses the note with the same `markdown` package and GFM
   extension set the preview uses (fidelity to the preview, one parser to
   pin).
2. Blocks it can represent (paragraphs, headings, lists and task lists,
   quotes, fenced code, inline bold/italic/strike/underline/code/link) become
   Delta ops.
3. Blocks it cannot represent losslessly — YAML frontmatter, raw HTML and HTML
   tables, footnotes, display and inline math, wikilinks and embeds, anything
   with an info string it cannot keep — stay as **opaque embed blocks** that
   carry their original Markdown text, render read-only (or through the
   existing renderers), and serialize back **byte for byte**.
4. Only blocks the user actually edited are re-serialized; untouched blocks
   keep their original bytes. Opening a note and saving with no edit must
   reproduce the file exactly.

The adapter lives behind an interface (`MarkdownDocumentCodec`) so
`super_editor` (or any other engine) can replace Quill without touching the
shell, the settings or the save path.

## Current state

- **Source editor:** `ui/note_view.dart` owns a `CodeLineEditingController`
  and a `re_editor`-based `editor/note_editor.dart`; incremental highlighting
  (`editor/highlight_sync.dart`), folding, line numbers, find & replace,
  markdown editing helpers, word count and outline all read that controller.
- **Preview:** `preview/markdown_preview.dart` renders the same text
  windowed, with the scroll map and the two-way scroll sync
  (`ui/editor_preview_split.dart`).
- **Layout:** `PreviewLayoutMode` (auto = split ≥600 dp / switch below;
  fullScreen = switch at any width) is **app-wide** in `AppSettingsRepo`
  (`core/settings/library_settings.dart`, drift `app_settings`), with the
  split ratio. The shell chooses `splitPreview`/`showPreview` and puts the
  eye/layout controls in the note status row (wide) or the app bar (phone).
- **Editor settings** (line numbers, autofocus, link type, indent, toolbar
  layout, text scale) are **per library** in `LibraryConfig` /
  `.copist/settings.json`.
- The Markdown extras the app commits to: frontmatter YAML, GFM tables, task
  lists, footnotes, KaTeX math `$…$`/`$$…$$`, `[[wikilinks]]`,
  `![[embeds]]`, tags, fenced code with a language.

## The mode model

Two independent per-library settings plus the existing app-wide layout mode:

| Editor | Preview | Layout |
| --- | --- | --- |
| Source | On | Today: `auto` (split ≥600 dp, switch below) or `fullScreen` (switch) |
| Source | **Off** | Full-width source editor; no preview pane, no eye, no layout menu, no split ratio |
| WYSIWYG | On | **Never split**: the eye switches between the WYSIWYG editor and the read-only preview, full screen, at any width |
| WYSIWYG | **Off** | Full-width WYSIWYG editor |

Note-kind GUIs (`type:` notes, T-TK-02) keep winning over both editors, exactly
as they win over the source editor today.

## Tasks

- [ ] **T-WYS-01** Spike and pin: add `flutter_quill`, `markdown_quill` (and
  `flutter_quill_extensions` only if needed), and measure. Convert every
  `test/spec.json` example and a set of real Copist notes (frontmatter,
  tables, footnotes, math, wikilinks, embeds) md→Delta→md; record exactly
  what changes. Measure the Delta build and layout on a novel-length note.
  *AC: a written loss list and a large-note verdict, with exact package pins.*
- [ ] **T-WYS-02** Adapter: `editor/wysiwyg/markdown_document_codec.dart`
  behind an interface, with the opaque-block envelope and per-block dirty
  tracking. Unit tests: a no-edit open/save round trip is byte-stable over
  the CommonMark corpus and the app extras; editing one block leaves its
  neighbours' bytes untouched.
- [ ] **T-WYS-03** Settings and persistence: `editorKind` (source | wysiwyg)
  and `previewEnabled` (bool) in `LibraryConfig` + `.copist/settings.json`
  (defaults preserve today: source, preview on; older files read as the
  defaults). Settings rows under **Editor** and strings (en/it).
- [ ] **T-WYS-04** WYSIWYG widget: `editor/wysiwyg/wysiwyg_editor.dart` over
  `QuillController`, with the debounced save, focus, the note text size, and
  library-relative image/embed resolution; opens the note from the adapter
  and serializes on every save.
- [ ] **T-WYS-05** Layout: `note_view.dart` gets the third body; split is
  impossible with WYSIWYG; preview off removes the preview chrome everywhere
  (wide status row and phone app bar); the eye becomes switch-only when
  WYSIWYG + preview is on.
- [ ] **T-WYS-06** Control adaptation: the inventory below. The toolbar drives
  the active editor, the source-only controls hide, find/spell/folding are
  explicitly out of scope in the WYSIWYG surface, and the word count/outline
  read the active document.
- [ ] **T-WYS-07** Large-note guard: above a measured threshold the WYSIWYG
  surface offers the source editor instead of opening slowly (or refuses
  silently and logs). No windowing is promised for Quill.
- [ ] **T-WYS-08** Tests: codec round trips, settings round trip and defaults,
  widget tests for the mode matrix and for every control that must hide, and
  a device pass on Linux and Android.
- [ ] **T-WYS-09** Docs: this file's Status, the design.md editor section, and
  the spec's editor line.

## Technical design

### Modules

- `editor/wysiwyg/markdown_document_codec.dart` — interface
  `MarkdownDocumentCodec` (`decode` → document, `encode` → Markdown) plus
  the Quill implementation. No Flutter import in the envelope logic, so the
  codec is unit-testable without a widget tree.
- `editor/wysiwyg/opaque_block.dart` — the embed carrying the original
  Markdown and its type (frontmatter, html, footnote, math, wikilink, …).
- `editor/wysiwyg/wysiwyg_editor.dart` — the widget: `QuillController`,
  configuration, embed builders, save wiring.
- `editor/wysiwyg/quill_toolbar.dart` — maps the active `ToolbarItem` to a
  Quill format/command; the source toolbar keeps its current implementation.
- `core/settings/library_settings.dart` — `EditorKind` enum next to
  `PreviewLayoutMode`, and `previewSplits` grows an editor-kind argument so
  every caller asks one question.

### The codec (the load-bearing piece)

- **Decode:** split the source into top-level blocks (reuse the shape of
  `preview/scroll_map.dart`'s `BlockLocator` rather than inventing a second
  one), convert representable blocks to Delta, and wrap the rest in an opaque
  embed. Frontmatter is always opaque and kept verbatim.
- **Encode:** walk the Delta; representable runs become Markdown, opaque
  embeds emit their stored text unchanged. An edit inside a supported block
  rewrites only that block; every other block is emitted from its original
  bytes.
- **Invariant:** `encode(decode(source))` is byte-identical to `source` for
  every note that was not edited, checked in the test suite over the whole
  CommonMark corpus and the app's own extras.
- **No silent loss:** a construct the codec cannot map becomes an opaque
  block. If the codec is ever unsure, it must keep the source, not approximate
  it.

### Settings

`editorKind` and `previewEnabled` go in `LibraryConfig` (per library, like
line numbers, link type and the toolbar), not in the app-wide drift
`app_settings` where `previewMode`/split ratio live. Reasons: they are
writing preferences that belong to the library (a code-notes library may want
source, a prose one WYSIWYG), all the other editor toggles are already per
library, and it avoids a migration on `copist.db`'s long chain. The layout
mode stays app-wide, because it follows the screen.

When WYSIWYG is active the app-wide `auto` (split) is meaningless; the layout
menu hides and the effective mode is the full-screen switch. The stored value
is left alone, so switching back to the source restores the split the user
had.

### Layout rules

- `previewSplits(...)` returns false whenever `previewEnabled == false` or
  `editorKind == wysiwyg`. There is one place that decides; the shell, the
  settings screen and `note_view.dart` all ask it.
- NoteView body order: kind GUI → WYSIWYG (preview off) → WYSIWYG | preview
  switch → source split → source | preview switch.
- The split ratio row in Settings already guards on `previewSplits`; it
  inherits the new answer.

### Control inventory (what changes / hides)

| Control | Source + preview | WYSIWYG | Preview off |
| --- | --- | --- | --- |
| Eye toggle (`editor-preview-toggle`) | as today | switch only (no split) | hidden |
| Layout menu (`layout-mode`) | as today | hidden | hidden |
| Fullscreen preview action | switch mode only | available | n/a |
| Split divider (`EditorPreviewSplit`) | as today | never mounted | never mounted |
| Scroll sync (`ScrollSync`, `ScrollMap`, `EditorLineView`) | as today | not built | not built |
| Split-ratio settings row | shown when it splits | hidden | hidden |
| Formatting toolbar | markdown inserts | Quill formats; unsupported items hidden | as active editor |
| Edit-raw / kind actions | as today | as today | as today |
| Find & replace panel | as today | hidden in v1 | as today |
| Spell-check underlines | as today | hidden in v1 | as today (source) |
| Line numbers, folding, indent helpers, math rule | as today | hidden (Quill has its own) | as active editor |
| Status row word count | reads the source controller | reads the Quill document | reads the active editor |
| Outline panel | source headings | headings from the document model | as active editor |
| Keyboard shortcuts (bold, italic, …) | source activators | Quill's own | as active editor |
| Unsaved/close guard | controller revision | controller revision (same tracker) | as active editor |

Two of these are deliberate v1 cuts, called out as such: **find & replace** and
**spell-check underlines** are tied to `re_editor`'s span builder and find
controller. Re-implementing them on Quill is possible (a custom span
builder / a document search) but it is its own task; the WYSIWYG surface
ships without them and the plan records the debt rather than pretending they
carry over.

### Save pipeline

The WYSIWYG widget edits a `QuillController`; the codec serializes it to
Markdown on the existing debounce (≈500 ms, save-in-flight lengthening), on
focus loss and on hide — the same cadence and the same atomic write as the
source editor. `_lastSavedRevision`/the unsaved tracker are driven from the
Quill controller so the close guard keeps working. The preview text, the
outline and the word count all read the serialized Markdown, so they stay
correct while the WYSIWYG surface is active.

### Performance

Quill builds the whole document; the M2 windowed preview does not apply. The
spike (T-WYS-01) measures a novel-length note; T-WYS-07 turns the number into
a guard. The feature is opt-in per library, so a library that never selects
WYSIWYG pays nothing.

## Exit criteria

- A note can be written in the WYSIWYG surface with bold/italic/strike/
  underline, headings, lists and task lists, quotes, links, code and images;
  the saved `.md` is unchanged where the user did not edit.
- Opening and saving any unedited CommonMark example and any Copist note is
  byte-stable, including the constructs in the opaque envelope.
- Settings choose source vs WYSIWYG and preview on/off per library; the
  defaults reproduce today's behaviour exactly.
- WYSIWYG is never side by side with the preview; preview off removes every
  preview control; the control inventory above is implemented and tested.
- Unit + widget tests green; verified on Linux and Android.

## Risks / open questions

- **Fidelity is the whole feature.** If the spike shows the codec cannot keep
  a representative real note byte-stable, stop and reconsider (a Markdown-
  native engine such as `super_editor` moves the risk from conversion to
  widget integration).
- **Large notes.** Quill has no windowing; the threshold and the fallback are
  a product decision to make with the spike numbers.
- **Package drift.** `markdown_quill` is a community converter; exact pins
  and the round-trip test are the guard. `flutter_quill` is pre-1.0-line
  moving API territory, like `window_manager`/nativeapi, so it gets the same
  exact pin + comment treatment.
- **Math and wikilinks** may need custom Quill embeds, or start as opaque
  read-only blocks and be promoted to real embeds in a follow-up. The plan
  allows both; the envelope is the floor, not the ceiling.
- **Find & replace and spell check** are not part of v1. If they turn out to
  be must-haves for the WYSIWYG surface, they add one task each and should be
  scheduled explicitly rather than assumed.
- **Two parsers, one format.** The codec must use the same `markdown` version
  and GFM/footnote extension set as the preview, or a note would render
  differently depending on the surface. The conformance floor (639/652) is
  the shared regression gate.

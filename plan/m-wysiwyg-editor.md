# WYSIWYG editor — execution plan (small-model friendly)

**Status:** In progress (implementation landed; device pass open) · **Depends on:** M2 (editor + preview), M6
(theming, text size) · **Branch:** `feat/wysiwyg-editor` · **Spec:**
*Requirements* (editor), [design.md](design.md)

This file is an **execution runbook**, not just a design note. It is written so
that even a small local model can follow it top to bottom and land a working
feature. Every phase has: goal, exact files, exact steps, code to write, a
command to run, and an acceptance check. Do the phases in order. Do not skip a
check because it looks obvious.

## Progress

Landed on `feat/wysiwyg-editor` (one commit per step):

- **Phase 0** — `flutter_quill ^11.5.1`.
- **Phase 1** — the shared parser, the block splitter, the opaque embed and
  `MarkdownDocumentCodec`, with the byte-stability test over
  `test/spec.json` and the app extras.
- **Phase 2** — `EditorKind` + `previewEnabled` in `LibraryConfig` (per
  library), the session plumbing and the Settings rows.
- **Phase 3** — `WysiwygEditor` and `QuillEditorCommands`, with unit and
  widget tests.
- **Phase 4/5** — `note_view.dart` and `shell.dart` pick the surface; the
  WYSIWYG editor never splits; the eye switches it to the preview.
- **Phase 7** — the 200 KB guard and these docs.
- **Phase 8** (the former v1 cuts) — find & replace over the Quill document
  (`wysiwyg_find_controller.dart` + `wysiwyg_find_panel.dart`, from the status
  row and Ctrl/Cmd+F) and the spell underlines via Quill's
  `textSpanBuilder`, with the review panel scanning and fixing the Quill
  document.
- **Phase 9** — the `wysiwyg` logger (open/change/emit/toolbar lines in the
  debug log), and a heading is not continued on Enter while lists and quotes
  still are (device report: typing after a heading came out bold).
- **Phase 10** — the formatting toolbar shows the formats that are on at the
  caret (a pressed button toggles off, like a word processor), and the
  surface never re-decodes from the parent's stale echo: that reset the
  buffer and put typed text back at the start of the note (device report).
- **Phase 11** — the blank lines between blocks are kept (the parser drops
  them from the AST, so the view ate them and the next edit wrote them away —
  device report), and Quill's near-white code-block style follows the app
  theme instead of showing as a white box in the dark.
- **Phase 12** — a switch between the source editor and WYSIWYG in the note's
  status row, next to the word count (the setting stays per library).

Still open: the **device pass** on Linux and Android (a real note with
frontmatter, table, footnote, math and a wikilink; edit one line; confirm the
diff and the switch).

## Mockups (the visual target)

`mockup/wysiwyg/index.html` is a self-contained HTML page with the final look
for every mode: Android Settings (the two new rows), the Android editor in
source / WYSIWYG / preview-off, the desktop split / WYSIWYG / preview-off, and
the mode matrix. Open it in a browser; the segmented controls switch modes and
the top-bar button switches the theme. `mockup/wysiwyg/README.md` explains it.

## How to use this plan (read before touching anything)

1. **One phase per session.** Finish a phase, run its checks, commit, then
   start the next. Never mix two phases in one commit.
2. **Read the target file before editing it.** Use the read tool; do not guess
   what a file contains from this plan alone. The plan quotes snippets that may
   be a few lines off after other edits.
3. **Never reorder existing code** unless a step says to.
4. **Always run the check of the phase.** If it does not pass, fix the phase
   before moving on. Do not "fix" a failure by weakening a test unless the plan
   says to.
5. **All repo text is English** (code, comments, commit messages) even if the
   conversation is Italian.
6. Before analyze/tests, run `dart format lib test tool` (see AGENTS.md).
7. If a code snippet here does not compile against the pinned package, stop and
   inspect the package source under
   `~/.pub-cache/hosted/pub.dev/flutter_quill-11.5.1/` before improvising.
8. **Never write a note the user did not type.** The codec must preserve
   untouched bytes; the tests in Phase 6 enforce that.

## Verdict

**Feasible**, but only if the Markdown conversion is owned by Copist. The
off-the-shelf converter is not good enough (spike below), so the plan does not
use it. The verdict is:

- Use `flutter_quill` 11.5.1 as the editing widget (WYSIWYG surface).
- Do **not** use `markdown_quill`. Write a Copist codec on top of the
  `markdown` package the preview already uses.
- Blocks the codec cannot represent become **opaque embeds**: they render
  read-only, carry their original source, and are written back **verbatim**.
- A note opened and saved **without edits must be byte-identical** to the file.
- The WYSIWYG surface and the preview are **never side by side**.

## Options considered

| Option | Markdown I/O | Fit | Verdict |
| --- | --- | --- | --- |
| `flutter_quill` 11.5.1 | none built in; Delta model + custom embeds | mature WYSIWYG on desktop/mobile; the Delta + embed API matches the codec | **chosen** |
| `super_editor` + `super_editor_markdown` | Markdown-native document model, both directions | cleaner serialization, but heavier widget adoption for toolbar/find/spell | fallback if Quill fidelity proves too low |
| `appflowy_editor` | own document model + Markdown plugin | large dependency tree, less control | rejected |
| `fleather` 1.28 | Delta, no Markdown | clean core, but no path for the `.md` disk format | rejected |
| Custom WYSIWYG on the `markdown` AST + `re_editor` | exact by construction | month-scale: caret, IME, embeds, tables all new | rejected |
| `flutter_quill` + `markdown_quill` 4.3.0 | converter both directions | measured 35/652 normalized | rejected (see spike) |

Package compatibility (checked against pub.dev and by a real `flutter pub add`):
`flutter_quill` 11.5.1 requires `sdk ^3.12.0` and `flutter >=3.44.0`; this
project is `sdk ^3.13.2` and Flutter 3.47.2, and the add resolved the package
and its transitive dependencies (`quill_native_bridge` and friends) without
conflicts.

## Spike results (already measured on this machine)

Run: added `flutter_quill 11.5.1` + `markdown_quill 4.3.0`, then converted
every `test/spec.json` example with
`MarkdownToDelta(markdownDocument: md.Document(encodeHtml: false, extensionSet: md.ExtensionSet.gitHubFlavored))`
and back with `DeltaToMarkdown()`.

- **exact round-trip: 6 / 652.**
- **round-trip after trimming trailing blank lines: 35 / 652.**
- Concrete failures observed on ordinary input:
  - every paragraph gains a trailing blank line (`"Hello\n"` -> `"Hello\n\n"`);
  - `*italic*` becomes `_italic_`;
  - `.` is escaped as `\.` in links/lists;
  - GFM tables are **destroyed** (`| A | B |` -> `AB12`) without the
    package's custom `EmbeddableTableSyntax` and embed handlers;
  - footnotes become `[1](#fn-1)` plus an ordered list, losing the semantic.

Conclusion: the converter turns a note into a different note. A codec that only
canonicalizes blocks the user actually edited, and keeps every other block's
original bytes, is the way. That is what this plan builds.

The dependency state was reverted after the spike; Phase 0 adds it again.

## Architecture (the shape everything follows)

Three surfaces, two independent per-library settings, one app-wide layout mode:

| Editor (setting) | Preview (setting) | What is on screen |
| --- | --- | --- |
| source | on | today: split >= 600 dp, else one pane behind a switch |
| source | off | the source editor, full width, no preview chrome at all |
| wysiwyg | on | **never split**: a switch flips between WYSIWYG and read-only preview |
| wysiwyg | off | the WYSIWYG editor, full width |

Pieces:

1. **Codec** (`lib/src/editor/wysiwyg/`): Markdown <-> Quill Delta, with
   opaque blocks.
2. **WYSIWYG widget** (`lib/src/editor/wysiwyg/wysiwyg_editor.dart`): the
   `QuillEditor` + controller + save wiring.
3. **Settings**: `editorKind` and `previewEnabled` in the per-library
   `.copist/settings.json`.
4. **Layout wiring**: `ui/note_view.dart` and `ui/shell.dart` pick the
   surface and show/hide the preview controls.
5. **Tests**: `test/unit/wysiwyg_codec_test.dart` etc.

Note-kind GUIs (`type:` notes, T-TK-02) keep winning over every editor.

## Repository map (what the executor must know)

| Path | What it is / why it matters here |
| --- | --- |
| `lib/src/ui/note_view.dart` | Owns the note buffer, the save debounce, the toolbar, the status row, and builds editor/preview. The WYSIWYG body plugs in here. |
| `lib/src/editor/note_editor.dart` | The `re_editor` widget. The WYSIWYG widget is a sibling of it, not a replacement of its file. |
| `lib/src/preview/scroll_map.dart` | Holds `BlockLocator.locate(lines)`: the line-based top-level block splitter. The codec reuses it so both surfaces agree on block boundaries. |
| `lib/src/preview/markdown_preview.dart` | Shows the exact `md.Document` configuration the codec must mirror (math + wikilink syntaxes, GFM set, `encodeHtml: false`). |
| `lib/src/core/settings/library_config.dart` | Per-library `settings.json` model + store. Add `editorKind` and `previewEnabled` here. |
| `lib/src/core/settings/library_settings.dart` | App-wide drift-backed settings (layout mode) + enums. Add `EditorKind` here. |
| `lib/src/library/session.dart` | The `LibrarySession` interface the UI uses. Add getters/setters here. |
| `lib/src/library/library_state.dart` | `LibraryController`, the real implementation. |
| `test/fakes/fake_library_session.dart` | The widget-test fake; it must implement the new interface too. |
| `lib/src/ui/settings.dart` | The Settings screen. Add the two rows and handlers here. |
| `lib/src/ui/shell.dart` | Reads settings, owns the preview toggle/layout actions, passes flags to `NoteView`. |
| `lib/src/ui/strings.dart` | All user-visible strings (en/it). |
| `lib/src/editor/toolbar_item.dart` | The toolbar catalogue; used to decide which WYSIWYG buttons show. |
| `test/spec.json` | 652 CommonMark examples; the codec round-trip corpus. |

## Phase 0 — dependency and re-run the spike

**Goal:** add the engine and prove it resolves. Do **not** add `markdown_quill`.

Steps:

1. Run:
   ~~~bash
   cd /home/alessandro/Projects/Copist
   flutter pub add flutter_quill
   ~~~
2. Confirm `pubspec.yaml` now has a line like `flutter_quill: ^11.5.1` under
   dependencies. Add a comment above it in the same style as the other
   packages:
   ~~~yaml
   # WYSIWYG editing surface (T-WYS-04). Delta model; the Markdown codec is
   # Copist's (markdown_quill was measured and rejected, see
   # plan/m-wysiwyg-editor.md).
   flutter_quill: ^11.5.1
   ~~~
3. Run `dart pub get` (flutter pub add already does).
4. Run `./scripts/copist.sh analyze`. It must be clean.
5. Commit:
   ~~~bash
   git add pubspec.yaml pubspec.lock
   git commit -m "wysiwyg: add flutter_quill (T-WYS-00)"
   ~~~

**Check:** `flutter analyze --fatal-infos` reports no issues.

## Phase 1 — the codec (pure Dart, no widget)

**Goal:** Markdown <-> Quill document with opaque preservation and a
byte-stable no-edit round trip. This is the load-bearing phase; do it fully
before any UI.

### Step 1.1 — shared parser: `lib/src/editor/wysiwyg/markdown_parse.dart`

Create the file with exactly:

~~~dart
import 'dart:convert';

import 'package:copist/src/preview/html_table.dart';
import 'package:copist/src/preview/math_syntax.dart';
import 'package:copist/src/preview/wikilink.dart';
import 'package:markdown/markdown.dart' as md;

/// Parses [source] exactly as the preview does.
///
/// The codec and the preview must agree about what a block is. Sharing this
/// function is the guard against the two drifting apart.
List<md.Node> parseMarkdownDocument(String source) {
  final document = md.Document(
    blockSyntaxes: <md.BlockSyntax>[
      const MathBlockSyntax(),
      ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
    ],
    inlineSyntaxes: [EmbedInlineSyntax(), WikilinkInlineSyntax()],
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  return splitHtmlTables(
    splitInlineMath(document.parseLines(const LineSplitter().convert(source))),
  );
}
~~~

Then make `lib/src/preview/markdown_preview.dart` use it: replace the body of
its private `_parseSyncSource` with a call to `parseMarkdownDocument(source)`
and delete the now-unused imports if the analyzer says so. Keep the method
private and its signature identical.

### Step 1.2 — blocks: `lib/src/editor/wysiwyg/markdown_blocks.dart`

Create the file with exactly:

~~~dart
import 'dart:convert';

import 'package:copist/src/editor/wysiwyg/markdown_parse.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:markdown/markdown.dart' as md;

/// One top-level block of a note: the exact bytes it came from and whether
/// the codec can represent it in the WYSIWYG document.
final class MarkdownBlock {
  const MarkdownBlock({
    required this.source,
    required this.tag,
    required this.opaque,
    this.node,
    this.level = 0,
  });

  /// The exact source slice, including its trailing newline when the file
  /// has one.
  final String source;

  /// The top-level tag: p, h1..h6, ul, ol, blockquote, pre, or raw.
  final String tag;

  /// True when the block is kept verbatim as an opaque embed.
  final bool opaque;

  /// The parsed element, or null for a raw (HTML/text) block.
  final md.Element? node;

  /// The heading level for h1..h6, else 0.
  final int level;
}

/// The top-level tags the codec can turn into Quill lines.
const Set<String> _blockTags = <String>{
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'ul',
  'ol',
  'blockquote',
  'pre',
};

/// The inline tags the codec can turn into Quill attributes.
const Set<String> _inlineTags = <String>{'strong', 'em', 'del', 'code', 'a'};

/// Splits [markdown] into top-level blocks.
///
/// The parser is the preview's, the boundaries are the scroll map's
/// `BlockLocator`. When the two disagree about the count, the whole note
/// becomes one opaque block rather than risk a silent mis-slice.
List<MarkdownBlock> splitMarkdownBlocks(String markdown) {
  if (markdown.isEmpty) return const <MarkdownBlock>[];
  final nodes = parseMarkdownDocument(markdown);
  final lines = const LineSplitter().convert(markdown);
  final starts = BlockLocator().locate(lines);
  if (starts.length != nodes.length) {
    return <MarkdownBlock>[
      MarkdownBlock(source: markdown, tag: 'raw', opaque: true),
    ];
  }
  final offsets = <int>[];
  var offset = 0;
  for (final line in lines) {
    offsets.add(offset);
    offset += line.length + 1;
  }
  final blocks = <MarkdownBlock>[];
  for (var i = 0; i < nodes.length; i++) {
    final node = nodes[i];
    final tag = node is md.Element ? node.tag : 'raw';
    final supported =
        node is md.Element && _blockTags.contains(tag) && _isSupported(node);
    final end = i + 1 < starts.length ? offsets[starts[i + 1]] : markdown.length;
    blocks.add(
      MarkdownBlock(
        source: markdown.substring(offsets[starts[i]], end),
        tag: tag,
        opaque: !supported,
        node: node is md.Element ? node : null,
        level: _headingLevel(tag),
      ),
    );
  }
  return blocks;
}

int _headingLevel(String tag) {
  if (tag.length == 2 && tag.startsWith('h')) {
    return int.tryParse(tag.substring(1)) ?? 0;
  }
  return 0;
}

/// True when every child of [element] has a Quill representation.
bool _isSupported(md.Element element) {
  if (element.tag == 'pre') return true;
  for (final child in element.children ?? const <md.Node>[]) {
    if (child is md.Text) continue;
    if (child is! md.Element) return false;
    switch (child.tag) {
      case 'strong':
      case 'em':
      case 'del':
      case 'code':
      case 'a':
      case 'input':
      case 'p':
        break;
      case 'li':
      case 'ul':
      case 'ol':
        break;
      default:
        return false;
    }
    if (!_isSupported(child)) return false;
  }
  return true;
}
~~~

**Key facts discovered by the AST dump** (do not re-derive unless the parser
changes): a GFM task list is `ul[class=contains-task-list] > li > input[type=checkbox]`
with `checked: true` on the done box; a code fence is
`pre > code[class=language-dart]`; a footnote ref is
`sup.footnote-ref > a` and the definitions are a trailing
`section.footnotes`; math is `math[latex=...,display=false]`; a wikilink is
`wikilink[target,heading,alias]`; an embed is `embed[target,alias]`; a raw
HTML block is a top-level `md.Text`. Everything except `p/h1..h6/ul/ol/blockquote/pre`
and the inline tags above is **opaque**.

### Step 1.3 — the opaque embed: `lib/src/editor/wysiwyg/opaque_embed.dart`

~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// The Delta key of a block the codec keeps verbatim.
const String opaqueEmbedKey = 'copist-opaque';

/// Renders an opaque block read-only, as its own source text.
final class OpaqueEmbedBuilder extends quill.EmbedBuilder {
  /// Creates the builder.
  const OpaqueEmbedBuilder();

  @override
  String get key => opaqueEmbedKey;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    final source = data is Map && data['source'] is String
        ? data['source'] as String
        : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        source,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
~~~

### Step 1.4 — the codec: `lib/src/editor/wysiwyg/markdown_document_codec.dart`

Create the file with exactly:

~~~dart
import 'dart:convert';

import 'package:copist/src/editor/wysiwyg/markdown_blocks.dart';
import 'package:copist/src/editor/wysiwyg/opaque_embed.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:markdown/markdown.dart' as md;

/// A decoded note: the document the editor edits plus the exact bytes it
/// came from and a snapshot used to detect "no edit".
final class DecodedNote {
  const DecodedNote({
    required this.source,
    required this.document,
    required this.snapshot,
  });

  final String source;
  final quill.Document document;
  final List<Map<String, dynamic>> snapshot;
}

/// Markdown <-> Quill Delta with opaque preservation.
final class MarkdownDocumentCodec {
  /// Creates the codec.
  const MarkdownDocumentCodec();

  static String get _nl => String.fromCharCode(10);
  static String get _tick => String.fromCharCode(96);

  /// Builds the editor document for [source].
  DecodedNote decode(String source) {
    final blocks = splitMarkdownBlocks(source);
    final ops = <Map<String, dynamic>>[];
    for (final block in blocks) {
      if (block.opaque) {
        ops.add(<String, dynamic>{
          'insert': <String, dynamic>{
            opaqueEmbedKey: <String, dynamic>{
              'tag': block.tag,
              'source': block.source,
            },
          },
        });
        ops.add(<String, dynamic>{'insert': _nl});
      } else {
        ops.addAll(_blockOps(block));
      }
    }
    final document = quill.Document.fromJson(ops);
    return DecodedNote(
      source: source,
      document: document,
      snapshot: document.toDelta().toJson(),
    );
  }

  /// Markdown for [document].
  ///
  /// When [decoded] is given and the document did not change, its original
  /// bytes are returned unchanged (the byte-stability guarantee). Otherwise
  /// the document is serialized canonically; opaque blocks are emitted
  /// verbatim.
  String encode(quill.Document document, {DecodedNote? decoded}) {
    final json = document.toDelta().toJson();
    if (decoded != null && _sameJson(json, decoded.snapshot)) {
      return decoded.source;
    }
    final buffer = StringBuffer();
    var runs = <({String text, Map<String, dynamic> attrs})>[];
    var pendingOpaque = false;
    for (final op in json) {
      final insert = op['insert'];
      final attrs = (op['attributes'] as Map<String, dynamic>?) ?? const {};
      if (insert is Map<String, dynamic> && insert.containsKey(opaqueEmbedKey)) {
        final value = insert[opaqueEmbedKey];
        final source = value is Map ? value['source'] : null;
        if (source is String) {
          buffer.write(source.endsWith(_nl) ? source : source + _nl);
          pendingOpaque = true;
        }
        continue;
      }
      if (insert is! String) continue;
      final parts = insert.split(_nl);
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) runs.add((text: parts[i], attrs: attrs));
        if (i < parts.length - 1) {
          if (pendingOpaque) {
            pendingOpaque = false;
          } else {
            buffer.write(_renderLine(runs, attrs));
          }
          runs = <({String text, Map<String, dynamic> attrs})>[];
        }
      }
    }
    if (runs.isNotEmpty) buffer.write(_renderLine(runs, const <String, dynamic>{}));
    return buffer.toString();
  }

  List<Map<String, dynamic>> _blockOps(MarkdownBlock block) {
    final node = block.node!;
    if (node.tag == 'pre') return _codeOps(node);
    if (node.tag == 'ul' || node.tag == 'ol') {
      return _listOps(node, tag: node.tag, indent: 0);
    }
    final attrs = _lineAttributes(block);
    return <Map<String, dynamic>>[
      ..._inlineOps(node.children ?? const <md.Node>[], const <String, dynamic>{}),
      <String, dynamic>{'insert': _nl, if (attrs.isNotEmpty) 'attributes': attrs},
    ];
  }

  Map<String, dynamic> _lineAttributes(MarkdownBlock block) {
    if (block.level > 0) return <String, dynamic>{'header': block.level};
    if (block.tag == 'blockquote') return <String, dynamic>{'blockquote': true};
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _codeOps(md.Element pre) {
    final children = pre.children ?? const <md.Node>[];
    final code = children.isEmpty ? null : children.first;
    final lang = code is md.Element
        ? (code.attributes['class'] ?? '').replaceFirst('language-', '')
        : '';
    return <Map<String, dynamic>>[
      <String, dynamic>{'insert': pre.textContent},
      <String, dynamic>{
        'insert': _nl,
        'attributes': <String, dynamic>{
          'code-block': true,
          if (lang.isNotEmpty) 'copist-lang': lang,
        },
      },
    ];
  }

  List<Map<String, dynamic>> _listOps(
    md.Element list, {
    required String tag,
    required int indent,
  }) {
    final ops = <Map<String, dynamic>>[];
    for (final item in list.children ?? const <md.Node>[]) {
      if (item is! md.Element || item.tag != 'li') continue;
      final inline = <md.Node>[];
      final nested = <md.Element>[];
      var type = tag == 'ol' ? 'ordered' : 'bullet';
      for (final child in item.children ?? const <md.Node>[]) {
        if (child is md.Element && (child.tag == 'ul' || child.tag == 'ol')) {
          nested.add(child);
        } else if (child is md.Element && child.tag == 'input') {
          type = child.attributes['checked'] != null ? 'checked' : 'unchecked';
        } else {
          inline.add(child);
        }
      }
      ops.addAll(_inlineOps(inline, const <String, dynamic>{}));
      ops.add(<String, dynamic>{
        'insert': _nl,
        'attributes': <String, dynamic>{
          'list': type,
          if (indent > 0) 'indent': indent,
        },
      });
      for (final child in nested) {
        ops.addAll(_listOps(child, tag: child.tag, indent: indent + 1));
      }
    }
    return ops;
  }

  List<Map<String, dynamic>> _inlineOps(
    List<md.Node> nodes,
    Map<String, dynamic> style,
  ) {
    final ops = <Map<String, dynamic>>[];
    for (final node in nodes) {
      if (node is md.Text) {
        if (node.text.isNotEmpty) {
          ops.add(<String, dynamic>{
            'insert': node.text,
            if (style.isNotEmpty) 'attributes': style,
          });
        }
        continue;
      }
      if (node is! md.Element) continue;
      final next = Map<String, dynamic>.of(style);
      switch (node.tag) {
        case 'strong':
          next['bold'] = true;
        case 'em':
          next['italic'] = true;
        case 'del':
          next['strike'] = true;
        case 'code':
          next['code'] = true;
        case 'a':
          next['link'] = node.attributes['href'] ?? '';
      }
      ops.addAll(
        _inlineOps(node.children ?? const <md.Node>[], next),
      );
    }
    return ops;
  }

  String _renderLine(
    List<({String text, Map<String, dynamic> attrs})> runs,
    Map<String, dynamic> attrs,
  ) {
    final text = runs.map((run) => _renderInline(run.text, run.attrs)).join();
    if (attrs['code-block'] == true) {
      final lang = attrs['copist-lang'];
      final body = text.endsWith(_nl) ? text : text + _nl;
      return '~~~' + (lang is String ? lang : '') + _nl + body + '~~~' + _nl;
    }
    final prefix = StringBuffer();
    if (attrs['header'] is int) {
      prefix.write('#' * (attrs['header'] as int));
      prefix.write(' ');
    }
    switch (attrs['list']) {
      case 'bullet':
        prefix.write('- ');
      case 'ordered':
        prefix.write('1. ');
      case 'checked':
        prefix.write('- [x] ');
      case 'unchecked':
        prefix.write('- [ ] ');
    }
    if (attrs['blockquote'] == true) prefix.write('> ');
    return prefix.toString() + text + _nl;
  }

  String _renderInline(String text, Map<String, dynamic> attrs) {
    var out = text;
    if (attrs['code'] == true) out = _tick + out + _tick;
    if (attrs['bold'] == true) out = '**' + out + '**';
    if (attrs['italic'] == true) out = '*' + out + '*';
    if (attrs['strike'] == true) out = '~~' + out + '~~';
    if (attrs['underline'] == true) out = '<u>' + out + '</u>';
    final link = attrs['link'];
    if (link is String && link.isNotEmpty) out = '[' + out + '](' + link + ')';
    return out;
  }

  bool _sameJson(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    return jsonEncode(a) == jsonEncode(b);
  }
}
~~~

### Step 1.5 — the codec test: `test/unit/wysiwyg_codec_test.dart`

Create the file with exactly:

~~~dart
// T-WYS-02: the Markdown <-> Quill codec is byte-stable when nothing changed
// and preserves every construct it cannot represent.
import 'dart:convert';
import 'dart:io';

import 'package:copist/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = MarkdownDocumentCodec();

  test('an unedited note round-trips byte for byte over spec.json', () {
    final examples =
        (jsonDecode(File('test/spec.json').readAsStringSync()) as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final failures = <String>[];
    for (final example in examples) {
      final source = example['markdown'] as String;
      final decoded = codec.decode(source);
      final back = codec.encode(decoded.document, decoded: decoded);
      if (back != source) {
        failures.add('#' + example['example'].toString());
      }
    }
    expect(
      failures,
      isEmpty,
      reason: 'codec changed ' + failures.length.toString() + ' notes: ' +
          failures.take(20).join(', '),
    );
  });

  test('every construct the app adds survives untouched', () {
    const note = '---\n'
        'id: 1\n'
        'title: Note\n'
        '---\n'
        '\n'
        '# Heading\n'
        '\n'
        'A paragraph with **bold** and *italic*.\n'
        '\n'
        '- [x] done\n'
        '- [ ] pending\n'
        '\n'
        '| A | B |\n'
        '| --- | --- |\n'
        '| 1 | 2 |\n'
        '\n'
        'A footnote[^n].\n'
        '\n'
        '[^n]: The note.\n'
        '\n'
        'Math \$x^2\$ and \$\$y^2\$\$.\n'
        '\n'
        'A [[wikilink]] and an ![[embed.png]].\n';
    final decoded = codec.decode(note);
    expect(codec.encode(decoded.document, decoded: decoded), note);
  });
}
~~~

Run:
~~~bash
dart format lib test tool
flutter test test/unit/wysiwyg_codec_test.dart
~~~

If the spec test fails, **do not** weaken it. Print the first failing example
and its source, and fix the codec mapping until it passes. The expected result
is 652/652 because the codec never rewrites an unedited document.

### Step 1.6 — commit

~~~bash
git add lib/src/editor/wysiwyg lib/src/preview/markdown_preview.dart test/unit/wysiwyg_codec_test.dart
git commit -m "wysiwyg: Markdown codec with opaque-block preservation (T-WYS-02)"
~~~

## Phase 2 — settings (per library)

**Goal:** persist `editorKind` and `previewEnabled` in `.copist/settings.json`
and surface them in Settings. Defaults must reproduce today's behaviour.

### Step 2.1 — `lib/src/core/settings/library_settings.dart`

Add the enum and widen `previewSplits` (keep existing call sites compiling by
giving the new parameters defaults):

~~~dart
/// Which editor a library writes in (T-WYS-03, default source).
enum EditorKind {
  /// The Markdown source editor (re_editor).
  source,

  /// The WYSIWYG surface (flutter_quill).
  wysiwyg,
}
~~~

Then replace the body of `previewSplits` with:

~~~dart
bool previewSplits(
  PreviewLayoutMode mode, {
  required bool narrow,
  EditorKind editor = EditorKind.source,
  bool previewEnabled = true,
}) =>
    previewEnabled &&
    editor == EditorKind.source &&
    !narrow &&
    mode == PreviewLayoutMode.auto;
~~~

### Step 2.2 — `lib/src/core/settings/library_config.dart`

The executor must read the file first. Make these edits (the analyzer will
guide you if a name moved):

1. Add `EditorKind` to the existing `show` import of
   `library_settings.dart`.
2. In the constructor defaults add:
   ~~~dart
   this.editorKind = EditorKind.source,
   this.previewEnabled = true,
   ~~~
3. In `fromJsonMap` add:
   ~~~dart
   editorKind: switch (json['editorKind']) {
     'wysiwyg' => EditorKind.wysiwyg,
     _ => EditorKind.source,
   },
   previewEnabled: _boolOr(json['previewEnabled'], true),
   ~~~
4. Add the fields (next to `spellDictionaries`):
   ~~~dart
   /// Which editor this library writes in (default source).
   final EditorKind editorKind;

   /// Whether the preview exists at all (default true).
   final bool previewEnabled;
   ~~~
5. In `copyWith` add `EditorKind? editorKind,` and `bool? previewEnabled,`
   and pass `editorKind ?? this.editorKind` / `previewEnabled ?? this.previewEnabled`.
6. In `_knownKeys` add `'editorKind'` and `'previewEnabled'`.
7. In `toJsonMap` add `'editorKind': editorKind.name,` and
   `'previewEnabled': previewEnabled,`.
8. In `operator ==` add `editorKind == other.editorKind &&` and
   `previewEnabled == other.previewEnabled &&`.

**Check:** `test/unit/library_config_test.dart` already round-trips a config;
run it after this step. Then add two tests to that file:

~~~dart
test('an older file reads back as the shipped editor defaults', () async {
  final lib = await makeLibrary();
  final store = LibraryConfigStore(lib.path);
  expect((await store.read()).editorKind, EditorKind.source);
  expect((await store.read()).previewEnabled, isTrue);
});

test('round trips the editor kind and the preview switch', () async {
  final lib = await makeLibrary();
  final store = LibraryConfigStore(lib.path);
  const config = LibraryConfig(
    trashEnabled: true,
    historyVersions: 10,
    quickNotePath: null,
    listNoteFolder: 'Lists',
    editorKind: EditorKind.wysiwyg,
    previewEnabled: false,
  );
  await store.write(config);
  final read = await store.read();
  expect(read.editorKind, EditorKind.wysiwyg);
  expect(read.previewEnabled, isFalse);
});
~~~

### Step 2.3 — session + controller + fake

`lib/src/library/session.dart` — add to the interface, next to the spell
settings:

~~~dart
/// Which editor the library writes in (default source).
Future<EditorKind> get editorKind;

/// Sets (and persists) the editor kind.
Future<void> setEditorKind(EditorKind kind);

/// Whether the preview exists at all (default true).
Future<bool> get previewEnabled;

/// Sets (and persists) the preview switch.
Future<void> setPreviewEnabled({required bool enabled});
~~~

`lib/src/library/library_state.dart` — implement over `LibraryConfig`,
mirroring `setSpellDictionaries`:

~~~dart
@override
Future<EditorKind> get editorKind async => (await _library).editorKind;

@override
Future<void> setEditorKind(EditorKind kind) async {
  _log.info('editor kind set to ' + kind.name);
  await _editLibrary((c) => c.copyWith(editorKind: kind));
}

@override
Future<bool> get previewEnabled async => (await _library).previewEnabled;

@override
Future<void> setPreviewEnabled({required bool enabled}) async {
  _log.info('preview enabled set to ' + enabled.toString());
  await _editLibrary((c) => c.copyWith(previewEnabled: enabled));
}
~~~

`test/fakes/fake_library_session.dart` — implement the same four over
`_config`, then `_bump()`, mirroring `setSpellDictionaries`.

### Step 2.4 — strings: `lib/src/ui/strings.dart`

Next to the other editor strings add:

~~~dart
static String get settingsEditorKindTitle =>
    _t('Editor', 'Editor');
static String get editorKindSource => _t('Markdown source', 'Sorgente Markdown');
static String get editorKindWysiwyg => _t('WYSIWYG', 'WYSIWYG');
static String get settingsPreviewEnabledTitle =>
    _t('Preview', 'Anteprima');
static String get settingsPreviewEnabledSubtitle => _t(
  'Show the rendered note beside the source editor.',
  'Mostra la nota renderizzata accanto all\'editor sorgente.',
);
~~~

Escape the apostrophe exactly as the other Italian strings do (inspect a
neighbouring `_t` call before copying).

### Step 2.5 — Settings screen: `lib/src/ui/settings.dart`

1. Add two fields near `_spellDictionaries`:
   ~~~dart
   EditorKind _editorKind = EditorKind.source;
   bool _previewEnabled = true;
   ~~~
2. In `_load` read `await controller.editorKind` and
   `await controller.previewEnabled` and assign them in the `setState`.
3. Under the **Editor** section add, next to `line-numbers`:
   ~~~dart
   SettingsValueRow(
     key: const Key('editor-kind-setting'),
     title: AppStrings.settingsEditorKindTitle,
     value: _editorKind == EditorKind.wysiwyg
         ? AppStrings.editorKindWysiwyg
         : AppStrings.editorKindSource,
     onTap: () => unawaited(_chooseEditorKind()),
   ),
   SwitchListTile(
     key: const Key('preview-enabled-setting'),
     title: Text(AppStrings.settingsPreviewEnabledTitle),
     subtitle: Text(AppStrings.settingsPreviewEnabledSubtitle),
     value: _previewEnabled,
     onChanged: _togglePreviewEnabled,
   ),
   ~~~
4. Add the handlers next to `_chooseIndentWidth`:
   ~~~dart
   Future<void> _chooseEditorKind() async {
     final kind = await showSettingsChoice<EditorKind>(
       context,
       dialogKey: const Key('editor-kind-dialog'),
       title: AppStrings.settingsEditorKindTitle,
       current: _editorKind,
       options: const [
         SettingsOption(EditorKind.source, 'Markdown source'),
         SettingsOption(EditorKind.wysiwyg, 'WYSIWYG'),
       ],
     );
     if (kind == null) return;
     await widget.controller.setEditorKind(kind);
     if (mounted) setState(() => _editorKind = kind);
   }

   Future<void> _togglePreviewEnabled(bool value) async {
     await widget.controller.setPreviewEnabled(enabled: value);
     if (mounted) setState(() => _previewEnabled = value);
   }
   ~~~
   Replace the two hard-coded option labels with the `AppStrings` getters if
   you want them localized; the keys stay the same either way.
5. The existing split-ratio row already checks `previewSplits`; pass
   `editor: _editorKind` and `previewEnabled: _previewEnabled` there and in
   every call in this file.

### Step 2.6 — check + commit

~~~bash
dart format lib test tool
./scripts/copist.sh check
git add lib/src/core/settings lib/src/library/session.dart lib/src/library/library_state.dart lib/src/ui/settings.dart lib/src/ui/strings.dart test/fakes/fake_library_session.dart test/unit/library_config_test.dart
git commit -m "wysiwyg: editor kind and preview switch settings (T-WYS-03)"
~~~

## Phase 3 — the WYSIWYG widget

**Goal:** a widget that opens Markdown, edits it in Quill, and reports
Markdown back on a debounce.

### Step 3.1 — `lib/src/editor/wysiwyg/wysiwyg_editor.dart`

~~~dart
import 'dart:async';

import 'package:copist/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:copist/src/editor/wysiwyg/opaque_embed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// The WYSIWYG writing surface: a Quill editor over the note's Markdown.
final class WysiwygEditor extends StatefulWidget {
  const new({
    required this.data,
    required this.onChanged,
    this.autoFocus = false,
    super.key,
  });

  /// The note's Markdown.
  final String data;

  /// Called with the serialized Markdown after a short typing pause.
  final ValueChanged<String> onChanged;

  /// Whether to focus on open.
  final bool autoFocus;

  @override
  State<WysiwygEditor> createState() => WysiwygEditorState();
}

final class WysiwygEditorState extends State<WysiwygEditor> {
  static const MarkdownDocumentCodec _codec = MarkdownDocumentCodec();

  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  late quill.QuillController _controller;
  late DecodedNote _decoded;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _decoded = _codec.decode(widget.data);
    _controller = quill.QuillController(
      document: _decoded.document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _emit);
  }

  void _emit() {
    if (!mounted) return;
    widget.onChanged(_codec.encode(_controller.document, decoded: _decoded));
  }

  @override
  void didUpdateWidget(WysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) return;
    if (widget.data ==
        _codec.encode(_controller.document, decoded: _decoded)) {
      return;
    }
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _decoded = _codec.decode(widget.data);
    _controller = quill.QuillController(
      document: _decoded.document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No toolbar here on purpose: the app's own EditorToolbar is the editor
    // chrome on both surfaces, in the same slot (top on desktop, bottom on a
    // phone). See Step 3.1b.
    return quill.QuillEditor(
      controller: _controller,
      focusNode: _focus,
      scrollController: _scroll,
      config: const quill.QuillEditorConfig(
        padding: EdgeInsets.all(16),
        embedBuilders: [OpaqueEmbedBuilder()],
      ),
    );
  }
}
~~~

Note: `QuillEditorConfig` is `const`, so `autoFocus: widget.autoFocus`
cannot go in the const instance. If the analyzer rejects it, build the config
without `const` and pass `autoFocus: widget.autoFocus`.

### Step 3.1b — the app toolbar drives both editors

The WYSIWYG widget deliberately has **no toolbar of its own**. The app's
existing toolbar (`lib/src/editor/toolbar.dart`) is the editor chrome on both
surfaces and in both positions: above the editor on desktop (`toolbarTop`),
below it on a phone. This is the design the mockups show
(`mockup/wysiwyg/index.html`).

Make the same toolbar act on the active editor:

1. Add `lib/src/editor/editor_commands.dart` with a small interface and two
   implementations:

   ~~~dart
   /// The formatting toolbar's commands against the active editor.
   abstract interface class EditorCommands {
     void apply(ToolbarItem item);
   }
   ~~~

   `SourceEditorCommands` wraps the existing `md_editing.dart` functions
   and the `CodeLineEditingController`; `QuillEditorCommands` wraps the
   `QuillController` exposed by `WysiwygEditorState`.
2. Expose the controller from `WysiwygEditorState` (a getter
   `QuillController get controller`) so `NoteView` can build the Quill
   commands with a `GlobalKey<WysiwygEditorState>`.
3. In `NoteView`, keep building the toolbar in the same slot and pass the
   commands for the active editor. Do **not** hide it when `showWysiwyg`.
4. Map each `ToolbarItem` to a Quill format (confirm the names against the
   package in `~/.pub-cache/.../flutter_quill-11.5.1/lib/src/document/attribute.dart`):

   | ToolbarItem | Quill |
   | --- | --- |
   | bold / italic / underline / strikethrough | `quill.Attribute.bold` / `.italic` / `.underline` / `.strikeThrough` |
   | superscript | `quill.Attribute.superscript` |
   | link | `quill.LinkAttribute(href)` after the URL dialog |
   | code | `quill.Attribute.inlineCode`; a fenced block uses `quill.Attribute.codeBlock` |
   | image | the app's library-relative image flow, inserted as an image embed |
   | heading | `quill.HeaderAttribute(level: n)` |
   | list / orderedList | `quill.ListAttribute('bullet')` / `quill.ListAttribute('ordered')` |
   | quote | `quill.Attribute.blockQuote` |
   | outdent / indent | `quill.IndentAttribute(level: n)` |

   Every item already in the user's `ToolbarLayout` gets a mapping; there is
   no second catalogue.

### Step 3.2 — the widget test: `test/widget/wysiwyg_editor_test.dart`

~~~dart
import 'package:copist/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens a note and reports edits as Markdown', (tester) async {
    String? reported;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            data: '# Heading\n\nA paragraph.\n',
            onChanged: (value) => reported = value,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(EditableText).first, 'changed');
    await tester.pump(const Duration(seconds: 1));
    expect(reported, isNotNull);
  });
}
~~~

If `find.byType(EditableText)` finds nothing (Quill uses a custom
`EditorTextSelectionGestureDetector`), adjust the finder until it finds the
editable; do not delete the test.

### Step 3.3 — check + commit

~~~bash
dart format lib test tool
flutter test test/widget/wysiwyg_editor_test.dart
git add lib/src/editor/wysiwyg/wysiwyg_editor.dart test/widget/wysiwyg_editor_test.dart
git commit -m "wysiwyg: the Quill editing surface (T-WYS-04)"
~~~

## Phase 4 — layout wiring

**Goal:** the shell and the note view choose the surface and never show the
WYSIWYG editor beside the preview.

### Step 4.1 — `lib/src/ui/note_view.dart`

Read the whole class first. Then:

1. Add to the `NoteView` constructor (and document them):
   ~~~dart
   this.showWysiwyg = false,
   this.onWysiwygChanged,
   ~~~
   ~~~dart
   /// Whether this note opens in the WYSIWYG surface instead of the source
   /// editor.
   final bool showWysiwyg;

   /// Reports a WYSIWYG edit as Markdown (the owner saves it).
   final ValueChanged<String>? onWysiwygChanged;
   ~~~
2. Add a field `String? _wysiwygText;` and a getter
   `String get _currentText => _wysiwygText ?? _controller.text;`.
3. In `_load`, where the file content is put into `_controller.text`, also
   set `_wysiwygText = text;` so the WYSIWYG surface opens with the file.
4. Change `_save` and `_refreshPreview` to read `_currentText` instead of
   `_controller.text`. Change the preview text source the same way.
5. Add:
   ~~~dart
   void _onWysiwygChanged(String markdown) {
     if (!mounted) return;
     _wysiwygText = markdown;
     _revision++;
     _unsaved?.noteChanged();
     _saveTimer?.cancel();
     final debounce = _saving
         ? const Duration(seconds: 1)
         : const Duration(milliseconds: 500);
     _saveTimer = Timer(debounce, _save);
     _previewTimer?.cancel();
     _previewTimer = Timer(const Duration(milliseconds: 500), _refreshPreview);
   }
   ~~~
6. In `build`, extend the body choice. Current order is kind GUI, split,
   switch. New order: kind GUI, then WYSIWYG (no preview, or switch), then the
   existing source paths:
   ~~~dart
   ? kindGui.buildBody(context, _kindHost)
   : widget.showWysiwyg
       ? WysiwygEditor(
           key: ValueKey(widget.path),
           data: _currentText,
           onChanged: widget.onWysiwygChanged ?? (_) {},
           autoFocus: widget.autofocusEditor,
         )
       : split
           ? EditorPreviewSplit(...)
           : AnimatedSwitcher(...)
   ~~~
   Add the import `package:copist/src/editor/wysiwyg/wysiwyg_editor.dart`.
7. The formatting toolbar is the **same** chrome on both editors and keeps
   its slot (top on desktop via `toolbarTop`, bottom on a phone). Do **not**
   hide it for WYSIWYG: leave
   `showToolbar = (split || !widget.showPreview) && toolbarLayout.visible.isNotEmpty`
   and pass the commands for the active editor (Step 3.1b).

### Step 4.2 — `lib/src/ui/shell.dart`

Read the class first. Then:

1. Add state fields next to `_previewMode`:
   ~~~dart
   EditorKind _editorKind = EditorKind.source;
   bool _previewEnabled = true;
   ~~~
2. In `_refreshEditorSettings` read them with the others:
   ~~~dart
   final editorKind = await controller.editorKind;
   final previewEnabled = await controller.previewEnabled;
   ~~~
   and assign in `setState` (add them to the change check so the shell
   rebuilds when they move).
3. Replace every `splitPreview: previewSplits(_previewMode, narrow: ...)`
   with the four-argument form:
   ~~~dart
   splitPreview: previewSplits(
     _previewMode,
     narrow: false, // or true in the phone branch
     editor: _editorKind,
     previewEnabled: _previewEnabled,
   ),
   ~~~
4. Pass `showWysiwyg: _editorKind == EditorKind.wysiwyg` and
   `onWysiwygChanged: ...` through `_DetailPane` to `NoteView`. If wiring
   the callback through the stateless `_DetailPane` is awkward, hoist it: add
   the two fields to `_DetailPane` exactly like `splitPreview`.
5. In the phone branch, gate `immersive` and the app-bar actions on
   `previewEnabled` and `_editorKind == EditorKind.source` (the eye and the
   layout menu must disappear when the preview is off; the layout menu must
   disappear when WYSIWYG is active).
6. In the wide `statusActions`, keep only:
   ~~~dart
   if (_previewToggleVisible && _previewEnabled) ...[
     if (_editorKind == EditorKind.source)
       _layoutModeAction(compact: true),
     if (!previewSplits(_previewMode, narrow: false,
         editor: _editorKind, previewEnabled: _previewEnabled))
       _previewToggleAction(compact: true),
   ],
   ~~~
   The same condition shape applies to the phone app-bar actions.
7. When `_editorKind == EditorKind.wysiwyg` and the preview is on, the eye
   must still switch panes (full screen). The replay of the source split is
   impossible because step 6 never shows the layout menu.

### Step 4.3 — manual check + commit

Run the app on Linux:
~~~bash
./scripts/copist.sh linux
~~~
Open Settings, switch Editor to WYSIWYG, close Settings, open a note. Verify:
the app toolbar shows at the bottom (phone) / top (desktop), the same as
source; the preview never sits beside it; turning Preview off
removes the eye; switching back to source restores the split.

~~~bash
./scripts/copist.sh check
git add lib/src/ui/note_view.dart lib/src/ui/shell.dart
git commit -m "wysiwyg: layout, never beside the preview (T-WYS-05)"
~~~

## Phase 5 — control inventory (what hides where)

Implement and test each row. The rule is a single source of truth:
`previewSplits(...)` and `previewEnabled`.

| Control | Source + preview | WYSIWYG | Preview off |
| --- | --- | --- | --- |
| eye (`editor-preview-toggle`) | shown | switch only | hidden |
| layout menu (`layout-mode`) | shown | hidden | hidden |
| fullscreen preview action | switch mode only | shown | n/a |
| `EditorPreviewSplit` | as today | never built | never built |
| scroll sync/map | as today | not built | not built |
| split-ratio settings row | shown when it splits | hidden | hidden |
| formatting toolbar | as today | same app toolbar, drives Quill; same slot | as today |
| find & replace (custom) | as today | WYSIWYG bar (`wysiwyg-find-*`), Ctrl/Cmd+F | as today |
| spell underlines | as today | wavy, via `textSpanBuilder` | as today (source) |
| line numbers, folding, indent helpers | as today | not shown | as today |
| word count / outline | source text | serialized Markdown | active editor |
| kind actions | as today | as today | as today |

Add widget tests for the four rows that matter most (eye hidden, layout menu
hidden, split never built, toolbar hidden), using the fake session. Model them
on `test/widget/spell_check_sheet_test.dart` and
`test/widget/settings_layout_test.dart`.

Commit:
~~~bash
git add lib test
git commit -m "wysiwyg: hide the source-only controls (T-WYS-06)"
~~~

## Phase 6 — tests

Required new/extended tests (names are exact):

1. `test/unit/wysiwyg_codec_test.dart` — from Phase 1.
2. `test/unit/library_config_test.dart` — the two tests from Phase 2.
3. `test/unit/wysiwyg_settings_test.dart` — that the four session getters
   round-trip through `FakeLibrarySession` (cheap, no widget).
4. `test/widget/wysiwyg_editor_test.dart` — from Phase 3.
5. `test/widget/wysiwyg_layout_test.dart` — the mode matrix with the fake.

Every test must be portable per AGENTS.md (build paths with `p.join`, no
`chmod`). Run the full suite before committing:

~~~bash
dart format lib test tool
./scripts/copist.sh check
~~~

## Phase 7 — large-note guard and docs

1. In `WysiwygEditorState.build`, before building Quill, if
   `widget.data.length > 200 * 1024` return a centered message offering the
   source editor (the exact threshold comes from the spike numbers; record it
   in a comment). Add the string to `AppStrings`.
   *Why:* Quill builds the whole document; there is no windowing.
2. Update `plan/m-wysiwyg-editor.md` Status to **In progress** with the date,
   and update `plan/design.md`'s editor section to name the third surface.
3. Commit:
   ~~~bash
   git add lib/src/editor/wysiwyg lib/src/ui/strings.dart plan
   git commit -m "wysiwyg: large-note guard and docs (T-WYS-07/09)"
   ~~~

## Final verification checklist

Run and paste the outcome (do not paste raw logs):

1. `./scripts/copist.sh check` — analyze clean, all tests pass.
2. `./scripts/copist.sh linux` — succeeds.
3. `./scripts/copist.sh apk` — succeeds.
4. Manual, Linux: source + preview split works as before.
5. Manual, Linux: WYSIWYG + preview on -> switch only, never split.
6. Manual, Linux: preview off -> no eye, no layout menu, no split ratio.
7. Manual, Linux: open a note with frontmatter, a table, a footnote, math and
   a wikilink in WYSIWYG; change one word; save; the diff touches only that
   line and keeps every opaque block byte-identical.
8. Manual, Android: same note opens and saves.

## Rollback

- Phase 0 only: `git revert` the dependency commit, or remove the
  `flutter_quill` line and `flutter pub get`.
- The whole feature: every phase is its own commit; `git revert` them in
  reverse order. Nothing else in the app depends on the new code.

## Troubleshooting

- **`markdown_quill` is mentioned anywhere:** delete it. It was measured and
  rejected (see Spike results).
- **The codec test fails on a spec example:** print the source and the encoded
  result, find the first differing block, and fix the mapping. Never relax the
  byte-equality assertion.
- **Quill throws "unknown embed":** make sure `OpaqueEmbedBuilder` is passed
  in `QuillEditorConfig.embedBuilders` and its `key` equals
  `opaqueEmbedKey`.
- **The document is empty after decode:** `splitMarkdownBlocks` may have
  returned one opaque block because `BlockLocator` and the parser disagreed.
  Log both counts; the fallback is intentional, not a crash.
- **Analyzer complains about a const constructor:** drop `const` on that
  widget/config; do not change the field types.

## Open questions (decide with the spike numbers)

- Exact large-note threshold (start at 200 KB, lower it if the device is slow).
- Whether the opaque embed should eventually become editable per construct
  (math, tables) instead of a read-only box.




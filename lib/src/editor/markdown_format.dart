/// Tidying a note's Markdown (#227), the corrector #72's rules included.
///
/// A note is a file someone writes by hand, and hands wander: a list
/// item wrapped over two lines without indentation, three blank lines
/// where one would do, a heading with no space after its hashes, spaces
/// left at the end of a line. Every one of those is valid Markdown and
/// every one of them reads worse than it should — the wrapped item is
/// why a checklist opened in the WYSIWYG as a list that started counting
/// again halfway down (0.0.8 test round).
///
/// This is the tidying, and it is deliberately a small one. It works on
/// the note's own lines rather than re-rendering a parsed tree, because
/// a formatter that rewrites what it did not understand is a formatter
/// that loses things: the code inside a fence, tables, math, frontmatter
/// and HTML pass through untouched, and so does the prose inside a
/// paragraph — no reflowing, no rewrapping, nothing that would make a
/// diff of a note unreadable.
///
/// What it does:
///
/// * a line that continues a list item is indented to that item's text,
///   so the item stays one item;
/// * a heading gets exactly one space after its hashes (`#Title`, which
///   is a paragraph and not a heading at all, is left alone: tidying is
///   not the place to change what a line means);
/// * blocks are set apart by exactly one blank line — runs of blank lines
///   collapse to one, a heading gets one where it had none, and the
///   trailing ones go;
/// * trailing spaces go, except the ones that mean a line break, kept as
///   exactly two — and dropped at the end of a block, where they break
///   nothing;
/// * the note ends with exactly one newline.
///
/// Those always run. The rules #72 added are switches ([LintRule]):
/// between them, a list comes back tight — no blank lines between its
/// items, one space after the marker — its task boxes canonical (`[ ]`,
/// `[x]`), and a fence gets its language and its closing fence, its two
/// fence lines being all of it the tidying reads. All of them are on by
/// default; passing `rules` leaves out the ones a library turned off.
///
/// Formatting twice changes nothing the second time, which the tests
/// hold for every case they cover.
library;

import 'package:niman/src/lint/fence_fixes.dart';
import 'package:niman/src/lint/lint_rule.dart';
import 'package:niman/src/lint/list_fixes.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The line separator the app normalizes to.
const String _newline = '\n';

/// A heading's hashes, however they are spaced from the text.
final RegExp _heading = RegExp(r'^(\s{0,3})(#{1,6})[ \t]*(\S.*)?$');

/// Tidies [source]; an empty note stays empty.
///
/// [rules] are the #72 rules to apply; null applies them all.
String formatMarkdown(String source, {Set<LintRule>? rules}) {
  final on = rules ?? LintRule.all;
  if (source.trim().isEmpty) return source.isEmpty ? source : _newline;
  final out = <String>[];
  for (final block in _units(source)) {
    // Frontmatter, fences, tables, math, HTML: kept verbatim. The one
    // exception is the trailing blank lines a block carries, which the
    // joining below decides instead.
    final lines = block.lines;
    final tidied = switch (block.kind) {
      _Unit.opaque => lines,
      _Unit.fence => tidyFence(
        lines,
        language: on.contains(LintRule.fenceLanguage),
        closing: on.contains(LintRule.closingFence),
      ),
      _Unit.list => tidyList(
        normalizeTaskBoxes(
          lines.map(_trimEnd).toList(),
          enabled: on.contains(LintRule.taskMarker),
        ),
        spacing: on.contains(LintRule.listSpacing),
        tight: on.contains(LintRule.tightLists),
      ),
      _Unit.heading => _headings(lines),
      _Unit.prose => lines.map(_trimEnd).toList(),
    };
    final body = _withoutTrailingBlanks(tidied);
    if (body.isEmpty) continue;
    // A break on the last line of a block breaks nothing.
    if (block.kind != _Unit.opaque && block.kind != _Unit.fence) {
      body[body.length - 1] = body.last.trimRight();
    }
    if (out.isNotEmpty) out.add('');
    out.addAll(body);
  }
  return '${out.join(_newline)}$_newline';
}

/// A heading block: one space between the hashes and the text.
List<String> _headings(List<String> lines) => [
  for (final raw in lines)
    if (_heading.firstMatch(_trimEnd(raw)) case final match?)
      '${match.group(1)}${match.group(2)} ${match.group(3) ?? ''}'.trimRight()
    else
      _trimEnd(raw),
];

/// [line] without its trailing spaces — except the two that mean a line
/// break, which are a mark like any other and are kept as exactly two.
String _trimEnd(String line) {
  final trimmed = line.trimRight();
  if (trimmed.isEmpty) return '';
  final spaces = line.length - trimmed.length;
  return spaces >= 2 ? '$trimmed  ' : trimmed;
}

List<String> _withoutTrailingBlanks(List<String> lines) {
  final out = [...lines];
  while (out.isNotEmpty && out.last.trim().isEmpty) {
    out.removeLast();
  }
  while (out.isNotEmpty && out.first.trim().isEmpty) {
    out.removeAt(0);
  }
  return out;
}

/// What a stretch of the note is, to the tidying.
enum _Unit {
  /// Kept as written: frontmatter, math, HTML, indented code, a table.
  opaque,

  /// A fenced code block: its fences and the code between them.
  fence,

  /// A list, its items and the lines that go on them, blank lines between
  /// items included.
  list,

  /// A heading.
  heading,

  /// Anything else: a paragraph, a quote, a rule.
  prose,
}

/// [source] cut into the stretches the tidying treats as one, read by the
/// engine's own block scanner: a block apiece, but a list whole across the
/// blank lines between its items, and blank lines left out.
List<({_Unit kind, List<String> lines})> _units(String source) {
  final buffer = SourceBuffer.fromText(source);
  final blocks = BlockScanner(buffer).index.blocks;
  final units = <({_Unit kind, List<String> lines})>[];
  List<String> linesOf(Block block) => [
    for (var line = block.startLine; line < block.endLine; line++)
      buffer.lineAt(line),
  ];
  for (var at = 0; at < blocks.length; at++) {
    final block = blocks[at];
    if (block.kind == BlockKind.blank) continue;
    if (block.kind == BlockKind.listItem) {
      final lines = linesOf(block);
      // The list goes on over blank lines as long as another item follows.
      while (at + 1 < blocks.length) {
        var next = at + 1;
        final gap = <String>[];
        while (next < blocks.length && blocks[next].kind == BlockKind.blank) {
          gap.addAll(linesOf(blocks[next]));
          next++;
        }
        if (next >= blocks.length || blocks[next].kind != BlockKind.listItem) {
          break;
        }
        lines
          ..addAll(gap)
          ..addAll(linesOf(blocks[next]));
        at = next;
      }
      units.add((kind: _Unit.list, lines: lines));
      continue;
    }
    final kind = switch (block.kind) {
      BlockKind.frontmatter ||
      BlockKind.indentedCode ||
      BlockKind.math ||
      BlockKind.html ||
      BlockKind.table => _Unit.opaque,
      BlockKind.fencedCode => _Unit.fence,
      BlockKind.heading => _Unit.heading,
      _ => _Unit.prose,
    };
    units.add((kind: kind, lines: linesOf(block)));
  }
  return units;
}

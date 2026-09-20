/// Tidying a note's Markdown (#227).
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
/// that loses things: fenced code, tables, math, frontmatter and HTML
/// pass through untouched, and so does the prose inside a paragraph —
/// no reflowing, no rewrapping, nothing that would make a diff of a note
/// unreadable.
///
/// What it does:
///
/// * a line that continues a list item is indented to that item's text,
///   so the item stays one item;
/// * a heading gets exactly one space after its hashes (`#Title`, which
///   is a paragraph and not a heading at all, is left alone: tidying is
///   not the place to change what a line means);
/// * runs of blank lines collapse to one, and the trailing ones go;
/// * trailing spaces go, except the ones that mean a line break, kept as
///   exactly two — and dropped at the end of a block, where they break
///   nothing;
/// * the note ends with exactly one newline.
///
/// Formatting twice changes nothing the second time, which the tests
/// hold for every case they cover.
library;

import 'dart:convert';

import 'package:niman/src/editor/wysiwyg/markdown_blocks.dart';

/// The line separator the app normalizes to.
const String _newline = '\n';

/// `- `, `* `, `+ `, `1. `, `1) ` — a list item's marker, with the
/// indent it sits at and the column its text starts in.
final RegExp _marker = RegExp(r'^(\s*)([-*+]|\d{1,9}[.)])(\s+)');

/// A heading's hashes, however they are spaced from the text.
final RegExp _heading = RegExp(r'^(\s{0,3})(#{1,6})[ \t]*(\S.*)?$');

/// Tidies [source]; an empty note stays empty.
String formatMarkdown(String source) {
  if (source.trim().isEmpty) return source.isEmpty ? source : _newline;
  final out = <String>[];
  for (final block in splitMarkdownBlocks(source)) {
    // Frontmatter, fences, tables, math, HTML: whatever the codec keeps
    // verbatim, this keeps verbatim too. The one exception is the
    // trailing blank lines a block carries, which the joining below
    // decides instead.
    final lines = const LineSplitter().convert(block.source);
    final tidied = block.opaque
        ? lines
        : switch (block.tag) {
            'ul' || 'ol' => _list(lines),
            'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6' => _headings(lines),
            _ => lines.map(_trimEnd).toList(),
          };
    final body = _withoutTrailingBlanks(tidied);
    if (body.isEmpty) continue;
    // A break on the last line of a block breaks nothing.
    if (!block.opaque) body[body.length - 1] = body.last.trimRight();
    if (out.isNotEmpty) out.add('');
    out.addAll(body);
  }
  return '${out.join(_newline)}$_newline';
}

/// A list block: every item keeps its marker, and a line that continues
/// one is indented to that item's text.
///
/// The continuation is what this is for. `1. a long item` wrapped onto a
/// bare next line is still that item to a parser, but it is written back
/// as a paragraph inside the list and the numbering starts again under
/// it; indented to the item's own text column it survives every trip
/// through the editors.
List<String> _list(List<String> lines) {
  final out = <String>[];
  var contentColumn = 0;
  for (final raw in lines) {
    final line = _trimEnd(raw);
    if (line.trim().isEmpty) {
      out.add('');
      continue;
    }
    final marker = _marker.firstMatch(line);
    if (marker != null) {
      contentColumn =
          marker.group(1)!.length +
          marker.group(2)!.length +
          marker.group(3)!.length;
      out.add(line);
      continue;
    }
    final indent = line.length - line.trimLeft().length;
    if (contentColumn == 0 || indent >= contentColumn) {
      out.add(line);
      continue;
    }
    out.add('${' ' * contentColumn}${line.trimLeft()}');
  }
  return out;
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

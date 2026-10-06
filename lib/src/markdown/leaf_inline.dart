/// A leaf's inline text, read off the note with where each piece of it
/// stands there ([SourceMap]): what the inline parser is given, and the
/// way its offsets go back to the note's lines.
///
/// The text is the writer's (`LeafText`, `TableHtml.cellsOf`), character
/// for character — asserted — so the read view, `live` and the HTML read
/// one text.
library;

import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/html/leaf_text.dart';
import 'package:niman/src/markdown/html/table_html.dart';
import 'package:niman/src/markdown/source_map.dart';

/// A leaf's inline text and its map.
typedef MappedText = ({String text, SourceMap map});

/// Reads a leaf's inline text off the note's lines.
abstract final class LeafInline {
  /// A paragraph's text over [spans], lines of the note read by [lineAt]:
  /// each line's leading white space off, the last line's trailing white
  /// space too, the lines joined by `\n` ([LeafText.paragraph]).
  static MappedText paragraph(
    List<SourceSpan> spans,
    String Function(int line) lineAt,
  ) {
    final text = StringBuffer();
    final map = SourceMap();
    for (var at = 0; at < spans.length; at++) {
      final span = spans[at];
      final line = lineAt(span.line);
      var start = span.start;
      while (start < span.end && _isBlank(line.codeUnitAt(start))) {
        start++;
      }
      var end = span.end;
      if (at == spans.length - 1) {
        while (end > start && _isBlank(line.codeUnitAt(end - 1))) {
          end--;
        }
      }
      if (at > 0) text.write('\n');
      map.add(text.length, end - start, span.line, start);
      text.write(line.substring(start, end));
    }
    final out = text.toString();
    assert(
      out == LeafText.paragraph(_linesOf(spans, lineAt)),
      'the writer reads the same text',
    );
    return (text: out, map: map);
  }

  /// A setext heading's text: its lines but the underline, as a
  /// paragraph's.
  static MappedText setextHeading(
    List<SourceSpan> spans,
    String Function(int line) lineAt,
  ) => paragraph(spans.sublist(0, spans.length - 1), lineAt);

  /// An ATX heading's text on [span]: its `#`s off, the white space around
  /// it, and a closing run of `#`s white space stands before
  /// ([LeafText.atxHeading]).
  static MappedText atxHeading(
    SourceSpan span,
    String Function(int line) lineAt,
  ) {
    final line = lineAt(span.line);
    final raw = line.substring(span.start, span.end);
    final text = LeafText.atxHeading(raw);
    var start = 0;
    while (start < raw.length && _isBlank(raw.codeUnitAt(start))) {
      start++;
    }
    while (start < raw.length && raw.codeUnitAt(start) == 0x23) {
      start++;
    }
    while (start < raw.length && _isBlank(raw.codeUnitAt(start))) {
      start++;
    }
    assert(raw.startsWith(text, start), 'the text is where the line has it');
    final map = SourceMap()..add(0, text.length, span.line, span.start + start);
    return (text: text, map: map);
  }

  /// The cells of a table's row on [span]: split at the pipes no backslash
  /// escapes, its outer pipes off, each trimmed, `\|` read as `|` — the
  /// backslash no character of the cell's text, and of its map
  /// ([TableHtml.cellsOf]).
  static List<MappedText> cells(
    SourceSpan span,
    String Function(int line) lineAt,
  ) {
    final line = lineAt(span.line);
    var start = span.start;
    var end = span.end;
    while (start < end && _isSpace(line.codeUnitAt(start))) {
      start++;
    }
    while (end > start && _isSpace(line.codeUnitAt(end - 1))) {
      end--;
    }
    if (start < end && line.codeUnitAt(start) == 0x7C) start++;
    if (end > start &&
        line.codeUnitAt(end - 1) == 0x7C &&
        !(end - 2 >= start && line.codeUnitAt(end - 2) == 0x5C)) {
      end--;
    }
    final out = <MappedText>[];
    var from = start;
    for (var at = start; at <= end; at++) {
      if (at < end && line.codeUnitAt(at) == 0x5C && at + 1 < end) {
        if (line.codeUnitAt(at + 1) == 0x7C) at++;
        continue;
      }
      if (at < end && line.codeUnitAt(at) != 0x7C) continue;
      out.add(_cell(line, span.line, from, at));
      from = at + 1;
    }
    assert(
      _sameCells(out, TableHtml.cellsOf(line.substring(span.start, span.end))),
      'the writer reads the same cells',
    );
    return out;
  }

  /// The cell of [line] between [start] and [end], trimmed, `\|` read as
  /// `|`.
  static MappedText _cell(String line, int lineIndex, int start, int end) {
    var a = start;
    var b = end;
    while (a < b && _isSpace(line.codeUnitAt(a))) {
      a++;
    }
    while (b > a && _isSpace(line.codeUnitAt(b - 1))) {
      b--;
    }
    final text = StringBuffer();
    final map = SourceMap();
    var from = a;
    for (var at = a; at < b; at++) {
      if (line.codeUnitAt(at) == 0x5C &&
          at + 1 < b &&
          line.codeUnitAt(at + 1) == 0x7C) {
        map.add(text.length, at - from, lineIndex, from);
        text.write(line.substring(from, at));
        from = at + 1;
        at++;
      }
    }
    map.add(text.length, b - from, lineIndex, from);
    text.write(line.substring(from, b));
    return (text: text.toString(), map: map);
  }

  static bool _sameCells(List<MappedText> cells, List<String> written) {
    if (cells.length != written.length) return false;
    for (var at = 0; at < cells.length; at++) {
      if (cells[at].text != written[at]) return false;
    }
    return true;
  }

  static List<String> _linesOf(
    List<SourceSpan> spans,
    String Function(int line) lineAt,
  ) => [
    for (final span in spans) lineAt(span.line).substring(span.start, span.end),
  ];

  /// A space or a tab: what a paragraph's lines are trimmed of.
  static bool _isBlank(int char) => char == 0x20 || char == 0x09;

  /// What `String.trim` takes off a cell, as the writer trims one: the
  /// white space Dart's `trim` knows.
  static bool _isSpace(int char) =>
      (char >= 0x09 && char <= 0x0D) ||
      char == 0x20 ||
      char == 0x85 ||
      char == 0xA0 ||
      char == 0x1680 ||
      (char >= 0x2000 && char <= 0x200A) ||
      char == 0x2028 ||
      char == 0x2029 ||
      char == 0x202F ||
      char == 0x205F ||
      char == 0x3000 ||
      char == 0xFEFF;
}

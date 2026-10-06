/// Where a leaf's inline text stands in the note (`docs/dev/block-tree.md`).
///
/// The inline parser reads a leaf's text — a paragraph's lines without
/// their containers' marks and their leading white space, joined; a
/// heading's words; a table cell's — and every node it makes carries its
/// offsets in that text. This is the way back: the text in stretches, each
/// a piece of one line of the note, character for character. What joins
/// the stretches — a paragraph's line endings, a cell's `\` before a `|` —
/// is no stretch's, and maps nowhere.
library;

/// A leaf's inline text, mapped to the note.
final class SourceMap {
  /// An empty map, stretches added in text order ([add]).
  new();

  final List<int> _at = <int>[];
  final List<int> _lengths = <int>[];
  final List<int> _lines = <int>[];
  final List<int> _columns = <int>[];

  /// Adds the stretch of [length] characters at offset [at] of the text,
  /// which stands at [column] of the note's line [line].
  void add(int at, int length, int line, int column) {
    assert(_at.isEmpty || at >= _at.last + _lengths.last, 'in text order');
    if (length <= 0) return;
    _at.add(at);
    _lengths.add(length);
    _lines.add(line);
    _columns.add(column);
  }

  /// The pieces of the note `[start, end)` of the text covers, in order:
  /// one per line it reaches. Two stretches on one line are one piece, over
  /// what stands between them — a cell's `\` before its `|`: a construct
  /// covers the characters its text was read from.
  List<({int line, int start, int end})> spans(int start, int end) {
    final out = <({int line, int start, int end})>[];
    for (var at = _first(start); at < _at.length && _at[at] < end; at++) {
      final from = _at[at];
      final a = start > from ? start : from;
      final stretchEnd = from + _lengths[at];
      final b = end < stretchEnd ? end : stretchEnd;
      if (a >= b) continue;
      final piece = (
        line: _lines[at],
        start: _columns[at] + a - from,
        end: _columns[at] + b - from,
      );
      if (out.isNotEmpty && out.last.line == piece.line) {
        out.last = (line: piece.line, start: out.last.start, end: piece.end);
      } else {
        out.add(piece);
      }
    }
    return out;
  }

  /// What stands between two stretches of one line and is no character of
  /// the text: a cell's `\` before its `|`, which the text reads as `|`.
  List<({int line, int start, int end})> gaps() => [
    for (var at = 1; at < _at.length; at++)
      if (_lines[at] == _lines[at - 1] &&
          _columns[at] > _columns[at - 1] + _lengths[at - 1])
        (
          line: _lines[at],
          start: _columns[at - 1] + _lengths[at - 1],
          end: _columns[at],
        ),
  ];

  /// Where offset [offset] of the text is in the note, or null for a
  /// character that is no line's: a line ending between two of a
  /// paragraph's lines.
  ({int line, int column})? positionOf(int offset) {
    final at = _first(offset);
    if (at >= _at.length || _at[at] > offset) return null;
    return (line: _lines[at], column: _columns[at] + offset - _at[at]);
  }

  /// The same text from [offset] on: what is left of a paragraph once the
  /// definitions it starts with, or an item's task box, are taken off.
  SourceMap from(int offset) {
    final out = SourceMap();
    for (var at = 0; at < _at.length; at++) {
      final from = _at[at];
      final end = from + _lengths[at];
      if (end <= offset) continue;
      final cut = offset > from ? offset - from : 0;
      out.add(
        from + cut - offset,
        _lengths[at] - cut,
        _lines[at],
        _columns[at] + cut,
      );
    }
    return out;
  }

  /// The index of the first stretch that ends after [offset].
  int _first(int offset) {
    var low = 0;
    var high = _at.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_at[middle] + _lengths[middle] <= offset) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

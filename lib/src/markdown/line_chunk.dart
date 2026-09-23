/// One chunk of a note's lines, as `LineStore` keeps them.
///
/// A note is read as one string, and a chunk starts as a **view** of it:
/// the string and where each of its lines starts in it. Splitting the
/// 246 MB note into 2.76 M strings of their own was ~600 ms of its load and
/// a garbage collector walking 2.76 M objects for as long as it was open;
/// the view is ~2 700 chunks over the one string. A line is cut out of the
/// text when it is read.
///
/// The first write to a chunk turns it into its **lines**, a string each —
/// what every chunk was before — so an edit costs what it did: the line it
/// writes, never the chunk's text copied again.
///
/// A line's terminator is not stored in a view: it is the `\n` or `\r\n`
/// the line's span ends with, and nothing on the note's last line.
library;

import 'dart:typed_data';

/// A run of consecutive lines: a view of the text they were read from, or
/// the lines themselves.
final class LineChunk {
  /// A view of [source]: line `i` spans `[bounds[i], bounds[i + 1])`,
  /// terminator included.
  new view(String source, Uint32List bounds)
    : _source = source,
      _bounds = bounds,
      _lines = null,
      _terminators = null;

  /// [lines], each ended by the terminator at the same index of
  /// [terminators]. The chunk writes to both lists.
  new lines(List<String> lines, List<String> terminators)
    : assert(lines.length == terminators.length, 'one terminator per line'),
      _lines = lines,
      _terminators = terminators,
      _source = null,
      _bounds = null;

  final String? _source;
  final Uint32List? _bounds;
  final List<String>? _lines;
  final List<String>? _terminators;

  /// Whether the chunk is a view of the text it was read from, which no
  /// write may touch.
  bool get isView => _lines == null;

  /// How many lines the chunk holds.
  int get length => _lines?.length ?? _bounds!.length - 1;

  /// Line [local]'s text, without its terminator.
  String lineAt(int local) {
    final lines = _lines;
    if (lines != null) return lines[local];
    final start = _bounds![local];
    return _source!.substring(start, start + lineLengthAt(local));
  }

  /// Line [local]'s terminator: `''`, `'\n'` or `'\r\n'`.
  String terminatorAt(int local) {
    final terminators = _terminators;
    if (terminators != null) return terminators[local];
    return switch (_terminatorLength(local)) {
      0 => '',
      1 => '\n',
      _ => '\r\n',
    };
  }

  /// How long line [local]'s text is, without cutting it out.
  int lineLengthAt(int local) {
    final lines = _lines;
    if (lines != null) return lines[local].length;
    final bounds = _bounds!;
    return bounds[local + 1] - bounds[local] - _terminatorLength(local);
  }

  /// How long line [local] is with its terminator.
  int spanAt(int local) {
    final lines = _lines;
    if (lines != null) return lines[local].length + _terminators![local].length;
    final bounds = _bounds!;
    return bounds[local + 1] - bounds[local];
  }

  /// Writes lines `[from, to)` and their terminators to [sink]: a view's
  /// as one slice of its text.
  void writeTo(StringSink sink, int from, int to) {
    final lines = _lines;
    if (lines == null) {
      if (from < to) {
        sink.write(_source!.substring(_bounds![from], _bounds[to]));
      }
      return;
    }
    final terminators = _terminators!;
    for (var at = from; at < to; at++) {
      sink
        ..write(lines[at])
        ..write(terminators[at]);
    }
  }

  /// The chunk's lines `[from, to)`, a string each.
  List<String> linesIn(int from, int to) {
    final lines = _lines;
    if (lines != null) return lines.sublist(from, to);
    return <String>[for (var at = from; at < to; at++) lineAt(at)];
  }

  /// The terminators of the chunk's lines `[from, to)`.
  List<String> terminatorsIn(int from, int to) {
    final terminators = _terminators;
    if (terminators != null) return terminators.sublist(from, to);
    return <String>[for (var at = from; at < to; at++) terminatorAt(at)];
  }

  /// A chunk of the same lines that may be written to, apart from this one.
  LineChunk writable() =>
      LineChunk.lines(linesIn(0, length), terminatorsIn(0, length));

  /// Makes line [local] say [line], ended by [terminator]. A view refuses:
  /// the store makes the chunk [writable] first.
  void setLine(int local, String line, String terminator) {
    _lines![local] = line;
    _terminators![local] = terminator;
  }

  /// How long the terminator ending a view's line [local] is: 2 for `\r\n`,
  /// 1 for `\n`, 0 on the note's last line.
  int _terminatorLength(int local) {
    final bounds = _bounds!;
    final start = bounds[local];
    final end = bounds[local + 1];
    final source = _source!;
    if (end == start || source.codeUnitAt(end - 1) != 0x0A) return 0;
    return end - 1 > start && source.codeUnitAt(end - 2) == 0x0D ? 2 : 1;
  }
}

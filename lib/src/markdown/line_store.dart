/// A note's lines and their terminators, kept in chunks that a copy shares.
///
/// Two costs of a flat line array were a note's length where they should
/// have been an edit's (`docs/dev/huge-notes.md`):
///
/// * **A copy** — the read pane is handed a snapshot of the editor's note
///   that the editor's edits no longer reach — copied both arrays and rebuilt
///   the line index: ~350 ms on the 246 MB note, on the frame that opened
///   the pane.
/// * **An edit that adds or removes a line** moved every line after it:
///   20 ms per Enter on the same note.
///
/// So the lines live in chunks of about [LineStore.chunkSize]. A copy takes
/// the list of chunks, not the lines — about 2 700 for 2.76 M lines — and
/// the two share every chunk until one of them writes to it; a write copies
/// the one chunk it lands in first (copy on write, per chunk). An edit that
/// changes the line count rewrites the chunks it touches and the chunk
/// starts, never the lines past it.
///
/// Reading stays cheap: line *i* is found by its chunk's start, and the chunk
/// the last read landed in is tried first, so a walk down the note — the
/// block scanner reads every line in order — does not search at all.
library;

/// Chunked lines and terminators, shared by copies until written.
final class LineStore {
  /// Holds [lines], each ended by the terminator at the same index of
  /// [terminators].
  new(List<String> lines, List<String> terminators)
    : assert(lines.length == terminators.length, 'one terminator per line') {
    for (var at = 0; at < lines.length; at += chunkSize) {
      final end = at + chunkSize < lines.length ? at + chunkSize : lines.length;
      _lines.add(lines.sublist(at, end));
      _terminators.add(terminators.sublist(at, end));
      _owned.add(true);
    }
    _restart();
  }

  /// A store holding what [other] holds now, apart from it: a write to
  /// either is not seen by the other. O(chunks).
  new sharing(LineStore other) : _cursor = 0, _length = other._length {
    _lines.addAll(other._lines);
    _terminators.addAll(other._terminators);
    _starts = List<int>.of(other._starts);
    _owned.addAll(List<bool>.filled(other._owned.length, false));
    other._owned.fillRange(0, other._owned.length, false);
  }

  /// How many lines a chunk is cut to, and half of what it may grow to
  /// before it is cut again.
  static const int chunkSize = 1024;

  final List<List<String>> _lines = <List<String>>[];
  final List<List<String>> _terminators = <List<String>>[];

  /// Whether this store may write to chunk *c* in place: false for a chunk
  /// it shares with a copy.
  final List<bool> _owned = <bool>[];

  /// Where each chunk starts, and the line count after the last: one entry
  /// more than there are chunks.
  List<int> _starts = <int>[0];

  /// The chunk the last read landed in.
  int _cursor = 0;

  int _length = 0;

  /// How many lines there are.
  int get length => _length;

  /// How many chunks the lines are kept in.
  int get chunkCount => _lines.length;

  /// Line [index].
  String lineAt(int index) {
    final chunk = _chunkOf(index);
    return _lines[chunk][index - _starts[chunk]];
  }

  /// Line [index]'s terminator.
  String terminatorAt(int index) {
    final chunk = _chunkOf(index);
    return _terminators[chunk][index - _starts[chunk]];
  }

  /// Replaces lines `[start, end)` with [lines], ended by [terminators].
  ///
  /// O(the lines written + the chunks) when the line count changes, and
  /// O(the lines written) when it does not.
  void replaceRange(
    int start,
    int end,
    List<String> lines,
    List<String> terminators,
  ) {
    assert(lines.length == terminators.length, 'one terminator per line');
    assert(0 <= start && start <= end && end <= _length, 'bad range');
    if (end - start == lines.length) {
      for (var at = 0; at < lines.length; at++) {
        final chunk = _chunkOf(start + at);
        _own(chunk);
        final local = start + at - _starts[chunk];
        _lines[chunk][local] = lines[at];
        _terminators[chunk][local] = terminators[at];
      }
      return;
    }
    // The chunks the range runs through, and where it starts and ends in
    // the first and the last of them. A range at the very end is the end of
    // the last chunk.
    final first = start == _length ? _lines.length - 1 : _chunkOf(start);
    final last = end == start
        ? first
        : end == _length
        ? _lines.length - 1
        : _chunkOf(end - 1);
    final from = start - _starts[first];
    final to = end - _starts[last];
    final touchedLines = <String>[
      ..._lines[first].take(from),
      ...lines,
      ..._lines[last].skip(to),
    ];
    final touchedTerminators = <String>[
      ..._terminators[first].take(from),
      ...terminators,
      ..._terminators[last].skip(to),
    ];
    final cutLines = <List<String>>[];
    final cutTerminators = <List<String>>[];
    if (touchedLines.length <= 2 * chunkSize) {
      if (touchedLines.isNotEmpty) {
        cutLines.add(touchedLines);
        cutTerminators.add(touchedTerminators);
      }
    } else {
      for (var at = 0; at < touchedLines.length; at += chunkSize) {
        final stop = at + chunkSize < touchedLines.length
            ? at + chunkSize
            : touchedLines.length;
        cutLines.add(touchedLines.sublist(at, stop));
        cutTerminators.add(touchedTerminators.sublist(at, stop));
      }
    }
    _lines.replaceRange(first, last + 1, cutLines);
    _terminators.replaceRange(first, last + 1, cutTerminators);
    _owned.replaceRange(
      first,
      last + 1,
      List<bool>.filled(cutLines.length, true),
    );
    _restart();
  }

  /// Makes chunk [chunk] this store's own, copying it if a copy shares it.
  void _own(int chunk) {
    if (_owned[chunk]) return;
    _lines[chunk] = List<String>.of(_lines[chunk]);
    _terminators[chunk] = List<String>.of(_terminators[chunk]);
    _owned[chunk] = true;
  }

  /// The chunk line [index] is in: the last read's, or its neighbour's —
  /// a walk down the note — or found by the chunk starts.
  int _chunkOf(int index) {
    assert(index >= 0 && index < _length, 'line $index out of range');
    final chunk = _cursor;
    if (index >= _starts[chunk]) {
      if (index < _starts[chunk + 1]) return chunk;
      if (chunk + 2 < _starts.length && index < _starts[chunk + 2]) {
        return _cursor = chunk + 1;
      }
    }
    var low = 0;
    var high = _lines.length - 1;
    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (_starts[middle] <= index) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return _cursor = low;
  }

  /// Recomputes the chunk starts after the chunks changed, O(chunks).
  void _restart() {
    if (_lines.isEmpty) {
      _lines.add(<String>[]);
      _terminators.add(<String>[]);
      _owned.add(true);
    }
    final starts = List<int>.filled(_lines.length + 1, 0);
    for (var at = 0; at < _lines.length; at++) {
      starts[at + 1] = starts[at] + _lines[at].length;
    }
    _starts = starts;
    _length = starts.last;
    _cursor = 0;
  }
}

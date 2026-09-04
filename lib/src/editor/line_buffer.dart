/// Plain-text line buffer: the edit model of the M2a line-based editor.
///
/// The content is a list of lines; the full text is the lines joined with
/// `\n`. Every offset in this API is a UTF-16 code unit position over the
/// full text (a line break counts as one unit), which is the same position
/// space as `TextEditingValue`.
///
/// The buffer holds text only. Highlighting (T-M2-02), visual-row wrapping
/// (M2a E2) and folding are presentation layers built on top of this model.
library;

/// The editor's plain-text edit model, split into lines.
///
/// Lines are split on `\n` only; a `\r` stays part of the line content
/// (normalizing CRLF files belongs to the load path, not the model).
final class LineBuffer {
  /// Creates an empty buffer (a single empty line, empty text).
  LineBuffer() : this._(<String>['']);

  /// Creates a buffer from [text], splitting it on `\n`.
  factory LineBuffer.fromText(String text) => LineBuffer._(text.split('\n'));

  LineBuffer._(List<String> lines) {
    _lines = lines;
    _resetPositions();
  }

  List<String> _lines = <String>[''];
  List<int> _lineStarts = const <int>[];

  /// Whether the buffer holds no text at all.
  bool get isEmpty => textLength == 0;

  /// The number of lines; a trailing `\n` yields a final empty line.
  int get lineCount => _lines.length;

  /// The full text length in UTF-16 code units, line breaks included.
  int get textLength => _lineStarts.last + _lines.last.length;

  /// The full text: lines joined with `\n`.
  ///
  /// O(text length) — for saving, initial load and tests, not hot paths.
  String get text => _lines.join('\n');

  /// Line [line], which never contains `\n`.
  String lineAt(int line) {
    _requireRange(line, 0, lineCount - 1, 'line');
    return _lines[line];
  }

  /// The length of line [line] in UTF-16 code units.
  int lineLength(int line) {
    _requireRange(line, 0, lineCount - 1, 'line');
    return _lines[line].length;
  }

  /// The (line, column) of full-text offset [offset].
  ///
  /// [offset] may be any value in 0..=textLength; `textLength` maps to the
  /// end of the last line. The column is in UTF-16 units within the line.
  (int, int) locationOf(int offset) {
    _requireRange(offset, 0, textLength, 'offset');
    final line = _lineAt(offset);
    return (line, offset - _lineStarts[line]);
  }

  /// The full-text offset of position (line [line], column [col]).
  int offsetOf(int line, int col) {
    _requireRange(line, 0, lineCount - 1, 'line');
    _requireRange(col, 0, _lines[line].length, 'col');
    return _lineStarts[line] + col;
  }

  /// Replaces the full-text offset range [start, end) with [insertion].
  ///
  /// [insertion] may contain `\n` (each one adds a line). `end == start`
  /// is a pure insertion; `insertion == ''` is a pure deletion.
  void replace(int start, int end, String insertion) {
    _requireRange(start, 0, textLength, 'start');
    _requireRange(end, start, textLength, 'end');
    if (start == end && insertion.isEmpty) return;

    final (firstLine, firstCol) = locationOf(start);
    final (lastLine, lastCol) = locationOf(end);
    final before = _lines[firstLine].substring(0, firstCol);
    final after = _lines[lastLine].substring(lastCol);
    final inserted = insertion.split('\n');
    if (inserted.length == 1) {
      _lines.replaceRange(
        firstLine,
        lastLine + 1,
        <String>[before + inserted.single + after],
      );
    } else {
      _lines.replaceRange(
        firstLine,
        lastLine + 1,
        <String>[
          before + inserted.first,
          ...inserted.sublist(1, inserted.length - 1),
          inserted.last + after,
        ],
      );
    }
    _resetPositions();
  }

  /// Inserts [text] at full-text offset [offset].
  void insert(int offset, String text) => replace(offset, offset, text);

  /// Deletes the full-text offset range [start, end).
  void delete(int start, int end) => replace(start, end, '');

  /// The text of the full-text offset range [start, end), `\n`-joined across
  /// lines. O(range) — does not materialize the full text (unlike [text]).
  String substring(int start, int end) {
    _requireRange(start, 0, textLength, 'start');
    _requireRange(end, start, textLength, 'end');
    if (start == end) return '';
    final (firstLine, firstCol) = locationOf(start);
    final (lastLine, lastCol) = locationOf(end);
    if (firstLine == lastLine) {
      return _lines[firstLine].substring(firstCol, lastCol);
    }
    return <String>[
      _lines[firstLine].substring(firstCol),
      ..._lines.sublist(firstLine + 1, lastLine),
      _lines[lastLine].substring(0, lastCol),
    ].join('\n');
  }

  /// Rebuilds [_lineStarts] (the full-text offset of every line).
  void _resetPositions() {
    final count = _lines.length;
    final starts = List<int>.filled(count, 0);
    var pos = 0;
    for (var i = 0; i < count; i++) {
      starts[i] = pos;
      pos += _lines[i].length + 1;
    }
    _lineStarts = starts;
  }

  static void _requireRange(int value, int low, int high, String name) {
    if (value < low || value > high) {
      throw ArgumentError.value(
        value,
        name,
        'must be within $low..=$high',
      );
    }
  }

  /// The line containing full-text offset [offset] (O(log lines)).
  int _lineAt(int offset) {
    final starts = _lineStarts;
    var low = 0;
    var high = starts.length;
    while (high - low > 1) {
      final mid = (low + high) >> 1;
      if (starts[mid] <= offset) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }
}

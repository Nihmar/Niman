/// The note's text, as lines, with an O(log n) offset ↔ line index.
///
/// This is the bottom of the new Markdown surface
/// (`docs/dev/unified-surface.md` §8.2): the note's Markdown *is* the document,
/// and this holds it. Everything above — the block scanner, the inline parser,
/// the height map, the caret — speaks in absolute source offsets, while
/// Markdown
/// parsing speaks in lines, so the two conversions are on every hot path and
/// both are O(log n) here rather than O(n).
///
/// **A line array, not a rope.** Markdown is line-structured: every block
/// decision except fenced code, HTML blocks and indented code is a per-line
/// decision, and those three are still decided per line with a carried state. A
/// rope would be more general than the parser can use, and would charge an
/// `offsetToLine` for every access the parser makes. [PrefixSums] restores the
/// one thing a rope gives for free.
///
/// **Cost, stated honestly.** Typing inside a line resizes one span:
/// [PrefixSums.setValue], O(chunk). An edit that changes *how many* lines there
/// are — Enter, a paste with newlines, a line joined — splices the index, which
/// rewrites one chunk of it rather than the note (a rebuilt Fenwick tree was
/// 41 ms per Enter at a million lines); what is left is the line array's own
/// move of the lines after the edit, a memory copy.
/// `source_buffer_test.dart` measures both, and the numbers are in the design
/// document.
///
/// **What is preserved, exactly.** Each line's terminator is stored separately,
/// so a file read as CRLF comes back as CRLF, a file with mixed terminators
/// keeps them line by line, a byte-order mark stays in the first line, and tabs
/// are never expanded. `text` is byte-faithful against what was read until
/// something actually changes it — which makes "disk is source of truth" a
/// property of the data structure rather than a promise from the code above it.
///
/// The one deliberate normalisation is on *insert*: text entering the buffer
/// has
/// its terminators rewritten to the document's dominant one, so typing in a
/// CRLF
/// file cannot quietly make it a mixed-EOL file. A lone `\r` is content, not a
/// terminator, because nothing in the app has ever produced one.
library;

import 'package:niman/src/markdown/prefix_sums.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// The text of a note, split into lines, with an index over it.
final class SourceBuffer {
  /// Wraps already-split lines and terminators.
  ///
  /// Private: the two lists must agree in length, and only `fromText` and the
  /// edit path can promise that.
  new _(this._lines, this._terminators, this._index)
    : _dominantEol = _detectEol(_terminators),
      _length = _index.total.toInt();

  /// Reads [text] into lines, keeping each line's own terminator.
  ///
  /// O(n) once, at load. An empty string is one empty line, not zero lines: a
  /// buffer always has at least one, which is what lets the index always answer
  /// with a valid line.
  factory fromText(String text) {
    final lines = <String>[];
    final terminators = <String>[];
    var start = 0;
    while (true) {
      final at = text.indexOf('\n', start);
      if (at < 0) {
        lines.add(text.substring(start));
        terminators.add('');
        break;
      }
      // A `\r` immediately before the `\n` belongs to the terminator, not to
      // the line: that is what makes CRLF round-trip as CRLF.
      final endsWithCr = at > start && text.codeUnitAt(at - 1) == 0x0D;
      lines.add(text.substring(start, endsWithCr ? at - 1 : at));
      terminators.add(endsWithCr ? '\r\n' : '\n');
      start = at + 1;
    }
    return SourceBuffer._(
      lines,
      terminators,
      PrefixSums(_spansOf(lines, terminators)),
    );
  }

  /// An empty buffer: one empty line, LF.
  factory empty() => SourceBuffer.fromText('');

  /// A buffer holding what this one holds now, which this one's edits no
  /// longer reach.
  ///
  /// The lines are the same strings — a string never changes, so sharing it
  /// is free — and only the two lists and the line index are new: O(lines),
  /// where [SourceBuffer.fromText] over the joined text is O(characters)
  /// twice. It is how the read pane gets the editor's note without a copy of
  /// its text: a
  /// 114 MB note took seconds to join, compare and split again for a preview
  /// that already had every line in memory (0.0.9 stress test).
  SourceBuffer snapshot() => SourceBuffer._(
    List<String>.of(_lines),
    List<String>.of(_terminators),
    PrefixSums(_spansOf(_lines, _terminators)),
  );

  /// The lines, without their terminators.
  final List<String> _lines;

  /// Each line's terminator: `''`, `'\n'` or `'\r\n'`.
  final List<String> _terminators;

  /// The prefix sums of `line.length + terminator.length`.
  final PrefixSums _index;

  /// The terminator newlines are rewritten to on insert.
  final String _dominantEol;

  /// The text's length in UTF-16 code units, terminators included.
  ///
  /// Kept in step with `_index.total`, which is the buffer's central invariant
  /// and is asserted after every edit.
  int _length;

  int _revision = 0;

  /// How many times the text has changed.
  ///
  /// Every derived structure — the block index, the inline spans, the height
  /// map
  /// — is stamped with the revision it was computed from and invalidated by
  /// comparison, rather than by a notification graph. That is what keeps a
  /// keystroke from fanning out to every listener in the app.
  int get revision => _revision;

  /// The text's length in UTF-16 code units, terminators included.
  int get length => _length;

  /// How many lines there are. Always at least one.
  int get lineCount => _lines.length;

  /// The terminator newlines are rewritten to when text is inserted.
  String get eol => _dominantEol;

  /// Whether the text starts with a byte-order mark.
  ///
  /// The mark stays in the first line rather than being lifted out, so offsets
  /// stay absolute over the whole file; a reader that cares — the frontmatter
  /// check, for one — has to tolerate it.
  bool get hasBom => _lines.first.startsWith('\uFEFF');

  /// The whole text, exactly as it would be written to disk.
  ///
  /// O(n): it reassembles every line. A caller on a hot path wants [lineAt] or
  /// [substring] instead; saving a note is what this exists for.
  String get text {
    final buffer = StringBuffer();
    for (var i = 0; i < _lines.length; i++) {
      buffer
        ..write(_lines[i])
        ..write(_terminators[i]);
    }
    return buffer.toString();
  }

  /// Line [line]'s text, without its terminator.
  String lineAt(int line) {
    assert(line >= 0 && line < _lines.length, 'line $line out of range');
    return _lines[line];
  }

  /// Line [line]'s terminator: `''` for the last line when the file does not
  /// end
  /// with one.
  String terminatorAt(int line) {
    assert(line >= 0 && line < _lines.length, 'line $line out of range');
    return _terminators[line];
  }

  /// [offset] as a caret can stand: inside the note, and never between the
  /// two characters of a `\r\n` — the pair is one line end, and an offset
  /// inside it is the end of the line's text. O(log n).
  int caretOffset(int offset) {
    final clamped = offset < 0 ? 0 : (offset > _length ? _length : offset);
    final line = lineOf(clamped);
    final end = offsetOfLine(line) + _lines[line].length;
    return clamped > end ? end : clamped;
  }

  /// The line [offset] falls in.
  ///
  /// O(log n). An offset inside a line's terminator belongs to that line, and
  /// an
  /// offset at [length] belongs to the last one.
  int lineOf(int offset) {
    assert(offset >= 0 && offset <= _length, 'offset $offset out of range');
    return _index.indexOf(offset.toDouble());
  }

  /// The offset at which line [line] starts.
  ///
  /// O(log n). [lineCount] is accepted and answers [length].
  int offsetOfLine(int line) {
    assert(line >= 0 && line <= _lines.length, 'line $line out of range');
    return _index.offsetOf(line).toInt();
  }

  /// How far into its line [offset] is, in UTF-16 code units.
  ///
  /// An offset inside a terminator gives a column past the line's own length,
  /// which is the honest answer: the caret is not between two visible
  /// characters.
  int columnOf(int offset) => offset - offsetOfLine(lineOf(offset));

  /// The offset of [column] on [line].
  ///
  /// The inverse of [columnOf], clamped into the line: a column past its end,
  /// or
  /// inside its terminator, answers the line's end rather than the next line's
  /// start.
  int offsetAt(int line, int column) {
    final start = offsetOfLine(line);
    final within = column < 0 ? 0 : column;
    final text = _lines[line].length;
    return start + (within > text ? text : within);
  }

  /// The text between [start] and [end], terminators included.
  ///
  /// O(the range), not O(the document) — this is what copying a selection
  /// costs.
  String substring(int start, int end) {
    assert(
      start >= 0 && end >= start && end <= _length,
      'bad range $start..$end',
    );
    final buffer = StringBuffer();
    var line = lineOf(start);
    var offset = start;
    while (offset < end && line < _lines.length) {
      final lineStart = offsetOfLine(line);
      final lineEnd = lineStart + _lines[line].length;
      if (offset < lineEnd) {
        final to = end < lineEnd ? end : lineEnd;
        buffer.write(
          _lines[line].substring(offset - lineStart, to - lineStart),
        );
        offset = to;
        if (offset >= end) break;
      }
      final terminatorEnd = lineEnd + _terminators[line].length;
      if (offset < terminatorEnd) {
        final to = end < terminatorEnd ? end : terminatorEnd;
        buffer.write(
          _terminators[line].substring(offset - lineEnd, to - lineEnd),
        );
        offset = to;
      }
      line++;
    }
    return buffer.toString();
  }

  /// Inserts [inserted] at [offset].
  SourceEdit insert(int offset, String inserted) =>
      replaceRange(offset, offset, inserted);

  /// Deletes `[start, end)`.
  SourceEdit delete(int start, int end) => replaceRange(start, end, '');

  /// Replaces `[start, end)` with [replacement], and bumps the revision.
  ///
  /// The general edit: an insertion is an empty range, a deletion an empty
  /// replacement. Terminators in [replacement] are rewritten to the document's
  /// dominant one, so an edit cannot introduce a second line-ending style; the
  /// terminator the replaced range's *last* line had is kept, so the text after
  /// the edit is untouched.
  ///
  /// With [verbatim], the replacement's terminators are kept as they are
  /// rather than rewritten: what an undo needs, because it puts back text the
  /// note held — a mixed-ending file's `\n` in a CRLF note included — and a
  /// rewrite would make the undone text a different length from the record.
  SourceEdit replaceRange(
    int start,
    int end,
    String replacement, {
    bool verbatim = false,
  }) {
    assert(
      start >= 0 && end >= start && end <= _length,
      'bad range $start..$end',
    );
    if (start == end && replacement.isEmpty) {
      return SourceEdit(
        firstLine: lineOf(start),
        removedLines: 1,
        insertedLines: 1,
        revision: _revision,
      );
    }

    final startLine = lineOf(start);
    final startColumn = start - offsetOfLine(startLine);
    final endLine = lineOf(end);
    final endColumn = end - offsetOfLine(endLine);

    // A boundary inside a terminator swallows the terminator, so the prefix is
    // the whole line and the suffix is empty.
    final prefix = startColumn < _lines[startLine].length
        ? _lines[startLine].substring(0, startColumn)
        : _lines[startLine];
    final suffix = endColumn < _lines[endLine].length
        ? _lines[endLine].substring(endColumn)
        : '';

    final inserted = _splitInserted(replacement);
    final ownEols = verbatim ? _eolsOf(replacement) : null;
    final merged = <String>[];
    final terminators = <String>[];
    merged.add('$prefix${inserted.first}');
    for (var i = 1; i < inserted.length - 1; i++) {
      merged.add(inserted[i]);
    }
    if (inserted.length > 1) {
      for (var i = 0; i < inserted.length - 1; i++) {
        terminators.add(ownEols?[i] ?? _dominantEol);
      }
      merged.add('${inserted.last}$suffix');
    } else {
      merged[0] = '${merged[0]}$suffix';
    }
    // The last merged line stands where `endLine` stood, so it inherits the
    // terminator that follows the edited region rather than inventing one.
    terminators.add(_terminators[endLine]);

    final removedCount = endLine - startLine + 1;
    _lines.replaceRange(startLine, endLine + 1, merged);
    _terminators.replaceRange(startLine, endLine + 1, terminators);

    if (merged.length == removedCount) {
      // Same line count: one span resized per line, O(log n) each.
      for (var i = 0; i < merged.length; i++) {
        _index.setValue(startLine + i, _spanOf(startLine + i).toDouble());
      }
    } else {
      // The line count moved: the index takes the new lines' spans in place
      // of the old ones, and every offset after them follows.
      _index.splice(startLine, removedCount, <double>[
        for (var i = 0; i < merged.length; i++)
          _spanOf(startLine + i).toDouble(),
      ]);
    }

    _length = _index.total.toInt();
    _revision++;
    assert(_validate(), 'buffer invariants broken after the edit');
    return SourceEdit(
      firstLine: startLine,
      removedLines: removedCount,
      insertedLines: merged.length,
      revision: _revision,
    );
  }

  /// The terminators [text] has, in order: `\r\n` or `\n`.
  static List<String> _eolsOf(String text) {
    final eols = <String>[];
    var at = text.indexOf('\n');
    while (at >= 0) {
      eols.add(at > 0 && text.codeUnitAt(at - 1) == 0x0D ? '\r\n' : '\n');
      at = text.indexOf('\n', at + 1);
    }
    return eols;
  }

  /// [offset], moved out of a `\r\n` it falls in the middle of: back to the
  /// end of the line's text, or with [forward] on to the next line's start.
  ///
  /// Nothing the surface does puts an offset there — a tap, an arrow key and
  /// the caret all stay on characters — but the platform addresses the whole
  /// text, terminators and all, and an edit that starts between the two units
  /// of a line break splits it.
  int snapOutOfTerminator(int offset, {bool forward = false}) {
    if (offset <= 0 || offset >= _length) return offset;
    final line = lineOf(offset);
    final textEnd = offsetOfLine(line) + _lines[line].length;
    if (offset <= textEnd) return offset;
    return forward ? offsetOfLine(line + 1) : textEnd;
  }

  /// The span of line [index]: its text plus its terminator.
  int _spanOf(int index) => _lines[index].length + _terminators[index].length;

  /// [inserted] as lines, terminators rewritten to the dominant one.
  List<String> _splitInserted(String inserted) {
    if (inserted.isEmpty) return <String>[''];
    final parts = inserted.split('\n');
    if (parts.length == 1) return parts;
    for (var i = 0; i < parts.length; i++) {
      // `\n` split leaves the `\r` of a `\r\n` on the end of the segment.
      if (parts[i].endsWith('\r')) {
        parts[i] = parts[i].substring(0, parts[i].length - 1);
      }
    }
    return parts;
  }

  /// Whether the arrays, the index and [length] agree.
  bool _validate() {
    var sum = 0;
    for (var i = 0; i < _lines.length; i++) {
      sum += _spanOf(i);
      if (_index.offsetOf(i) != sum - _spanOf(i)) return false;
    }
    return sum == _length &&
        _index.total == _length &&
        _index.length == _lines.length;
  }

  /// The dominant terminator of [terminators]: CRLF only if it is the majority.
  static String _detectEol(List<String> terminators) {
    var crlf = 0;
    var lf = 0;
    for (final terminator in terminators) {
      if (terminator == '\r\n') {
        crlf++;
      } else if (terminator == '\n') {
        lf++;
      }
    }
    return crlf > lf ? '\r\n' : '\n';
  }

  /// The spans of every line, for building or rebuilding the index.
  static List<double> _spansOf(List<String> lines, List<String> terminators) =>
      <double>[
        for (var i = 0; i < lines.length; i++)
          (lines[i].length + terminators[i].length).toDouble(),
      ];
}

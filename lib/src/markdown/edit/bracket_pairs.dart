/// Brackets typed in pairs, in `source` and in `live`: `(` writes `()`, `[`
/// writes `[]`, `{` writes `{}`, the caret between the two.
///
/// What every code editor does, and what a Markdown note wants as much: a
/// link is `[text](target)`, a wikilink `[[note]]`, a task `- [ ] `. Four
/// rules, each the one a writer expects:
///
/// * an opening bracket closes itself when what follows is a space, the
///   line's end or a closing bracket — not before a word, where the writer
///   is wrapping something already written, and not after a backslash, where
///   `\(` opens inline math and wants `\)`;
/// * over a selection it wraps it instead, the selection kept inside;
/// * a closing bracket typed where the one the pair wrote stands steps over
///   it, so typing on through `(a)` does not leave `(a))`;
/// * Backspace between an empty pair takes both.
library;

import 'package:niman/src/markdown/source_buffer.dart';

/// An edit a bracket asks for: `[start, end)` replaced with `text`, and the
/// selection after it. An empty `text` over an empty range only moves the
/// caret.
typedef BracketEdit = ({
  int start,
  int end,
  String text,
  int anchor,
  int extent,
});

/// A closing bracket this pair wrote: on `line`, `fromEnd` characters from
/// its end counting itself — which the text typed before it leaves alone.
typedef _Closer = ({int line, int fromEnd, String char});

/// The brackets of one note's surface, and the closing ones it wrote.
final class BracketPairs {
  /// Each opening bracket and the one that closes it.
  static const Map<String, String> pairs = <String, String>{
    '(': ')',
    '[': ']',
    '{': '}',
  };

  static final Set<String> _closing = pairs.values.toSet();

  final List<_Closer> _closers = <_Closer>[];

  /// What typing [typed] over `[start, end)` of [buffer] does instead of
  /// inserting it; null when it is only typed.
  BracketEdit? typed(SourceBuffer buffer, int start, int end, String typed) {
    final close = pairs[typed];
    if (close != null) {
      if (start != end) {
        final inside = buffer.substring(start, end);
        return (
          start: start,
          end: end,
          text: '$typed$inside$close',
          anchor: start + 1,
          extent: end + 1,
        );
      }
      if (!_closesBefore(buffer, start)) return null;
      final line = buffer.lineOf(start);
      final column = start - buffer.offsetOfLine(line);
      _closers.add((
        line: line,
        fromEnd: buffer.lineLengthAt(line) - column + 1,
        char: close,
      ));
      return (
        start: start,
        end: start,
        text: '$typed$close',
        anchor: start + 1,
        extent: start + 1,
      );
    }
    if (start == end && _closing.contains(typed)) {
      final closer = _closerAt(buffer, start, typed);
      if (closer == null) return null;
      _closers.remove(closer);
      return (
        start: start,
        end: start,
        text: '',
        anchor: start + 1,
        extent: start + 1,
      );
    }
    return null;
  }

  /// What Backspace at [caret] does instead of taking one character; null
  /// when it takes one. Between an empty pair it takes both.
  BracketEdit? backspace(SourceBuffer buffer, int caret) {
    if (caret <= 0 || caret >= buffer.length) return null;
    final open = buffer.substring(caret - 1, caret);
    final close = pairs[open];
    if (close == null || buffer.substring(caret, caret + 1) != close) {
      return null;
    }
    final line = buffer.lineOf(caret);
    final column = caret - buffer.offsetOfLine(line);
    _closers.removeWhere(
      (c) =>
          c.line == line &&
          c.fromEnd == buffer.lineLengthAt(line) - column &&
          c.char == close,
    );
    return (
      start: caret - 1,
      end: caret + 1,
      text: '',
      anchor: caret - 1,
      extent: caret - 1,
    );
  }

  /// The caret is on [line]: the closing brackets written on other lines
  /// are forgotten, and a bracket typed later is typed, not stepped over.
  void caretOnLine(int line) {
    if (_closers.isEmpty) return;
    _closers.removeWhere((closer) => closer.line != line);
  }

  /// Forgets every closing bracket written: another note.
  void clear() => _closers.clear();

  /// Whether an opening bracket at [offset] closes itself: at the line's
  /// end, before a space or a closing bracket, and not after a backslash.
  static bool _closesBefore(SourceBuffer buffer, int offset) {
    if (offset > 0 && buffer.substring(offset - 1, offset) == r'\') {
      return false;
    }
    if (offset >= buffer.length) return true;
    final next = buffer.substring(offset, offset + 1);
    return next == '\n' ||
        next == ' ' ||
        next == '\t' ||
        _closing.contains(next);
  }

  /// The closing bracket [char] this pair wrote, standing at [offset].
  _Closer? _closerAt(SourceBuffer buffer, int offset, String char) {
    if (offset >= buffer.length ||
        buffer.substring(offset, offset + 1) != char) {
      return null;
    }
    final line = buffer.lineOf(offset);
    final fromEnd =
        buffer.lineLengthAt(line) - (offset - buffer.offsetOfLine(line));
    for (final closer in _closers.reversed) {
      if (closer.line == line &&
          closer.fromEnd == fromEnd &&
          closer.char == char) {
        return closer;
      }
    }
    return null;
  }
}

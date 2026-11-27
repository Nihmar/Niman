import 'dart:math' as math;

import 'package:niman/src/editor/touched_lines.dart';
import 'package:niman/src/markdown/edit/list_indent_edit.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// What Tab and Shift+Tab do where a line is just text: no list item is
/// nested, nothing renumbered, whatever the line looks like. The rule for a
/// line of fenced code, display maths or the frontmatter, and for any line
/// that is not a list item when the caret is collapsed (#1335, #1345).
///
/// * A collapsed caret: Tab inserts [width] spaces at the caret, and
///   Shift+Tab takes back the spaces right before it (up to [width]) — so
///   the two are inverses wherever the caret is — or, with none there, up to
///   [width] of the line's leading spaces.
/// * A range: Tab puts [width] spaces at the start of each line it touches
///   and Shift+Tab takes up to [width] leading spaces off each. A blank line
///   is left as it is, and nothing but spaces is ever taken.
///
/// Null when nothing would change. Each end of the selection stays on its own
/// text.
ListIndentEdit? plainIndentEdit(
  SourceBuffer buffer,
  SelectionModel selection, {
  required int width,
  required bool outdent,
}) {
  if (selection.isCollapsed) {
    return _atCaret(buffer, selection.extent, width, outdent);
  }
  final touched = touchedBufferLines(buffer, selection);
  // Per touched line, the columns it grows (or shrinks, negative) by.
  final delta = <int>[];
  for (var line = touched.first; line <= touched.last; line++) {
    final text = buffer.lineAt(line);
    delta.add(
      outdent ? -_leadingSpaces(text, width) : (_isBlank(text) ? 0 : width),
    );
  }
  var from = 0;
  while (from < delta.length && delta[from] == 0) {
    from++;
  }
  if (from == delta.length) return null;
  var to = delta.length - 1;
  while (delta[to] == 0) {
    to--;
  }
  final text = StringBuffer();
  for (var at = from; at <= to; at++) {
    final line = touched.first + at;
    final own = buffer.lineAt(line);
    text.write(
      delta[at] > 0
          ? '${' ' * delta[at]}$own'
          : own.substring(math.min(-delta[at], own.length)),
    );
    if (at < to) text.write(buffer.terminatorAt(line));
  }
  int moved(int offset) {
    final line = buffer.lineOf(offset);
    final index = line - touched.first;
    var shift = 0;
    for (var at = 0; at < index && at < delta.length; at++) {
      shift += delta[at];
    }
    if (index < 0 || index >= delta.length) return offset + shift;
    final column = offset - buffer.offsetOfLine(line);
    // Spaces put in front of a caret leave it behind them; a caret in the
    // spaces taken goes to the line's start, and one past them moves with
    // its text.
    return buffer.offsetOfLine(line) +
        shift +
        math.max(0, column + delta[index]);
  }

  final first = touched.first + from;
  final last = touched.first + to;
  return (
    start: buffer.offsetOfLine(first),
    end: buffer.offsetOfLine(last) + buffer.lineLengthAt(last),
    text: text.toString(),
    caret: SelectionModel(
      anchor: moved(selection.anchor),
      extent: moved(selection.extent),
    ),
  );
}

/// Tab and Shift+Tab with a collapsed caret at [at].
ListIndentEdit? _atCaret(SourceBuffer buffer, int at, int width, bool outdent) {
  if (!outdent) {
    return (
      start: at,
      end: at,
      text: ' ' * width,
      caret: SelectionModel.at(at + width),
    );
  }
  final line = buffer.lineOf(at);
  final start = buffer.offsetOfLine(line);
  // The spaces right before the caret, the ones the last Tab put there.
  final before = buffer.substring(math.max(start, at - width), at);
  var behind = 0;
  while (behind < before.length && before[before.length - 1 - behind] == ' ') {
    behind++;
  }
  if (behind > 0) {
    return (
      start: at - behind,
      end: at,
      text: '',
      caret: SelectionModel.at(at - behind),
    );
  }
  final lead = _leadingSpaces(buffer.lineAt(line), width);
  if (lead == 0) return null;
  return (
    start: start,
    end: start + lead,
    text: '',
    caret: SelectionModel.at(math.max(start, at - lead)),
  );
}

/// How many of the first [most] characters of [text] are spaces.
int _leadingSpaces(String text, int most) {
  var spaces = 0;
  while (spaces < most && spaces < text.length && text[spaces] == ' ') {
    spaces++;
  }
  return spaces;
}

/// Whether [text] is empty or holds only whitespace (a `\r` included).
bool _isBlank(String text) => text.trim().isEmpty;

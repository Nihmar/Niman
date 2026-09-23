/// Pure Markdown editing commands (T-UI-08): text + selection in, new text
/// + selection out. No editor/model dependency - unit-testable and applied
/// through the re_editor controller by the toolbar (see ui/note_view.dart).
library;

import 'package:flutter/services.dart';

/// The result of a Markdown editing command.
final class MarkdownEdit {
  /// Creates an edit result.
  const new({required this.text, required this.selection});

  /// The new full text.
  final String text;

  /// Where the caret/selection lands after the command.
  final TextSelection selection;
}

/// Wraps [selection] with [left]/[right] markers (bold '**', italic '*',
/// strike '~~', sup '<sup>…</sup>', underline '<u>…</u>', link '[[…]]').
/// A collapsed selection inserts the markers at the caret and leaves the
/// caret between them; a non-empty selection keeps the inner text selected.
MarkdownEdit wrapSelection({
  required String text,
  required TextSelection selection,
  required String left,
  required String right,
}) {
  final start = selection.start;
  final end = selection.end;
  final selected = text.substring(start, end);
  final newText = text.replaceRange(start, end, '$left$selected$right');
  if (selection.isCollapsed) {
    return MarkdownEdit(
      text: newText,
      selection: TextSelection.collapsed(offset: start + left.length),
    );
  }
  return MarkdownEdit(
    text: newText,
    selection: TextSelection(
      baseOffset: start + left.length,
      extentOffset: start + left.length + selected.length,
    ),
  );
}

/// Inserts a fenced code block at the caret: empty selection lands the
/// caret on the block's first line; a selection is wrapped in fences and
/// stays selected.
MarkdownEdit codeBlock({
  required String text,
  required TextSelection selection,
}) {
  const fence = '```';
  if (selection.isCollapsed) {
    final at = selection.start;
    // "fence + newline, caret line, newline + fence".
    const insert = '$fence\n\n$fence';
    final newText = text.replaceRange(at, at, insert);
    return MarkdownEdit(
      text: newText,
      selection: TextSelection.collapsed(offset: at + 4),
    );
  }
  return wrapSelection(
    text: text,
    selection: selection,
    left: '$fence\n',
    right: '\n$fence',
  );
}

/// Prefixes every line the [selection] touches with [prefix] ('- ' for
/// lists, '> ' for quotes), one pass per line. The selection shifts by the
/// total inserted length, keeping the caret in place.
MarkdownEdit prefixLines({
  required String text,
  required TextSelection selection,
  required String prefix,
}) {
  final startLine = _lineIndexOf(text, selection.start);
  final endLine = _lineIndexOf(text, selection.end);
  final lines = text.split('\n');
  final newLines = <String>[...lines];
  for (var i = startLine; i <= endLine; i++) {
    newLines[i] = '$prefix${newLines[i]}';
  }
  final newText = newLines.join('\n');
  final shift = prefix.length * (endLine - startLine + 1);
  return MarkdownEdit(
    text: newText,
    selection: TextSelection(
      baseOffset: selection.start + shift,
      extentOffset: selection.end + shift,
    ),
  );
}

/// Sets the heading [level] (1..6) of every line the [selection] touches.
///
/// A line already carrying that level is de-headed (toggled off); any
/// other existing heading is replaced; plain text gets the level.
MarkdownEdit setHeading({
  required String text,
  required TextSelection selection,
  required int level,
}) {
  final startLine = _lineIndexOf(text, selection.start);
  final endLine = _lineIndexOf(text, selection.end);
  final lines = text.split('\n');
  final newLines = <String>[...lines];
  for (var i = startLine; i <= endLine; i++) {
    final line = newLines[i];
    final match = _headingPrefix.matchAsPrefix(line);
    final stripped = match == null ? line : line.substring(match[0]!.length);
    final existing = match == null ? 0 : match[1]!.length;
    newLines[i] = existing == level ? stripped : '${'#' * level} $stripped';
  }
  final newText = newLines.join('\n');
  return MarkdownEdit(
    text: newText,
    selection: _shiftSelectionForLines(
      oldText: text,
      newText: newText,
      selection: selection,
      startLine: startLine,
      endLine: endLine,
    ),
  );
}

/// Numbers every line the [selection] touches as an ordered list, starting
/// at 1 for the first touched line (`1. `, `2. `, …).
MarkdownEdit orderedList({
  required String text,
  required TextSelection selection,
}) {
  final startLine = _lineIndexOf(text, selection.start);
  final endLine = _lineIndexOf(text, selection.end);
  final lines = text.split('\n');
  final newLines = <String>[...lines];
  for (var i = startLine; i <= endLine; i++) {
    newLines[i] = '${i - startLine + 1}. ${newLines[i]}';
  }
  final newText = newLines.join('\n');
  return MarkdownEdit(
    text: newText,
    selection: _shiftSelectionForLines(
      oldText: text,
      newText: newText,
      selection: selection,
      startLine: startLine,
      endLine: endLine,
    ),
  );
}

/// Makes every line the [selection] touches a task (`- [ ] `), or takes the
/// task off them all when every one of them is a task already (#263).
///
/// A bulleted item keeps its marker and gains the box, a numbered one its
/// number (`1. [ ] `, a task in GFM too), and any other line becomes a
/// bulleted task at its own indent. A blank line among several is left
/// alone: a list is made of the lines that say something. Taking the task
/// off leaves the line's text, as the list buttons' second press would.
MarkdownEdit toggleTaskList({
  required String text,
  required TextSelection selection,
}) {
  final startLine = _lineIndexOf(text, selection.start);
  final endLine = _lineIndexOf(text, selection.end);
  final lines = text.split('\n');
  final newLines = <String>[...lines];
  final several = endLine > startLine;
  bool skipped(String line) => several && line.trim().isEmpty;
  var allTasks = true;
  for (var i = startLine; i <= endLine; i++) {
    if (skipped(lines[i])) continue;
    if (!(listItemHead(lines[i])?.box ?? false)) allTasks = false;
  }
  for (var i = startLine; i <= endLine; i++) {
    final line = lines[i];
    if (skipped(line)) continue;
    final head = listItemHead(line);
    if (allTasks) {
      newLines[i] = '${head!.indent}${head.content}';
    } else if (head == null) {
      final indent = line.length - line.trimLeft().length;
      newLines[i] =
          '${line.substring(0, indent)}- [ ] ${line.substring(indent)}';
    } else if (!head.box) {
      newLines[i] = '${head.indent}${head.marker} [ ] ${head.content}';
    }
  }
  final newText = newLines.join('\n');
  return MarkdownEdit(
    text: newText,
    selection: _shiftSelectionForLines(
      oldText: text,
      newText: newText,
      selection: selection,
      startLine: startLine,
      endLine: endLine,
    ),
  );
}

/// Indents (or outdents, with [outdent] true) every line the [selection]
/// touches by [width] spaces: indent adds [width] spaces at each line's
/// start; outdent removes up to [width] leading spaces (never content).
MarkdownEdit indentLines({
  required String text,
  required TextSelection selection,
  required int width,
  required bool outdent,
}) {
  final startLine = _lineIndexOf(text, selection.start);
  final endLine = _lineIndexOf(text, selection.end);
  final lines = text.split('\n');
  final newLines = <String>[...lines];
  if (outdent) {
    for (var i = startLine; i <= endLine; i++) {
      final line = newLines[i];
      final spaces = _leadingSpaces(line);
      newLines[i] = line.substring(spaces < width ? spaces : width);
    }
  } else {
    final pad = ' ' * width;
    for (var i = startLine; i <= endLine; i++) {
      newLines[i] = '$pad${newLines[i]}';
    }
  }
  final newText = newLines.join('\n');
  return MarkdownEdit(
    text: newText,
    selection: _shiftSelectionForLines(
      oldText: text,
      newText: newText,
      selection: selection,
      startLine: startLine,
      endLine: endLine,
    ),
  );
}

/// A leading run of `#` (1..6) and the one following space — an ATX
/// heading prefix.
final RegExp _headingPrefix = RegExp('^(#{1,6}) ?');

/// The number of leading spaces in [line].
int _leadingSpaces(String line) {
  var count = 0;
  while (count < line.length && line.codeUnitAt(count) == 0x20) {
    count++;
  }
  return count;
}

/// Recomputes [selection] against the text after a line-level edit: the
/// touched lines (startLine..endLine) changed length at their starts, so
/// each endpoint lands on the same line, shifted by the lines at and
/// before it (clamped so an offset never goes negative).
TextSelection _shiftSelectionForLines({
  required String oldText,
  required String newText,
  required TextSelection selection,
  required int startLine,
  required int endLine,
}) {
  return TextSelection(
    baseOffset: _mapEndpoint(
      oldText,
      newText,
      selection.baseOffset,
      startLine,
      endLine,
    ),
    extentOffset: _mapEndpoint(
      oldText,
      newText,
      selection.extentOffset,
      startLine,
      endLine,
    ),
  );
}

int _mapEndpoint(
  String oldText,
  String newText,
  int offset,
  int startLine,
  int endLine,
) {
  final (line, off) = _lineAndOffset(oldText, offset);
  if (line < startLine || line > endLine) {
    return _lineStart(newText, line) + off;
  }
  final delta =
      newText.split('\n')[line].length - oldText.split('\n')[line].length;
  final newOff = off + delta;
  return _lineStart(newText, line) + (newOff < 0 ? 0 : newOff);
}

/// The head of a list item: everything on the line before its content.
///
/// What Enter needs in order to carry a list on (#142): the indent to
/// keep, the marker to repeat or count on, and whether the writer is
/// standing on an item with nothing in it — which is how every editor
/// spells "I am done with this list".
final class ListItemHead {
  /// Creates a head; use [listItemHead], not this constructor.
  const new({
    required this.indent,
    required this.marker,
    required this.content,
    this.number,
    this.box = false,
  });

  /// The item's leading whitespace, kept by the line that follows.
  final String indent;

  /// The marker as written: `-`, `*`, `+`, or `3.` / `3)`.
  final String marker;

  /// The item's number, for an ordered item; null for a bulleted one.
  final int? number;

  /// Whether the item carries a task box.
  final bool box;

  /// What the item says, after the marker and the box.
  final String content;

  /// Whether the item is empty — marker, maybe a box, and nothing else.
  bool get isEmpty => content.trim().isEmpty;

  /// What a line continuing this item starts with.
  ///
  /// An ordered item counts on, because a writer numbering by hand
  /// expects the next number even though Markdown renumbers for them. A
  /// ticked item does not pass its tick along: a new item is a new
  /// thing to do.
  String get continuation {
    final number = this.number;
    final next = number == null
        ? marker
        : '${number + 1}${marker[marker.length - 1]}';
    return '$indent$next ${box ? '[ ] ' : ''}';
  }
}

/// A list marker at the start of a line, with the task box that may
/// follow it.
final RegExp _listItem = RegExp(
  r'^([ \t]*)([-*+]|(\d{1,9})([.)]))[ \t]+(\[[ xX]\][ \t]+)?(.*)$',
);

/// A list item with a marker and nothing after it (`- `, `1.`), which
/// the pattern above cannot match because it wants the space.
final RegExp _bareListItem = RegExp(r'^([ \t]*)([-*+]|(\d{1,9})([.)]))[ \t]*$');

/// The head of the list item on [line], or null when it is not one.
///
/// Line-local on purpose: the caller knows whether the line is inside a
/// code fence, and this does not.
ListItemHead? listItemHead(String line) {
  final match = _listItem.firstMatch(line) ?? _bareListItem.firstMatch(line);
  if (match == null) return null;
  final digits = match.group(3);
  return ListItemHead(
    indent: match.group(1)!,
    marker: match.group(2)!,
    number: digits == null ? null : int.tryParse(digits),
    box: match.groupCount >= 5 && match.group(5) != null,
    content: match.groupCount >= 6 ? match.group(6) ?? '' : '',
  );
}

/// The absolute offset where [line] starts in [text].
int _lineStart(String text, int line) {
  var index = 0;
  for (var current = 0; current < line; current++) {
    final nl = text.indexOf('\n', index);
    if (nl < 0) return text.length;
    index = nl + 1;
  }
  return index;
}

/// The (line, offset-within-line) for the absolute [offset] in [text].
(int, int) _lineAndOffset(String text, int offset) {
  var line = 0;
  var lineStart = 0;
  for (var i = 0; i < offset && i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) {
      line++;
      lineStart = i + 1;
    }
  }
  return (line, offset - lineStart);
}

/// The 0-based line index containing [offset].
int _lineIndexOf(String text, int offset) {
  var line = 0;
  for (var i = 0; i < offset && i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}

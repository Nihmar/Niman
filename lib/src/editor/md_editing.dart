/// Pure Markdown editing commands (T-UI-08): text + selection in, new text
/// + selection out. No editor/model dependency - unit-testable and applied
/// to the surface by the toolbar and the menu (see ui/note_view.dart).
library;

import 'package:flutter/services.dart';
import 'package:niman/src/editor/list_item_head.dart';

export 'package:niman/src/editor/list_item_head.dart';

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
/// lists, '> ' for quotes), one pass per line. Each end of the selection
/// stays on its own text: it moves by what its own line gained, not by what
/// the lines above it did too.
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
    if (skipped(lines[i])) continue;
    // A CRLF note's line still ends in its `\r`: the terminator, kept as it
    // was and no part of the item (#1374).
    final cr = lines[i].endsWith('\r') ? '\r' : '';
    final line = cr.isEmpty
        ? lines[i]
        : lines[i].substring(0, lines[i].length - 1);
    final head = listItemHead(line);
    if (allTasks) {
      newLines[i] = '${head!.indent}${head.content}$cr';
    } else if (head == null) {
      final indent = line.length - line.trimLeft().length;
      newLines[i] =
          '${line.substring(0, indent)}- [ ] ${line.substring(indent)}$cr';
    } else if (!head.box) {
      newLines[i] = '${head.indent}${head.marker} [ ] ${head.content}$cr';
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

/// Inserts an empty table of [columns] columns and [rows] body rows, on
/// lines of its own, with the caret in its first header cell (#262).
MarkdownEdit insertTable({
  required String text,
  required TextSelection selection,
  int columns = 2,
  int rows = 1,
}) {
  String row(String cell) =>
      '|${List<String>.filled(columns, ' $cell ').join('|')}|';
  return insertBlock(
    text: text,
    selection: selection,
    block: <String>[
      row('  '),
      row('---'),
      for (var body = 0; body < rows; body++) row('  '),
    ],
    // The first header cell's text starts two columns in: `| `.
    caret: (line: 0, column: 2),
  );
}

/// Inserts two equal columns (#729), on lines of their own as a table is,
/// with [left] — the first column's text — selected, so typing replaces
/// it. The outer fence is four colons: djot and commonmark-hs close it
/// where Pandoc does.
MarkdownEdit insertColumns({
  required String text,
  required TextSelection selection,
  required String left,
  required String right,
}) {
  final edit = insertBlock(
    text: text,
    selection: selection,
    block: <String>[
      ':::: columns',
      '::: column',
      left,
      ':::',
      '',
      '::: column',
      right,
      ':::',
      '::::',
    ],
    caret: (line: 2, column: 0),
  );
  final start = edit.selection.extentOffset;
  return MarkdownEdit(
    text: edit.text,
    selection: TextSelection(
      baseOffset: start,
      extentOffset: start + left.length,
    ),
  );
}

/// Inserts an Eisenhower matrix (#1139): a table whose first row is the
/// urgency axis and whose first column is the importance axis, the four
/// quadrants left empty and the caret in the first of them.
///
/// The labels are the app's strings in the language active now, escaped
/// for a cell. A note is plain Markdown: a matrix written today keeps its
/// words when the app language changes. The row labels are bold, being
/// the row's name rather than the first of its cells.
MarkdownEdit insertEisenhowerMatrix({
  required String text,
  required TextSelection selection,
  required String urgent,
  required String notUrgent,
  required String important,
  required String notImportant,
}) {
  final urgentCell = _tableCell(urgent);
  final notUrgentCell = _tableCell(notUrgent);
  final importantCell = '**${_tableCell(important)}**';
  final notImportantCell = '**${_tableCell(notImportant)}**';
  // The caret is left in this matrix's first quadrant, so running the tool
  // again lands inside the table just written: the second one goes under
  // it rather than splitting it in two (#1139).
  final caret = _afterTable(text, selection.extentOffset);
  return insertBlock(
    text: text,
    selection: TextSelection.collapsed(offset: caret),
    block: <String>[
      '|  | $urgentCell | $notUrgentCell |',
      '| --- | --- | --- |',
      '| $importantCell |  |  |',
      '| $notImportantCell |  |  |',
    ],
    // The first quadrant: the second cell of the first body row.
    caret: (line: 2, column: '| $importantCell | '.length),
  );
}

/// [label] as a table cell's text: a pipe in it is escaped, so it stays
/// the cell's rather than ending it.
String _tableCell(String label) => label.replaceAll('|', r'\|');

/// [offset] moved past the table its line belongs to, when it is one: the
/// end of the table's last row, so a block inserted there goes under the
/// table rather than through it. [offset] itself when its line is no
/// table's.
///
/// A table is taken to be the run of lines starting with a pipe whose
/// second line is the delimiter row: the shape [insertTable] and this
/// writer leave, which is the one a second run meets.
int _afterTable(String text, int offset) {
  final lines = text.split('\n');
  final at = _lineIndexOf(text, offset);
  if (!_startsTableRow(lines[at])) return offset;
  var first = at;
  while (first > 0 && _startsTableRow(lines[first - 1])) {
    first--;
  }
  if (first + 1 >= lines.length || !_delimiterRow.hasMatch(lines[first + 1])) {
    return offset;
  }
  var last = at;
  while (last < lines.length - 1 && _startsTableRow(lines[last + 1])) {
    last++;
  }
  return _lineStart(text, last) + lines[last].length;
}

/// Whether [line] looks like one of a table's rows: it starts with a pipe.
bool _startsTableRow(String line) => line.trimLeft().startsWith('|');

/// A table's delimiter row: cells of dashes with optional alignment colons,
/// between outer pipes.
final RegExp _delimiterRow = RegExp(r'^\s*\|(\s*:?-+:?\s*\|)+\s*$');

/// Inserts [block]'s lines on lines of their own, the caret at [caret] in
/// them — at the end of the last one without it.
///
/// Where they go follows the caret: a blank line is replaced by them, a
/// caret at the very start of a line puts them above that line, and
/// anywhere else puts them below. A block glued to a paragraph is read as
/// the paragraph's text, so a blank line keeps it from its neighbours on
/// either side, where there is not one already. A selection is not
/// replaced: the block goes by the caret's end of it.
MarkdownEdit insertBlock({
  required String text,
  required TextSelection selection,
  required List<String> block,
  ({int line, int column})? caret,
}) {
  final lines = text.split('\n');
  final at0 = selection.extentOffset;
  final line = _lineIndexOf(text, at0);
  final column = at0 - _lineStart(text, line);
  final blank = lines[line].trim().isEmpty;
  final at = blank || column == 0 ? line : line + 1;
  final remove = blank ? 1 : 0;
  final before = at > 0 && lines[at - 1].trim().isNotEmpty;
  final afterIndex = at + remove;
  final after =
      afterIndex < lines.length && lines[afterIndex].trim().isNotEmpty;
  final inserted = <String>[if (before) '', ...block, if (after) ''];
  final newLines = <String>[...lines]..replaceRange(at, at + remove, inserted);
  final target = caret ?? (line: block.length - 1, column: block.last.length);
  final newText = newLines.join('\n');
  final offset =
      _lineStart(newText, at + (before ? 1 : 0) + target.line) + target.column;
  return MarkdownEdit(
    text: newText,
    selection: TextSelection.collapsed(offset: offset),
  );
}

/// Inserts [snippet] at the caret, in place of the selection: a snippet of
/// one line where the caret is, one of several lines on lines of its own
/// ([insertBlock]). The caret lands after it.
MarkdownEdit insertSnippet({
  required String text,
  required TextSelection selection,
  required String snippet,
}) {
  if (!snippet.contains('\n')) {
    final newText = text.replaceRange(selection.start, selection.end, snippet);
    return MarkdownEdit(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + snippet.length,
      ),
    );
  }
  return insertBlock(
    text: text,
    selection: selection,
    block: snippet.split('\n'),
  );
}

/// Takes the heading off every line the [selection] touches: the text of a
/// heading becomes a paragraph's — Obsidian's "Body" (#260).
MarkdownEdit removeHeading({
  required String text,
  required TextSelection selection,
}) {
  final startLine = _lineIndexOf(text, selection.start);
  final endLine = _lineIndexOf(text, selection.end);
  final lines = text.split('\n');
  final newLines = <String>[...lines];
  for (var i = startLine; i <= endLine; i++) {
    final match = _headingPrefix.matchAsPrefix(lines[i]);
    if (match != null) newLines[i] = lines[i].substring(match[0]!.length);
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

/// Cites footnote [label] at the caret and writes its definition under
/// the caret's paragraph, the caret left on it to be written (#260).
///
/// Under the paragraph rather than at the note's end: a definition can
/// stand anywhere, and there it is found beside what cites it — and the
/// edit is the paragraph's, not the note's. [text] need hold the caret's
/// paragraph from its line on; the definition goes after the first blank
/// line, or at the end of [text] when it has none.
MarkdownEdit insertFootnote({
  required String text,
  required TextSelection selection,
  required String label,
}) {
  final caret = selection.extentOffset;
  final reference = '[^$label]';
  final withReference = text.replaceRange(caret, caret, reference);
  final lines = withReference.split('\n');
  var end = _lineIndexOf(withReference, caret + reference.length);
  while (end + 1 < lines.length && lines[end + 1].trim().isNotEmpty) {
    end++;
  }
  final definition = '[^$label]: ';
  final newLines = <String>[...lines]..insertAll(end + 1, ['', definition]);
  final newText = newLines.join('\n');
  final at = _lineStart(newText, end + 2) + definition.length;
  return MarkdownEdit(
    text: newText,
    selection: TextSelection.collapsed(offset: at),
  );
}

/// The next number a new footnote can take: one past the highest of
/// [labels] that are numbers.
String nextFootnoteLabel(Iterable<String> labels) {
  var highest = 0;
  for (final label in labels) {
    final number = int.tryParse(label);
    if (number != null && number > highest) highest = number;
  }
  return '${highest + 1}';
}

/// A leading run of `#` (1..6) and the one following space — an ATX
/// heading prefix.
final RegExp _headingPrefix = RegExp('^(#{1,6}) ?');

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

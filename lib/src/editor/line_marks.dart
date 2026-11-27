/// The list, numbered list and quote commands: marks at the start of the
/// lines a selection touches, that a second press takes off again (#1340).
///
/// Each is text and selection in, text and selection out, like the rest of
/// `md_editing.dart`, and works behind the quote marks a line opens with and
/// before its own `\r` on a CRLF note.
library;

import 'package:flutter/services.dart';

import 'package:niman/src/editor/line_selection.dart';
import 'package:niman/src/editor/list_row.dart';
import 'package:niman/src/editor/md_editing.dart' show MarkdownEdit;
import 'package:niman/src/editor/touched_lines.dart';

/// Makes every line the [selection] touches a bulleted item, or takes the
/// bullet off them all when every one of them is a bulleted item already.
///
/// A numbered item takes a bullet in place of its number and a task its bullet
/// without the box (the marker is swapped, not added to); an item already
/// bulleted is as it was; any other line gets `- ` at its own indent, behind
/// its quote marks. A blank line among several is left alone, as the
/// checklist leaves it: a list is made of the lines that say something.
MarkdownEdit toggleBulletList({
  required String text,
  required TextSelection selection,
}) => _marks(
  text,
  selection,
  off: (row) => row.head != null && row.head!.number == null && !row.head!.box,
  strip: _withoutMarker,
  put: (row, _) => _bulleted(row),
);

/// Numbers every line the [selection] touches as an ordered list, starting at
/// 1 for the first of them (`1. `, `2. `, …), or takes the numbers off them
/// all when every one of them is a numbered item already.
///
/// A bulleted item takes its number in place of its bullet (a task keeps its
/// box: `1. [ ] `, a task in GFM too), a numbered one is numbered anew. A
/// blank line among several is left alone, and does not count.
MarkdownEdit orderedList({
  required String text,
  required TextSelection selection,
}) => _marks(
  text,
  selection,
  off: (row) => row.head?.number != null,
  strip: _withoutMarker,
  put: _numbered,
);

/// Puts every line the [selection] touches in a quote (`> `), or takes one
/// level of quote off them all when every one of them is in one already.
///
/// A line already in a quote is left as it is when the others are not; the
/// mark goes before everything else on a line, its indent and its list marker
/// included.
MarkdownEdit toggleQuote({
  required String text,
  required TextSelection selection,
}) => _marks(
  text,
  selection,
  off: (row) => row.marks.isNotEmpty,
  strip: (row) => row.line.replaceFirst(_firstMark, ''),
  put: (row, _) => row.marks.isEmpty ? '> ${row.line}' : row.line,
);

/// A quote's first mark: its up-to-three spaces, the `>` and the space after.
final RegExp _firstMark = RegExp('^ {0,3}> ?');

/// The shape the three commands share: [off] says a line has the mark; when
/// every line touched does, [strip] takes it off, otherwise [put] makes each
/// of them have it (the line, and the number it is among the touched lines
/// that say something).
MarkdownEdit _marks(
  String text,
  TextSelection selection, {
  required bool Function(ListRow row) off,
  required String Function(ListRow row) strip,
  required String Function(ListRow row, int number) put,
}) {
  final (first: startLine, last: endLine) = touchedLines(text, selection);
  final lines = text.split('\n');
  final newLines = <String>[...lines];
  final several = endLine > startLine;
  final touched = <int>[
    for (var at = startLine; at <= endLine; at++)
      if (!(several && lines[at].trim().isEmpty)) at,
  ];
  final rows = [for (final at in touched) ListRow(lines[at])];
  final allOff = rows.every(off);
  for (var at = 0; at < touched.length; at++) {
    newLines[touched[at]] = allOff ? strip(rows[at]) : put(rows[at], at + 1);
  }
  final newText = newLines.join('\n');
  return MarkdownEdit(
    text: newText,
    selection: shiftSelectionForLines(
      oldText: text,
      newText: newText,
      selection: selection,
      startLine: startLine,
      endLine: endLine,
    ),
  );
}

/// [row]'s line without its list marker (and task box): the quote marks and
/// the indent stay, and so does the line's `\r`.
String _withoutMarker(ListRow row) {
  final head = row.head!;
  return '${row.marks}${head.indent}${head.content}${row.cr}';
}

/// [row]'s line as a bulleted item: an item with another marker has it
/// swapped, a task loses its box, any other line gets `- ` at its own indent.
String _bulleted(ListRow row) {
  final head = row.head;
  if (head == null) return _inserted(row, '-');
  if (head.number == null) {
    if (!head.box) return row.line;
    return '${row.marks}${head.indent}${head.marker} ${head.content}${row.cr}';
  }
  return '${row.marks}${head.indent}- ${head.content}${row.cr}';
}

/// [row]'s line as the [number]th item of a numbered list: an item has its
/// marker swapped, keeping its task box, any other line gets the number at its
/// own indent.
String _numbered(ListRow row, int number) {
  final marker = '$number${row.delimiter ?? '.'}';
  final head = row.head;
  if (head == null) return _inserted(row, marker);
  final box = head.box ? '[ ] ' : '';
  return '${row.marks}${head.indent}$marker $box${head.content}${row.cr}';
}

/// [row]'s line with [marker] and a space put at the start of its text, behind
/// its quote marks and its indent.
String _inserted(ListRow row, String marker) =>
    '${row.marks}${row.body.substring(0, row.lead)}$marker '
    '${row.body.substring(row.lead)}${row.cr}';

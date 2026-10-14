import 'package:niman/src/editor/md_editing.dart';

/// The quote marks a line opens with: each `>` with up to three spaces
/// before it and one after.
final RegExp _quoteMarks = RegExp('^(?: {0,3}> ?)*');

/// One line of a note read the way the list indent needs it: behind its quote
/// marks, how far it is indented, and — when it is a list item — where its
/// content starts.
///
/// Line-local, like [listItemHead]: the caller knows whether the line is
/// inside a code fence.
final class ListRow {
  /// Reads [line] (a trailing `\r` of a CRLF note is set aside and kept).
  factory(String line) {
    final cr = line.endsWith('\r') ? '\r' : '';
    final text = cr.isEmpty ? line : line.substring(0, line.length - 1);
    final marks = _quoteMarks.matchAsPrefix(text)![0]!;
    final body = text.substring(marks.length);
    var depth = 0;
    for (var at = 0; at < marks.length; at++) {
      if (marks.codeUnitAt(at) == 0x3E) depth++;
    }
    final lead = _leadLength(body);
    return ListRow._(
      cr: cr,
      marks: marks,
      body: body,
      depth: depth,
      lead: lead,
      indent: columnsOf(body, lead),
      blank: lead == body.length,
      head: listItemHead(body),
    );
  }

  const new _({
    required this.cr,
    required this.marks,
    required this.body,
    required this.depth,
    required this.lead,
    required this.indent,
    required this.blank,
    required this.head,
  });

  /// The line's `\r`, or nothing.
  final String cr;

  /// The quote marks the line opens with, as written.
  final String marks;

  /// The line after its quote marks.
  final String body;

  /// How many quotes the line is inside.
  final int depth;

  /// The characters of leading whitespace in [body].
  final int lead;

  /// The columns of leading whitespace in [body]; a tab goes to the next
  /// multiple of four.
  final int indent;

  /// Whether [body] says nothing.
  final bool blank;

  /// The list item the line is, or null.
  final ListItemHead? head;

  /// The marker's own delimiter, `.` or `)`; null for a bulleted item.
  String? get delimiter =>
      head?.number == null ? null : head!.marker[head!.marker.length - 1];

  /// The column where the item's content starts: past the marker and the
  /// spaces after it. That column is what a line has to reach to be inside
  /// the item (CommonMark); a marker with nothing after it, or with five
  /// spaces or more, counts one space.
  int get contentColumn {
    final head = this.head!;
    var at = head.indent.length + head.marker.length;
    final from = at;
    while (at < body.length && (body[at] == ' ' || body[at] == '\t')) {
      at++;
    }
    final gap = at - from;
    return indent + head.marker.length + (gap == 0 || gap >= 5 ? 1 : gap);
  }

  /// The line with its indent moved by [delta] columns (never below zero),
  /// and the item's marker replaced by [marker] when one is given. A line that
  /// would not change is returned as it was written.
  String reshape(int delta, {String? marker}) {
    if (blank || (delta == 0 && marker == null)) return '$marks$body$cr';
    final spaces = ' ' * (indent + delta < 0 ? 0 : indent + delta);
    final head = this.head;
    final rest = marker == null || head == null
        ? body.substring(lead)
        : '$marker${body.substring(lead + head.marker.length)}';
    return '$marks$spaces$rest$cr';
  }
}

/// The leading spaces and tabs of [text].
int _leadLength(String text) {
  var at = 0;
  while (at < text.length && (text[at] == ' ' || text[at] == '\t')) {
    at++;
  }
  return at;
}

/// The columns the first [length] characters of [text] take; a tab goes to
/// the next multiple of four.
int columnsOf(String text, int length) {
  var column = 0;
  for (var at = 0; at < length; at++) {
    column = text[at] == '\t' ? column + 4 - column % 4 : column + 1;
  }
  return column;
}

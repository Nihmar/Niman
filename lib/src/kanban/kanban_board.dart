import 'package:niman/src/kanban/kanban_column.dart';

/// A kanban board read from a note's text (#1154): its columns in the
/// file's order, and the facts the byte-stable edits need.
///
/// The board is a view of the text, not a copy to write back: it keeps the
/// lines it was read from so [render] hands the text back as it came, and
/// every line index it carries indexes that text split on `\n`.
final class KanbanBoard {
  /// Creates a board over [lines].
  new({
    required List<String> lines,
    required this.columns,
    required this.contentEnd,
    required this.settingsLine,
    required this.frontmatterEnd,
    required this.lineEnding,
  }) : lines = List<String>.unmodifiable(lines);

  /// The note's lines, `text.split('\n')`: a CRLF note's lines keep their
  /// trailing `\r`.
  final List<String> lines;

  /// The columns, in the file's order.
  final List<KanbanColumn> columns;

  /// The exclusive end of the board: the settings footer's line when there
  /// is one, else the last content line (the phantom line a trailing
  /// newline produces is not one).
  final int contentEnd;

  /// The line index of Obsidian's `%% kanban:settings` footer, or null.
  /// From it to the end of the note is the footer, which is never read
  /// into columns and never touched by an edit.
  final int? settingsLine;

  /// The exclusive end of the leading frontmatter block; 0 when the note
  /// has none.
  final int frontmatterEnd;

  /// The note's dominant line ending, `\n` or `\r\n`: the one new lines are
  /// written with.
  final String lineEnding;

  /// Whether the note ends with Obsidian's settings footer.
  bool get hasSettings => settingsLine != null;

  /// The note's text, as read: the lines joined with `\n`.
  String render() => lines.join('\n');

  /// [content] as a line of this note: with the `\r` a CRLF note's lines
  /// carry.
  String endLine(String content) =>
      lineEnding == '\r\n' ? '$content\r' : content;
}

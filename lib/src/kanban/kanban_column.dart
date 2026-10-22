import 'package:niman/src/kanban/kanban_card.dart';

/// One column of a kanban board: a `##` heading and the cards under it.
final class KanbanColumn {
  /// Creates a column.
  const new({
    required this.name,
    required this.headingLine,
    required this.headingMarkerEnd,
    required this.endLine,
    required this.insertLine,
    required this.cards,
  });

  /// The heading's text without the `##` (and without a closing run of
  /// `#`), trimmed.
  final String name;

  /// The 0-based index of the heading's line in the note text (split on
  /// `\n`).
  final int headingLine;

  /// The offset within the heading's line just after its `##`.
  final int headingMarkerEnd;

  /// The exclusive end of the column's region: the next column's heading,
  /// or the end of the board (the settings footer, or the last line).
  final int endLine;

  /// The line a card added at the end of the column is inserted before:
  /// right after the column's last non-blank line, so the blank lines that
  /// separate it from the next heading stay where they are. For a column
  /// with nothing under its heading but blank lines, the line right under
  /// the heading.
  final int insertLine;

  /// The column's cards, in the file's order.
  final List<KanbanCard> cards;
}

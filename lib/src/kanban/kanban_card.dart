/// One card of a kanban board: a top-level list item of a column and the
/// lines nested under it.
final class KanbanCard {
  /// Creates a card.
  const new({
    required this.line,
    required this.end,
    required this.indent,
    required this.marker,
    required this.boxStart,
    required this.titleStart,
    required this.checked,
    required this.title,
    required this.body,
    required this.tags,
    required this.due,
  });

  /// The 0-based index of the card's first line in the note text (split on
  /// `\n`).
  final int line;

  /// The exclusive end of the card: the line after its last body line.
  /// Blank lines after the last body line are not part of the card; blank
  /// lines between body lines are.
  final int end;

  /// The first line's leading spaces and tabs, counted as characters.
  final int indent;

  /// The list marker: `-`, `*` or `+`.
  final String marker;

  /// The offset of the task box's `[` within the first line, or null when
  /// the card has no box.
  final int? boxStart;

  /// The offset within the first line where the title begins: after the
  /// marker and the box, and the space that follows them.
  final int titleStart;

  /// Whether the box is ticked (`[x]` or `[X]`); null when the card has no
  /// box, which a toggle then leaves alone.
  final bool? checked;

  /// The first line's text without its marker and box, trimmed. Tags and
  /// the due date stay in it, as written.
  final String title;

  /// The lines under the first one, with their common indentation removed
  /// and blank lines empty. Empty when the card is one line.
  final List<String> body;

  /// The `#tag` words of the title, without the `#`.
  final List<String> tags;

  /// The first valid `due:YYYY-MM-DD` of the title, as a local date; null
  /// when there is none.
  final DateTime? due;

  /// Whether the card has a task box.
  bool get hasBox => checked != null;

  /// How many lines the card spans, body included.
  int get lineCount => end - line;
}

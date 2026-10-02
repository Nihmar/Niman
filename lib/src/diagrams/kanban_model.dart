/// The kanban model (#530): its columns and their cards.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// How urgent a card is, as `priority:` writes it.
enum KanbanPriority {
  /// `Very High`.
  veryHigh,

  /// `High`.
  high,

  /// `Low`.
  low,

  /// `Very Low`.
  veryLow,
}

/// One card.
final class KanbanCard {
  /// Creates a card.
  const new({required this.text, this.ticket, this.assigned, this.priority});

  /// What the card says.
  final String text;

  /// Its `ticket:`, or null.
  final String? ticket;

  /// Who it is `assigned:` to, or null.
  final String? assigned;

  /// Its `priority:`, or null.
  final KanbanPriority? priority;
}

/// One column and its cards.
final class KanbanColumn {
  /// Creates a column.
  const new({required this.title, required this.cards});

  /// Its title.
  final String title;

  /// Its cards, top to bottom.
  final List<KanbanCard> cards;
}

/// A parsed kanban board.
final class KanbanBoard {
  /// Creates a board.
  const new({required this.columns});

  /// The columns, left to right.
  final List<KanbanColumn> columns;
}

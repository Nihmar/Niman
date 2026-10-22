import 'dart:math' as math;

import 'package:niman/src/kanban/kanban_board.dart';

/// A card of the board on screen: its column and its place in it.
typedef CardPos = ({
  /// The column's index.
  int column,

  /// The card's index in its column.
  int card,
});

/// Where a dragged card would land: the gap before a card of a column
/// (`0` the top, the column's card count the end), counted before the card
/// leaves its place.
typedef DropSpot = ({
  /// The column's index.
  int column,

  /// The index of the card the gap is before.
  int slot,
});

/// A way to move a card without dragging it.
enum KanbanDirection {
  /// To the column before.
  left,

  /// To the column after.
  right,

  /// One place up its column.
  up,

  /// One place down its column.
  down,
}

/// Where card [at] goes when moved one step [direction], as its place in the
/// destination after the move; null at the edge of the board.
///
/// Across columns it keeps its index, clamped to the end of the column it
/// enters; within one, it swaps with its neighbour.
CardPos? moveTarget(KanbanBoard board, CardPos at, KanbanDirection direction) {
  final columns = board.columns;
  switch (direction) {
    case KanbanDirection.left:
    case KanbanDirection.right:
      final step = direction == KanbanDirection.left ? -1 : 1;
      final column = at.column + step;
      if (column < 0 || column >= columns.length) return null;
      final count = columns[column].cards.length;
      return (column: column, card: math.min(at.card, count));
    case KanbanDirection.up:
    case KanbanDirection.down:
      final step = direction == KanbanDirection.up ? -1 : 1;
      final card = at.card + step;
      if (card < 0 || card >= columns[at.column].cards.length) return null;
      return (column: at.column, card: card);
  }
}

/// [spot] for the card [from] being dragged, or null when dropping there
/// would leave the card where it is.
DropSpot? effectiveSpot(CardPos from, DropSpot spot) {
  if (spot.column == from.column &&
      (spot.slot == from.card || spot.slot == from.card + 1)) {
    return null;
  }
  return spot;
}

/// The card's place in its destination after a drop on [spot].
int dropIndex(CardPos from, DropSpot spot) =>
    spot.column == from.column && spot.slot > from.card
    ? spot.slot - 1
    : spot.slot;

import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_edits.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';
import 'package:niman/src/ui/strings.dart';

/// What the cards and columns of the board on screen share (#1167): the
/// board they were drawn from, the edits they make, the drag in flight and
/// the card that takes the focus once an edit has landed.
///
/// It holds no state of the note: the board view refreshes [board] and
/// [edits] from the text on every build, and every action goes through
/// [edits].
final class KanbanBoardController {
  /// A controller over [host]'s note, announcing through [announce].
  new({
    required this.host,
    required this.mathCache,
    required this.announce,
    required this.board,
    required this.edits,
  });

  /// The note's window, for following links.
  NoteKindHost host;

  /// The formulas of the card titles, shared by the cards.
  final MathCache mathCache;

  /// Says a message to a screen reader.
  final void Function(String message) announce;

  /// The board on screen.
  KanbanBoard board;

  /// The edits over the text [board] was read from.
  KanbanEdits edits;

  /// The card being dragged, if any.
  final ValueNotifier<CardPos?> dragging = ValueNotifier<CardPos?>(null);

  /// Where the dragged card would land now, if anywhere.
  final ValueNotifier<DropSpot?> spot = ValueNotifier<DropSpot?>(null);

  /// Reads where the dragged card would land from the pointer's global
  /// position: the board sets it, as it knows where the columns are.
  void Function(Offset position) dragUpdate = _ignore;

  static void _ignore(Offset position) {}

  /// The card that takes the focus when the board is next drawn from the
  /// edited text: the card just moved, so the keys can go on with it.
  CardPos? pendingFocus;

  /// Releases the notifiers.
  void dispose() {
    dragging.dispose();
    spot.dispose();
  }

  /// Whether card [at] has a place one step [direction].
  bool canMove(CardPos at, KanbanDirection direction) =>
      moveTarget(board, at, direction) != null;

  /// Moves card [at] one step [direction]; the focus follows it.
  void move(CardPos at, KanbanDirection direction) {
    final to = moveTarget(board, at, direction);
    if (to == null) return;
    _moveTo(at, to);
  }

  /// Ends the drag in flight: the card is dropped where [spot] says, or
  /// stays where it was when the pointer was nowhere a card can land.
  void dragEnd() {
    final from = dragging.value;
    final target = spot.value;
    dragging.value = null;
    spot.value = null;
    if (from != null && target != null) drop(from, target);
  }

  /// Drops card [from] on [target], as a drag ends.
  void drop(CardPos from, DropSpot target) {
    if (effectiveSpot(from, target) == null) return;
    _moveTo(from, (column: target.column, card: dropIndex(from, target)));
  }

  void _moveTo(CardPos from, CardPos to) {
    final moved = edits.move(
      fromColumn: from.column,
      fromCard: from.card,
      toColumn: to.column,
      toIndex: to.card,
    );
    if (!moved) return;
    pendingFocus = to;
    final total =
        board.columns[to.column].cards.length +
        (to.column == from.column ? 0 : 1);
    announce(
      AppStrings.kanbanMovedTo(
        board.columns[to.column].name,
        to.card + 1,
        total,
      ),
    );
  }

  /// Deletes card [at]; the focus goes to the card that takes its place
  /// (or the one before it, for the last).
  void delete(CardPos at) {
    if (!edits.deleteCard(at.column, at.card)) return;
    final left = board.columns[at.column].cards.length - 1;
    pendingFocus = left <= 0
        ? null
        : (column: at.column, card: at.card < left ? at.card : left - 1);
  }
}

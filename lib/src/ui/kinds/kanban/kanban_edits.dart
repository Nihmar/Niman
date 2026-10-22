import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/kanban/card_edits.dart' as cards;
import 'package:niman/src/kanban/column_edits.dart' as columns;

/// What the board does to the note (#1167): each action is one function of
/// `lib/src/kanban/` over the note's text and one `applyEdit`, so one
/// action is one undo step. The view never builds text itself.
///
/// The indexes an action takes are those of the board the view drew from
/// [text]. If the note has moved on since (the host's text is no longer the
/// one drawn), the action is dropped: its indexes would name other cards.
final class KanbanEdits {
  /// Edits that apply to the board drawn from [text], through [host].
  const new({required this.text, required this.host});

  /// The note text the board on screen was read from.
  final String text;

  /// The note's window.
  final NoteKindHost host;

  /// Whether the note still is the text the board was drawn from.
  bool get current => host.text == text;

  /// Applies [next] when it differs from the note; true when it did.
  bool _apply(String next) {
    if (!current || next == text) return false;
    host.applyEdit(next);
    return true;
  }

  /// Flips the box of card [card] of [column].
  bool toggle(int column, int card) =>
      _apply(cards.toggleCard(text, column, card));

  /// Moves a card; [toIndex] is its place in the destination afterwards.
  bool move({
    required int fromColumn,
    required int fromCard,
    required int toColumn,
    required int toIndex,
  }) => _apply(
    cards.moveCard(
      text,
      fromColumn: fromColumn,
      fromCard: fromCard,
      toColumn: toColumn,
      toIndex: toIndex,
    ),
  );

  /// Adds a card titled [title] at the end of [column].
  bool addCard(int column, String title) =>
      _apply(cards.addCard(text, column, title));

  /// Retitles a card.
  bool retitle(int column, int card, String title) =>
      _apply(cards.editCardTitle(text, column, card, title));

  /// Deletes a card and its body.
  bool deleteCard(int column, int card) =>
      _apply(cards.deleteCard(text, column, card));

  /// Adds a column named [name] at the end of the board.
  bool addColumn(String name) => _apply(columns.addColumn(text, name));

  /// Renames [column].
  bool renameColumn(int column, String name) =>
      _apply(columns.renameColumn(text, column, name));

  /// Deletes [column] with its cards.
  bool deleteColumn(int column) => _apply(columns.deleteColumn(text, column));
}

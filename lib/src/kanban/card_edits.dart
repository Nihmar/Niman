/// The edits the board view makes to a kanban note's cards (#1154): each a
/// function from the note's text to the new text, addressing columns and
/// cards by their index in the board [parseKanban] reads from that text.
///
/// The disk is the source of truth, so an edit rewrites only the lines it
/// touches. Every other line keeps its bytes, line endings included; a
/// moved card keeps its bytes apart from its leading spaces. An index out
/// of range throws a [RangeError].
library;

import 'package:niman/src/kanban/board_edit_scope.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/kanban/kanban_card.dart';
import 'package:niman/src/kanban/kanban_column.dart';

/// [text] with the card [fromCard] of column [fromColumn] moved so that it
/// is card [toIndex] of column [toColumn].
///
/// [toIndex] is the card's place in the destination after the move: `0` is
/// the top, the destination's card count (one less within the same column)
/// the end. A card moved into an empty column lands right under its
/// heading; one moved to the end of a column lands before the blank lines
/// that separate the column from the next heading. The card's body goes
/// with it, and it takes the indentation of the card it lands before (or,
/// at the end, after), so it is a sibling of the cards there.
/// A move that changes nothing returns [text] itself.
String moveCard(
  String text, {
  required int fromColumn,
  required int fromCard,
  required int toColumn,
  required int toIndex,
}) {
  return editBoard(text, (board, lines) {
    final card = _cardAt(board, fromColumn, fromCard);
    final target = _columnAt(board, toColumn);
    if (fromColumn == toColumn && toIndex == fromCard) return false;
    final others = <KanbanCard>[
      for (final c in target.cards)
        if (!identical(c, card)) c,
    ];
    RangeError.checkValueInInterval(toIndex, 0, others.length, 'toIndex');
    final insertLine = toIndex < others.length
        ? others[toIndex].line
        : target.insertLine;
    final neighbour = _neighbour(others, toIndex);
    final delta = (neighbour?.indent ?? 0) - card.indent;
    final moved = reindent(lines.sublist(card.line, card.end), delta);
    lines.removeRange(card.line, card.end);
    final at = insertLine > card.line
        ? insertLine - card.lineCount
        : insertLine;
    lines.insertAll(at, moved);
    return true;
  });
}

/// [text] with a card titled [title] added to column [column], at the end
/// or, with [index], as that card of it.
///
/// The card is written `- [ ] title`, indented like the card it goes before
/// (or, at the end, after).
/// A blank [title] adds nothing.
String addCard(String text, int column, String title, {int? index}) {
  final clean = oneLine(title);
  if (clean.isEmpty) return text;
  return editBoard(text, (board, lines) {
    final target = _columnAt(board, column);
    final cards = target.cards;
    if (index != null) {
      RangeError.checkValueInInterval(index, 0, cards.length, 'index');
    }
    final at = index != null && index < cards.length
        ? cards[index].line
        : target.insertLine;
    final neighbour = _neighbour(cards, index ?? cards.length);
    final pad = neighbour == null
        ? ''
        : lines[neighbour.line].substring(0, neighbour.indent);
    lines.insert(at, board.endLine('$pad- [ ] $clean'));
    return true;
  });
}

/// [text] with the title of card [card] of column [column] replaced by
/// [title], keeping the card's indentation, marker and box. A title equal
/// to the current one returns [text] itself; a blank one clears the title.
String editCardTitle(String text, int column, int card, String title) {
  final clean = oneLine(title);
  return editBoard(text, (board, lines) {
    final target = _cardAt(board, column, card);
    if (clean == target.title) return false;
    final raw = lines[target.line];
    final cr = raw.endsWith('\r') ? '\r' : '';
    final head = raw.substring(0, target.titleStart);
    final String prefix;
    if (clean.isEmpty) {
      prefix = head.trimRight();
    } else if (head.endsWith(' ') || head.endsWith('\t')) {
      prefix = head;
    } else {
      prefix = '$head ';
    }
    lines[target.line] = '$prefix$clean$cr';
    return true;
  });
}

/// [text] with the box of card [card] of column [column] flipped; a card
/// without a box is left alone ([text] comes back). Only the box character
/// changes.
String toggleCard(String text, int column, int card) {
  return editBoard(text, (board, lines) {
    final target = _cardAt(board, column, card);
    final box = target.boxStart;
    if (box == null) return false;
    final raw = lines[target.line];
    final at = box + 1;
    lines[target.line] = raw.replaceRange(
      at,
      at + 1,
      raw.codeUnitAt(at) == 0x20 ? 'x' : ' ',
    );
    return true;
  });
}

/// [text] without card [card] of column [column], its body with it.
String deleteCard(String text, int column, int card) {
  return editBoard(text, (board, lines) {
    final target = _cardAt(board, column, card);
    lines.removeRange(target.line, target.end);
    return true;
  });
}

/// The card whose indentation a card put at [index] among [cards] takes:
/// the one it goes before, or the last one when it goes at the end; null
/// in an empty column.
KanbanCard? _neighbour(List<KanbanCard> cards, int index) {
  if (cards.isEmpty) return null;
  return index < cards.length ? cards[index] : cards.last;
}

KanbanColumn _columnAt(KanbanBoard board, int column) {
  RangeError.checkValidIndex(column, board.columns, 'column');
  return board.columns[column];
}

KanbanCard _cardAt(KanbanBoard board, int column, int card) {
  final cards = _columnAt(board, column).cards;
  RangeError.checkValidIndex(card, cards, 'card');
  return cards[card];
}

/// The edits the board view makes to a kanban note's columns (#1154): add,
/// rename and delete, each a function from the note's text to the new text.
///
/// Like the card edits (`card_edits.dart`) they rewrite only the lines they
/// touch, and they never reach Obsidian's `%% kanban:settings` footer: a
/// column added at the end of the board goes in before it.
library;

import 'package:niman/src/kanban/board_edit_scope.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/kanban/kanban_column.dart';

/// [text] with a column named [name] added at the end of the board: after
/// the last non-blank line before the settings footer (or the end of the
/// note), set off from it by a blank line. Without a column or any text
/// before it, as in a note with only a frontmatter, the heading follows
/// directly. A blank [name] adds nothing.
String addColumn(String text, String name) {
  final clean = oneLine(name);
  if (clean.isEmpty) return text;
  return editBoard(text, (board, lines) {
    var last = board.contentEnd - 1;
    while (last >= 0 && lines[last].trim().isEmpty) {
      last--;
    }
    final tight = last < 0 || last < board.frontmatterEnd;
    lines.insertAll(last + 1, <String>[
      if (!tight) board.endLine(''),
      board.endLine('## $clean'),
    ]);
    return true;
  });
}

/// [text] with column [column] renamed to [name]: its heading line becomes
/// `## name` (its indentation and `\r` kept, a closing run of `#` dropped).
/// A name equal to the current one returns [text] itself; a blank one adds
/// nothing.
String renameColumn(String text, int column, String name) {
  final clean = oneLine(name);
  if (clean.isEmpty) return text;
  return editBoard(text, (board, lines) {
    final target = _columnAt(board, column);
    if (clean == target.name) return false;
    final raw = lines[target.headingLine];
    final cr = raw.endsWith('\r') ? '\r' : '';
    final head = raw.substring(0, target.headingMarkerEnd);
    lines[target.headingLine] = '$head $clean$cr';
    return true;
  });
}

/// [text] without column [column]: its heading and its cards, bodies
/// included, and the `**Complete**` line Obsidian's plugin writes in a lane.
/// When nothing else is left in the column but blank lines they go too, so
/// the spacing around its neighbours stays the file's; any prose between
/// its cards stays where it was.
String deleteColumn(String text, int column) {
  return editBoard(text, (board, lines) {
    final target = _columnAt(board, column);
    final gone = <int>{target.headingLine};
    for (final card in target.cards) {
      for (var i = card.line; i < card.end; i++) {
        gone.add(i);
      }
    }
    for (var i = target.headingLine; i < target.endLine; i++) {
      if (lines[i].trim() == _laneMark) gone.add(i);
    }
    var onlyBlank = true;
    for (var i = target.headingLine; i < target.endLine; i++) {
      if (!gone.contains(i) && lines[i].trim().isNotEmpty) {
        onlyBlank = false;
        break;
      }
    }
    if (onlyBlank) {
      lines.removeRange(target.headingLine, target.endLine);
    } else {
      final kept = <String>[
        for (var i = 0; i < lines.length; i++)
          if (!gone.contains(i)) lines[i],
      ];
      lines
        ..clear()
        ..addAll(kept);
    }
    return true;
  });
}

/// The line Obsidian's Kanban plugin writes in a lane whose cards it
/// completes: it belongs to the lane, so it goes with it.
const String _laneMark = '**Complete**';

KanbanColumn _columnAt(KanbanBoard board, int column) {
  RangeError.checkValidIndex(column, board.columns, 'column');
  return board.columns[column];
}

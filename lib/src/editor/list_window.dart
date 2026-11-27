import 'package:niman/src/editor/list_row.dart';

/// The lines `first..last` of a note widened to the list block around them:
/// every line the indent of a list item has to look at — the items above it
/// (the one it nests under, the sublist it joins), its own subtree and the
/// siblings below (renumbered). Nothing past the block is read — and upward
/// nothing past the nearest item on the margin — so a command over this
/// window gives the answer it would give over the whole note, without a read
/// of every line of a long list above the caret.
///
/// [lineAt] is asked for lines in `0..lineCount - 1`, one at a time, outward
/// from the touched ones.
///
/// The whole block below the lines is read; [listIndentWindowBelow] reads as
/// far as it is asked to.
({int first, int last}) listIndentWindow(
  String Function(int line) lineAt,
  int lineCount,
  int first,
  int last,
) {
  final window = listIndentWindowBelow(lineAt, lineCount, first, last);
  return (first: window.first, last: window.last);
}

/// [listIndentWindow] that reads at most [below] lines past `last` (all of
/// the block when null), and says whether it reached the end of the block:
/// `complete` false means more lines of it are below the window. With `top`
/// the upward walk, which an earlier call made, is not made again.
///
/// The edit of an indent reads only as far down as it changes anything — the
/// subtree of the item and the siblings it renumbers — by asking for a few
/// lines, and for as many more as the answer says it needs
/// (`indentListLinesWithin`): the cost follows the lines that change, not the
/// length of the list (#1355).
({int first, int last, bool complete}) listIndentWindowBelow(
  String Function(int line) lineAt,
  int lineCount,
  int first,
  int last, {
  int? below,
  int? top,
}) {
  // A line belongs to the block when it is an item or is indented; a blank
  // line only when something that belongs follows it.
  bool belongs(ListRow row) => row.head != null || row.indent > 0;

  // Upward the walk ends at the nearest item on the margin (at the quote
  // depth of the touched lines): nothing above it can hold an item that is
  // below it, so the structure from there on is the whole note's.
  var up = top ?? first;
  if (top == null) {
    final depth = ListRow(lineAt(first)).depth;
    for (var at = first - 1; at >= 0; at--) {
      final row = ListRow(lineAt(at));
      if (row.blank) continue;
      if (!belongs(row)) break;
      up = at;
      if (row.head != null && row.indent == 0 && row.depth == depth) break;
    }
  }
  var bottom = last;
  var complete = true;
  final stop = below == null ? lineCount : last + 1 + below;
  for (var at = last + 1; at < lineCount; at++) {
    if (at >= stop) {
      complete = false;
      break;
    }
    final row = ListRow(lineAt(at));
    if (row.blank) continue;
    if (!belongs(row)) break;
    bottom = at;
  }
  return (first: up, last: bottom, complete: complete);
}

/// Where the caret on [column] of a line of [before] lands once the line
/// reads [after]: what the edit changed is at the line's start, so a caret
/// past it moves with the text and one inside it stays inside what replaced
/// it.
int mapColumn(String before, String after, int column) {
  var same = 0;
  while (same < before.length &&
      same < after.length &&
      before.codeUnitAt(before.length - 1 - same) ==
          after.codeUnitAt(after.length - 1 - same)) {
    same++;
  }
  final delta = after.length - before.length;
  if (column >= before.length - same) return column + delta;
  final room = after.length - same;
  final moved = column + delta;
  return moved < 0 ? 0 : (moved > room ? room : moved);
}

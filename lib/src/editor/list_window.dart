import 'package:niman/src/editor/list_row.dart';

/// The lines `first..last` of a note widened to the list block around them:
/// every line the indent of a list item has to look at — the items above it
/// (the one it nests under, the sublist it joins), its own subtree and the
/// siblings below (renumbered). Nothing past the block is read, so a command
/// over this window gives the answer it would give over the whole note.
///
/// [lineAt] is asked for lines in `0..lineCount - 1`, one at a time, outward
/// from the touched ones.
({int first, int last}) listIndentWindow(
  String Function(int line) lineAt,
  int lineCount,
  int first,
  int last,
) {
  // A line belongs to the block when it is an item or is indented; a blank
  // line only when something that belongs follows it.
  bool belongs(ListRow row) => row.head != null || row.indent > 0;

  var top = first;
  for (var at = first - 1; at >= 0; at--) {
    final row = ListRow(lineAt(at));
    if (row.blank) continue;
    if (!belongs(row)) break;
    top = at;
  }
  var bottom = last;
  for (var at = last + 1; at < lineCount; at++) {
    final row = ListRow(lineAt(at));
    if (row.blank) continue;
    if (!belongs(row)) break;
    bottom = at;
  }
  return (first: top, last: bottom);
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

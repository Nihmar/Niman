import 'package:niman/src/editor/list_row.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// How many lines above the line the walk looks at for the item it goes on:
/// a paragraph wrapped over more lines than this is not a list item's, as far
/// as Enter can tell, and gets the platform's line break.
const int _reach = 256;

/// The columns the line after [line] starts at when [line], not a list item
/// itself, goes on the text of the item above it: the item's content column
/// (CommonMark's own rule for a line to be inside it), or null when [line] is
/// not that — a line at the margin is a lazy continuation, and a line indented
/// less than the item's text is not inside it either (#1344).
///
/// [row] is [line] read behind its quote marks. The item is the nearest one
/// above, found over the lines that go on it — indented text, blank lines —
/// and at the quote depth of [line]; nothing else is read.
int? continuationIndent(SourceBuffer buffer, int line, ListRow row) {
  final from = line - _reach < 0 ? 0 : line - _reach;
  for (var at = line - 1; at >= from; at--) {
    final above = ListRow(buffer.lineAt(at));
    if (above.depth != row.depth) return null;
    if (above.blank) continue;
    final head = above.head;
    if (head != null) {
      final column = above.contentColumn;
      return row.indent >= column ? column : null;
    }
    // A line at the margin ends whatever item there was above it.
    if (above.indent == 0) return null;
  }
  return null;
}

import 'package:niman/src/editor/list_row.dart';
import 'package:niman/src/editor/list_tree.dart';
import 'package:niman/src/editor/list_window.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// How many lines below the item the first read holds.
const int _firstRead = 32;

/// The edit Enter makes at [offset] in the numbered item on [line] when the
/// items after it were counted on from it: the new item, and each of those
/// siblings one number up — `1. a|` / `2. b` gives `1. a` / `2. ` / `3. b`
/// (#1343). Null when no sibling counts on from the item (the new item is the
/// only edit, which the caller makes), or when the line is no numbered item.
///
/// The edit replaces `[offset, end)` where `end` is the end of the last
/// sibling renumbered, in one piece — one undo step — with the line endings
/// the note has. Only the siblings that count on one by one are renumbered
/// (the rule of the indent: a list numbered by hand stays as written), and
/// only as many lines are read as they are: a few below the item, and twice
/// as many for as long as the run goes on past what was read, like
/// `listIndentEdit`.
///
/// [continuation] is what the new item starts with after its line break
/// (the quote marks and the marker); the text of the line from the caret on
/// goes with it.
({int start, int end, String text, SelectionModel caret})? numberedEnter(
  SourceBuffer buffer, {
  required int line,
  required int offset,
  required String continuation,
}) {
  var reach = _firstRead;
  int? top;
  while (true) {
    final window = listIndentWindowBelow(
      buffer.lineAt,
      buffer.lineCount,
      line,
      line,
      below: reach,
      top: top,
    );
    top = window.first;
    final rows = [
      for (var at = window.first; at <= window.last; at++)
        ListRow(buffer.lineAt(at)),
    ];
    final index = line - window.first;
    final head = rows[index].head;
    if (head == null || head.number == null) return null;
    final counting = ListTree(rows).countingAfter(index);
    if (counting.open && !window.complete) {
      reach *= 2;
      continue;
    }
    if (counting.run.isEmpty) return null;
    final lineStart = buffer.offsetOfLine(line);
    final first = buffer.lineAt(line);
    final text = StringBuffer(buffer.terminatorAt(line))
      ..write(continuation)
      ..write(first.substring(offset - lineStart));
    var expected = head.number!;
    var next = 0;
    for (var at = index + 1; at <= counting.run.last; at++) {
      text.write(buffer.terminatorAt(window.first + at - 1));
      if (counting.run[next] == at) {
        expected += 1;
        text.write(
          _renumbered(rows[at], rows[at].head!.markerFor(expected + 1)),
        );
        next++;
      } else {
        text.write(buffer.lineAt(window.first + at));
      }
    }
    final last = window.first + counting.run.last;
    final eol = buffer.terminatorAt(line).length;
    return (
      start: offset,
      end: buffer.offsetOfLine(last) + buffer.lineLengthAt(last),
      text: text.toString(),
      caret: SelectionModel.at(offset + eol + continuation.length),
    );
  }
}

/// [row]'s line with its marker replaced by [marker], the rest — the quote
/// marks, the indent as it was written, what the item says — untouched.
String _renumbered(ListRow row, String marker) {
  final head = row.head!;
  return '${row.marks}${row.body.substring(0, row.lead)}$marker'
      '${row.body.substring(row.lead + head.marker.length)}${row.cr}';
}

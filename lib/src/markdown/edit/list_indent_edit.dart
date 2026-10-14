import 'package:niman/src/editor/list_indent.dart';
import 'package:niman/src/editor/list_window.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// What Tab and Shift+Tab do to a note: replace `[start, end)` with `text`
/// and put the selection on `caret`.
typedef ListIndentEdit = ({
  int start,
  int end,
  String text,
  SelectionModel caret,
});

/// The edit that indents (or outdents, `outdent` true) the lines [selection]
/// touches in [buffer], by the rule of `indentLines` — the one the toolbar's
/// indent runs — or null when nothing would change.
///
/// Only the list block around the selection is read, and only the lines that
/// change are replaced, each keeping its own line terminator. Each end of the
/// selection stays on its own line and character.
ListIndentEdit? listIndentEdit(
  SourceBuffer buffer,
  SelectionModel selection, {
  required int width,
  required bool outdent,
}) {
  final touched = (
    first: buffer.lineOf(selection.start),
    last: buffer.lineOf(selection.end),
  );
  final window = listIndentWindow(
    buffer.lineAt,
    buffer.lineCount,
    touched.first,
    touched.last,
  );
  final before = [
    for (var at = window.first; at <= window.last; at++) buffer.lineAt(at),
  ];
  final after = indentListLines(
    before,
    first: touched.first - window.first,
    last: touched.last - window.first,
    width: width,
    outdent: outdent,
  );
  var from = 0;
  while (from < before.length && before[from] == after[from]) {
    from++;
  }
  if (from == before.length) return null;
  var to = before.length - 1;
  while (before[to] == after[to]) {
    to--;
  }
  final text = StringBuffer();
  for (var at = from; at <= to; at++) {
    text.write(after[at]);
    if (at < to) text.write(buffer.terminatorAt(window.first + at));
  }
  int moved(int offset) {
    final line = buffer.lineOf(offset);
    final index = line - window.first;
    var shift = 0;
    for (var at = 0; at < index; at++) {
      shift += after[at].length - before[at].length;
    }
    final column = offset - buffer.offsetOfLine(line);
    return buffer.offsetOfLine(line) +
        shift +
        mapColumn(before[index], after[index], column);
  }

  return (
    start: buffer.offsetOfLine(window.first + from),
    end:
        buffer.offsetOfLine(window.first + to) +
        buffer.lineLengthAt(window.first + to),
    text: text.toString(),
    caret: SelectionModel(
      anchor: moved(selection.anchor),
      extent: moved(selection.extent),
    ),
  );
}

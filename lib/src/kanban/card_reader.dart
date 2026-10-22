import 'package:niman/src/kanban/kanban_card.dart';
import 'package:niman/src/kanban/line_facts.dart';
import 'package:niman/src/todo/parser.dart';

/// The card whose first line is [first] (read as [facts]) and whose lines
/// run to [end] (exclusive); [lines] are the note's lines without their
/// trailing `\r`.
///
/// The tags and the due date come from the todo.txt parser the app already
/// has, run over the title, so `#tag` and `due:YYYY-MM-DD` mean on a card
/// what they mean on a task.
KanbanCard readCard(List<String> lines, int first, int end, LineFacts facts) {
  final text = facts.text;
  final start = facts.textStart.clamp(0, text.length);
  final title = text.substring(start).trim();
  final box = facts.boxStart;
  final task = parseTodoLine(title);
  return KanbanCard(
    line: first,
    end: end,
    indent: facts.indent,
    marker: facts.marker!,
    boxStart: box,
    titleStart: start,
    checked: box == null ? null : text.codeUnitAt(box + 1) != 0x20,
    title: title,
    body: _body(lines, first + 1, end),
    tags: task.hashtags,
    due: task.due,
  );
}

/// [lines] from [from] to [end] with their common indentation removed.
List<String> _body(List<String> lines, int from, int end) {
  if (from >= end) return const <String>[];
  var common = -1;
  for (var i = from; i < end; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;
    final indent = _indentOf(line);
    if (common < 0 || indent < common) common = indent;
  }
  if (common < 0) common = 0;
  return <String>[
    for (var i = from; i < end; i++)
      if (lines[i].trim().isEmpty) '' else lines[i].substring(common),
  ];
}

int _indentOf(String line) {
  var at = 0;
  while (at < line.length &&
      (line.codeUnitAt(at) == 0x20 || line.codeUnitAt(at) == 0x09)) {
    at++;
  }
  return at;
}

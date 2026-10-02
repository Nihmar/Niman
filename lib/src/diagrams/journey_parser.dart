/// The parser behind a `journey` Mermaid fence (#530).
///
/// A user journey is a `title`, its `section`s and one task a line,
/// `task : score : actor, actor` — a score from 0 to 5, the actors who
/// took part. Like the other parsers it reports a syntax error as a
/// [MermaidParseException] naming the line.
library;

import 'package:niman/src/diagrams/journey_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// `task : score : actors`, the actors optional.
final RegExp _task = RegExp(r'^(.+?)\s*:\s*([^:]+?)\s*(?::\s*(.*))?$');

/// Parses a user journey (the fence's content, header included).
JourneyChart parseJourney(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  final header = index < lines.length
      ? stripMermaidComment(lines[index]).trim().toLowerCase()
      : '';
  if (header != 'journey') {
    throw MermaidParseException(index + 1, 'expected "journey"');
  }
  String? title;
  final actors = <String>[];
  final names = <String?>[null];
  final tasks = <List<JourneyTask>>[[]];
  for (index++; index < lines.length; index++) {
    final line = stripMermaidComment(lines[index]).trim();
    if (line.isEmpty) continue;
    final number = index + 1;
    final lower = line.toLowerCase();
    if (lower.startsWith('title ')) {
      title = line.substring(6).trim();
      continue;
    }
    if (lower.startsWith('section ')) {
      names.add(decodeMermaidEntities(line.substring(8).trim()));
      tasks.add([]);
      continue;
    }
    if (lower.startsWith('acctitle') || lower.startsWith('accdescr')) {
      continue;
    }
    final task = _task.firstMatch(line);
    if (task == null) {
      throw MermaidParseException(
        number,
        'expected a task ("task : score : actors"), found "$line"',
      );
    }
    final score = double.tryParse(task.group(2)!);
    // Written the way round that refuses NaN, which no comparison holds.
    if (score == null || !(score >= 0 && score <= 5)) {
      throw MermaidParseException(
        number,
        'a score is a number from 0 to 5, found "${task.group(2)}"',
      );
    }
    final who = <int>[];
    for (final actor in (task.group(3) ?? '').split(',')) {
      final name = decodeMermaidEntities(actor.trim());
      if (name.isEmpty) continue;
      var at = actors.indexOf(name);
      if (at < 0) {
        at = actors.length;
        actors.add(name);
      }
      if (!who.contains(at)) who.add(at);
    }
    tasks.last.add(
      JourneyTask(
        label: decodeMermaidEntities(task.group(1)!.trim()),
        score: score,
        actors: who,
      ),
    );
  }
  if (tasks.every((section) => section.isEmpty)) {
    throw const MermaidParseException(1, 'a journey needs a task');
  }
  return JourneyChart(
    title: title == null || title.isEmpty ? null : decodeMermaidEntities(title),
    actors: List.unmodifiable(actors),
    sections: [
      for (var s = 0; s < names.length; s++)
        if (tasks[s].isNotEmpty || names[s] != null)
          JourneySection(name: names[s], tasks: List.unmodifiable(tasks[s])),
    ],
  );
}

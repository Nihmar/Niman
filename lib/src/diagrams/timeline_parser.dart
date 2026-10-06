/// The parser behind a `timeline` Mermaid fence (#530).
///
/// A timeline is a `title`, its `section`s and one period a line,
/// `period : event : event`; a line that opens with `:` adds events to the
/// period before it. An event is split from the next at a colon followed
/// by a space, so a time written `10:30` stays whole. Like the other
/// parsers it reports a syntax error as a [MermaidParseException] naming
/// the line.
library;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/timeline_model.dart';

/// The colon between a period and its events, or two events: one followed
/// by a space or the end of the line.
final RegExp _separator = RegExp(r':(?=\s|$)');

/// Parses a timeline (the fence's content, header included).
TimelineChart parseTimeline(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  final header = index < lines.length
      ? stripMermaidComment(lines[index]).trim().toLowerCase()
      : '';
  if (header != 'timeline') {
    throw MermaidParseException(index + 1, 'expected "timeline"');
  }
  String? title;
  final names = <String?>[null];
  final periods = <List<({String label, List<String> events})>>[[]];
  for (index++; index < lines.length; index++) {
    final line = stripMermaidComment(lines[index]).trim();
    if (line.isEmpty) continue;
    final number = index + 1;
    final lower = line.toLowerCase();
    if (lower.startsWith('title ')) {
      title = line.substring(6).trim();
    } else if (lower.startsWith('section ')) {
      names.add(decodeMermaidEntities(line.substring(8).trim()));
      periods.add([]);
    } else if (lower.startsWith('acctitle') || lower.startsWith('accdescr')) {
      continue;
    } else if (line.startsWith(':')) {
      final last = periods.last.isEmpty ? null : periods.last.last;
      if (last == null) {
        throw MermaidParseException(
          number,
          'an event needs a period before it',
        );
      }
      last.events.addAll(_events(line.substring(1)));
    } else {
      final parts = line.split(_separator);
      periods.last.add((
        label: decodeMermaidEntities(parts.first.trim()),
        events: _events(parts.skip(1).join(':')),
      ));
    }
  }
  if (periods.every((section) => section.isEmpty)) {
    throw const MermaidParseException(1, 'a timeline needs a period');
  }
  return TimelineChart(
    title: title == null || title.isEmpty ? null : decodeMermaidEntities(title),
    sections: [
      for (var s = 0; s < names.length; s++)
        if (periods[s].isNotEmpty || names[s] != null)
          TimelineSection(
            name: names[s],
            periods: [
              for (final period in periods[s])
                TimelinePeriod(
                  label: period.label,
                  events: List.unmodifiable(period.events),
                ),
            ],
          ),
    ],
  );
}

/// The events [written] after a period's colon, empty ones left out.
List<String> _events(String written) => [
  for (final event in written.split(_separator))
    if (event.trim().isNotEmpty) decodeMermaidEntities(event.trim()),
];

/// The parser behind a `gantt` Mermaid fence (#530).
///
/// A Gantt chart is its settings — `title`, `dateFormat`, `axisFormat`,
/// `excludes` — its `section`s and one task a line, `label : data`. What
/// the drawing has no use for (`todayMarker`, `tickInterval`, `click`, the
/// accessibility lines) is stepped over. Like the other parsers it reports
/// a syntax error as a [MermaidParseException] naming the line.
library;

import 'package:niman/src/diagrams/gantt_dates.dart';
import 'package:niman/src/diagrams/gantt_model.dart';
import 'package:niman/src/diagrams/gantt_tasks.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// The settings whose line carries nothing to draw.
const Set<String> _ignored = {
  'todaymarker',
  'tickinterval',
  'weekday',
  'weekend',
  'includes',
  'click',
  'displaymode',
  'inclusiveenddates',
  'topaxis',
  'acctitle',
  'accdescr',
};

/// The day names `excludes` may list, Monday first.
const List<String> _weekdays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// Parses a Gantt chart (the fence's content, header included).
GanttChart parseGantt(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  if (index >= lines.length ||
      stripMermaidComment(lines[index]).trim().toLowerCase() != 'gantt') {
    throw MermaidParseException(index + 1, 'expected "gantt"');
  }
  String? title;
  String? axisFormat;
  var format = GanttDateFormat.of('YYYY-MM-DD');
  var excludeLine = 0;
  var excludes = '';
  final names = <String>[''];
  final specs = <GanttTaskSpec>[];
  for (index++; index < lines.length; index++) {
    final line = stripMermaidComment(lines[index]).trim();
    if (line.isEmpty) continue;
    final number = index + 1;
    final space = line.indexOf(RegExp(r'[\s:]'));
    final word = (space < 0 ? line : line.substring(0, space)).toLowerCase();
    final rest = space < 0 ? '' : line.substring(space).trim();
    switch (word) {
      case 'title':
        title = rest;
      case 'dateformat':
        format = GanttDateFormat.of(rest);
      case 'axisformat':
        axisFormat = rest;
      case 'excludes':
        excludes = rest;
        excludeLine = number;
      case 'section':
        names.add(rest);
      case _ when _ignored.contains(word):
        break;
      default:
        final colon = line.indexOf(':');
        if (colon <= 0) {
          throw MermaidParseException(
            number,
            'expected a task ("label : data"), found "$line"',
          );
        }
        specs.add(
          readGanttTask(
            line.substring(0, colon).trim(),
            line.substring(colon + 1),
            names.length - 1,
            number,
          ),
        );
    }
  }
  if (specs.isEmpty) {
    throw const MermaidParseException(1, 'a gantt chart needs a task');
  }
  final tasks = resolveGanttTasks(
    specs,
    format,
    _excludes(excludes, format, excludeLine),
  );
  return GanttChart(
    title: title == null || title.isEmpty ? null : title,
    axisFormat: axisFormat == null || axisFormat.isEmpty ? null : axisFormat,
    sections: [
      for (var s = 0; s < names.length; s++)
        if (specs.any((spec) => spec.section == s))
          GanttSection(
            name: names[s],
            tasks: [
              for (var i = 0; i < specs.length; i++)
                if (specs[i].section == s) tasks[i],
            ],
          ),
    ],
  );
}

/// What `excludes` [written] on diagram [line] leaves out: `weekends`,
/// day names, dates in the chart's [format].
GanttExcludes _excludes(String written, GanttDateFormat format, int line) {
  var weekends = false;
  final weekdays = <int>{};
  final days = <DateTime>{};
  for (final item in written.split(RegExp(r'[\s,]+'))) {
    final word = item.toLowerCase();
    if (word.isEmpty) continue;
    if (word == 'weekends') {
      weekends = true;
    } else if (_weekdays.contains(word)) {
      weekdays.add(_weekdays.indexOf(word) + 1);
    } else {
      final date = format.read(item);
      if (date == null) {
        throw MermaidParseException(
          line,
          'expected weekends, a day name or a date, found "$item"',
        );
      }
      days.add(DateTime.utc(date.year, date.month, date.day));
    }
  }
  return (weekends: weekends, weekdays: weekdays, days: days);
}

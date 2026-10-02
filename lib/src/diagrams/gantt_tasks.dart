/// A Gantt chart's tasks as written, and their dates resolved (#530).
///
/// A task line's data is `[tags,] [id,] [start,] end`: tags among `done`,
/// `active`, `crit` and `milestone`; a start that is a date or
/// `after id …` (and, left out, the end of the task before); an end that is
/// a date, a duration or `until id`. The dates are resolved once every
/// task is read, so a task may wait on one written after it, and the days
/// the chart `excludes` stretch a task over them, as Mermaid does.
library;

import 'package:niman/src/diagrams/gantt_dates.dart';
import 'package:niman/src/diagrams/gantt_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';

/// The tags a task's data may open with.
const Set<String> _tags = {'done', 'active', 'crit', 'milestone'};

/// One day, in milliseconds.
const int _day = 24 * 60 * 60 * 1000;

/// A task as written: its dates not resolved yet.
typedef GanttTaskSpec = ({
  String label,
  int section,
  int line,
  Set<String> tags,
  String? id,
  String? start,
  String end,
});

/// The days a chart leaves out of its tasks' durations.
typedef GanttExcludes = ({
  bool weekends,
  Set<int> weekdays,
  Set<DateTime> days,
});

/// The task [label]'s [data], written on diagram [line] of [section].
GanttTaskSpec readGanttTask(String label, String data, int section, int line) {
  final items = [for (final item in data.split(',')) item.trim()];
  final tags = <String>{};
  while (items.isNotEmpty && _tags.contains(items.first.toLowerCase())) {
    tags.add(items.removeAt(0).toLowerCase());
  }
  if (items.isEmpty || items.length > 3 || items.any((i) => i.isEmpty)) {
    throw MermaidParseException(
      line,
      'expected "[id,] [start,] end" after the colon, found "$data"',
    );
  }
  return (
    label: label,
    section: section,
    line: line,
    tags: tags,
    id: items.length == 3 ? items[0] : null,
    start: items.length >= 2 ? items[items.length - 2] : null,
    end: items.last,
  );
}

/// Every task of [specs] placed in time, in order, read with [format] and
/// stretched over the days [excludes] leaves out.
List<GanttTask> resolveGanttTasks(
  List<GanttTaskSpec> specs,
  GanttDateFormat format,
  GanttExcludes excludes,
) {
  final byId = <String, int>{
    for (var i = 0; i < specs.length; i++)
      if (specs[i].id != null) specs[i].id!: i,
  };
  final starts = List<DateTime?>.filled(specs.length, null);
  final ends = List<DateTime?>.filled(specs.length, null);
  var progress = true;
  while (progress) {
    progress = false;
    for (var i = 0; i < specs.length; i++) {
      if (ends[i] != null) continue;
      final spec = specs[i];
      final start = _start(spec, i, format, byId, ends);
      if (start == null) continue;
      final end = _end(spec, start, format, byId, starts);
      if (end == null) continue;
      starts[i] = start;
      ends[i] = _stretched(start, end, excludes);
      progress = true;
    }
  }
  for (var i = 0; i < specs.length; i++) {
    if (ends[i] == null) {
      throw MermaidParseException(specs[i].line, 'a task waits on itself');
    }
  }
  return [
    for (var i = 0; i < specs.length; i++)
      GanttTask(
        label: specs[i].label,
        id: specs[i].id,
        start: starts[i]!,
        end: ends[i]!.isBefore(starts[i]!) ? starts[i]! : ends[i]!,
        done: specs[i].tags.contains('done'),
        active: specs[i].tags.contains('active'),
        critical: specs[i].tags.contains('crit'),
        milestone: specs[i].tags.contains('milestone'),
      ),
  ];
}

/// When task [i] starts, or null while what it waits on is unresolved.
DateTime? _start(
  GanttTaskSpec spec,
  int i,
  GanttDateFormat format,
  Map<String, int> byId,
  List<DateTime?> ends,
) {
  final written = spec.start;
  if (written == null) {
    if (i == 0) {
      throw MermaidParseException(spec.line, 'the first task needs a start');
    }
    return ends[i - 1];
  }
  if (written.toLowerCase().startsWith('after ')) {
    DateTime? latest;
    for (final id in written.substring(6).trim().split(RegExp(r'\s+'))) {
      final other = byId[id];
      if (other == null) {
        throw MermaidParseException(spec.line, 'no task has the id "$id"');
      }
      final end = ends[other];
      if (end == null) return null;
      if (latest == null || end.isAfter(latest)) latest = end;
    }
    return latest;
  }
  return format.read(written) ??
      (throw MermaidParseException(
        spec.line,
        'expected a date in the chart\'s dateFormat or "after id", '
        'found "$written"',
      ));
}

/// When a task starting at [start] ends, or null while the task it runs
/// `until` is unresolved.
DateTime? _end(
  GanttTaskSpec spec,
  DateTime start,
  GanttDateFormat format,
  Map<String, int> byId,
  List<DateTime?> starts,
) {
  final written = spec.end;
  if (written.toLowerCase().startsWith('until ')) {
    final id = written.substring(6).trim();
    final other = byId[id];
    if (other == null) {
      throw MermaidParseException(spec.line, 'no task has the id "$id"');
    }
    return starts[other];
  }
  final duration = ganttDuration(written);
  if (duration != null) return start.add(duration);
  return format.read(written) ??
      (throw MermaidParseException(
        spec.line,
        'expected a duration (like 3d), a date or "until id", '
        'found "$written"',
      ));
}

/// [end], pushed a day further for every excluded day from [start] to it,
/// as Mermaid stretches a task over a weekend.
DateTime _stretched(DateTime start, DateTime end, GanttExcludes excludes) {
  if (!excludes.weekends &&
      excludes.weekdays.isEmpty &&
      excludes.days.isEmpty) {
    return end;
  }
  var day = DateTime.utc(start.year, start.month, start.day);
  var stretched = end;
  // A bound, so a chart that excludes every day cannot loop for ever.
  for (var guard = 0; guard < 100000 && !day.isAfter(stretched); guard++) {
    if (_excluded(day, excludes)) {
      stretched = stretched.add(const Duration(milliseconds: _day));
    }
    day = day.add(const Duration(milliseconds: _day));
  }
  return stretched;
}

bool _excluded(DateTime day, GanttExcludes excludes) =>
    (excludes.weekends && day.weekday >= DateTime.saturday) ||
    excludes.weekdays.contains(day.weekday) ||
    excludes.days.contains(day);

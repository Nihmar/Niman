/// The ticks of a Gantt chart's time axis (#530): a step that keeps the
/// dates written under them apart, falling on calendar boundaries —
/// midnight, the first of a month, New Year's Day.
library;

/// One step the axis may take: a `count` of a calendar `unit`.
typedef GanttStep = ({GanttUnit unit, int count});

/// The calendar units a step is counted in.
enum GanttUnit {
  /// Hours.
  hour,

  /// Days.
  day,

  /// Months.
  month,

  /// Years.
  year,
}

/// The steps the axis tries, smallest first.
const List<GanttStep> _steps = [
  (unit: GanttUnit.hour, count: 1),
  (unit: GanttUnit.hour, count: 3),
  (unit: GanttUnit.hour, count: 6),
  (unit: GanttUnit.hour, count: 12),
  (unit: GanttUnit.day, count: 1),
  (unit: GanttUnit.day, count: 2),
  (unit: GanttUnit.day, count: 7),
  (unit: GanttUnit.day, count: 14),
  (unit: GanttUnit.month, count: 1),
  (unit: GanttUnit.month, count: 3),
  (unit: GanttUnit.month, count: 6),
  (unit: GanttUnit.year, count: 1),
  (unit: GanttUnit.year, count: 5),
  (unit: GanttUnit.year, count: 10),
];

/// The smallest step that puts no more than [most] ticks between [from]
/// and [to].
GanttStep ganttStep(DateTime from, DateTime to, int most) {
  for (final step in _steps) {
    if (ganttTicks(from, to, step, limit: most + 1).length <= most) {
      return step;
    }
  }
  return _steps.last;
}

/// The ticks from [from] to [to] at [step], each on a boundary of its
/// unit; at most [limit] of them.
List<DateTime> ganttTicks(
  DateTime from,
  DateTime to,
  GanttStep step, {
  int limit = 1000,
}) {
  final ticks = <DateTime>[];
  var tick = _first(from, step);
  while (!tick.isAfter(to) && ticks.length < limit) {
    ticks.add(tick);
    tick = _next(tick, step);
  }
  return ticks;
}

/// The first boundary of [step] at or after [from].
DateTime _first(DateTime from, GanttStep step) {
  final start = switch (step.unit) {
    GanttUnit.hour => DateTime.utc(
      from.year,
      from.month,
      from.day,
      from.hour - from.hour % step.count,
    ),
    GanttUnit.day => DateTime.utc(from.year, from.month, from.day),
    GanttUnit.month => DateTime.utc(
      from.year,
      from.month - (from.month - 1) % step.count,
    ),
    GanttUnit.year => DateTime.utc(from.year - from.year % step.count),
  };
  var tick = start;
  while (tick.isBefore(from)) {
    tick = _next(tick, step);
  }
  return tick;
}

DateTime _next(DateTime tick, GanttStep step) => switch (step.unit) {
  GanttUnit.hour => tick.add(Duration(hours: step.count)),
  GanttUnit.day => DateTime.utc(tick.year, tick.month, tick.day + step.count),
  GanttUnit.month => DateTime.utc(tick.year, tick.month + step.count),
  GanttUnit.year => DateTime.utc(tick.year + step.count),
};

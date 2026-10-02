/// The Gantt-chart model (#530): its sections and their tasks, each placed
/// in time, and how the axis writes its dates.
///
/// Like the other models it carries no geometry: the dates are resolved —
/// `after`, `until`, durations and excluded days — and the layout turns
/// them into bars.
library;

/// One task, placed in time.
final class GanttTask {
  /// Creates a task.
  const new({
    required this.label,
    required this.start,
    required this.end,
    this.id,
    this.done = false,
    this.active = false,
    this.critical = false,
    this.milestone = false,
  });

  /// Its name, written on its bar.
  final String label;

  /// The id other tasks refer to it by, or null.
  final String? id;

  /// When it starts, in UTC.
  final DateTime start;

  /// When it ends, in UTC; a milestone's end is its start.
  final DateTime end;

  /// `done`: finished.
  final bool done;

  /// `active`: under way.
  final bool active;

  /// `crit`: on the critical path.
  final bool critical;

  /// `milestone`: a point in time, drawn as a diamond.
  final bool milestone;
}

/// One `section` and its tasks.
final class GanttSection {
  /// Creates a section.
  const new({required this.name, required this.tasks});

  /// Its name, written beside its rows; empty for the tasks before the
  /// first `section`.
  final String name;

  /// Its tasks, in the order they were written.
  final List<GanttTask> tasks;
}

/// A parsed Gantt chart.
final class GanttChart {
  /// Creates a Gantt chart.
  const new({required this.sections, this.title, this.axisFormat});

  /// The sections, in order.
  final List<GanttSection> sections;

  /// The title drawn above the chart, or null.
  final String? title;

  /// How the axis writes a date (strftime), or null for the default.
  final String? axisFormat;
}

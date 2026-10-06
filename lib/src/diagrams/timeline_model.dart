/// The timeline model (#530): its periods, each with its events, grouped
/// in sections.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// One period and what happened in it.
final class TimelinePeriod {
  /// Creates a period.
  const new({required this.label, required this.events});

  /// Its name: a year, a date, an era.
  final String label;

  /// Its events, in the order they were written.
  final List<String> events;
}

/// One `section` and its periods.
final class TimelineSection {
  /// Creates a section.
  const new({required this.periods, this.name});

  /// Its name, or null for the periods before the first `section`.
  final String? name;

  /// Its periods, in order.
  final List<TimelinePeriod> periods;
}

/// A parsed timeline.
final class TimelineChart {
  /// Creates a timeline.
  const new({required this.sections, this.title});

  /// The sections, in order.
  final List<TimelineSection> sections;

  /// The title drawn above it, or null.
  final String? title;
}

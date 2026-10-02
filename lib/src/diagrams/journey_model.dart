/// The user-journey model (#530): its actors, and its sections of tasks,
/// each with how it went and who took part.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// One task of a journey.
final class JourneyTask {
  /// Creates a task.
  const new({required this.label, required this.score, required this.actors});

  /// What was done.
  final String label;

  /// How it went, from 0 (badly) to 5 (well).
  final double score;

  /// Who took part, by their place in [JourneyChart.actors].
  final List<int> actors;
}

/// One `section` and its tasks.
final class JourneySection {
  /// Creates a section.
  const new({required this.tasks, this.name});

  /// Its name, or null for the tasks before the first `section`.
  final String? name;

  /// Its tasks, in order.
  final List<JourneyTask> tasks;
}

/// A parsed user journey.
final class JourneyChart {
  /// Creates a journey.
  const new({required this.sections, required this.actors, this.title});

  /// The sections, in order.
  final List<JourneySection> sections;

  /// Everyone who takes part, in the order they first appear.
  final List<String> actors;

  /// The title drawn above it, or null.
  final String? title;
}

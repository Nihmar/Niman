import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/grade.dart';

/// What a session came to.
@immutable
final class SessionSummary {
  /// A summary of a session.
  const new({
    required this.reviewed,
    required this.grades,
    required this.elapsed,
    required this.nextDue,
    required this.nextCount,
  });

  /// The cards graded, each once however many times it came back.
  final int reviewed;

  /// How many times each grade was given; [Grade.again] is the number of
  /// times a card was asked again.
  final Map<Grade, int> grades;

  /// From the start to the last grade, or to now while the session runs.
  final Duration elapsed;

  /// The next day, after today, on which the session's decks have a card
  /// due; null when none has.
  final DateTime? nextDue;

  /// How many cards of the session's decks are due on [nextDue].
  final int nextCount;

  /// The number of Again grades.
  int get again => grades[Grade.again] ?? 0;

  /// All the grades given.
  int get graded => grades.values.fold(0, (sum, count) => sum + count);
}

/// The scheduler (#533, `docs/records/flashcards.md`, "Scheduling"): SM-2
/// with four grades.
///
/// | Grade | q | Effect |
/// |---|---|---|
/// | Again | 1 | reps 0, interval 0, due today: the session asks it again |
/// | Hard | 3 | interval x 1.2, at least a day more (1 day at 0 reps) |
/// | Good | 4 | 1 day, then 6, then round(interval x ef), a day more at least |
/// | Easy | 5 | as Good, x 1.3, at least a day more than Good |
///
/// The ease moves by SM-2's formula for every grade, never under 1.3, and
/// the interval is computed from the ease the card had *before* the
/// review. All dates are calendar days: `today` is a date at midnight
/// (`studyToday`), and a due date is `today + interval` days on the
/// calendar.
library;

import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/flashcards/review_state.dart';

/// The state [state] — null for a card never reviewed — becomes when it is
/// graded [grade] on the day [today], at [now] (the moment, default the
/// current one).
ReviewState gradeCard(
  ReviewState? state,
  Grade grade,
  DateTime today, {
  DateTime? now,
}) {
  final ef = _easeAfter(state?.ef ?? ReviewState.startEase, grade);
  final reps = grade == Grade.again ? 0 : (state?.reps ?? 0) + 1;
  final interval = intervalAfter(state, grade);
  return ReviewState(
    ef: ef,
    interval: interval,
    reps: reps,
    due: DateTime(today.year, today.month, today.day + interval),
    at: (now ?? DateTime.now()).toUtc(),
    // The day of the first grade stays with the card for good.
    first: state == null
        ? DateTime(today.year, today.month, today.day)
        : state.first,
  );
}

/// The interval, in days, [state] would have after [grade]: what a grade
/// button shows. 0 for Again, which comes back in the session.
int intervalAfter(ReviewState? state, Grade grade) {
  final interval = state?.interval ?? 0;
  final reps = state?.reps ?? 0;
  final ef = state?.ef ?? ReviewState.startEase;
  final good = switch (reps) {
    0 => 1,
    1 => 6,
    _ => _atLeast(interval + 1, (interval * ef).round()),
  };
  return switch (grade) {
    Grade.again => 0,
    Grade.hard => _atLeast(interval + 1, (interval * 1.2).round()),
    Grade.good => good,
    Grade.easy => _atLeast(good + 1, (good * 1.3).round()),
  };
}

/// The interval of each grade for [state], for the four buttons.
Map<Grade, int> intervalPreviews(ReviewState? state) => {
  for (final grade in Grade.values) grade: intervalAfter(state, grade),
};

/// SM-2's ease after a review of quality q: `ef + (0.1 - (5-q) * (0.08 +
/// (5-q) * 0.02))`, kept at 1.3 or over.
double _easeAfter(double ef, Grade grade) {
  final miss = 5 - grade.quality;
  final next = ef + (0.1 - miss * (0.08 + miss * 0.02));
  return next < ReviewState.minEase ? ReviewState.minEase : next;
}

int _atLeast(int least, int value) => value < least ? least : value;

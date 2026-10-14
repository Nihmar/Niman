import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/ui/strings.dart';

/// When a card comes back, in words: **Due** for a card whose day has come,
/// **New** for one never reviewed, otherwise how far away it is.
String nextLabel(ReviewState? state, DateTime today) {
  if (state == null) return AppStrings.flashcardsNew;
  final days = state.daysUntilDue(today);
  return days <= 0 ? AppStrings.flashcardsDue : daysLabel(days);
}

/// [days] from today, more than none: `in 3 days`, `in 2 months`.
String daysLabel(int days) {
  if (days < 30) return AppStrings.flashcardsInDays(days);
  if (days < 365) return AppStrings.flashcardsInMonths((days / 30).round());
  return AppStrings.flashcardsInYears((days / 365).round());
}

/// When a grade brings a card back, [days] from today: **today** for
/// Again, **tomorrow**, then [daysLabel].
String comesBackLabel(int days) => switch (days) {
  <= 0 => AppStrings.flashcardsToday,
  1 => AppStrings.flashcardsTomorrow,
  _ => daysLabel(days),
};

/// A grade's name, as its button reads.
String gradeName(Grade grade) => switch (grade) {
  Grade.again => AppStrings.flashcardsGradeAgain,
  Grade.hard => AppStrings.flashcardsGradeHard,
  Grade.good => AppStrings.flashcardsGradeGood,
  Grade.easy => AppStrings.flashcardsGradeEasy,
};

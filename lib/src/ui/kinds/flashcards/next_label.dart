import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/ui/strings.dart';

/// When a card comes back, in words: **Due** for a card whose day has come,
/// **New** for one never reviewed, otherwise how far away it is.
String nextLabel(ReviewState? state, DateTime today) {
  if (state == null) return AppStrings.flashcardsNew;
  final days = state.daysUntilDue(today);
  if (days <= 0) return AppStrings.flashcardsDue;
  if (days < 30) return AppStrings.flashcardsInDays(days);
  if (days < 365) return AppStrings.flashcardsInMonths((days / 30).round());
  return AppStrings.flashcardsInYears((days / 365).round());
}

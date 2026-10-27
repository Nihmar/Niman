/// A recurrence rule in the words of the app language (#1189).
///
/// The rule itself is language-free (`RecurrenceDescription`); the words
/// come from the strings, one sentence shape per language, so this works for
/// a task's `rec:` today and for a calendar event's later.
library;

import 'package:niman/src/core/recurrence/recurrence_description.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';
import 'package:niman/src/ui/strings.dart';

/// [description] in words: "every day", "every weekday", "every 2 weeks",
/// "every week on Mon, Wed", "every month on the 2nd Tuesday".
///
/// With [fromDue], a rule counted from the due date (strict) says so:
/// "every week from the due date". The list rows leave it out to stay short.
String recurrenceWords(
  RecurrenceDescription description, {
  bool fromDue = false,
}) {
  final n = description.interval;
  var words = switch (description.unit) {
    RecurrenceUnit.day => AppStrings.recurDays(n),
    RecurrenceUnit.week => AppStrings.recurWeeks(n),
    RecurrenceUnit.month => AppStrings.recurMonths(n),
    RecurrenceUnit.year => AppStrings.recurYears(n),
    RecurrenceUnit.businessDay => AppStrings.recurBusinessDays(n),
  };
  if (description.weekdays.isNotEmpty) {
    final names = AppStrings.weekdayNamesShort;
    words = AppStrings.recurOnWeekdays(
      words,
      [for (final weekday in description.weekdays) names[weekday - 1]]
          .join(', '),
    );
  }
  final nth = description.nthWeekday;
  if (nth != null) {
    words = AppStrings.recurNthWeekday(words, nth.nth, nth.weekday);
  }
  if (fromDue && description.strict) {
    words = AppStrings.recurFromDue(words);
  }
  return words;
}

/// [words] with its first letter in capitals, for a menu entry or a label:
/// "Every week on Mon". A script without letter case is left as it is.
String sentenceCase(String words) {
  if (words.isEmpty) return words;
  final first = String.fromCharCode(words.runes.first);
  return first.toUpperCase() + words.substring(first.length);
}

/// Which day a review counts for (#533).
library;

import 'package:niman/src/journal/journal_settings.dart';

/// The study day at [now], as a date at midnight: the journal's day, so a
/// review at 1 a.m. with **A new day starts at** 4 still counts for the day
/// before, as a journal entry does (`JournalSettings.today`).
DateTime studyToday(DateTime now, int dayStartHour) =>
    JournalSettings(dayStartHour: dayStartHour).today(now);

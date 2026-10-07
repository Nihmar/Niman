/// The Material localizations every calendar reads, starting the week on
/// the day [AppWeekStart] says (#566) rather than on the app language's.
///
/// `MaterialLocalizations.firstDayOfWeekIndex` is what the journal's month,
/// the todo date panel and the date picker dialog all lay their grid out
/// by, and Flutter reads it off the date symbols of the app's language — an
/// English interface starts the week on Sunday on a system set to Italy.
/// These are Flutter's own localizations for the language, every text
/// theirs, with the one date format that carries the first day built on a
/// copy of the language's symbols whose first day is the one in force.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_custom.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/date_time_patterns.dart';
import 'package:intl/intl.dart' as intl;
import 'package:niman/src/core/week_start.dart';

/// Loads Flutter's Material localizations with the week starting on
/// [firstDayIndex] (0 for Sunday, as Material counts).
final class WeekStartMaterialLocalizations
    extends LocalizationsDelegate<MaterialLocalizations> {
  /// The delegate for [firstDayIndex].
  const new(this.firstDayIndex);

  /// The delegate for the first day in force.
  factory current() =>
      WeekStartMaterialLocalizations(AppWeekStart.firstDayIndex);

  /// The first day, 0 for Sunday.
  final int firstDayIndex;

  static final Map<(Locale, int), MaterialLocalizations> _loaded =
      <(Locale, int), MaterialLocalizations>{};

  @override
  bool isSupported(Locale locale) =>
      GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final cached = _loaded[(locale, firstDayIndex)];
    if (cached != null) return SynchronousFuture(cached);
    // Flutter's own first: it loads the date data every format below reads.
    return GlobalMaterialLocalizations.delegate.load(locale).then((base) {
      if (base.firstDayOfWeekIndex == firstDayIndex) {
        return _loaded[(locale, firstDayIndex)] = base;
      }
      final name = _dateLocale(locale);
      return _loaded[(locale, firstDayIndex)] = getMaterialTranslation(
        locale,
        intl.DateFormat.y(name),
        intl.DateFormat.yMd(name),
        intl.DateFormat.yMMMd(name),
        intl.DateFormat.MMMEd(name),
        _longDate(name),
        intl.DateFormat.yMMMM(name),
        intl.DateFormat.MMMd(name),
        intl.NumberFormat.decimalPattern(name),
        intl.NumberFormat('00', name),
      )!;
    });
  }

  @override
  bool shouldReload(WeekStartMaterialLocalizations old) =>
      old.firstDayIndex != firstDayIndex;

  /// The locale the date formats are read in: [locale]'s, its language's,
  /// or the default one — as Flutter's own delegate falls back.
  static String? _dateLocale(Locale locale) {
    final full = intl.Intl.canonicalizedLocale(locale.toString());
    if (intl.DateFormat.localeExists(full)) return full;
    if (intl.DateFormat.localeExists(locale.languageCode)) {
      return locale.languageCode;
    }
    return null;
  }

  /// The long date of [name] — the format the first day is read from — in
  /// a locale of its own: [name]'s symbols with the first day changed, so
  /// it writes every date as [name] does.
  intl.DateFormat _longDate(String? name) {
    final real = intl.DateFormat.yMMMMEEEEd(name);
    final base = name ?? intl.Intl.getCurrentLocale();
    final week = '${base.replaceAll('_', '')}_WEEK$firstDayIndex';
    if (!intl.DateFormat.localeExists(week)) {
      final symbols = Map<dynamic, dynamic>.of(
        real.dateSymbols.serializeToMap(),
      );
      symbols['NAME'] = week;
      // intl counts from Monday as 0.
      symbols['FIRSTDAYOFWEEK'] = (firstDayIndex + 6) % 7;
      initializeDateFormattingCustom(
        locale: week,
        symbols: DateSymbols.deserializeFromMap(symbols),
        patterns: dateTimePatternMap()[base.split('_').first],
      );
    }
    return intl.DateFormat(real.pattern, week);
  }
}

// The first day of the week the calendars start on (#566): the system's by
// default — the region it is set to, not the language the app speaks — or
// the one the library sets.
//
// A small global for the reason `core/text_scale.dart` is one: the app root
// reads it to hand every calendar its localizations, above any provider.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Which day a library's calendars start the week on.
enum WeekStart {
  /// The system's: its region's first day.
  system,

  /// Monday.
  monday,

  /// Saturday.
  saturday,

  /// Sunday.
  sunday;

  /// The choice stored as [raw], the system's for anything else.
  static WeekStart fromName(Object? raw) => WeekStart.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => WeekStart.system,
  );
}

/// The first day in force: the open library's choice, the system's while
/// none is open or it chose none.
final class AppWeekStart {
  const new _();

  /// Bumped whenever the first day may have changed; the app root listens
  /// and hands the calendars their localizations again.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static WeekStart _choice = WeekStart.system;
  static int? _system;

  /// The open library's choice.
  static WeekStart get choice => _choice;

  static set choice(WeekStart value) {
    if (_choice == value) return;
    _choice = value;
    revision.value++;
  }

  /// The first day as Material counts it — 0 for Sunday, 1 for Monday, 6
  /// for Saturday — which every calendar reads.
  static int get firstDayIndex => switch (_choice) {
    WeekStart.system => _system ??= systemFirstDayIndex(),
    WeekStart.monday => 1,
    WeekStart.saturday => 6,
    WeekStart.sunday => 0,
  };

  /// The system's locales changed: its first day is read again.
  static void systemChanged() {
    _system = null;
    if (_choice == WeekStart.system) revision.value++;
  }
}

/// The system's first day of the week, as Material counts it (0 for
/// Sunday): the one CLDR gives its region.
///
/// The region is the time locale's — on Linux `LC_ALL`, then `LC_TIME`,
/// then `LANG`, which a desktop sets apart from the language — and the
/// platform's locale elsewhere. A locale with no region answers its
/// language's day; one unknown altogether, Monday, as ISO 8601 has it.
int systemFirstDayIndex({String? timeLocale, String? platformLocale}) {
  final names = [
    timeLocale ?? (Platform.isLinux ? _linuxTimeLocale() : null),
    platformLocale ?? PlatformDispatcher.instance.locale.toString(),
  ];
  final symbols = dateTimeSymbolMap();
  for (final name in names) {
    if (name == null) continue;
    final clean = name.split('.').first.split('@').first.replaceAll('-', '_');
    if (clean.isEmpty || clean == 'C' || clean == 'POSIX') continue;
    final language = clean.split('_').first.toLowerCase();
    final found = symbols[Intl.canonicalizedLocale(clean)] ?? symbols[language];
    if (found != null) return (found.FIRSTDAYOFWEEK + 1) % 7;
  }
  return 1;
}

/// The name of the weekday Material counts as [materialIndex] (0 for
/// Sunday) in [language], standing alone, capitalized as a label is —
/// English's when the language has no symbols.
String weekdayName(int materialIndex, String language) {
  final symbols = dateTimeSymbolMap();
  final found = symbols[language] ?? symbols['en']!;
  final name = found.STANDALONEWEEKDAYS[materialIndex % 7];
  return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}

/// The locale a Linux session formats dates in, or null when it names none.
String? _linuxTimeLocale() {
  final environment = Platform.environment;
  for (final key in ['LC_ALL', 'LC_TIME', 'LANG']) {
    final value = environment[key];
    if (value == null || value.isEmpty) continue;
    // The C locale is no region: the next variable, or the platform's.
    if (value.startsWith('C.') || value == 'C' || value == 'POSIX') continue;
    return value;
  }
  return null;
}

// #566: the calendars start the week on the system's first day — its
// region's, not the app language's — or on the one the library sets.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/week_start.dart';
import 'package:niman/src/ui/week_start_localizations.dart';

void main() {
  tearDown(() => AppWeekStart.choice = WeekStart.system);

  test("the system's first day is its region's", () {
    int first(String time) =>
        systemFirstDayIndex(timeLocale: time, platformLocale: 'en_US');
    expect(first('it_IT.UTF-8'), 1, reason: 'Monday');
    expect(first('en_GB.UTF-8@euro'), 1);
    expect(first('en_US'), 0, reason: 'Sunday');
    expect(first('en-US'), 0);
    expect(first('ar_EG'), 6, reason: 'Saturday');
    // A locale with no region answers its language's day.
    expect(first('de'), 1);
    // The C locale names no region: the platform's is read.
    expect(first('C.UTF-8'), 0);
    expect(systemFirstDayIndex(timeLocale: 'xx_YY', platformLocale: 'zz'), 1);
  });

  test('a library keeps its choice, the system for anything else', () {
    final fresh = LibraryConfig.fromJsonMap(const <String, Object?>{});
    expect(fresh.weekStart, WeekStart.system);
    final saved = fresh.copyWith(weekStart: WeekStart.saturday).toJsonMap();
    expect(saved['weekStart'], 'saturday');
    expect(LibraryConfig.fromJsonMap(saved).weekStart, WeekStart.saturday);
    expect(
      LibraryConfig.fromJsonMap(const {'weekStart': 'someday'}).weekStart,
      WeekStart.system,
    );
  });

  test('a weekday is named in the language, as a label', () {
    expect(weekdayName(1, 'en'), 'Monday');
    expect(weekdayName(0, 'it'), 'Domenica');
    expect(weekdayName(6, 'xx'), 'Saturday');
  });

  test('a chosen day is the one in force', () {
    AppWeekStart.choice = WeekStart.sunday;
    expect(AppWeekStart.firstDayIndex, 0);
    AppWeekStart.choice = WeekStart.saturday;
    expect(AppWeekStart.firstDayIndex, 6);
    AppWeekStart.choice = WeekStart.monday;
    expect(AppWeekStart.firstDayIndex, 1);
  });

  test("Flutter's own texts, the week starting on the day asked", () async {
    for (final day in [0, 1, 6]) {
      final words = await WeekStartMaterialLocalizations(day)
          .load(const Locale('en'));
      expect(words.firstDayOfWeekIndex, day);
      expect(words.cancelButtonLabel, 'Cancel');
      expect(words.formatFullDate(DateTime(2026, 10, 7)), contains('October'));
    }
  });

  testWidgets('an English calendar starts on Monday when asked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [WeekStartMaterialLocalizations(1)],
        home: Scaffold(
          body: CalendarDatePicker(
            initialDate: DateTime(2026, 10, 7),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            onDateChanged: (_) {},
          ),
        ),
      ),
    );
    final monday = tester.getCenter(find.text('M')).dx;
    for (final element in find.text('S').evaluate()) {
      expect(
        monday,
        lessThan(tester.getCenter(find.byWidget(element.widget)).dx),
      );
    }
    // October 2026 starts on a Thursday: three empty cells before the 1st.
    expect(
      tester.getCenter(find.text('1')).dx,
      greaterThan(tester.getCenter(find.text('M')).dx),
    );
  });
}

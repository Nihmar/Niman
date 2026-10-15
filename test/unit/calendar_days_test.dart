import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/calendar_days.dart';

void main() {
  group('addCalendarDays', () {
    test('lands on midnight of the date days later, not 24 h later', () {
      // Europe's clocks fall back on 2026-10-25: from the midnight before,
      // `Duration(days: 1)` reaches 23:00 of the 25th on such a machine.
      final tomorrow = addCalendarDays(DateTime(2026, 10, 25), 1);
      expect(tomorrow, DateTime(2026, 10, 26));
      expect(tomorrow.hour, 0);
      expect(tomorrow.minute, 0);
    });

    test('a week from the Tuesday before the change is the Tuesday after', () {
      final week = addCalendarDays(DateTime(2026, 10, 20), 7);
      expect((week.year, week.month, week.day), (2026, 10, 27));
      expect(week.hour, 0);
    });

    test('keeps midnight across the spring-forward day too', () {
      final next = addCalendarDays(DateTime(2026, 3, 28), 1);
      expect((next.month, next.day, next.hour), (3, 29, 0));
      final after = addCalendarDays(DateTime(2026, 3, 29), 1);
      expect((after.month, after.day, after.hour), (3, 30, 0));
    });

    test('rolls over month and year ends, and counts backwards', () {
      expect(addCalendarDays(DateTime(2026, 12, 30), 7), DateTime(2027, 1, 6));
      expect(addCalendarDays(DateTime(2026, 3), -1), DateTime(2026, 2, 28));
      expect(addCalendarDays(DateTime(2028, 2, 28), 1), DateTime(2028, 2, 29));
    });

    test('drops the time of day', () {
      expect(
        addCalendarDays(DateTime(2026, 10, 24, 17, 30), 1),
        DateTime(2026, 10, 25),
      );
    });

    test('zero days is the same date', () {
      expect(
        addCalendarDays(DateTime(2026, 10, 25), 0),
        DateTime(2026, 10, 25),
      );
    });
  });
}

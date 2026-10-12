// #730 phase 3: an event's time as the journal shows it — as written, or
// as a clock, a `Z` time in the device's own zone.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/time_display.dart';

CalendarEventTime _time(String raw) =>
    parseCalendarLine('2026-10-12 w42 Mon  $raw meeting.').events.single.time!;

void main() {
  final day = DateTime(2026, 10, 12);

  test('as written is exactly what the line says', () {
    for (final raw in ['9-12', '13:30-14', '0600Z', '8', '0815']) {
      expect(calendarTimeText(_time(raw), asClock: false), raw);
    }
    expect(calendarTimeText(null, asClock: false), '');
  });

  test('a clock is zero-padded, with an en dash for a range', () {
    expect(
      calendarTimeText(_time('9-12'), asClock: true, day: day),
      '09:00–12:00',
    );
    expect(
      calendarTimeText(_time('13:30-14'), asClock: true, day: day),
      '13:30–14:00',
    );
    expect(calendarTimeText(_time('8'), asClock: true, day: day), '08:00');
    expect(calendarTimeText(_time('0815'), asClock: true, day: day), '08:15');
  });

  test('a range with only an end keeps its shape', () {
    expect(
      calendarTimeText(_time('-12:00'), asClock: true, day: day),
      '–12:00',
    );
    expect(calendarTimeText(_time('-12:00'), asClock: false), '-12:00');
  });

  test("a Z time is the device zone's clock", () {
    final utc = DateTime.utc(2026, 10, 12, 6).toLocal();
    expect(
      calendarTimeText(_time('0600Z'), asClock: true, day: day),
      '${utc.hour.toString().padLeft(2, '0')}:'
      '${utc.minute.toString().padLeft(2, '0')}',
    );
  });

  test('a Z time past midnight lands on the clock it is there', () {
    final utc = DateTime.utc(2026, 10, 12, 23).toLocal();
    expect(
      calendarTimeText(_time('2300Z'), asClock: true, day: day),
      '${utc.hour.toString().padLeft(2, '0')}:'
      '${utc.minute.toString().padLeft(2, '0')}',
    );
    // The line's day, not the clock's: the event is where it was written.
    expect(calendarTimeText(_time('2300Z'), asClock: false), '2300Z');
  });
}

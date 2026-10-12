// #730 phase 3: merging calendar.txt — the day line two devices each added
// an event to, a line removed on one side, a goal edited on both, and the
// endings each line keeps.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diff/calendar_merge.dart';

void main() {
  const first = '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis.';
  const second = '2026-10-13 w42 Tue  10-11 seminar +thesis.';

  test('two devices add an event to the same day: both are in, in time', () {
    const base = '$first\n$second\n';
    const local =
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. '
        '15-16 meeting with Luca +thesis.\n$second\n';
    const remote =
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. '
        '18-19 jogging @park.\n$second\n';

    final merged = mergeCalendar(base, local, remote);
    expect(
      merged,
      '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. '
      '15-16 meeting with Luca +thesis. 18-19 jogging @park.\n'
      '$second\n',
    );
  });

  test('with no base, the union is one line per day, in time order', () {
    const local = '2026-10-12 w42 Mon  15-16 meeting with Luca.\n';
    const remote = '2026-10-12 w42 Mon  9-12 thesis.\n';
    expect(
      mergeCalendar('', local, remote),
      '2026-10-12 w42 Mon  9-12 thesis. 15-16 meeting with Luca.\n',
      reason: 'the local head, the two events in time order',
    );
  });

  test('the same event added on both sides is in once', () {
    const base = '$first\n';
    const local =
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. '
        '15-16 meeting.\n';
    const remote =
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. '
        '15-16 meeting.\n';
    expect(mergeCalendar(base, local, remote), local);
  });

  test('an event removed on either side is out', () {
    const base = '2026-10-12 w42 Mon  9-12 thesis. 15-16 meeting.\n';
    // Removed here, added there: the removal wins, the addition stands.
    const local = '2026-10-12 w42 Mon  9-12 thesis. 18-19 jogging.\n';
    const remote = '2026-10-12 w42 Mon  9-12 thesis. 15-16 meeting.\n';
    expect(
      mergeCalendar(base, local, remote),
      '2026-10-12 w42 Mon  9-12 thesis. 18-19 jogging.\n',
    );
  });

  test('a day line removed on one side is out', () {
    const base = '$first\n$second\n';
    const local = '$first\n';
    const remote = '$first\n$second\n';
    expect(mergeCalendar(base, local, remote), '$first\n');

    // The other way round: the side that still has it does not put it back.
    expect(mergeCalendar(base, '$first\n$second\n', '$first\n'), '$first\n');
  });

  test('a day added on one side is in', () {
    const base = '$first\n';
    const local = '$first\n';
    const remote = '$first\n$second\n';
    expect(mergeCalendar(base, local, remote), '$first\n$second\n');
    expect(mergeCalendar(base, remote, local), '$first\n$second\n');
  });

  test('a day line untouched here comes back byte for byte', () {
    const base = '$first\r\n$second\r\n';
    const local = '$first\r\n$second\r\n';
    const remote = '$first\r\n$second\r\n';
    expect(mergeCalendar(base, local, remote), base);
  });

  test("every line keeps its own ending, a rebuilt one the local side's", () {
    // Both devices added an event to the first day, so the merged line is
    // rebuilt — and it keeps this side's ending (CRLF). The second day is
    // untouched by the merge and keeps its own (CRLF here, LF there: each
    // line its own).
    const base = '$first\r\n$second\r\n';
    const local =
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. 15-16 meeting.\r\n'
        '$second\r\n';
    const remote =
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. 18-19 jogging.\n'
        '$second\n';
    final merged = mergeCalendar(base, local, remote);
    expect(
      merged,
      '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. 15-16 meeting. '
      '18-19 jogging.\r\n'
      '$second\r\n',
    );
  });

  test("the local side's head is the one kept", () {
    const base = '$first\n';
    // Both sides added an event to the same day, and the other device
    // writes the head without the week number: the merge takes this
    // side's head.
    const local =
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. '
        '15-16 meeting.\n';
    const remote =
        '2026-10-12 Mon  9-12 thesis chapter 3 +thesis. '
        '18-19 jogging.\n';
    expect(
      mergeCalendar(base, local, remote),
      '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. 15-16 meeting. '
      '18-19 jogging.\n',
    );
  });

  test('two lines for one day become one', () {
    const local =
        '2026-10-12 w42 Mon  9-12 thesis.\n'
        '2026-10-12 w42 Mon  15-16 meeting.\n';
    const remote = '2026-10-12 w42 Mon  9-12 thesis.\n';
    expect(
      mergeCalendar('', local, remote),
      '2026-10-12 w42 Mon  9-12 thesis. 15-16 meeting.\n',
    );
  });

  test('a goal is prose, not a set: both edits come out as records', () {
    const base = '2026  The year of the move +home\n';
    // Each side edited the same goal differently: the record rule keeps
    // both lines, so neither edit is thrown away.
    const local = '2026  The year of the move +home, at last\n';
    const remote = '2026  The year of the big move +home\n';
    expect(
      mergeCalendar(base, local, remote),
      '2026  The year of the move +home, at last\n'
      '2026  The year of the big move +home\n',
    );
  });

  test('a goal added on one side, and the comments around it', () {
    const base = '# the year\n2026  The year of the move +home\n';
    const local = '# the year\n2026  The year of the move +home\n';
    const remote =
        '# the year\n2026  The year of the move +home\n'
        '2026-10  Finish the thesis draft +thesis\n';
    expect(
      mergeCalendar(base, local, remote),
      '# the year\n2026  The year of the move +home\n'
      '2026-10  Finish the thesis draft +thesis\n',
    );
  });

  test('a day keeps the events both sides still have, and no others', () {
    // This side added one and the other side removed one: the removal
    // wins for what is gone from the base, the addition stands.
    const base = '2026-10-12 w42 Mon  9-12 thesis. 15-16 meeting.\n';
    const local =
        '2026-10-12 w42 Mon  9-12 thesis. 15-16 meeting. '
        '18-19 jogging.\n';
    const remote = '2026-10-12 w42 Mon  9-12 thesis.\n';
    expect(
      mergeCalendar(base, local, remote),
      '2026-10-12 w42 Mon  9-12 thesis. 18-19 jogging.\n',
      reason: 'the meeting went, the jogging came',
    );

    // The other side emptied the day while this one kept the event and
    // added another: the removal wins for what the base held, the
    // addition stands — nothing the base had comes back.
    expect(
      mergeCalendar(
        '2026-10-12 w42 Mon  9-12 thesis.\n',
        '2026-10-12 w42 Mon  9-12 thesis. 15-16 meeting.\n',
        '2026-10-12 w42 Mon\n',
      ),
      '2026-10-12 w42 Mon  15-16 meeting.\n',
    );
  });

  test('what the parser cannot read follows the record rule', () {
    const base = 'just a note to myself\n2026-10-12 w42 Mon  9-12 thesis.\n';
    const local = 'just a note to myself\n2026-10-12 w42 Mon  9-12 thesis.\n';
    const remote =
        'another note entirely\n'
        '2026-10-12 w42 Mon  9-12 thesis.\n';
    expect(
      mergeCalendar(base, local, remote),
      'another note entirely\n2026-10-12 w42 Mon  9-12 thesis.\n',
      reason: 'the base line is gone from the server, the new one is in',
    );
  });

  test('a day key is the date, whatever the head writes', () {
    expect(calendarDayKey('2026-10-12 w42 Mon  9-12 a.'), '2026-10-12');
    expect(calendarDayKey('2026-10-12 Mon  9-12 a.'), '2026-10-12');
    expect(calendarDayKey('2026-10-12 w41 Mon  9-12 a.'), '2026-10-12');
    expect(calendarDayKey('2026  The year +home'), isNull);
    expect(calendarDayKey('2026-10  The month +thesis'), isNull);
    expect(calendarDayKey('# a comment'), isNull);
  });
}

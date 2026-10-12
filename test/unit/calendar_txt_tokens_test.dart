// #730 phase 1: the editor's runs over a calendar.txt line — the date, the
// week and weekday of a head, the event times, the asides, the tokens and
// the `rem:`, and the wavy flag a head that does not match its date wears.
// Every line's runs are disjoint and in order, which the painter requires.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_txt_tokens.dart';
import 'package:niman/src/editor/highlighting.dart';

void main() {
  /// The run covering the first occurrence of [text] in [line].
  Token tokenFor(String line, String text) {
    final at = line.indexOf(text);
    expect(at, isNot(-1), reason: '"$text" is in the line');
    return calendarTxtTokens(
      line,
    ).firstWhere((token) => token.start == at && token.end == at + text.length);
  }

  /// The kind of the run covering the first occurrence of [text].
  TokenKind kindOf(String line, String text) => tokenFor(line, text).kind;

  /// Every line's runs are disjoint and sorted, whatever the line holds.
  void expectRunsDisjoint(List<String> lines) {
    for (final line in lines) {
      final tokens = calendarTxtTokens(line);
      for (var at = 1; at < tokens.length; at++) {
        expect(
          tokens[at].start,
          greaterThanOrEqualTo(tokens[at - 1].end),
          reason: 'disjoint and in order: "$line"',
        );
      }
      for (final token in tokens) {
        expect(token.start, greaterThanOrEqualTo(0));
        expect(
          token.end,
          lessThanOrEqualTo(line.length),
          reason: 'inside the line: "$line"',
        );
      }
    }
  }

  test('the file is the calendar, by name', () {
    expect(isCalendarTxtFile('calendar.txt'), isTrue);
    expect(isCalendarTxtFile('CALENDAR.TXT'), isTrue);
    expect(isCalendarTxtFile('Calendar.txt'), isTrue);
    expect(isCalendarTxtFile('todo.txt'), isFalse);
    expect(isCalendarTxtFile('calendar.txt.md'), isFalse);
  });

  test('a day head: the date, then the week and the weekday', () {
    const line = '2026-10-12 w42 Mon  9-12 library.';
    expect(kindOf(line, '2026-10-12'), TokenKind.calendarDate);
    expect(kindOf(line, 'w42'), TokenKind.calendarHead);
    expect(kindOf(line, 'Mon'), TokenKind.calendarHead);
    expect(kindOf(line, '9-12'), TokenKind.calendarTime);
  });

  test('a week number or a weekday that does not match is flagged', () {
    // The editor mockup's two flagged lines (#730).
    const week = '2026-10-15 w41 Thu  8-1345 exam session +teaching.';
    expect(kindOf(week, 'w41'), TokenKind.calendarMismatch);
    expect(kindOf(week, 'Thu'), TokenKind.calendarHead);

    const weekday = '2026-10-09 w41 Sat  20 dinner at Anna.';
    expect(kindOf(weekday, 'w41'), TokenKind.calendarHead);
    expect(kindOf(weekday, 'Sat'), TokenKind.calendarMismatch);
  });

  test("an event's tokens are a task list's roles", () {
    const line =
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis @library #uni '
        'rem:8:45.';
    expect(kindOf(line, '+thesis'), TokenKind.todoProject);
    expect(kindOf(line, '@library'), TokenKind.todoContext);
    expect(kindOf(line, '#uni'), TokenKind.tag);
    expect(kindOf(line, 'rem:8:45'), TokenKind.todoKeyValue);
  });

  test('a time range is one run, the whole of it', () {
    const line = '2026-10-12 w42 Mon  13:30-14 call with Marta @phone.';
    final time = tokenFor(line, '13:30-14');
    expect(time.kind, TokenKind.calendarTime);
    expect(line.substring(time.start, time.end), '13:30-14');
  });

  test('an aside is dimmed, and read for no tokens', () {
    const line = '2026-10-12 w42 Mon  8-1345 exam (14-1545 +teaching).';
    expect(kindOf(line, '(14-1545 +teaching)'), TokenKind.calendarAside);
    expect(
      calendarTxtTokens(line).where((t) => t.kind == TokenKind.todoProject),
      isEmpty,
      reason: 'inside the aside',
    );
  });

  test('a goal head: the period, the week, and the text after it', () {
    const week = '2026-10-12 w42  Writing week +thesis';
    expect(kindOf(week, '2026-10-12'), TokenKind.calendarDate);
    expect(kindOf(week, 'w42'), TokenKind.calendarHead);
    expect(kindOf(week, '+thesis'), TokenKind.todoProject);

    const month = '2026-10  Finish the thesis draft';
    expect(kindOf(month, '2026-10'), TokenKind.calendarDate);

    const year = '2026  The year of the move +home';
    expect(kindOf(year, '2026'), TokenKind.calendarDate);
    expect(kindOf(year, '+home'), TokenKind.todoProject);
  });

  test('a flagged week on a goal is flagged too', () {
    const line = '2026-10-12 w41  Writing week';
    expect(kindOf(line, 'w41'), TokenKind.calendarMismatch);
  });

  test('the text around the runs is plain, and a line Niman cannot read '
      'has none', () {
    const line = '2026-10-12 w42 Mon  9-12 library.';
    final tokens = calendarTxtTokens(line);
    expect(tokens.first.start, 0);
    expect(
      tokens.every((t) => t.kind != TokenKind.plain),
      isTrue,
      reason: 'plain is the absence of a run, never one',
    );
    expect(calendarTxtTokens('just a note to myself'), isEmpty);
    expect(calendarTxtTokens(''), isEmpty);
  });

  test('every line keeps its runs disjoint and in order', () {
    // Two events, a reminder, an aside and a tag, on one line.
    const busy =
        '2026-10-12 w42 Mon  13:30-14 call with Marta @phone rem:13:15. '
        '18-19 jogging @park (if dry). #family';
    expectRunsDisjoint(const [
      '2026  The year of the move +home',
      '2026-10  Finish the thesis draft +thesis',
      '2026-10-05 w41  Reading week',
      '2026-10-05 w41 Mon  9-12 library +thesis @library.',
      '2026-10-06 w41 Tue',
      busy,
      '2026-10-15 w41 Thu  8-1345 exam session +teaching (14-1545).',
      '2026-10-20 w43 Tue  9 supervisor +thesis @uni.',
      'no date at all, just words',
      '   ',
      '2026-10-051x',
      '2026-10-12 w42 Mo  9-12 call.',
    ]);
  });
}

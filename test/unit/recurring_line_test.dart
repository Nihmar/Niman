// #1189: the next copy a recurring task leaves when it is completed.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/recurring_line.dart';

void main() {
  final today = DateTime(2026, 10, 26, 14, 30);

  group('recurrenceRuleOf', () {
    test('reads the first rec: tag', () {
      expect(
        recurrenceRuleOf(parseTodoLine('water plants rec:+1w due:2026-10-20')),
        RecurrenceRule.parse('+1w'),
      );
    });

    test('is null with no rec: or an unreadable one', () {
      expect(recurrenceRuleOf(parseTodoLine('water plants')), isNull);
      expect(recurrenceRuleOf(parseTodoLine('water plants rec:often')), isNull);
      expect(recurrenceRuleOf(parseTodoLine('rec:0d')), isNull);
    });
  });

  group('nextRecurringLine', () {
    test('counts from the completion day and moves due: in place', () {
      expect(
        nextRecurringLine('water plants rec:1w due:2026-10-20 +home', today),
        'water plants rec:1w due:2026-11-02 +home',
      );
    });

    test('a strict rule counts from the due date', () {
      expect(
        nextRecurringLine('pay rent rec:+1m due:2026-10-01', today),
        'pay rent rec:+1m due:2026-11-01',
      );
    });

    test('a strict rule does not catch up: one step from a late due date', () {
      expect(
        nextRecurringLine('stretch rec:+1d due:2026-10-01', today),
        'stretch rec:+1d due:2026-10-02',
      );
    });

    test('a task with no due: gains one, from the completion day', () {
      expect(
        nextRecurringLine('water plants rec:+2d', today),
        'water plants rec:+2d due:2026-10-28',
      );
    });

    test('t: and rem: move by the days due: moved; rem: keeps its time', () {
      expect(
        nextRecurringLine(
          'standup rec:1d due:2026-10-20 t:2026-10-18 rem:2026-10-20T09:15',
          today,
        ),
        'standup rec:1d due:2026-10-27 t:2026-10-25 rem:2026-10-27T09:15',
      );
    });

    test('without a due:, rem: moves from the completion day', () {
      expect(
        nextRecurringLine('call rec:1w rem:2026-10-26T08:00', today),
        'call rec:1w rem:2026-11-02T08:00 due:2026-11-02',
      );
    });

    test('a month end clamps', () {
      expect(
        nextRecurringLine('report rec:+1m due:2026-01-31', DateTime(2026, 2)),
        'report rec:+1m due:2026-02-28',
      );
    });

    test('the extended forms step like the rule says', () {
      // 2026-10-26 is a Monday.
      expect(
        nextRecurringLine('gym rec:1w;mo,we,fr due:2026-10-26', today),
        'gym rec:1w;mo,we,fr due:2026-10-28',
      );
      expect(
        nextRecurringLine('meeting rec:1m;2tu due:2026-10-13', today),
        'meeting rec:1m;2tu due:2026-11-10',
      );
    });

    test('priority and other tags stay; the creation date becomes today', () {
      expect(
        nextRecurringLine(
          '(B) 2026-01-02 file taxes +money @desk rec:1y due:2026-04-15 k:v',
          today,
        ),
        '(B) 2026-10-26 file taxes +money @desk rec:1y due:2027-10-26 k:v',
      );
    });

    test('a line with no creation date gets none', () {
      expect(
        nextRecurringLine('(B) walk rec:1d', today),
        '(B) walk rec:1d due:2026-10-27',
      );
    });

    test('tags inside a wikilink are not touched', () {
      expect(
        nextRecurringLine(
          '[[Plan due:2026-10-20]] rec:1w due:2026-10-20',
          today,
        ),
        '[[Plan due:2026-10-20]] rec:1w due:2026-11-02',
      );
    });

    test('spacing inside the description is kept', () {
      expect(
        nextRecurringLine('a  b   rec:1d  due:2026-10-20', today),
        'a  b   rec:1d  due:2026-10-27',
      );
    });

    test('no copy for a line that does not repeat', () {
      expect(nextRecurringLine('plain task', today), isNull);
      expect(nextRecurringLine('odd rec:sometimes', today), isNull);
      expect(nextRecurringLine('x 2026-10-01 done rec:1d', today), isNull);
    });

    test('is a pure function of the line and the day', () {
      const line = '(A) 2026-01-01 water rec:1w due:2026-10-20';
      expect(
        nextRecurringLine(line, DateTime(2026, 10, 26, 8)),
        nextRecurringLine(line, DateTime(2026, 10, 26, 22)),
      );
    });
  });
}

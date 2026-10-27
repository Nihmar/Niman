// #1188: the `rec:` grammar — Simpletask's `[+]N(d|w|m|y|b)` and Niman's
// `;mo,we,fr` / `;2tu` / `;-1fr` extensions, `until:` and `except:`. An
// unreadable value is null, never an exception.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';
import 'package:niman/src/core/recurrence/recurrence_weekday.dart';

void main() {
  group('rec: base grammar', () {
    test('every unit, with and without the strict plus', () {
      const units = {
        'd': RecurrenceUnit.day,
        'w': RecurrenceUnit.week,
        'm': RecurrenceUnit.month,
        'y': RecurrenceUnit.year,
        'b': RecurrenceUnit.businessDay,
      };
      units.forEach((letter, unit) {
        final loose = RecurrenceRule.parse('3$letter')!;
        expect(loose.unit, unit);
        expect(loose.interval, 3);
        expect(loose.strict, isFalse);
        expect(loose.weekdays, isEmpty);
        expect(loose.nthWeekday, isNull);
        final strict = RecurrenceRule.parse('+3$letter')!;
        expect(strict.unit, unit);
        expect(strict.strict, isTrue);
      });
    });

    test('the unit letter is case-insensitive, leading zeros are read', () {
      expect(RecurrenceRule.parse('2W'), RecurrenceRule.parse('2w'));
      expect(RecurrenceRule.parse('01d')!.interval, 1);
    });

    test('N is at least 1 and at most 9999', () {
      expect(RecurrenceRule.parse('0d'), isNull);
      expect(RecurrenceRule.parse('9999d')!.interval, 9999);
      expect(RecurrenceRule.parse('10000d'), isNull);
    });

    test('canonical token round-trips', () {
      for (final token in [
        '1d',
        '+1w',
        '12m',
        '1y',
        '3b',
        '1w;mo,we,fr',
        '+2w;su',
        '1m;2tu',
        '2m;-1fr',
      ]) {
        expect(RecurrenceRule.parse(token)!.token, token, reason: token);
      }
    });
  });

  group('Niman extensions', () {
    test('weekday lists: any case, sorted, without repeats', () {
      final rule = RecurrenceRule.parse('1w;FR,Mo,we,mo')!;
      expect(rule.weekdays, [DateTime.monday, DateTime.wednesday, 5]);
      expect(rule.token, '1w;mo,we,fr');
    });

    test('Nth and last weekday of a month', () {
      final second = RecurrenceRule.parse('1m;2tu')!;
      expect(second.nthWeekday, const NthWeekday(2, DateTime.tuesday));
      expect(second.nthWeekday!.isLast, isFalse);
      final last = RecurrenceRule.parse('1m;-1FR')!;
      expect(last.nthWeekday, const NthWeekday(-1, DateTime.friday));
      expect(last.nthWeekday!.isLast, isTrue);
    });

    test('an extension on a unit it does not fit is unreadable', () {
      for (final value in ['1d;mo', '1y;2tu', '1b;mo', '1w;2tu', '1m;mo,we']) {
        expect(RecurrenceRule.parse(value), isNull, reason: value);
      }
    });

    test('bad weekday codes and counts are unreadable', () {
      for (final value in [
        '1w;',
        '1w;mo,',
        '1w;mo,xx',
        '1w;monday',
        '1m;',
        '1m;5tu',
        '1m;0tu',
        '1m;-2tu',
        '1m;+2tu',
        '1m;2xx',
        '1m;tu',
        '1m;2tu,3we',
      ]) {
        expect(RecurrenceRule.parse(value), isNull, reason: value);
      }
    });
  });

  group('unreadable values', () {
    test('return null and never throw', () {
      for (final value in [
        '',
        ' ',
        '1',
        'w',
        'd1',
        '+',
        '++1d',
        '-1d',
        '1.5d',
        '1 d',
        ' 1d',
        '1d ',
        '1x',
        '1dd',
        '1d;',
        '99999999999999999999d',
        'abc',
        '1w;mo;tu',
        '١d',
      ]) {
        expect(
          () => RecurrenceRule.parse(value),
          returnsNormally,
          reason: value,
        );
        expect(RecurrenceRule.parse(value), isNull, reason: value);
      }
    });
  });

  group('rule value semantics', () {
    test('equal rules compare equal', () {
      expect(
        RecurrenceRule.parse('1w;mo,fr'),
        RecurrenceRule.parse('1w;FR,mo'),
      );
      expect(
        RecurrenceRule.parse('1w;mo,fr').hashCode,
        RecurrenceRule.parse('1w;fr,mo').hashCode,
      );
      expect(RecurrenceRule.parse('1w'), isNot(RecurrenceRule.parse('+1w')));
      expect(RecurrenceRule.parse('1w'), isNot(RecurrenceRule.parse('2w')));
    });

    test('the description is the rule as data', () {
      final d = RecurrenceRule.parse('+2w;mo,we')!.description;
      expect(d.unit, RecurrenceUnit.week);
      expect(d.interval, 2);
      expect(d.strict, isTrue);
      expect(d.weekdays, [DateTime.monday, DateTime.wednesday]);
      expect(d.nthWeekday, isNull);
      expect(d.isPlain, isFalse);

      final nth = RecurrenceRule.parse('1m;-1fr')!.description;
      expect(nth.nthWeekday, const NthWeekday(-1, DateTime.friday));
      expect(nth.isPlain, isFalse);

      final weekdays = RecurrenceRule.parse('1b')!.description;
      expect(weekdays.isEveryBusinessDay, isTrue);
      expect(weekdays.isPlain, isTrue);
      expect(
        RecurrenceRule.parse('2b')!.description.isEveryBusinessDay,
        isFalse,
      );
    });
  });

  group('until: and except:', () {
    test('until reads a real date', () {
      expect(RecurrenceBounds.parseUntil('2026-12-31'), DateTime(2026, 12, 31));
      expect(RecurrenceBounds.parseUntil('2024-02-29'), DateTime(2024, 2, 29));
    });

    test('until rejects anything else', () {
      for (final value in [
        '',
        '2026-12-3',
        '26-12-31',
        '2026/12/31',
        '2026-02-30',
        '2026-13-01',
        '2026-00-10',
        '2025-02-29',
        ' 2026-12-31',
        '2026-12-31T10:00',
      ]) {
        expect(RecurrenceBounds.parseUntil(value), isNull, reason: value);
      }
    });

    test('except reads a comma list in order, without repeats', () {
      expect(RecurrenceBounds.parseExcept('2026-11-18,2026-11-04,2026-11-18'), [
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 4),
      ]);
      expect(RecurrenceBounds.parseExcept('2026-11-04'), [
        DateTime(2026, 11, 4),
      ]);
    });

    test('one bad entry makes the whole value unreadable', () {
      for (final value in [
        '',
        ',',
        '2026-11-04,',
        ',2026-11-04',
        '2026-11-04,nope',
        '2026-11-04,2026-02-30',
        '2026-11-04, 2026-11-05',
      ]) {
        expect(RecurrenceBounds.parseExcept(value), isNull, reason: value);
      }
    });

    test('tokens come back canonical', () {
      final bounds = RecurrenceBounds(
        until: DateTime(2026, 12, 31),
        except: [DateTime(2026, 11, 18, 9), DateTime(2026, 11, 4)],
      );
      expect(bounds.untilToken, 'until:2026-12-31');
      expect(bounds.exceptToken, 'except:2026-11-04,2026-11-18');
      expect(RecurrenceBounds.none.untilToken, isNull);
      expect(RecurrenceBounds.none.exceptToken, isNull);
    });

    test('excludes: inclusive until, listed exceptions', () {
      final bounds = RecurrenceBounds(
        until: DateTime(2026, 12, 31),
        except: [DateTime(2026, 11, 4)],
      );
      expect(bounds.excludes(DateTime(2026, 12, 31)), isFalse);
      expect(bounds.excludes(DateTime(2027)), isTrue);
      expect(bounds.excludes(DateTime(2026, 11, 4, 15)), isTrue);
      expect(bounds.excludes(DateTime(2026, 11, 5)), isFalse);
    });

    test('bounds with the same content are equal', () {
      expect(
        RecurrenceBounds(
          until: DateTime(2026),
          except: [DateTime(2026, 2), DateTime(2026, 3)],
        ),
        RecurrenceBounds(
          until: DateTime(2026),
          except: [DateTime(2026, 3), DateTime(2026, 2)],
        ),
      );
    });
  });
}

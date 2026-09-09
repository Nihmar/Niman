// T-M4-06 AC: one test per placeholder, and the date formats — rendered
// against a fixed local clock so the assertions do not depend on when the
// suite runs or where.
import 'package:copist/src/core/language.dart';
import 'package:copist/src/templates/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A local time with a two-digit day, a single-digit hour and a second,
  // so the padded and unpadded tokens are told apart.
  final clock = DateTime(2026, 3, 9, 7, 5, 42);

  String render(String source, {String title = 'My Note'}) =>
      applyTemplate(source, title: title, now: clock, uuid: () => 'fixed-uuid');

  group('placeholders', () {
    test('title', () {
      expect(render('# {{title}}\n'), '# My Note\n');
      expect(render('{{title}} and {{title}}'), 'My Note and My Note');
    });

    test('date, default and explicit format', () {
      expect(render('{{date}}'), '2026-03-09');
      expect(render('{{date:YYYY}}'), '2026');
      expect(render('{{date:DD/MM/YYYY}}'), '09/03/2026');
      expect(render('{{date:D-M-YY}}'), '9-3-26');
    });

    test('time and now', () {
      expect(render('{{time}}'), '07:05');
      expect(render('{{time:HH:mm:ss}}'), '07:05:42');
      expect(render('{{now}}'), '2026-03-09 07:05');
    });

    test('uuid, one value per occurrence', () {
      expect(render('{{uuid}}'), 'fixed-uuid');
      var n = 0;
      final out = applyTemplate(
        '{{uuid}} {{uuid}}',
        title: 'x',
        now: clock,
        uuid: () => 'id${++n}',
      );
      expect(out, 'id1 id2');
    });

    test('whitespace and case inside the braces are tolerated', () {
      expect(render('{{ title }}'), 'My Note');
      expect(render('{{TITLE}}'), 'My Note');
      expect(render('{{ date : YYYY }}'), '2026');
    });

    test('an unknown placeholder is left exactly as written', () {
      expect(render('{{nope}}'), '{{nope}}');
      expect(render('{{title}} {{nope:x}}'), 'My Note {{nope:x}}');
    });

    test('everything that is not a placeholder is copied through', () {
      const source = '---\ntype: note\n---\n\n# Heading\n\n- [ ] {{title}}\n';
      expect(
        render(source),
        '---\ntype: note\n---\n\n# Heading\n\n- [ ] My Note\n',
      );
      expect(render('a { b {{ c }} } d'), 'a { b {{ c }} } d');
      expect(render('no placeholders here'), 'no placeholders here');
    });
  });

  group('formatDateTime', () {
    test('every token renders, padded and unpadded', () {
      expect(formatDateTime(clock, 'YYYY YY MM M DD D'), '2026 26 03 3 09 9');
      expect(formatDateTime(clock, 'HH H mm m ss s'), '07 7 05 5 42 42');
    });

    test('the longest token wins', () {
      expect(formatDateTime(clock, 'YYYY'), '2026');
      expect(formatDateTime(clock, 'YY'), '26');
    });

    test('separators and unknown characters are literal', () {
      expect(formatDateTime(clock, 'YYYY/MM/DD'), '2026/03/09');
      expect(formatDateTime(clock, 'week of DD.MM'), 'week of 09.03');
    });

    test('quoted text stays out of the way of the tokens', () {
      expect(formatDateTime(clock, "'on' YYYY"), 'on 2026');
      expect(formatDateTime(clock, "DD 'of' MM"), '09 of 03');
      expect(formatDateTime(clock, "YYYY''"), "2026'");
      // An unclosed quote takes the rest of the format literally.
      expect(formatDateTime(clock, "YYYY 'tail"), '2026 tail');
    });

    test('an empty format renders nothing', () {
      expect(formatDateTime(clock, ''), '');
    });
  });

  // T-TPL-01: the filter pipe, and the date vocabulary a person writing
  // a lecture or a journal note actually asks for.
  group('filters', () {
    test('the text ones, alone and chained', () {
      expect(render('{{title|upper}}'), 'MY NOTE');
      expect(render('{{title|lower}}'), 'my note');
      expect(render('{{title|slug}}'), 'my-note');
      expect(render('{{title|slug|upper}}'), 'MY-NOTE');
      expect(render('{{title|title}}', title: 'my note'), 'My Note');
      expect(render('{{title|trim}}', title: '  spaced  '), 'spaced');
      expect(render('{{title|pad:10}}'), '000My Note');
    });

    test('title case leaves a word the user capitalised alone', () {
      expect(
        render('{{title|title}}', title: 'the iPhone note'),
        'The iPhone Note',
      );
      expect(render('{{title|title}}', title: 'a USB cable'), 'A USB Cable');
    });

    test('default fills in for an empty value', () {
      expect(render('{{title|default:Untitled}}', title: ''), 'Untitled');
      expect(render('{{title|default:Untitled}}'), 'My Note');
    });

    test('an unknown filter leaves the whole placeholder standing', () {
      expect(render('{{title|nope}}'), '{{title|nope}}');
      expect(render('{{title|upper|nope}}'), '{{title|upper|nope}}');
      expect(render('{{title|pad:wide}}'), '{{title|pad:wide}}');
    });

    test('a pipe inside a quoted date format is not a filter', () {
      expect(render("{{time:HH'|'mm}}"), '07|05');
    });

    test('uuid takes filters too', () {
      expect(render('{{uuid|upper}}'), 'FIXED-UUID');
    });
  });

  group('date shifts', () {
    test('days and weeks', () {
      expect(render('{{date|+7d}}'), '2026-03-16');
      expect(render('{{date|-1w}}'), '2026-03-02');
      expect(render('{{date:YYYY-MM-DD|+1w|+1d}}'), '2026-03-17');
    });

    test('months and years, with the day clamped into the month', () {
      expect(render('{{date|+1m}}'), '2026-04-09');
      expect(render('{{date|+1y}}'), '2027-03-09');
      // 31 January plus a month is the end of February, not March.
      expect(
        applyTemplate('{{date|+1m}}', title: 'x', now: DateTime(2026, 1, 31)),
        '2026-02-28',
      );
      // And across the year boundary.
      expect(
        applyTemplate('{{date|+2m}}', title: 'x', now: DateTime(2026, 11, 30)),
        '2027-01-30',
      );
    });

    test('startof and endof snap to the week, month and year', () {
      // The fixed clock is a Monday, so the week already starts there.
      expect(render('{{date|startof:week}}'), '2026-03-09');
      expect(render('{{date|endof:week}}'), '2026-03-15');
      expect(render('{{date|startof:month}}'), '2026-03-01');
      expect(render('{{date|endof:month}}'), '2026-03-31');
      expect(render('{{date|startof:year}}'), '2026-01-01');
      expect(render('{{date|endof:year}}'), '2026-12-31');
    });

    test('a shift then a text filter, in that order', () {
      expect(render('{{date:MMMM|+1m|upper}}'), 'APRIL');
      // The other way round there is no date left to move.
      expect(render('{{date:MMMM|upper|+1m}}'), '{{date:MMMM|upper|+1m}}');
    });
  });

  group('the written-out date tokens', () {
    setUp(AppLanguages.reset);
    tearDown(AppLanguages.reset);

    test('month and weekday names, in the app language', () {
      expect(formatDateTime(clock, 'dddd D MMMM YYYY'), 'Monday 9 March 2026');
      expect(formatDateTime(clock, 'ddd DD MMM'), 'Mon 09 Mar');
      AppLanguages.choice = AppLanguage.italian;
      expect(formatDateTime(clock, 'dddd D MMMM YYYY'), 'lunedì 9 marzo 2026');
      expect(formatDateTime(clock, 'ddd DD MMM'), 'lun 09 mar');
    });

    test('MMMM never reads as two MM', () {
      expect(formatDateTime(clock, 'MMMM MMM MM M'), 'March Mar 03 3');
    });

    test('the ISO week and the quarter', () {
      expect(formatDateTime(clock, 'WW'), '11');
      expect(formatDateTime(clock, 'W'), '11');
      expect(formatDateTime(clock, 'Q'), '1');
      // 1 January 2026 is a Thursday, so it belongs to week 1...
      expect(formatDateTime(DateTime(2026), 'W'), '1');
      // ...and 31 December 2024 to week 1 of 2025, not week 53 of 2024.
      expect(formatDateTime(DateTime(2024, 12, 31), 'W'), '1');
      expect(formatDateTime(DateTime(2026, 12, 31), 'W'), '53');
    });
  });

  group('newUuidV4', () {
    test('is a v4 UUID, and a different one each time', () {
      final id = newUuidV4();
      expect(
        id,
        matches(
          RegExp(
            '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
            r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect({for (var i = 0; i < 50; i++) newUuidV4()}, hasLength(50));
    });
  });

  group('the local clock', () {
    test('the default clock is local time, not UTC', () {
      // A template that prints the date must print the date the person
      // reading it is having.
      final out = applyTemplate('{{date}}', title: 'x');
      final today = DateTime.now();
      expect(
        out,
        '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}',
      );
    });
  });
}

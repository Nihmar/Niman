// T-M4-06 AC: one test per placeholder, and the date formats — rendered
// against a fixed local clock so the assertions do not depend on when the
// suite runs or where.
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

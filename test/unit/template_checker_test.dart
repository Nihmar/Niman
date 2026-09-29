// T-TPL-09: the syntax checker. One case per row of the issue's three
// tables — structural, unknown identifiers, invalid arguments — plus the
// boundaries around what it suggests and what it deliberately leaves
// alone. Each case names the row it pins, and the two rows whose
// "suggested correction" the issue's Boundaries section overrules say so.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/templates/checker.dart';

void main() {
  /// The single error of [source], with the check that there is exactly
  /// one — most rows are one mistake in a one-line template.
  TemplateSyntaxError only(String source) {
    final errors = checkTemplateSyntax(source);
    expect(errors, hasLength(1), reason: 'for $source: $errors');
    return errors.single;
  }

  group('structural errors', () {
    test('unclosed opening braces: {{title is closed to {{title}}', () {
      final error = only('{{title');
      expect(error.kind, TemplateSyntaxErrorKind.structural);
      expect(error.offset, 0);
      expect(error.length, 7);
      expect(error.suggestion, '{{title}}');
    });

    test('unclosed closing braces: title}} is reported and left alone', () {
      final error = only('title}}');
      expect(error.kind, TemplateSyntaxErrorKind.structural);
      expect(error.offset, 5);
      expect(error.length, 2);
      expect(error.suggestion, isNull);
    });

    test('nested braces inside a placeholder: {{ {{title}} }} is split', () {
      // The inner placeholder is one the engine answers, so the row is the
      // pair of braces left over around it — one unmatched at each end,
      // and no correction: the fix is to drop them, not to add more.
      final errors = checkTemplateSyntax('{{ {{title}} }}');
      expect(errors, hasLength(2));
      expect(errors.map((error) => error.offset), [0, 13]);
      expect(errors.map((error) => error.length), [2, 2]);
      expect(errors.map((error) => error.kind), [
        TemplateSyntaxErrorKind.structural,
        TemplateSyntaxErrorKind.structural,
      ]);
      expect(errors.map((error) => error.suggestion), [null, null]);
    });

    test('a brace next to a placeholder is literal, not a pair', () {
      // `{{{title}}}` is a `{`, the placeholder and a `}`: the engine
      // renders `{Title}`, and the lone braces either side are text.
      expect(checkTemplateSyntax('{{{title}}}'), isEmpty);
      expect(checkTemplateSyntax('x{{{title}}'), isEmpty);
      // Two whole pairs around one are two stray pairs.
      final errors = checkTemplateSyntax('{{{{title}}}}');
      expect(errors.map((error) => error.offset), [0, 11]);
      expect(errors.map((error) => error.length), [2, 2]);
    });

    test('no arrangement of braces makes the checker throw', () {
      // Every string of up to eight characters over `{`, `}` and a
      // letter — each brace run at every boundary a placeholder can have —
      // plus the shapes a person actually types. The checker runs on a
      // timer while the template is edited, so a throw is an uncaught
      // error and a stale list of mistakes on screen.
      final sources = <String>[
        '{{{title}}}',
        '{{{{title}}}}',
        '{{title}}}',
        '{{{title}}',
        '}}{{title}}{{',
        '{{title}}{{',
        '{{date:YYYY}}{{{',
        '{ {{title}} }',
        '{{ {{title}}',
      ];
      void grow(String prefix) {
        sources.add(prefix);
        if (prefix.length == 8) return;
        for (final char in ['{', '}', 'a']) {
          grow('$prefix$char');
        }
      }

      grow('');
      for (final source in sources) {
        final errors = checkTemplateSyntax(source);
        for (final error in errors) {
          expect(
            error.offset,
            inInclusiveRange(0, source.length),
            reason: source,
          );
          expect(
            error.end,
            inInclusiveRange(error.offset, source.length),
            reason: source,
          );
        }
      }
    });

    test('empty placeholder: {{}} and {{ }} have nothing to suggest', () {
      for (final source in ['{{}}', '{{ }}']) {
        final error = only(source);
        expect(error.kind, TemplateSyntaxErrorKind.structural, reason: source);
        expect(error.offset, 0, reason: source);
        expect(error.length, source.length, reason: source);
        expect(error.suggestion, isNull, reason: source);
        expect(error.message, contains('no name'), reason: source);
      }
    });
  });

  group('unknown identifiers', () {
    test('unknown placeholder name: {{titlex}} → {{title}}', () {
      final error = only('{{titlex}}');
      expect(error.kind, TemplateSyntaxErrorKind.unknown);
      expect(error.offset, 0);
      expect(error.length, 10);
      expect(error.message, "unknown placeholder 'titlex'");
      expect(error.suggestion, '{{title}}');
      // Case-insensitive: the engine folds the name, and so does the
      // check, so the same typo in capitals is the same typo.
      expect(only('{{Titlex}}').suggestion, '{{title}}');
      // `titel` is two edits from `title` and two from `time`: an
      // ambiguity, so it is reported and nothing is suggested.
      final ambiguous = only('{{titel}}');
      expect(ambiguous.kind, TemplateSyntaxErrorKind.unknown);
      expect(ambiguous.suggestion, isNull);
    });

    test('unknown filter: {{title|upperr}} → {{title|upper}}', () {
      final error = only('{{title|upperr}}');
      expect(error.kind, TemplateSyntaxErrorKind.unknown);
      expect(error.offset, 0);
      expect(error.length, 16);
      expect(error.message, "unknown filter 'upperr'");
      expect(error.suggestion, '{{title|upper}}');
      // The filters around it are the ones that were written.
      expect(only('{{title|slug|upperr}}').suggestion, '{{title|slug|upper}}');
    });

    test('unknown date token in format: {{date:YYYYY}} → {{date:YYYY}}', () {
      final error = only('{{date:YYYYY}}');
      expect(error.kind, TemplateSyntaxErrorKind.unknown);
      expect(error.offset, 0);
      expect(error.length, 14);
      expect(error.message, "unknown date token 'YYYYY'");
      expect(error.suggestion, '{{date:YYYY}}');
      // Only the token is replaced, not the rest of the format.
      expect(only('{{date:YYYYY-MM}}').suggestion, '{{date:YYYY-MM}}');
    });
  });

  group('invalid arguments and filter syntax', () {
    test('pad: with a non-numeric width is reported, not guessed at', () {
      final error = only('{{title|pad:wide}}');
      expect(error.kind, TemplateSyntaxErrorKind.argument);
      expect(error.message, contains('number for its width'));
      // The issue's table suggests `pad:3`; a width is a number only the
      // author knows, so the checker reports and suggests nothing.
      expect(error.suggestion, isNull);
      expect(checkTemplateSyntax('{{title|pad:3}}'), isEmpty);
    });

    test('date shift with a non-integer count is left standing', () {
      for (final source in ['{{date|+xd}}', '{{title|+xd}}', '{{date|+7dd}}']) {
        final error = only(source);
        expect(error.kind, TemplateSyntaxErrorKind.argument, reason: source);
        expect(error.message, contains('not a date move'), reason: source);
        expect(error.suggestion, isNull, reason: source);
      }
      for (final source in [
        '{{date|+7d}}',
        '{{date|-1w}}',
        '{{date|+1y}}',
        '{{date|startof:month}}',
        '{{date|endof:year}}',
      ]) {
        expect(checkTemplateSyntax(source), isEmpty, reason: source);
      }
    });

    test('unclosed single quote in a date format', () {
      // The row as the issue writes it: the quotes round the pipe pair up,
      // so what is missing is the placeholder's closing braces — and that
      // is exactly the correction the row asks for.
      final unclosed = only("{{time:HH'|'mm");
      expect(unclosed.kind, TemplateSyntaxErrorKind.structural);
      expect(unclosed.message, contains('unclosed opening braces'));
      expect(unclosed.suggestion, "{{time:HH'|'mm}}");
      // A quote that really is unclosed: everything after it, the pipe
      // included, is read as ordinary text, and closing it would change
      // what the format means — so the checker says what is wrong and
      // stops there.
      final quote = only("{{time:HH'|mm}}");
      expect(quote.kind, TemplateSyntaxErrorKind.argument);
      expect(quote.message, contains('unclosed quote'));
      expect(quote.suggestion, isNull);
    });

    test('ask and choice with no label are reported and left standing', () {
      for (final source in ['{{ask:}}', '{{ask}}', '{{choice:}}']) {
        final error = only(source);
        expect(error.kind, TemplateSyntaxErrorKind.argument, reason: source);
        expect(error.message, contains('no label'), reason: source);
        expect(error.suggestion, isNull, reason: source);
      }
      for (final source in [
        '{{ask:Name}}',
        '{{ask:Name:Ada}}',
        '{{choice:Kind:a,b}}',
      ]) {
        expect(checkTemplateSyntax(source), isEmpty, reason: source);
      }
    });
  });

  group('the boundaries of a suggestion', () {
    test('a plain note reports nothing', () {
      const note =
          '# A note\n\nJust text — a { brace } and a } alone.\n\n'
          'A link [[Some note]] and a bare 2026-03-09.\n';
      expect(checkTemplateSyntax(note), isEmpty);
    });

    test('a template the engine answers in full reports nothing', () {
      const template =
          '---\ntype: note\n---\n\n'
          '# {{title}}\n\n'
          'Created {{date:YYYY-MM-DD}} at {{time:HH:mm}} '
          "{{date:'week' WW}}\n"
          'Moved {{date|+7d}} and snapped {{date|endof:month}}\n'
          'Id {{uuid|upper}} — {{counter:quest|pad:3}}\n'
          '{{ask:Name:Ada}} from {{choice:Kind:a,b}}\n'
          '{{parent}} in {{folder}}, {{clipboard|trim|title}}\n'
          '{{selection|default:Nothing}} {{cursor}}\n'
          '{{include:_repro}} on {{now}}.\n';
      expect(checkTemplateSyntax(template), isEmpty);
    });

    test('an unclosed brace with a clear end is the one that is closed', () {
      // The file ends where the placeholder does: the fix is a brace pair.
      expect(only('Use {{title').suggestion, '{{title}}');
      expect(only('{{date}} {{title').suggestion, '{{title}}');
      // Text follows, so there is no end the checker can point at.
      final open = only('# {{title and then a sentence');
      expect(open.kind, TemplateSyntaxErrorKind.structural);
      expect(open.suggestion, isNull);
      // At the end of the file too, when the body is not a placeholder.
      final typo = only('{{titlex');
      expect(typo.kind, TemplateSyntaxErrorKind.structural);
      expect(typo.suggestion, isNull);
    });

    test('an ambiguous case reports without a suggestion', () {
      // `+xd` on a placeholder that is not a date, and a field with no
      // label: both are reported, neither is guessed at.
      final move = only('{{title|+xd}}');
      expect(move.kind, TemplateSyntaxErrorKind.argument);
      expect(move.suggestion, isNull);
      final field = only('{{ask:}}');
      expect(field.kind, TemplateSyntaxErrorKind.argument);
      expect(field.suggestion, isNull);
      // Two tokens equally close: `YYY` could be `YY` or `YYYY`.
      final tie = only('{{date:YYY}}');
      expect(tie.kind, TemplateSyntaxErrorKind.unknown);
      expect(tie.suggestion, isNull);
    });

    test('a format the engine reads as written is not a mistake', () {
      // `DDTHH` is `DD`, the `T` of an ISO stamp and `HH`; `week` starts
      // no token at all. Neither is a typo, and neither is reported.
      for (final source in [
        '{{date:YYYY-MM-DDTHH:mm}}',
        '{{date:YYYY - week WW}}',
        "{{date:DD 'of' MMMM}}",
      ]) {
        expect(checkTemplateSyntax(source), isEmpty, reason: source);
      }
    });

    test('a suggestion is a fix for its own span, and nothing is moved', () {
      for (final source in [
        '{{titlex}}',
        '{{title|upperr}}',
        '{{date:YYYYY}}',
        '{{title',
      ]) {
        final error = only(source);
        final suggestion = error.suggestion!;
        // The span is what the suggestion replaces: put it back and the
        // mistake is gone, with nothing else in the text touched.
        final span = source.substring(error.offset, error.end);
        expect(span, source, reason: source);
        expect(checkTemplateSyntax(suggestion), isEmpty, reason: suggestion);
      }
    });

    test('mistakes come in the order they stand in the source', () {
      const source = '# {{titlex}} and {{title|upperr}} and {{date:YYYYY}}';
      final errors = checkTemplateSyntax(source);
      expect(errors, hasLength(3));
      expect(errors.map((error) => error.offset), [2, 17, 38]);
      expect(errors.map((error) => error.suggestion), [
        '{{title}}',
        '{{title|upper}}',
        '{{date:YYYY}}',
      ]);
      // Each error's span is the placeholder it is about.
      for (final error in errors) {
        expect(source.substring(error.offset, error.end), startsWith('{{'));
        expect(source.substring(error.offset, error.end), endsWith('}}'));
      }
    });

    test('a placeholder with two mistakes gets two errors', () {
      final errors = checkTemplateSyntax('{{titlex|upperr}}');
      expect(errors, hasLength(2));
      expect(errors.map((error) => error.suggestion), [
        '{{title|upperr}}',
        '{{titlex|upper}}',
      ]);
    });
  });
}

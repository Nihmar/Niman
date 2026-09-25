// The template commands as the editor sees them: the placeholders the
// engine answers, found in a line, and laid over the Markdown's colours.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/templates/template_commands.dart';

void main() {
  group('a command', () {
    test('is a placeholder the engine answers, with or without more', () {
      for (final body in [
        'title',
        'date:YYYY-MM-DD',
        'date:YYYY|+7d',
        'counter:quest|pad:3',
        ' Cursor ',
        'ask:Name',
        'choice:Kind:a,b',
        'include:_repro',
        'parent',
      ]) {
        expect(isTemplateCommand(body), isTrue, reason: body);
      }
    });

    test('is not a placeholder the engine leaves standing', () {
      for (final body in ['titel', '', 'foo:bar', 'date2']) {
        expect(isTemplateCommand(body), isFalse, reason: body);
      }
      // What the engine does with it: nothing.
      expect(applyTemplate('{{titel}}', title: 'x'), '{{titel}}');
    });

    test("stands in a line where its braces do, a typo's left out", () {
      const line = 'Due {{date:YYYY-MM-DD|+7d}}, by {{titel}} {{cursor}}';
      expect(templateCommandsIn(line), [(4, 27), (42, 52)]);
      expect(templateCommandsIn('no braces at all'), isEmpty);
    });
  });

  group('laid over a line', () {
    const bold = Token(TokenKind.bold, 2, 20);

    test('a command inside a run cuts it in two around itself', () {
      expect(overlayTokens([bold], [(6, 15)], TokenKind.templateCommand), [
        const Token(TokenKind.bold, 2, 6),
        const Token(TokenKind.templateCommand, 6, 15),
        const Token(TokenKind.bold, 15, 20),
      ]);
    });

    test('a command over the edge of runs keeps what lies outside it', () {
      const marker = Token(TokenKind.bold, 0, 2, marker: true);
      expect(
        overlayTokens(
          [marker, bold],
          [(1, 4), (18, 25)],
          TokenKind.templateCommand,
        ),
        [
          const Token(TokenKind.bold, 0, 1, marker: true),
          const Token(TokenKind.templateCommand, 1, 4),
          const Token(TokenKind.bold, 4, 18),
          const Token(TokenKind.templateCommand, 18, 25),
        ],
      );
    });

    test('a command on plain text is a run of its own', () {
      expect(overlayTokens(const [], [(3, 9)], TokenKind.templateCommand), [
        const Token(TokenKind.templateCommand, 3, 9),
      ]);
      expect(overlayTokens([bold], const [], TokenKind.templateCommand), [
        bold,
      ]);
    });
  });
}

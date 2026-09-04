import 'package:copist/src/editor/highlight_style.dart';
import 'package:copist/src/editor/highlighting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tokenStyle', () {
    test('plain is unstyled (null override)', () {
      expect(tokenStyle(TokenKind.plain), isNull);
    });

    test('the primary kinds are all styled and pairwise distinct', () {
      const kinds = [
        TokenKind.bold,
        TokenKind.italic,
        TokenKind.strike,
        TokenKind.codeInline,
        TokenKind.link,
        TokenKind.wikilink,
        TokenKind.mathInline,
        TokenKind.mathBlock,
        TokenKind.tag,
        TokenKind.image,
      ];
      final styles = kinds.map(tokenStyle).toList();
      for (final style in styles) {
        expect(style, isNotNull, reason: 'a primary kind must be styled');
      }
      for (var i = 0; i < styles.length; i++) {
        for (var j = i + 1; j < styles.length; j++) {
          expect(
            styles[i],
            isNot(styles[j]),
            reason: '${kinds[i]} and ${kinds[j]} should look different',
          );
        }
      }
    });

    test('math spans are styled (distinct from plain)', () {
      expect(tokenStyle(TokenKind.mathInline), isNotNull);
      expect(tokenStyle(TokenKind.mathBlock), isNotNull);
    });

    test('heading text is bold', () {
      expect(headingStyle.fontWeight, FontWeight.bold);
    });
  });
}

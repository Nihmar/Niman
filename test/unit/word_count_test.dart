// The word count's scan against the regex it replaced (T-M2-07, 0.0.9 stress
// test): the same answer, whitespace for whitespace.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/word_count.dart';

void main() {
  final regex = RegExp(r'\S+');
  int byRegex(String text) => regex.allMatches(text).length;

  test('counts as the regex did, over every kind of whitespace', () {
    const spaces = <String>[
      ' ',
      '\t',
      '\n',
      '\r',
      '\v',
      '\f',
      '\u00A0',
      '\u1680',
      '\u2000',
      '\u2005',
      '\u200A',
      '\u2028',
      '\u2029',
      '\u202F',
      '\u205F',
      '\u3000',
      '\uFEFF',
    ];
    const words = <String>['a', 'parola', 'è', '日本', '😀', '**x**', '-'];
    final random = Random(3);
    for (var round = 0; round < 500; round++) {
      final out = StringBuffer();
      final parts = random.nextInt(30);
      for (var at = 0; at < parts; at++) {
        out.write(
          random.nextBool()
              ? spaces[random.nextInt(spaces.length)]
              : words[random.nextInt(words.length)],
        );
      }
      final text = out.toString();
      expect(
        countWords(text),
        byRegex(text),
        reason: text.codeUnits.toString(),
      );
    }
  });

  test('the edges', () {
    expect(countWords(''), 0);
    expect(countWords('   '), 0);
    expect(countWords('one'), 1);
    expect(countWords(' one  two\nthree '), 3);
  });
}

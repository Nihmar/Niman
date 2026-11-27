// NFC without a dependency: the letters and marks the dictionaries are in.
// Escapes are written `\u{...}` so a combining mark is visible in the source.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/unicode_nfc.dart';

void main() {
  test('Latin letters and their combining marks compose', () {
    expect(UnicodeNfc.compose('citta\u{0300}'), 'citt\u{00E0}');
    expect(UnicodeNfc.compose('cafe\u{0301}'), 'caf\u{00E9}');
    expect(UnicodeNfc.compose('n\u{0303}'), '\u{00F1}');
    expect(UnicodeNfc.compose('A\u{030A}'), '\u{00C5}');
    expect(UnicodeNfc.compose('c\u{0327}'), '\u{00E7}');
    expect(UnicodeNfc.compose('s\u{030C}'), '\u{0161}');
    expect(UnicodeNfc.compose('o\u{0308}'), '\u{00F6}');
  });

  test('Vietnamese stacks of marks compose, whichever order they come in', () {
    // a, dot below, circumflex: the order Unicode's decomposition gives.
    expect(UnicodeNfc.compose('a\u{0323}\u{0302}'), '\u{1EAD}');
    // a, circumflex, dot below: put in canonical order first.
    expect(UnicodeNfc.compose('a\u{0302}\u{0323}'), '\u{1EAD}');
  });

  test('two marks of one class on a letter compose only the first', () {
    expect(UnicodeNfc.compose('a\u{0301}\u{0300}'), '\u{00E1}\u{0300}');
  });

  test('Greek and Cyrillic compose', () {
    expect(UnicodeNfc.compose('\u{03B1}\u{0301}'), '\u{03AC}');
    expect(UnicodeNfc.compose('\u{03B9}\u{0308}'), '\u{03CA}');
    expect(UnicodeNfc.compose('\u{0438}\u{0306}'), '\u{0439}');
    expect(UnicodeNfc.compose('\u{0435}\u{0308}'), '\u{0451}');
  });

  test('what is composed already, or has nothing to compose with, stays', () {
    expect(UnicodeNfc.compose('citt\u{00E0}'), 'citt\u{00E0}');
    expect(UnicodeNfc.compose('plain'), 'plain');
    expect(UnicodeNfc.compose(''), '');
    // A mark with nothing to compose with, or a pair Unicode has no letter
    // for, is left alone.
    expect(UnicodeNfc.compose('\u{0301}a'), '\u{0301}a');
    expect(UnicodeNfc.compose('x\u{0301}'), 'x\u{0301}');
    expect(UnicodeNfc.compose('\u{1F600}\u{0301}'), '\u{1F600}\u{0301}');
  });
}

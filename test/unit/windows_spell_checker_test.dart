// The Windows spell checker against the machine's own (T-PP-09 on Windows):
// only on a Windows host, and only for a language Windows has installed.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/spellcheck/windows_spell_checker.dart';

void main() {
  final skip = Platform.isWindows ? false : 'the system checker is Windows';

  test('lists the languages Windows spellchecks', () {
    expect(windowsSpellLanguages(), isNotEmpty);
  }, skip: skip);

  test('English: a word is right, a typo is wrong and gets suggestions', () {
    final checker = WindowsSpellChecker.open(language: 'en-US');
    if (checker == null) {
      markTestSkipped('no English on this Windows');
      return;
    }
    addTearDown(checker.dispose);
    expect(checker.available, isTrue);
    expect(checker.isCorrect('hello'), isTrue);
    expect(checker.isCorrect('helo'), isFalse);
    expect(checker.suggest('helo'), contains('hello'));
  }, skip: skip);

  test('a hunspell-style name finds the same language', () {
    final checker = WindowsSpellChecker.open(language: 'en_US');
    if (checker == null) {
      markTestSkipped('no English on this Windows');
      return;
    }
    addTearDown(checker.dispose);
    expect(checker.isCorrect('world'), isTrue);
  }, skip: skip);
}

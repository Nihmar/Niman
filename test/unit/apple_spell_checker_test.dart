// The Apple spell checker against the machine's own (T-PP-09,
// docs/records/apple-platforms.md): only on a Mac host (iOS's runs on a
// device), and only for a language the system has.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/spellcheck/apple_spell_checker.dart';

void main() {
  final skip = Platform.isMacOS ? false : 'the system checker is the Mac';

  test('lists the languages macOS spellchecks', () {
    expect(appleSpellLanguages(), isNotEmpty);
  }, skip: skip);

  test('English: a word is right, a typo is wrong and gets suggestions', () {
    final checker = AppleSpellChecker.open(language: 'en');
    if (checker == null) {
      markTestSkipped('no English on this Mac');
      return;
    }
    addTearDown(checker.dispose);
    expect(checker.available, isTrue);
    expect(checker.isCorrect('hello'), isTrue);
    expect(checker.isCorrect('helo'), isFalse);
    expect(checker.suggest('helo'), contains('hello'));
  }, skip: skip);

  test('Italian: the language named, not the locale, decides', () {
    final checker = AppleSpellChecker.open(language: 'it_IT');
    if (checker == null) {
      markTestSkipped('no Italian on this Mac');
      return;
    }
    addTearDown(checker.dispose);
    expect(checker.isCorrect('perché'), isTrue);
    expect(checker.isCorrect('percheé'), isFalse);
  }, skip: skip);
}

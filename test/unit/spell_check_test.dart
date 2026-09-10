// T-PP-09 (revised): hunspell through FFI drives the editor's underline.
// The engine is exercised live where the system has it, and the document
// state is exercised with a fake so the logic runs everywhere.
import 'dart:io';

import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/spellcheck/editor_spell_check.dart';
import 'package:copist/src/spellcheck/hunspell_spell_checker.dart';
import 'package:copist/src/spellcheck/spell_checker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Whether the host actually has hunspell + a dictionary; decided once so a
/// bare machine simply skips the live test.
final bool _hasHunspell = () {
  final checker = HunspellSpellChecker.open();
  if (checker == null) return false;
  checker.dispose();
  return true;
}();

void main() {
  group('dictionary discovery', () {
    test('prefers the locale, then falls back to any pair', () {
      final dir = Directory.systemTemp.createTempSync('copist-spell');
      addTearDown(() => dir.deleteSync(recursive: true));
      for (final name in ['en_US', 'it_IT']) {
        File(p.join(dir.path, '$name.aff')).writeAsStringSync('SET UTF-8');
        File(p.join(dir.path, '$name.dic')).writeAsStringSync('1\nword');
      }

      final it = discoverDictionary(locale: 'it_IT.UTF-8', dirs: [dir.path]);
      expect(it?.dic, endsWith('it_IT.dic'));
      // No French dictionary: the first available pair still serves.
      expect(discoverDictionary(locale: 'fr_FR', dirs: [dir.path]), isNotNull);
      expect(
        discoverDictionary(locale: 'en_GB', dirs: ['/nonexistent']),
        isNull,
      );
    });
  });

  group('skip ranges', () {
    test('cover code, math and links, but not prose tokens', () {
      expect(spellSkipRanges([const Token(TokenKind.codeInline, 6, 12)]), [
        const TextRange(start: 6, end: 12),
      ]);
      expect(spellSkipRanges([const Token(TokenKind.mathInline, 0, 3)]), [
        const TextRange(start: 0, end: 3),
      ]);
      expect(spellSkipRanges([const Token(TokenKind.bold, 0, 4)]), isEmpty);
    });
  });

  group('editor spell state', () {
    test('underlines only the misspelled words', () {
      final check = EditorSpellCheck(
        createChecker: () => _FakeChecker({'wrold'}),
      );
      expect(check.rangesFor(0, 'hello wrold', skip: const []), [
        const TextRange(start: 6, end: 11),
      ]);
    });

    test('skipped code is not checked', () {
      final check = EditorSpellCheck(
        createChecker: () => _FakeChecker({'wrold', 'code'}),
      );
      final skip = spellSkipRanges([const Token(TokenKind.codeInline, 6, 12)]);
      expect(check.rangesFor(0, 'wrold `code`', skip: skip), [
        const TextRange(start: 0, end: 5),
      ]);
    });

    test('camel-case identifiers are left alone', () {
      final check = EditorSpellCheck(
        createChecker: () => _FakeChecker({'fooBar'}),
      );
      expect(check.rangesFor(0, 'fooBar', skip: const []), isEmpty);
    });

    test('a disabled checker underlines nothing', () {
      final check = EditorSpellCheck(
        createChecker: () => _FakeChecker({'wrold'}),
      );
      // Setup and read are separate assertions on purpose.
      // ignore: cascade_invocations
      check.setEnabled(enabled: false);
      expect(check.rangesFor(0, 'wrold', skip: const []), isEmpty);
      expect(check.available, isFalse);
    });

    test('reset forgets the cached lines', () {
      final check = EditorSpellCheck(
        createChecker: () => _FakeChecker({'wrold'}),
      );
      const skip = <TextRange>[];
      check.rangesFor(0, 'wrold', skip: skip);
      // Priming and reset are separate statements on purpose.
      // ignore: cascade_invocations
      check.reset();
      // Still recomputed (and still correct) after the reset.
      expect(check.rangesFor(0, 'wrold', skip: skip), [
        const TextRange(start: 0, end: 5),
      ]);
    });
  });

  test('the system hunspell checks and suggests', () {
    final checker = HunspellSpellChecker.open();
    addTearDown(checker!.dispose);
    expect(checker.available, isTrue);
    expect(checker.isCorrect('hello'), isTrue);
    expect(checker.isCorrect('helo'), isFalse);
    expect(checker.suggest('helo'), contains('hello'));
  }, skip: _hasHunspell ? null : 'hunspell or a dictionary is not installed');

  test('the no-op reports unavailable and accepts every word', () {
    const checker = NoopSpellChecker();
    expect(checker.available, isFalse);
    expect(checker.isCorrect('anything'), isTrue);
    expect(checker.suggest('anything'), isEmpty);
  });
}

/// A checker whose misspellings are the words in [wrong].
final class _FakeChecker implements SpellChecker {
  new(this.wrong);

  final Set<String> wrong;

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) => !wrong.contains(word);

  @override
  List<String> suggest(String word) => const <String>[];

  @override
  void dispose() {}
}

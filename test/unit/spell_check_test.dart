// T-PP-09 (revised): hunspell through FFI drives the editor's underline.
// The engine is exercised live where the system has it, and the document
// state is exercised with a fake so the logic runs everywhere.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlight_sync.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/hunspell_spell_checker.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/ui/theme/tokens.dart';
import 'package:path/path.dart' as p;
import 'package:re_editor/re_editor.dart';

/// Whether the machine has the Italian dictionary (installed separately).
final bool _hasItalian = discoverDictionaries().containsKey('it_IT');

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
      final dir = Directory.systemTemp.createTempSync('niman-spell');
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

  group('dictionary choice', () {
    test('lists every pair and keeps directory priority', () {
      final first = Directory.systemTemp.createTempSync('niman-spell-a');
      final second = Directory.systemTemp.createTempSync('niman-spell-b');
      addTearDown(() {
        first.deleteSync(recursive: true);
        second.deleteSync(recursive: true);
      });
      for (final dir in [first, second]) {
        for (final name in ['en_US', 'it_IT']) {
          File(p.join(dir.path, '$name.aff')).writeAsStringSync('SET UTF-8');
          File(p.join(dir.path, '$name.dic')).writeAsStringSync('1\nword');
        }
      }

      final found = discoverDictionaries(dirs: [first.path, second.path]);
      expect(found.keys, containsAll(['en_US', 'it_IT']));
      expect(found['it_IT']!.dic, startsWith(first.path));
    });

    test('setDictionaries swaps the engines, clears and notifies once', () {
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'wrold'}),
      );
      var notified = 0;
      check.addListener(() => notified++);

      // Setup and read are separate assertions on purpose.
      // ignore: cascade_invocations
      check.setDictionaries(['it_IT', 'en_US']);
      expect(check.dictionaries, ['it_IT', 'en_US']);
      expect(notified, 1);

      check.setDictionaries(['it_IT', 'en_US']);
      expect(notified, 1, reason: 'the same names are a no-op');

      // Blank and duplicate names are dropped, the order is kept.
      check.setDictionaries(['en_US', ' ', 'en_US', 'it_IT']);
      expect(check.dictionaries, ['en_US', 'it_IT']);
      expect(notified, 2);
    });
  });

  group('MultiSpellChecker', () {
    test('accepts a word any engine knows and merges suggestions', () {
      final multi = MultiSpellChecker([
        _FakeChecker(
          {'hello', 'x'},
          suggestions: const {
            'x': ['alpha'],
          },
        ),
        _FakeChecker(
          {'ciao', 'x'},
          suggestions: const {
            'x': ['beta', 'alpha'],
          },
        ),
      ]);
      expect(multi.available, isTrue);
      // 'hello' is wrong to the first engine but right to the second.
      expect(multi.isCorrect('hello'), isTrue);
      expect(multi.isCorrect('ciao'), isTrue);
      // Wrong to both engines.
      expect(multi.isCorrect('x'), isFalse);
      expect(multi.suggest('x'), ['alpha', 'beta']);
    });

    test('with no available engine accepts every word', () {
      final multi = MultiSpellChecker([
        const NoopSpellChecker(),
        const NoopSpellChecker(),
      ]);
      expect(multi.available, isFalse);
      expect(multi.isCorrect('anything'), isTrue);
      expect(multi.suggest('anything'), isEmpty);
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
        createChecker: (_) => _FakeChecker({'wrold'}),
      );
      expect(check.rangesFor(0, 'hello wrold', skip: const []), [
        const TextRange(start: 6, end: 11),
      ]);
    });

    test('accepts a word any of the chosen dictionaries knows', () {
      final check = EditorSpellCheck(
        dictionaries: const ['it_IT', 'en_US'],
        createChecker: (dictionary) => switch (dictionary) {
          'it_IT' => _FakeChecker({'hello', 'hola'}),
          _ => _FakeChecker({'ciao', 'hola'}),
        },
      );
      // 'ciao' is wrong to en_US but right to it_IT; 'hello' the reverse.
      expect(check.rangesFor(0, 'ciao hello', skip: const []), isEmpty);
      // 'hola' is wrong to both, so it is underlined.
      expect(check.rangesFor(1, 'hola', skip: const []), [
        const TextRange(start: 0, end: 4),
      ]);
    });

    test('skipped code is not checked', () {
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'wrold', 'code'}),
      );
      final skip = spellSkipRanges([const Token(TokenKind.codeInline, 6, 12)]);
      expect(check.rangesFor(0, 'wrold `code`', skip: skip), [
        const TextRange(start: 0, end: 5),
      ]);
    });

    test('camel-case identifiers are left alone', () {
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'fooBar'}),
      );
      expect(check.rangesFor(0, 'fooBar', skip: const []), isEmpty);
    });

    test('a disabled checker underlines nothing', () {
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'wrold'}),
      );
      // Setup and read are separate assertions on purpose.
      // ignore: cascade_invocations
      check.setEnabled(enabled: false);
      expect(check.rangesFor(0, 'wrold', skip: const []), isEmpty);
      expect(check.available, isFalse);
    });

    test('scan lists the note issues with suggestions', () {
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker(
          {'wrold'},
          suggestions: const {
            'wrold': ['world', 'would'],
          },
        ),
      );
      final issues = check.scan([
        (text: 'hello wrold', skip: const <TextRange>[]),
      ]);
      expect(issues, hasLength(1));
      final issue = issues.single;
      expect(issue.word, 'wrold');
      expect(issue.line, 0);
      expect(issue.start, 6);
      expect(issue.end, 11);
      expect(issue.lineText, 'hello wrold');
      expect(issue.suggestions, ['world', 'would']);
    });

    test('reset forgets the cached lines', () {
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'wrold'}),
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

  test('the real engine underlines a real typo in a real span', () {
    final check = EditorSpellCheck();
    addTearDown(check.dispose);
    const line = 'hello wrold';
    final ranges = check.rangesFor(0, line, skip: const <TextRange>[]);
    expect(ranges, isNotEmpty);

    final sync = EditorHighlightSync();
    final controller = CodeLineEditingController()..text = line;
    addTearDown(controller.dispose);
    sync.onBufferChanged(controller.codeLines);
    const spell = TextStyle(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: Color(0xFFB00020),
    );
    final span = sync.spanFor(
      index: 0,
      text: line,
      base: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      syntax: SyntaxColors.fallbackLight,
      dark: false,
      spellRanges: ranges,
      spellStyle: spell,
    );

    // Walk to the misspelled run and check the wavy style landed.
    final walk = <TextSpan>[span];
    TextStyle? found;
    while (walk.isNotEmpty) {
      final node = walk.removeLast();
      if (node.text == 'wrold') found = node.style;
      walk.addAll(node.children?.whereType<TextSpan>() ?? const []);
    }
    expect(found?.decorationStyle, TextDecorationStyle.wavy);
  }, skip: _hasHunspell ? null : 'hunspell or a dictionary is not installed');

  test('the Italian dictionary checks Italian', () {
    final checker = HunspellSpellChecker.open(dictionary: 'it_IT');
    addTearDown(checker!.dispose);
    expect(checker.isCorrect('ciao'), isTrue);
    expect(checker.isCorrect('qwertyuiop'), isFalse);
  }, skip: _hasItalian ? null : 'it_IT is not installed');

  test('the no-op reports unavailable and accepts every word', () {
    const checker = NoopSpellChecker();
    expect(checker.available, isFalse);
    expect(checker.isCorrect('anything'), isTrue);
    expect(checker.suggest('anything'), isEmpty);
  });
}

/// A checker whose misspellings are the words in [wrong].
final class _FakeChecker implements SpellChecker {
  new(this.wrong, {this.suggestions = const <String, List<String>>{}});

  final Set<String> wrong;
  final Map<String, List<String>> suggestions;

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) => !wrong.contains(word);

  @override
  List<String> suggest(String word) => suggestions[word] ?? const <String>[];

  @override
  void dispose() {}
}

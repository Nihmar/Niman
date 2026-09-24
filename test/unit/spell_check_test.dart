// T-PP-09 (revised): hunspell through FFI drives the editor's underline.
// The engine is exercised live where the system has it, and the document
// state is exercised with a fake so the logic runs everywhere.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/hunspell_spell_checker.dart';
import 'package:niman/src/spellcheck/personal_dictionary.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:path/path.dart' as p;

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

    test('a pass lists the note issues; suggestions come per word', () async {
      var suggests = 0;
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker(
          {'wrold'},
          suggestions: const {
            'wrold': ['world', 'would'],
          },
          onSuggest: () => suggests++,
        ),
      );
      const lines = <String>['hello wrold', 'wrold again'];
      final scan = check.startScan(
        lineCount: lines.length,
        lineAt: (i) => (text: lines[i], skip: const <TextRange>[]),
      );
      await scan.run();
      expect(scan.done, isTrue);
      expect(scan.capped, isFalse);
      expect(scan.linesDone, 2);
      final issue = scan.issues.first;
      expect(issue.word, 'wrold');
      expect(issue.line, 0);
      expect(issue.start, 6);
      expect(issue.end, 11);
      expect(issue.lineText, 'hello wrold');
      // The pass makes none of hunspell's slow suggestions (#61).
      expect(suggests, 0);
      expect(check.suggestionsFor('wrold'), ['world', 'would']);
      expect(check.suggestionsFor('wrold'), ['world', 'would']);
      expect(suggests, 1, reason: 'cached per word');
    });

    test('a pass stops at the cap, and says so', () async {
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'wrold'}),
      );
      final scan = check.startScan(
        lineCount: EditorSpellCheck.maxIssues + 50,
        lineAt: (_) => (text: 'wrold', skip: const <TextRange>[]),
      );
      await scan.run();
      expect(scan.issues, hasLength(EditorSpellCheck.maxIssues));
      expect(scan.capped, isTrue);
      expect(scan.done, isTrue);
    });

    test('a long pass hands the frame back between slices, and a cancelled '
        'one stops', () async {
      final check = EditorSpellCheck(
        // Every word costs 2 ms, as a cold hunspell verdict can.
        createChecker: (_) => _FakeChecker({'wrold'}, cost: 2),
      );
      final scan = check.startScan(
        lineCount: 40,
        // A new word per line, so no verdict comes from the cache.
        lineAt: (i) =>
            (text: '${_letters(i)} wrold', skip: const <TextRange>[]),
      );
      var notices = 0;
      scan.addListener(() => notices++);
      final running = scan.run();
      // Other work gets a turn before the pass is over.
      var turns = 0;
      while (!scan.done) {
        turns++;
        await Future<void>.delayed(Duration.zero);
      }
      await running;
      expect(turns, greaterThan(1));
      expect(notices, greaterThan(2));

      final stopped = check.startScan(
        lineCount: 40,
        lineAt: (i) => (text: _letters(i + 1000), skip: const <TextRange>[]),
      );
      final going = stopped.run();
      await Future<void>.delayed(Duration.zero);
      stopped.cancel();
      await going;
      expect(stopped.linesDone, lessThan(40));
      expect(stopped.done, isFalse);
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

  group('personal dictionary (issue #60)', () {
    Future<PersonalDictionary> open() {
      final dir = Directory.systemTemp.createTempSync('niman-spell-dict');
      addTearDown(() => dir.deleteSync(recursive: true));
      return PersonalDictionary.open(dir.path);
    }

    test('the personal words pass whatever the engine says', () async {
      final dictionary = await open();
      await dictionary.add('helo');
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'helo', 'wrold'}),
        dictionary: dictionary,
      );
      // The engine flags 'helo', the dictionary vetoes it.
      expect(check.isMisspelled('helo'), isFalse);
      expect(check.rangesFor(0, 'helo wrold', skip: const []), [
        const TextRange(start: 5, end: 10),
      ]);
    });

    test('adding a word from the menu clears its underline', () async {
      final dictionary = await open();
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'wrold'}),
        dictionary: dictionary,
      );
      expect(check.isMisspelled('wrold'), isTrue);
      await check.addToDictionary('wrold');
      expect(dictionary.contains('wrold'), isTrue);
      expect(check.isMisspelled('wrold'), isFalse);
      expect(check.rangesFor(0, 'wrold', skip: const []), isEmpty);
    });

    test(
      'with no dictionary the verdict is unchanged and add is a no-op',
      () async {
        final check = EditorSpellCheck(
          createChecker: (_) => _FakeChecker({'wrold'}),
        );
        expect(check.isMisspelled('wrold'), isTrue);
        await check.addToDictionary('wrold');
        expect(check.isMisspelled('wrold'), isTrue);
      },
    );

    test('isMisspelled follows the underline gates', () async {
      final dictionary = await open();
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'wrold'}),
        dictionary: dictionary,
      );
      expect(check.isMisspelled('wrold'), isTrue);
      // A dictionary word is not a misspelling.
      await check.addToDictionary('wrold');
      expect(check.isMisspelled('wrold'), isFalse);
      // A one-letter run and a camel-case word are not checkable.
      expect(check.isMisspelled('a'), isFalse);
      expect(check.isMisspelled('fooBar'), isFalse);
      // A disabled checker flags nothing.
      check.setEnabled(enabled: false);
      expect(check.isMisspelled('wrold'), isFalse);
      // An unavailable engine flags nothing.
      final unavailable = EditorSpellCheck(
        createChecker: (_) => const NoopSpellChecker(),
        dictionary: dictionary,
      );
      expect(unavailable.isMisspelled('wrold'), isFalse);
    });

    test('setPersonalDictionary swaps the words and notifies', () async {
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'alpha'}),
      );
      var notified = 0;
      check.addListener(() => notified++);
      final first = await open();
      await first.add('alpha');
      check.setPersonalDictionary(first);
      expect(notified, 1);
      expect(check.personalDictionary, first);
      expect(check.isMisspelled('alpha'), isFalse);
      // The same dictionary is a no-op.
      check.setPersonalDictionary(first);
      expect(notified, 1);
      final second = await open();
      check.setPersonalDictionary(second);
      expect(notified, 2);
      expect(check.personalDictionary, second);
      // 'alpha' is no longer a personal word.
      expect(check.isMisspelled('alpha'), isTrue);
    });

    test('spellWordAt finds the word under the caret', () {
      const text = 'the quick zebra';
      expect(spellWordAt(text, 0), 'the');
      expect(spellWordAt(text, 2), 'the');
      expect(spellWordAt(text, 3), 'the', reason: 'the caret at the end');
      expect(spellWordAt(text, 4), 'quick', reason: 'the caret at the start');
      expect(spellWordAt(text, text.length), 'zebra');
      expect(spellWordAt(text, -1), isNull);
      expect(spellWordAt(text, text.length + 1), isNull);
    });

    test('spellWordForSelection names the word the selection sits in', () {
      const text = 'the quick zebra';
      expect(spellWordForSelection(text, 2, 2), 'the', reason: 'caret');
      expect(spellWordForSelection(text, 0, 3), 'the', reason: 'whole word');
      expect(spellWordForSelection(text, 1, 3), 'the', reason: 'partial');
      expect(spellWordForSelection(text, 4, 9), 'quick');
      expect(spellWordForSelection(text, 0, 9), isNull, reason: 'two words');
      expect(spellWordForSelection(text, -1, 0), isNull);
      expect(spellWordForSelection(text, 0, text.length + 1), isNull);
    });

    test(
      'the menu item appears only for a flagged word and acts on it',
      () async {
        final dictionary = await open();
        final check = EditorSpellCheck(
          createChecker: (_) => _FakeChecker({'wrold'}),
          dictionary: dictionary,
        );
        var dismissed = 0;
        final item = addToDictionaryItem(
          spell: check,
          text: 'hello wrold',
          start: 6,
          end: 11,
          onDismiss: () => dismissed++,
        );
        expect(item, isNotNull);
        final entry = item!;
        // A caret in whitespace offers nothing.
        expect(
          addToDictionaryItem(
            spell: check,
            text: 'hello wrold',
            start: 5,
            end: 5,
            onDismiss: () => dismissed++,
          ),
          isNull,
        );
        // A correct word offers nothing.
        expect(
          addToDictionaryItem(
            spell: check,
            text: 'hello wrold',
            start: 2,
            end: 2,
            onDismiss: () => dismissed++,
          ),
          isNull,
        );
        // Two words selected offer nothing.
        expect(
          addToDictionaryItem(
            spell: check,
            text: 'hello wrold',
            start: 0,
            end: 11,
            onDismiss: () => dismissed++,
          ),
          isNull,
        );
        // The entry adds the word and closes the menu.
        entry.onPressed?.call();
        expect(dismissed, 1);
        await _settle();
        expect(dictionary.contains('wrold'), isTrue);
        expect(check.isMisspelled('wrold'), isFalse);
      },
    );

    test('without a dictionary the menu offers nothing', () {
      final check = EditorSpellCheck(
        createChecker: (_) => _FakeChecker({'wrold'}),
      );
      expect(
        addToDictionaryItem(
          spell: check,
          text: 'wrold',
          start: 0,
          end: 5,
          onDismiss: () {},
        ),
        isNull,
      );
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

  test('the real engine finds a real typo', () {
    final check = EditorSpellCheck();
    addTearDown(check.dispose);
    const line = 'hello wrold';
    final ranges = check.rangesFor(0, line, skip: const <TextRange>[]);
    expect(ranges.map((r) => r.textInside(line)), ['wrold']);
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

/// Pumps the event loop: the dictionary write is real disk I/O.
Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// [n] spelled in letters, one word per number: `wbca` for 120.
String _letters(int n) {
  final letters = [
    for (final digit in '$n'.split('')) 'abcdefghij'[int.parse(digit)],
  ];
  return 'w${letters.join()}';
}

/// A checker whose misspellings are the words in [wrong].
final class _FakeChecker implements SpellChecker {
  new(
    this.wrong, {
    this.suggestions = const <String, List<String>>{},
    this.cost = 0,
    this.onSuggest,
  });

  final Set<String> wrong;
  final Map<String, List<String>> suggestions;

  /// Milliseconds each verdict keeps the isolate busy.
  final int cost;
  final void Function()? onSuggest;

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) {
    if (cost > 0) {
      final clock = Stopwatch()..start();
      while (clock.elapsedMilliseconds < cost) {}
    }
    return !wrong.contains(word);
  }

  @override
  List<String> suggest(String word) {
    onSuggest?.call();
    return suggestions[word] ?? const <String>[];
  }

  @override
  void dispose() {}
}

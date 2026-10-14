// T-PP-09, #61: the spelling review panel. It opens at once and fills as
// the pass goes; suggestions come after the list; a fix is applied
// through the editor and the list follows without a second pass; a pass
// that hit the cap says so and offers another.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_check_sheet.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';
import 'package:niman/src/ui/strings.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// 'wrold' and 'teh' are wrong; each has suggestions.
final class _Checker implements SpellChecker {
  const new();

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) => word != 'wrold' && word != 'teh';

  @override
  List<String> suggest(String word) => switch (word) {
    'wrold' => const ['world', 'would', 'worlds'],
    'teh' => const ['the'],
    _ => const <String>[],
  };

  @override
  void dispose() {}
}

/// A checker whose every verdict costs [cost] ms, as a cold hunspell one
/// can; nothing is wrong.
final class _SlowChecker implements SpellChecker {
  const new(this.cost);

  final int cost;

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) {
    final clock = Stopwatch()..start();
    while (clock.elapsedMilliseconds < cost) {}
    return true;
  }

  @override
  List<String> suggest(String word) => const <String>[];

  @override
  void dispose() {}
}

/// A checker that takes [cost] ms a word and finds only 'wrold' wrong.
final class _SlowWrong implements SpellChecker {
  const new(this.cost);

  final int cost;

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) {
    final clock = Stopwatch()..start();
    while (clock.elapsedMilliseconds < cost) {}
    return word != 'wrold';
  }

  @override
  List<String> suggest(String word) => const <String>[];

  @override
  void dispose() {}
}

void main() {
  late EditorSpellCheck spell;

  setUp(() => spell = EditorSpellCheck(createChecker: (_) => const _Checker()));
  tearDown(() => spell.dispose());

  Future<({List<(SpellIssue, String)> applied, int Function() starts})> pump(
    WidgetTester tester,
    List<String> lines, {
    bool available = true,
  }) async {
    final applied = <(SpellIssue, String)>[];
    var starts = 0;
    await tester.pumpWidget(
      _app(
        SpellCheckSheet(
          available: available,
          start: () {
            starts++;
            return spell.startScan(
              lineCount: lines.length,
              lineAt: (i) => (text: lines[i], skip: const <TextRange>[]),
            );
          },
          suggest: spell.suggestionsFor,
          apply: (issue, replacement) {
            applied.add((issue, replacement));
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (applied: applied, starts: () => starts);
  }

  testWidgets('a fix is applied, and the list follows without a second '
      'pass', (tester) async {
    final run = await pump(tester, ['hello wrold and teh end']);
    expect(find.text('wrold'), findsOne);
    expect(find.text('teh'), findsOne);

    await tester.tap(find.widgetWithText(ActionChip, 'world'));
    await tester.pumpAndSettle();
    final (fixed, replacement) = run.applied.single;
    expect((fixed.word, replacement), ('wrold', 'world'));
    expect(find.text('wrold'), findsNothing);
    expect(run.starts(), 1, reason: 'no second pass');

    await tester.tap(find.widgetWithText(ActionChip, 'the'));
    await tester.pumpAndSettle();
    final (next, _) = run.applied.last;
    expect(next.word, 'teh');
    expect(next.start, 'hello world and '.length);
    expect(find.text(AppStrings.spellCheckEmpty), findsOne);
  });

  testWidgets('docked, a click shows the word, Ignore and Add drop it, and '
      'an edit checks again (#712)', (tester) async {
    final lines = ['wrold teh wrold'];
    final edited = ChangeNotifier();
    addTearDown(edited.dispose);
    final shown = <String>[];
    final added = <String>[];
    var starts = 0;
    await tester.pumpWidget(
      _app(
        SpellCheckSheet(
          docked: true,
          available: true,
          edited: edited,
          start: () {
            starts++;
            return spell.startScan(
              lineCount: lines.length,
              lineAt: (i) => (text: lines[i], skip: const <TextRange>[]),
            );
          },
          suggest: spell.suggestionsFor,
          apply: (_, _) => true,
          reveal: (issue) {
            shown.add('${issue.word}@${issue.start}');
            return true;
          },
          addWord: (word) async => added.add(word),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('spell-check-close')), findsNothing);

    await tester.tap(find.byKey(const Key('spell-issue-0-6')));
    expect(shown, ['teh@6']);

    await tester.tap(find.byKey(const Key('spell-ignore-0-0')));
    await tester.pumpAndSettle();
    expect(find.text('wrold'), findsNothing, reason: 'every one of the word');
    await tester.tap(find.byKey(const Key('spell-add-0-6')));
    await tester.pumpAndSettle();
    expect(added, ['teh']);
    expect(find.text(AppStrings.spellCheckEmpty), findsOne);

    lines[0] = 'still wrold teh';
    edited.notifyListeners();
    await tester.pumpAndSettle();
    expect(starts, 2);
    expect(find.text('wrold'), findsNothing, reason: 'ignored, #907');
    // The fake dictionary did not learn 'teh': it is listed again.
    expect(find.text('teh'), findsOne);
  });

  // #907: Ignore was only a drop from the list, and the next edit's rescan
  // brought the word back.
  testWidgets('an ignored word stays ignored through the rescans, and in '
      'a pane built again', (tester) async {
    final lines = ['wrold teh'];
    final edited = ChangeNotifier();
    addTearDown(edited.dispose);
    final ignored = <String>{};
    Future<void> open() async {
      await tester.pumpWidget(
        _app(
          SpellCheckSheet(
            key: UniqueKey(),
            docked: true,
            available: true,
            edited: edited,
            ignored: ignored,
            start: () => spell.startScan(
              lineCount: lines.length,
              lineAt: (i) => (text: lines[i], skip: const <TextRange>[]),
            ),
            suggest: spell.suggestionsFor,
            apply: (_, _) => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open();
    await tester.tap(find.byKey(const Key('spell-ignore-0-0')));
    await tester.pumpAndSettle();
    expect(find.text('wrold'), findsNothing);
    expect(ignored, {'wrold'});

    // An edit anywhere: the note is checked again.
    lines[0] = 'wrold teh, and wrold more';
    edited.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('wrold'), findsNothing, reason: 'still ignored');
    expect(find.text('teh'), findsOne);

    // The pane closed and opened again, as on another tab and back.
    await open();
    expect(find.text('wrold'), findsNothing);
    expect(find.text('teh'), findsOne);
  });

  testWidgets('a rescan keeps the list on screen until the new pass can '
      'replace it', (tester) async {
    final slow = EditorSpellCheck(createChecker: (_) => const _SlowWrong(1));
    addTearDown(slow.dispose);
    // A new word per line, as a note has: none comes from the cache.
    final longNote = [
      for (var i = 0; i < 300; i++)
        'w${String.fromCharCodes('$i'.codeUnits.map((c) => c + 49))}',
      'wrold',
    ];
    final edited = ChangeNotifier();
    addTearDown(edited.dispose);
    var pass = 0;
    await tester.pumpWidget(
      _app(
        SpellCheckSheet(
          docked: true,
          available: true,
          edited: edited,
          start: () => pass++ == 0
              ? spell.startScan(
                  lineCount: 1,
                  lineAt: (_) => (text: 'wrold teh', skip: const <TextRange>[]),
                )
              : slow.startScan(
                  lineCount: longNote.length,
                  lineAt: (i) => (text: longNote[i], skip: const <TextRange>[]),
                ),
          suggest: spell.suggestionsFor,
          apply: (_, _) => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('wrold'), findsOne);
    expect(find.text('teh'), findsOne);

    edited.notifyListeners();
    await tester.pump();
    expect(find.byKey(const Key('spell-check-progress')), findsOne);
    expect(find.text('teh'), findsOne, reason: 'the list is not emptied');
    expect(find.text(AppStrings.spellCheckScanning), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('spell-check-progress')), findsNothing);
    expect(find.text('wrold'), findsOne);
    expect(find.text('teh'), findsNothing, reason: 'the new pass replaced it');
  });

  testWidgets('an earlier fix of another length moves what follows it', (
    tester,
  ) async {
    final run = await pump(tester, ['wrold teh']);
    await tester.tap(find.widgetWithText(ActionChip, 'worlds'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'the'));
    await tester.pumpAndSettle();
    final (moved, _) = run.applied.last;
    // "teh" was at 6; "worlds" is one longer than "wrold".
    expect(moved.word, 'teh');
    expect(moved.start, 7);
    expect(moved.end, 10);
  });

  testWidgets('a pass that hit the cap says so, and checks again', (
    tester,
  ) async {
    final run = await pump(tester, [
      for (var i = 0; i < EditorSpellCheck.maxIssues + 10; i++) 'wrold',
    ]);
    expect(find.byKey(const Key('spell-check-capped')), findsOne);
    await tester.tap(find.byKey(const Key('spell-check-again')));
    await tester.pumpAndSettle();
    expect(run.starts(), 2);
  });

  testWidgets('the close button is offered', (tester) async {
    await pump(tester, const []);
    expect(find.byKey(const Key('spell-check-close')), findsOneWidget);
  });

  testWidgets('an empty note shows the all-clear', (tester) async {
    await pump(tester, const ['all good here']);
    expect(find.text(AppStrings.spellCheckEmpty), findsOneWidget);
  });

  testWidgets('a missing hunspell shows the platform note', (tester) async {
    await pump(tester, const ['wrold'], available: false);
    expect(find.text(AppStrings.spellCheckUnavailable), findsOneWidget);
  });

  // #61: the pass used to run whole before the sheet could draw.
  testWidgets('on a long, slow note it opens at once and fills as it goes', (
    tester,
  ) async {
    final slow = EditorSpellCheck(createChecker: (_) => const _SlowChecker(1));
    addTearDown(slow.dispose);
    // A new word per line, as a note has: none comes from the cache.
    final lines = [
      for (var i = 0; i < 300; i++)
        'w${String.fromCharCodes('$i'.codeUnits.map((c) => c + 49))}',
    ];
    final clock = Stopwatch()..start();
    await tester.pumpWidget(
      _app(
        SpellCheckSheet(
          available: true,
          start: () => slow.startScan(
            lineCount: lines.length,
            lineAt: (i) => (text: lines[i], skip: const <TextRange>[]),
          ),
          suggest: slow.suggestionsFor,
          apply: (_, _) => true,
        ),
      ),
    );
    // The first frame came after one slice, not after 300 ms of checking.
    expect(clock.elapsedMilliseconds, lessThan(150));
    expect(find.byKey(const Key('spell-check-progress')), findsOne);
    expect(find.text(AppStrings.spellCheckScanning), findsOne);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('spell-check-progress')), findsNothing);
    expect(find.text(AppStrings.spellCheckEmpty), findsOne);
  });
}

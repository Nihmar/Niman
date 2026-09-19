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
          apply: (issue, replacement) => applied.add((issue, replacement)),
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
          apply: (_, _) {},
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

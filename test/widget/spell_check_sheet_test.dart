// T-PP-09: the spelling review panel lists hunspell's findings and applies
// a suggestion back through the editor's scan/apply closures.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/spellcheck/spell_check_sheet.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';
import 'package:niman/src/ui/strings.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

const _issue = SpellIssue(
  line: 2,
  start: 6,
  end: 11,
  word: 'wrold',
  lineText: 'hello wrold',
  suggestions: ['world', 'would'],
);

void main() {
  testWidgets('a suggestion tap applies the fix and re-scans', (tester) async {
    var applied = '';
    var scans = 0;
    await tester.pumpWidget(
      _app(
        SpellCheckSheet(
          available: true,
          scan: () {
            scans++;
            return const [_issue];
          },
          apply: (issue, replacement) => applied = replacement,
        ),
      ),
    );

    expect(find.text('wrold'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'world'));
    expect(applied, 'world');
    expect(scans, 2, reason: 'open, then re-scan after the fix');
  });

  testWidgets('the close button is offered', (tester) async {
    await tester.pumpWidget(
      _app(
        SpellCheckSheet(
          available: true,
          scan: () => const [],
          apply: (issue, replacement) {},
        ),
      ),
    );
    expect(find.byKey(const Key('spell-check-close')), findsOneWidget);
  });

  testWidgets('an empty note shows the all-clear', (tester) async {
    await tester.pumpWidget(
      _app(
        SpellCheckSheet(
          available: true,
          scan: () => const [],
          apply: (issue, replacement) {},
        ),
      ),
    );
    expect(find.text(AppStrings.spellCheckEmpty), findsOneWidget);
  });

  testWidgets('a missing hunspell shows the platform note', (tester) async {
    await tester.pumpWidget(
      _app(
        SpellCheckSheet(
          available: false,
          scan: () => const [],
          apply: (issue, replacement) {},
        ),
      ),
    );
    expect(find.text(AppStrings.spellCheckUnavailable), findsOneWidget);
  });
}

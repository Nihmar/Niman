// Tidy on close is a library's editor setting, on unless switched off, and
// the Editor settings screen switches it; the rules row chooses which #72
// rules the tidy applies.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/lint/lint_rule.dart';
import 'package:niman/src/ui/settings_editor.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  testWidgets('the Editor screen switches it for the library', (tester) async {
    final controller = FakeLibrarySession();
    var notified = 0;
    final events = controller.events.listen((_) => notified++);
    addTearDown(events.cancel);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsEditorScreen(controller: controller, spellCheck: null),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.byKey(SettingsKeys.tidyOnClose);
    await tester.scrollUntilVisible(row, 200);
    // Built is not the same as on screen: see settings_typewriter_test.
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    final toggle = find.descendant(of: row, matching: find.byType(Switch));
    expect(tester.widget<Switch>(toggle).value, isTrue);

    final before = notified;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(await controller.tidyOnClose, isFalse);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    // The shell hears of it, so the next close follows it.
    expect(notified, greaterThan(before));
  });

  testWidgets('the Editor screen chooses which rules a tidy applies', (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsEditorScreen(controller: controller, spellCheck: null),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.byKey(SettingsKeys.lintRules);
    await tester.scrollUntilVisible(row, 200);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    // Every rule is on to start with but the ones off by default, and the
    // row says so.
    final all = LintRule.values.length;
    final onByDefault = LintRule.defaults.length;
    expect(find.text(AppStrings.lintRulesValue(onByDefault, all)), findsOne);

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lint-rules-dialog')), findsOne);
    for (final rule in LintRule.values) {
      final box = find.byKey(Key('lint-rule-${rule.id}'));
      expect(tester.widget<CheckboxListTile>(box).value, rule.onByDefault);
    }

    // Turn one rule off, the hard-break one on, and save.
    await tester.tap(find.byKey(const Key('lint-rule-tight-lists')));
    await tester.pumpAndSettle();
    final hard = find.byKey(const Key('lint-rule-hard-breaks-as-paragraphs'));
    await tester.ensureVisible(hard);
    await tester.tap(hard);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lint-rules-save')));
    await tester.pumpAndSettle();
    expect(await controller.lintRulesOff, {'tight-lists'});
    expect(find.text(AppStrings.lintRulesValue(all - 1, all)), findsOne);

    // And the dialog remembers it, with the reset putting the defaults back.
    await tester.tap(row);
    await tester.pumpAndSettle();
    final tight = find.byKey(const Key('lint-rule-tight-lists'));
    expect(tester.widget<CheckboxListTile>(tight).value, isFalse);
    expect(tester.widget<CheckboxListTile>(hard).value, isTrue);
    await tester.tap(find.byKey(const Key('lint-rules-reset')));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(tight).value, isTrue);
    expect(tester.widget<CheckboxListTile>(hard).value, isFalse);
    await tester.tap(find.byKey(const Key('lint-rules-save')));
    await tester.pumpAndSettle();
    expect(await controller.lintRulesOff, LintRule.offByDefaultIds);
  });
}

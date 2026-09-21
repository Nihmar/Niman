// The engine switch is reachable: it is in the appearance screen, it persists
// to the library, and it reads back. Without this the unified surface would be
// code that only a test can turn on — which is what it was until this round.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/settings_appearance.dart';
import 'package:niman/src/ui/settings_keys.dart';

import '../fakes/fake_library_session.dart';

void main() {
  testWidgets("the appearance screen switches the note's engine", (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    await tester.pumpWidget(
      MaterialApp(home: SettingsAppearanceScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final row = find.byKey(SettingsKeys.markdownEngine);
    await tester.scrollUntilVisible(row, 200);
    final toggle = find.descendant(of: row, matching: find.byType(Switch));
    // The shipped behaviour is the default: the switch starts off.
    expect(tester.widget<Switch>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(await controller.markdownEngine, MarkdownEngine.unified);

    // And back, because a switch that only goes one way is a trap.
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(await controller.markdownEngine, MarkdownEngine.legacy);
  });

  testWidgets('the row is hidden with the preview it replaces', (tester) async {
    final controller = FakeLibrarySession();
    await controller.setPreviewEnabled(enabled: false);
    await tester.pumpWidget(
      MaterialApp(home: SettingsAppearanceScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    // No preview means no engine to choose between: the row says what the
    // note is drawn with, and with no preview there is nothing to say.
    expect(find.byKey(SettingsKeys.markdownEngine), findsNothing);
  });
}

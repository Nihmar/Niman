// Tidy on close is a library's editor setting, on unless switched off, and
// the Editor settings screen switches it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/settings_editor.dart';
import 'package:niman/src/ui/settings_keys.dart';

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
}

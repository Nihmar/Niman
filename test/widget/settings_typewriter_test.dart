// Issue #70: typewriter mode is a library's editor setting, off unless
// asked for, and the Editor settings screen switches it.
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
    final row = find.byKey(SettingsKeys.typewriter);
    await tester.scrollUntilVisible(row, 200);
    // Built is not the same as on screen: the drag stops as soon as the
    // row enters the cache extent, and the switch's centre can land just
    // under the fold, where the tap misses it.
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    final toggle = find.descendant(of: row, matching: find.byType(Switch));
    expect(tester.widget<Switch>(toggle).value, isFalse);

    final before = notified;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(await controller.typewriter, isTrue);
    expect(tester.widget<Switch>(toggle).value, isTrue);
    // The shell hears of it, so an open note takes it on the spot.
    expect(notified, greaterThan(before));
  });
}

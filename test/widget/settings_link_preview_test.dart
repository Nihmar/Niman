// Issue #846: the link preview is a library's editor setting, on unless a
// library says otherwise, and the Editor settings screen switches it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/ui/settings_editor.dart';
import 'package:niman/src/ui/settings_keys.dart';

import '../fakes/fake_library_session.dart';

void main() {
  test('it is on by default, and a stored false turns it off', () {
    expect(LibraryConfig.defaults.linkPreview, isTrue);
    expect(
      LibraryConfig.fromJsonMap(const <String, Object?>{'linkPreview': false})
          .linkPreview,
      isFalse,
    );
    expect(
      LibraryConfig.fromJsonMap(const <String, Object?>{'linkPreview': 'no'})
          .linkPreview,
      isTrue,
      reason: 'a value that is not a bool reads as the default',
    );
    expect(
      LibraryConfig.defaults.copyWith(linkPreview: false).toJsonMap(),
      containsPair('linkPreview', false),
    );
  });

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
    final row = find.byKey(SettingsKeys.linkPreview);
    await tester.scrollUntilVisible(row, 200);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    expect(find.text('Preview links'), findsOneWidget);
    final toggle = find.descendant(of: row, matching: find.byType(Switch));
    expect(tester.widget<Switch>(toggle).value, isTrue);

    final before = notified;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(await controller.linkPreview, isFalse);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(notified, greaterThan(before), reason: 'the shell hears of it');
  });
}

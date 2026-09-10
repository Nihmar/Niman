// T-PP-10: the in-app reference is generated from the registry, so a key
// shown here is a key the shell installs.
import 'package:copist/src/ui/app_shortcuts.dart';
import 'package:copist/src/ui/keyboard_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the reference lists every registered accelerator', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: KeyboardShortcutsScreen()));
    await tester.pumpAndSettle();

    for (final shortcut in copistAppShortcuts) {
      expect(
        find.byKey(Key('shortcut-${shortcut.command.name}')),
        findsOneWidget,
        reason: shortcut.command.name,
      );
    }
    expect(find.text('Ctrl+Shift+N'), findsOneWidget);

    // The editor's own keys sit at the bottom of the list.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Ctrl+F'), findsOneWidget);
  });
}

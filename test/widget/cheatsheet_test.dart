// The Markdown cheatsheet (#265): every construct, written and shown, a
// copy of each, and an insert when there is a note to take one.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/cheatsheet/cheatsheet_entries.dart';
import 'package:niman/src/ui/cheatsheet/cheatsheet_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<String>? onInsert,
  Size size = const Size(1100, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: CheatsheetScreen(onInsert: onInsert)),
  );
  await tester.pumpAndSettle();
}

/// Scrolls the page until [entry] is built.
Future<void> _reach(WidgetTester tester, CheatsheetEntry entry) async {
  await tester.scrollUntilVisible(
    find.byKey(Key('cheat-${entry.id}-shown')),
    300,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('cheatsheet')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every example is written and shown, without a fault', (
    tester,
  ) async {
    await _pump(tester);
    for (final entry in cheatsheetEntries) {
      await _reach(tester, entry);
      expect(
        tester
            .widget<SelectableText>(
              find.descendant(
                of: find.byKey(Key('cheat-${entry.id}-written')),
                matching: find.byType(SelectableText),
              ),
            )
            .data,
        entry.source,
      );
      expect(tester.takeException(), isNull, reason: entry.id);
    }
  });

  testWidgets('a wide page sets the two side by side, a narrow one stacks', (
    tester,
  ) async {
    Offset written() =>
        tester.getTopLeft(find.byKey(const Key('cheat-headings-written')));
    Offset shown() =>
        tester.getTopLeft(find.byKey(const Key('cheat-headings-shown')));
    await _pump(tester);
    expect(shown().dy, written().dy);
    expect(shown().dx, greaterThan(written().dx));
    await _pump(tester, size: const Size(400, 900));
    expect(shown().dy, greaterThan(written().dy));
    expect(shown().dx, written().dx);
  });

  testWidgets('copy puts the example on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester);
    await tester.tap(find.byKey(const Key('cheat-emphasis-copy')));
    await tester.pump();
    expect(copied, cheatsheetEntries[1].source);
    expect(find.byKey(const Key('cheat-emphasis-insert')), findsNothing);
  });

  testWidgets('with a note open, insert hands the example over', (
    tester,
  ) async {
    final inserted = <String>[];
    await _pump(tester, onInsert: inserted.add);
    await tester.tap(find.byKey(const Key('cheat-headings-insert')));
    await tester.pump();
    expect(inserted, [cheatsheetEntries.first.source]);
  });
}

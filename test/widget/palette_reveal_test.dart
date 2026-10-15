// Issue #980: a palette's list is taller than its panel, and the row the
// arrows are on has to stay in view — Enter runs the row, so a row nobody
// can see is a choice nobody made. The quick pick and the command palette
// share the scroll.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/palette/quick_pick.dart';

void main() {
  final names = [for (var i = 0; i < 40; i++) 'Template ${i + 1}'];

  Future<List<int?>> openQuickPick(WidgetTester tester) async {
    final picked = <int?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked.add(
              await showQuickPick<int>(
                context,
                hint: 'Pick',
                items: [for (var i = 0; i < 40; i++) (names[i], i)],
                itemKey: (value) => Key('item-$value'),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return picked;
  }

  /// Whether [row] is built and lies inside the visible list.
  bool inView(WidgetTester tester, Finder row) {
    if (row.evaluate().isEmpty) return false;
    final list = tester.getRect(find.byType(ListView));
    final rect = tester.getRect(row);
    return rect.top >= list.top - 0.5 && rect.bottom <= list.bottom + 0.5;
  }

  Future<void> down(WidgetTester tester, int times) async {
    for (var i = 0; i < times; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  group('quick pick', () {
    testWidgets('the arrows walk past the visible rows and keep up', (
      tester,
    ) async {
      final picked = await openQuickPick(tester);
      await down(tester, 25);
      expect(inView(tester, find.byKey(const Key('item-25'))), isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(picked.single, 25);
    });

    testWidgets('and back up again', (tester) async {
      await openQuickPick(tester);
      await down(tester, 25);
      for (var i = 0; i < 24; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(inView(tester, find.byKey(const Key('item-1'))), isTrue);
    });

    testWidgets('wrapping to the last row, and to the first', (tester) async {
      await openQuickPick(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(inView(tester, find.byKey(const Key('item-39'))), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(inView(tester, find.byKey(const Key('item-0'))), isTrue);
    });

    testWidgets('a new filter starts at the top', (tester) async {
      await openQuickPick(tester);
      await down(tester, 25);
      await tester.enterText(find.byKey(const Key('quick-pick-field')), 'tem');
      await tester.pumpAndSettle();
      expect(inView(tester, find.byKey(const Key('item-0'))), isTrue);
    });
  });

  group('command palette', () {
    Future<void> openPalette(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCommandPalette(
                context,
                commands: [
                  for (final command in AppCommand.values)
                    PaletteCommand.of(command),
                ],
                searchNotes: (_) async => [
                  for (var i = 0; i < 20; i++) 'Notes/note$i.md',
                ],
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      // The palette lists twelve commands and up to twenty notes: more
      // than the panel shows.
      await tester.enterText(find.byKey(const Key('palette-field')), 'a');
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('the arrows walk past the visible rows and keep up', (
      tester,
    ) async {
      await openPalette(tester);
      await down(tester, 25);
      expect(inView(tester, find.byKey(const Key('palette-item-25'))), isTrue);
    });

    testWidgets('wrapping up from the first lands on the last, in view', (
      tester,
    ) async {
      await openPalette(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      // The list is lazy: the rows built are the ones near the end.
      final built = [
        for (var i = 0; i < 300; i++)
          if (find.byKey(Key('palette-item-$i')).evaluate().isNotEmpty) i,
      ];
      final last = built.last;
      expect(last, greaterThan(20));
      expect(inView(tester, find.byKey(Key('palette-item-$last'))), isTrue);
    });
  });
}

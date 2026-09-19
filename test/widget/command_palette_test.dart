// Issue #155: the palette panel — one field, commands and notes found
// together, run without the mouse, and a footer that teaches it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  PaletteChoice? picked;
  var closed = false;

  Future<void> open(WidgetTester tester, {bool notesOnly = false}) async {
    picked = null;
    closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  picked = await showCommandPalette(
                    context,
                    notesOnly: notesOnly,
                    commands: [
                      PaletteCommand.of(AppCommand.newNote),
                      PaletteCommand.of(AppCommand.splitRight),
                      PaletteCommand.of(AppCommand.tabSettings),
                    ],
                    recentNotes: const ['Recent.md'],
                    searchNotes: (q) async => [
                      if ('planet.md'.contains(q)) 'Notes/planet.md',
                    ],
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the recent, with a footer that teaches it', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('command-palette')), findsOne);
    expect(find.text(AppStrings.paletteFooter), findsOne);
    expect(find.text('Recent'), findsOne);
    // The name is Group: Verb, … when it asks; the binding beside it.
    expect(find.textContaining(': '), findsWidgets);
    expect(find.textContaining('…'), findsOne);
    expect(find.text(r'Ctrl+\'), findsOne);
  });

  testWidgets('typing finds commands and notes together', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('palette-field')), 'pla');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('planet'), findsOne);
    await tester.enterText(find.byKey(const Key('palette-field')), 'split');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining(AppStrings.splitRight), findsOne);
    expect(find.text('planet'), findsNothing);
  });

  testWidgets('↓ and ↵ run a command without the mouse', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('palette-field')), 'o');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(picked, isA<PaletteCommandChoice>());
  });

  testWidgets('a note is picked by a tap too', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('palette-field')), 'planet');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('palette-item-0')));
    await tester.pumpAndSettle();
    expect((picked! as PaletteNoteChoice).path, 'Notes/planet.md');
  });

  testWidgets('esc dismisses, picking nothing', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(picked, isNull);
    expect(find.byKey(const Key('command-palette')), findsNothing);
  });

  testWidgets('Go to note offers notes alone', (tester) async {
    await open(tester, notesOnly: true);
    expect(find.textContaining(': '), findsNothing);
    expect(find.text('Recent'), findsOne);
  });
}

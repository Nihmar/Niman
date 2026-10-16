// Issue #1034: Enter while the note search for the typed text is still
// out must not open the previous keystroke's (or the recent) row.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/palette/command_palette.dart';

void main() {
  late Completer<List<String>> search;
  PaletteChoice? picked;
  var closed = false;

  Future<void> open(WidgetTester tester) async {
    picked = null;
    closed = false;
    search = Completer<List<String>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                picked = await showCommandPalette(
                  context,
                  notesOnly: true,
                  commands: const [],
                  recentNotes: const ['old.md'],
                  searchNotes: (_) => search.future,
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Enter while the search is pending waits for its hits', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('palette-field')), 'proj');
    await tester.pump(const Duration(milliseconds: 130));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    // The stale row (old.md) was not opened.
    expect(closed, isFalse);
    expect(picked, isNull);

    search.complete(['proj.md']);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect((picked! as PaletteNoteChoice).path, 'proj.md');
  });

  testWidgets('typing on after Enter drops the queued choice', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('palette-field')), 'pro');
    await tester.pump(const Duration(milliseconds: 130));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.enterText(find.byKey(const Key('palette-field')), 'proj');
    await tester.pump(const Duration(milliseconds: 130));
    search.complete(['proj.md']);
    await tester.pumpAndSettle();
    expect(closed, isFalse);
  });

  testWidgets('with nothing typed Enter opens the recent note at once', (
    tester,
  ) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect((picked! as PaletteNoteChoice).path, 'old.md');
  });
}

// #202: the floating window. Screens opened from its page open inside
// it, not over the whole app; Esc steps back out of them before it
// closes the window; a click outside closes it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/floating_window.dart';

import '../fakes/shell_harness.dart';

void main() {
  const window = Key('window');

  Future<void> open(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1400, 1000));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showFloatingWindow(
                context,
                title: 'Window',
                panelKey: window,
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('inner')),
                    ),
                  ),
                  child: const Text('push'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a pushed screen opens inside the window', (tester) async {
    await open(tester);
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(window), matching: find.text('inner')),
      findsOne,
    );
    expect(
      tester.getSize(find.byKey(window)),
      FloatingWindow.defaultSize,
      reason: 'the panel keeps its size: the screen is not full-window',
    );
  });

  testWidgets('Esc steps back, then closes', (tester) async {
    await open(tester);
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('inner'), findsNothing);
    expect(find.text('push'), findsOne, reason: 'back to the first page');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(window), findsNothing);
  });

  testWidgets('a click outside closes it', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(window), findsNothing);
  });

  testWidgets('a small window keeps a margin round the panel', (tester) async {
    await open(tester);
    tester.view.physicalSize = const Size(700, 500);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(window)),
      const Size(
        700 - 2 * FloatingWindow.margin,
        500 - 2 * FloatingWindow.margin,
      ),
    );
  });
}

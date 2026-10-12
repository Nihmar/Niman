// #712: the app's one list of choices is a sheet where a thumb taps and a
// pop-up menu where a pointer aims.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/floating_window.dart';

void main() {
  late Future<String?> result;

  Future<void> open(WidgetTester tester, {required bool dense}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: dense ? VisualDensity.compact : null),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                key: const Key('open'),
                onPressed: () {
                  result = showActionSheet<String>(
                    context,
                    title: 'Pick one',
                    sheetKey: const Key('choice-sheet'),
                    anchor: menuAnchorOf(context),
                    items: (context) => [
                      ListTile(
                        key: const Key('choice-one'),
                        title: const Text('One'),
                        onTap: () => Navigator.pop(context, 'one'),
                      ),
                      ListTile(
                        key: const Key('choice-two'),
                        title: const Text('Two'),
                        onTap: () => Navigator.pop(context, 'two'),
                      ),
                    ],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('a pointer gets a menu, the rows still closing it', (
    tester,
  ) async {
    await open(tester, dense: true);
    expect(find.byKey(const Key('choice-sheet')), findsOne);
    expect(find.text('Pick one'), findsOne);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byKey(const Key('choice-two')));
    await tester.pumpAndSettle();
    expect(await result, 'two');
  });

  testWidgets('inside a floating window the menu grows from its button '
      '(#780)', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: VisualDensity.compact),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showFloatingWindow(
              context,
              title: 'Window',
              panelKey: const Key('window'),
              // The window's own navigator and overlay: not the screen's
              // origin.
              builder: (context) => Center(
                child: Builder(
                  builder: (button) => TextButton(
                    key: const Key('menu-button'),
                    onPressed: () => showActionSheet<String>(
                      button,
                      sheetKey: const Key('choice-sheet'),
                      anchor: menuAnchorOf(button),
                      items: (context) => [
                        ListTile(
                          title: const Text('One'),
                          onTap: () => Navigator.pop(context, 'one'),
                        ),
                      ],
                    ),
                    child: const Text('menu'),
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-button')));
    await tester.pumpAndSettle();

    final button = tester.getRect(find.byKey(const Key('menu-button')));
    final menu = tester.getRect(find.byKey(const Key('choice-sheet')));
    final window = tester.getRect(find.byKey(const Key('window')));
    // The menu opens over the button, its rows from the button's corner
    // (the menu's own padding above them), not a window's offset away.
    expect(window.contains(menu.topLeft), isTrue);
    expect(menu.left, closeTo(button.left, 1));
    expect(menu.top, closeTo(button.top, 12));
  });

  testWidgets('a thumb gets the sheet', (tester) async {
    await open(tester, dense: false);
    expect(find.byKey(const Key('choice-sheet')), findsOne);
    expect(find.byType(BottomSheet), findsOne);
    await tester.tap(find.byKey(const Key('choice-one')));
    await tester.pumpAndSettle();
    expect(await result, 'one');
  });
}

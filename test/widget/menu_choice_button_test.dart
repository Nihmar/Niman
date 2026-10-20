// The app's drop-down (#1119, #1123): inline or as a form's field, it opens
// the app's own popup menu — the pointer's compact rows on a desktop, a
// thumb's on a phone — and a null among the options is a pick like any.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/menu_choice_button.dart';
import 'package:niman/src/ui/pointer_menu.dart';
import 'package:niman/src/ui/pointer_menu_scope.dart';

/// A desktop's theme: pointer-dense.
final ThemeData _pointer = ThemeData(visualDensity: VisualDensity.compact);

/// A phone's theme: standard density.
final ThemeData _touch = ThemeData(visualDensity: VisualDensity.standard);

const List<MenuChoice<String?>> _options = [
  (null, 'Same as the app'),
  ('a', 'Alpha'),
  ('b', 'Beta'),
];

void main() {
  final rows = find.byWidgetPredicate((w) => w is PopupMenuItem<int>);

  Future<List<String?>> pump(
    WidgetTester tester,
    ThemeData theme, {
    String? value = 'a',
    InputDecoration? decoration,
  }) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picked = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (context, child) => PointerMenuScope(child: child!),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MenuChoiceButton<String?>(
                  key: const Key('choice'),
                  value: value,
                  options: _options,
                  decoration: decoration,
                  itemKey: (value) => Key('choice-$value'),
                  onChanged: picked.add,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return picked;
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('choice')));
    await tester.pumpAndSettle();
    expect(rows, findsNWidgets(_options.length));
  }

  void expectRowHeight(double height) {
    for (final row in rows.evaluate()) {
      expect(row.size!.height, height);
    }
  }

  for (final (name, decoration) in [
    ('inline', null),
    ('as a field', const InputDecoration(labelText: 'Theme')),
  ]) {
    group(name, () {
      testWidgets("on a pointer, has the app's compact rows", (tester) async {
        await pump(tester, _pointer, decoration: decoration);
        await open(tester);
        expectRowHeight(pointerDenseItemHeight);
      });

      testWidgets("on a phone, keeps a thumb's rows", (tester) async {
        await pump(tester, _touch, decoration: decoration);
        await open(tester);
        expectRowHeight(kMinInteractiveDimension);
      });

      testWidgets('a null option is picked, not taken for a dismissal', (
        tester,
      ) async {
        final picked = await pump(tester, _pointer, decoration: decoration);
        await open(tester);
        await tester.tap(find.byKey(const Key('choice-null')));
        await tester.pumpAndSettle();
        expect(picked, [null]);
      });
    });
  }

  testWidgets("inline, it is as tall as one of the menu's rows", (
    tester,
  ) async {
    await pump(tester, _pointer);
    expect(
      tester.getSize(find.byKey(const Key('choice'))).height,
      pointerDenseItemHeight,
    );
    await pump(tester, _touch);
    // The app's theme animates to the new one.
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('choice'))).height,
      kMinInteractiveDimension,
    );
  });

  testWidgets('as a field, the label frames the value and the current one '
      'is checked', (tester) async {
    await pump(
      tester,
      _pointer,
      value: 'b',
      decoration: const InputDecoration(labelText: 'Theme'),
    );
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    await open(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('choice-b')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });
}

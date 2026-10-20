// The app's switch is drawn for the device (#1125): Material's 52 x 32
// touch switch on a thumb's theme, a smaller one that takes only the room
// it draws on a pointer's, and the same control either way.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_switch.dart';
import 'package:niman/src/ui/app_switch_list_tile.dart';

final ThemeData _pointer = ThemeData(visualDensity: VisualDensity.compact);
final ThemeData _touch = ThemeData(visualDensity: VisualDensity.standard);

Future<void> _pump(WidgetTester tester, ThemeData theme, Widget body) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: body)),
    ),
  );
}

void main() {
  testWidgets('a pointer gets the small switch, with no target around it', (
    tester,
  ) async {
    await _pump(
      tester,
      _pointer,
      AppSwitch(key: const Key('s'), value: true, onChanged: (_) {}),
    );
    final size = tester.getSize(find.byKey(const Key('s')));
    expect(size.width, closeTo(52 * AppSwitch.pointerScale, 0.01));
    expect(size.height, closeTo(32 * AppSwitch.pointerScale, 0.01));
    expect(size.width, inInclusiveRange(36, 38));
    expect(size.height, inInclusiveRange(22, 24));
    // The switch inside is drawn at the same size, not just boxed in it.
    final inner = tester.getRect(find.byType(Switch));
    expect(inner.width, closeTo(size.width, 0.01));
    expect(inner.height, closeTo(size.height, 0.01));
  });

  testWidgets('a thumb gets the switch of Material, target and all', (
    tester,
  ) async {
    await _pump(
      tester,
      _touch,
      AppSwitch(key: const Key('s'), value: true, onChanged: (_) {}),
    );
    final size = tester.getSize(find.byKey(const Key('s')));
    expect(size.height, 48);
    expect(size.width, greaterThan(52));
    expect(find.byType(FittedBox), findsNothing);
  });

  for (final (name, theme) in [('pointer', _pointer), ('thumb', _touch)]) {
    testWidgets('a tap flips it on a $name', (tester) async {
      final seen = <bool>[];
      await _pump(
        tester,
        theme,
        AppSwitch(key: const Key('s'), value: false, onChanged: seen.add),
      );
      await tester.tap(find.byKey(const Key('s')));
      expect(seen, [true]);
    });

    testWidgets('a disabled one ignores a tap on a $name', (tester) async {
      await _pump(
        tester,
        theme,
        const AppSwitch(key: Key('s'), value: false, onChanged: null),
      );
      await tester.tap(find.byKey(const Key('s')), warnIfMissed: false);
      await tester.pump();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });
  }

  testWidgets('a pointer switch takes the keyboard, focus and all', (
    tester,
  ) async {
    final seen = <bool>[];
    await _pump(tester, _pointer, AppSwitch(value: false, onChanged: seen.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(seen, [true]);
  });

  testWidgets('the row of a list tile flips the switch', (tester) async {
    final seen = <bool>[];
    await _pump(
      tester,
      _pointer,
      AppSwitchListTile(
        value: true,
        title: const Text('Remind me'),
        onChanged: seen.add,
      ),
    );
    await tester.tap(find.text('Remind me'));
    expect(seen, [false]);
    await tester.tap(find.byType(Switch));
    expect(seen, [false, false]);
  });

  testWidgets('a list tile without a handler is disabled', (tester) async {
    await _pump(
      tester,
      _pointer,
      const AppSwitchListTile(
        value: true,
        title: Text('Remind me'),
        onChanged: null,
      ),
    );
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });
}

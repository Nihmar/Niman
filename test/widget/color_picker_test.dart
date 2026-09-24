// Issue #269: the color picker — the square, the hue bar and the hex
// field are three ways into the same color, and what comes out is a color
// a theme can store.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/color_picker_dialog.dart';

void main() {
  /// Opens the picker on [initial], does [move] in it, and answers with
  /// what OK returned.
  Future<Color?> pick(
    WidgetTester tester,
    Color initial,
    Future<void> Function(WidgetTester) move,
  ) async {
    Color? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showColorPickerDialog(
                context,
                title: 'accent',
                initial: initial,
              ).then((value) => result = value),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await move(tester);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.actionOk));
    await tester.pumpAndSettle();
    return result;
  }

  /// A press at [point], moved a little so the drag is recognized.
  Future<void> panTo(WidgetTester tester, Offset point) async {
    final gesture = await tester.startGesture(point);
    await gesture.moveBy(const Offset(1, 0));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('the square takes saturation and value', (tester) async {
    final picked = await pick(tester, const Color(0xFF3366CC), (tester) async {
      // The bottom-left corner is no saturation and no value: black.
      final square = tester.getRect(
        find.byKey(const Key('color-picker-square')),
      );
      await panTo(tester, square.bottomLeft + const Offset(4, -4));
    });

    expect(picked, isNotNull);
    // No saturation, and almost no value: as good as black.
    for (final channel in [picked!.r, picked.g, picked.b]) {
      expect(channel, lessThan(0.05));
    }
  });

  testWidgets('the hue bar takes the hue', (tester) async {
    final picked = await pick(tester, const Color(0xFF3366CC), (tester) async {
      // The far left of the bar is hue 0: red.
      final bar = tester.getRect(find.byKey(const Key('color-picker-hue')));
      await panTo(tester, Offset(bar.left + 2, bar.center.dy));
    });

    final hsv = HSVColor.fromColor(picked!);
    expect(hsv.hue, lessThan(5));
    // The saturation and the value came along untouched.
    expect(hsv.saturation, closeTo(0.75, 0.05));
  });

  testWidgets('the hex field is the third way in', (tester) async {
    final picked = await pick(tester, const Color(0xFF000000), (tester) async {
      await tester.enterText(
        find.byKey(const Key('color-picker-hex')),
        '#00695C',
      );
      await tester.pumpAndSettle();
    });

    expect(picked, const Color(0xFF00695C));
  });

  testWidgets('what comes out is a color a theme can store', (tester) async {
    final picked = await pick(tester, const Color(0xFF3366CC), (tester) async {
      final square = tester.getRect(
        find.byKey(const Key('color-picker-square')),
      );
      await panTo(tester, square.center);
    });

    // Opaque, and 8-bit: `#RRGGBB` is what a theme file holds.
    expect(picked!.toARGB32() & 0xFF000000, 0xFF000000);
    expect(picked, Color(picked.toARGB32()));
  });
}

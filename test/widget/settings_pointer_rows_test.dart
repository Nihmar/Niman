// #712: where a pointer aims, a settings choice is a drop-down under its
// field and a scale is a slider in its row; a phone keeps the dialogs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/settings_dialogs.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/settings_slider_row.dart';

void main() {
  Widget app(Widget child, {required bool dense}) => MaterialApp(
    theme: ThemeData(
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
    ),
    home: Scaffold(body: child),
  );

  Widget choiceRow(List<String> picked) => Builder(
    builder: (context) => SettingsValueRow(
      title: 'Keep',
      value: '7 days',
      onTap: () async {
        final days = await showSettingsChoice<int>(
          context,
          dialogKey: const Key('keep-dialog'),
          title: 'Keep',
          current: 7,
          options: const [
            SettingsOption(7, '7 days'),
            SettingsOption(30, '30 days'),
          ],
        );
        picked.add('$days');
      },
    ),
  );

  testWidgets('a pointer picks from a drop-down under the field', (
    tester,
  ) async {
    final picked = <String>[];
    await tester.pumpWidget(app(choiceRow(picked), dense: true));
    final field = find.byType(OutlinedButton);
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(find.byType(SimpleDialog), findsNothing);
    final option = find.byKey(const Key('settings-choice-30'));
    expect(
      tester.getTopLeft(option).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(field).dy - 1),
      reason: 'under the field',
    );
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(picked, ['30']);
  });

  testWidgets('a phone keeps the dialog', (tester) async {
    await tester.pumpWidget(app(choiceRow([]), dense: false));
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(find.byType(SimpleDialog), findsOne);
  });

  testWidgets('a slider row keeps a drag when it is let go', (tester) async {
    final kept = <double>[];
    await tester.pumpWidget(
      app(
        SettingsSliderRow(
          sliderKey: const Key('s'),
          title: 'Size',
          value: 1,
          min: 0.5,
          max: 1.5,
          divisions: 10,
          format: (v) => '${(v * 100).round()} %',
          onChanged: kept.add,
        ),
        dense: true,
      ),
    );
    expect(find.text('100 %'), findsOne);
    final slider = find.byKey(const Key('s'));
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(Offset(tester.getSize(slider).width / 4, 0));
    await tester.pump();
    expect(kept, isEmpty, reason: 'not while dragging');
    expect(find.text('100 %'), findsNothing, reason: 'the value follows');
    await gesture.up();
    await tester.pump();
    expect(kept, hasLength(1));
    expect(kept.single, greaterThan(1));
  });
}

// #712: a desktop types a time into fields (input mode), a phone turns
// the dial #504 kept.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/os_pickers.dart';

void main() {
  Future<void> open(WidgetTester tester, TargetPlatform platform) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showClockPicker(
              context,
              initialTime: const TimeOfDay(hour: 9, minute: 30),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a desktop opens the time picker in its input mode (#712)', (
    tester,
  ) async {
    await open(tester, TargetPlatform.linux);
    final clock = tester.widget<TimePickerDialog>(
      find.byType(TimePickerDialog),
    );
    expect(clock.initialEntryMode, TimePickerEntryMode.input);
  });

  testWidgets('a phone keeps the dial (#504)', (tester) async {
    await open(tester, TargetPlatform.android);
    final clock = tester.widget<TimePickerDialog>(
      find.byType(TimePickerDialog),
    );
    expect(clock.initialEntryMode, TimePickerEntryMode.dial);
  });
}

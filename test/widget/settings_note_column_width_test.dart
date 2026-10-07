// The note column's width reads as a share of the default column, not in
// pixels: 700 px is 100%, and the slider runs 70%–200% in 5% steps. The
// settings file still stores pixels, so nothing written before moves.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/ui/settings_editor.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  test('a width reads as a share of the default column', () {
    expect(AppStrings.noteColumnWidthValue(defaultNoteColumnWidth), '100%');
    expect(AppStrings.noteColumnWidthValue(minNoteColumnWidth), '70%');
    expect(AppStrings.noteColumnWidthValue(maxNoteColumnWidth), '200%');
    // A width set by hand off the 5% grid still reads as a whole number.
    expect(AppStrings.noteColumnWidthValue(820), '117%');
  });

  testWidgets('the slider stops on round percentages and saves pixels', (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsEditorScreen(controller: controller, spellCheck: null),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.byKey(SettingsKeys.noteColumnWidth);
    await tester.scrollUntilVisible(row, 200);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    expect(find.descendant(of: row, matching: find.text('100%')), findsOne);

    await tester.tap(row);
    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(
      find.byKey(const Key('note-column-width-slider')),
    );
    // Every stop is a whole 5% of the default column.
    final step = (slider.max - slider.min) / slider.divisions!;
    expect(step, defaultNoteColumnWidth * 0.05);

    await tester.drag(
      find.byKey(const Key('note-column-width-slider')),
      const Offset(-2000, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('70%'), findsOne);
    await tester.tap(find.byKey(const Key('settings-slider-save')));
    await tester.pumpAndSettle();

    expect(await controller.noteColumnWidth, minNoteColumnWidth);
    expect(find.descendant(of: row, matching: find.text('70%')), findsOne);
  });
}

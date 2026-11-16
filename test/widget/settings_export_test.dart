// Settings → Export (#1285): the paper a PDF export is printed on, picked
// from the sizes offered, kept app-wide, and found by the settings search.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/paper_size.dart';
import 'package:niman/src/ui/settings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsBody(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the paper is A4 until another is picked, and is kept', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('settings-area-export')));
    await tester.pumpAndSettle();
    final row = find.byKey(const Key('pdf-paper-setting'));
    expect(
      find.descendant(of: row, matching: find.text('A4 · 210 × 297 mm')),
      findsOneWidget,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    // Every size is offered.
    for (final size in PaperSize.values) {
      expect(find.byKey(Key('settings-choice-$size')), findsOneWidget);
    }
    await tester.tap(find.byKey(Key('settings-choice-${PaperSize.letter}')));
    await tester.pumpAndSettle();
    expect(controller.pdfPaperValue, PaperSize.letter);
    expect(
      find.descendant(of: row, matching: find.text('Letter · 8.5 × 11 in')),
      findsOneWidget,
    );
  });
}

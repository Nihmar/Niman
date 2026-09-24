// Settings → Appearance → Book appearance (#280): the sheet the book's Aa
// button opens, reached from Settings too, on the same values.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/settings_keys.dart';

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
    EpubLooks.reset();
  });

  testWidgets('the row opens the sheet and says what was picked', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsBody(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-area-appearance')));
    await tester.pumpAndSettle();
    expect(find.text('Literata · 100%'), findsOneWidget);

    await tester.tap(find.byKey(SettingsKeys.epubLook));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('epub-look-font-mono')));
    await tester.pumpAndSettle();
    expect((await controller.epubLook).font, EpubFont.mono);

    // The sheet closed, the row reads the new face.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('epub-look-sheet')), findsNothing);
    expect(find.text('Monospace · 100%'), findsOneWidget);
  });
}
